import 'dart:async';
import 'dart:convert';

import 'package:btc_blake2b_wallet/core/models/lightning_channel.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_connection.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_invoice_record.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_movement.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/lightning_service.dart';
import 'package:btc_blake2b_wallet/core/services/lightning/nwc_lightning_service.dart';
import 'package:btc_blake2b_wallet/core/services/nostr/nostr_crypto.dart';
import 'package:btc_blake2b_wallet/core/services/nostr/nostr_event.dart';
import 'package:btc_blake2b_wallet/core/services/nostr/nostr_transport.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nodo finto che parla il PROTOCOLLO VERO: decifra le richieste NIP-04,
/// risponde cifrato e firmato (kind 23195/23199), emette notifiche.
class FakeDlnNode implements NostrTransport {
  FakeDlnNode() {
    nodePubHex = NostrCrypto.derivePublicKey(nodePrivHex);
  }

  final String nodePrivHex = NostrCrypto.randomHex32();
  late final String nodePubHex;

  final StreamController<NostrEvent> _controller =
      StreamController<NostrEvent>.broadcast();
  bool _connected = false;
  DateTime? _connectedSince;

  /// Se true, non risponde (per il test del timeout).
  bool silent = false;

  /// Se true, NON risponde alla prossima richiesta (poi torna normale):
  /// simula una risposta persa (socket zombie).
  bool silentOnce = false;

  /// Conta le connessioni: verifica il riciclo del socket.
  int connectCalls = 0;

  /// Se valorizzato, risponde con questo errore.
  String? forcedErrorCode;

  final List<Map<String, dynamic>> receivedRequests = [];
  final List<NostrEvent> published = [];

  @override
  bool get isConnected => _connected;

  @override
  DateTime? get connectedSince => _connectedSince;

  /// Se true, connect fallisce (per testare CONNECT_FAILED).
  bool failConnect = false;

  @override
  Future<void> connect(String relayUrl) async {
    if (failConnect) {
      throw Exception('relay down (test)');
    }
    connectCalls++;
    _connected = true;
    _connectedSince = DateTime.now();
  }

  @override
  Future<void> close() async {
    // // PERCHÉ (test): NON chiude lo stream — il service si riconnette più
    // volte (connect chiama disconnect prima) e deve poter ri-sottoscrivere.
    _connected = false;
    _connectedSince = null;
  }

  @override
  Stream<NostrEvent> subscribe(List<Map<String, dynamic>> filters) =>
      _controller.stream;

  @override
  Future<void> publish(NostrEvent event) async {
    published.add(event);
    if (event.kind != NwcLightningService.nwcRequestKind &&
        event.kind != NwcLightningService.nccRequestKind) {
      return;
    }

    // Il nodo decifra con la propria privkey + pubkey del mittente.
    final plaintext = NostrCrypto.nip04Decrypt(
      privkeyHex: nodePrivHex,
      pubkeyHex: event.pubkey,
      payload: event.content,
    );
    final request = (jsonDecode(plaintext) as Map).cast<String, dynamic>();
    receivedRequests.add(request);
    if (silent) return;
    if (silentOnce) {
      // Risposta "persa": il client deve riciclare e ritentare.
      silentOnce = false;
      return;
    }

    Map<String, dynamic>? result;
    Map<String, dynamic>? error;
    final method = '${request['method']}';
    if (forcedErrorCode != null) {
      error = {'code': forcedErrorCode, 'message': 'access denied (test)'};
    } else {
      result = _handle(
        method,
        (request['params'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
    }

    final responseJson = jsonEncode({
      'result_type': method,
      'result': result,
      'error': error,
    });
    final encrypted = NostrCrypto.nip04Encrypt(
      privkeyHex: nodePrivHex,
      pubkeyHex: event.pubkey,
      plaintext: responseJson,
    );
    final response = NostrEvent.unsigned(
      pubkey: nodePubHex,
      kind: event.kind == NwcLightningService.nwcRequestKind
          ? NwcLightningService.nwcResponseKind
          : NwcLightningService.nccResponseKind,
      tags: [
        ['p', event.pubkey],
        ['e', event.id],
      ],
      content: encrypted,
    ).sign(nodePrivHex);

    // Simula il giro sul relay: risposta emessa in un microtask successivo.
    scheduleMicrotask(() => _controller.add(response));
  }

  Map<String, dynamic> _handle(String method, Map<String, dynamic> params) {
    switch (method) {
      case 'get_info':
        return {
          'alias': 'test-node',
          'pubkey': nodePubHex,
          'network': 'bitcoin',
          'color': '0203a0',
          'version': 'v26.06.7-blake2b.2',
          'num_peers': 10,
          'num_peers_connected': 3,
          'num_active_channels': 1,
          'num_pending_channels': 0,
          'blockheight': 100,
          'block_height': 100,
        };
      case 'list_transactions':
        return {
          'transactions': [
            {
              'id': '1-0',
              'type': 'deposit',
              'direction': 'in',
              'amount_msat': 5606000,
              'timestamp': 1789316694,
              'blockheight': 971877,
              'outpoint': 'aa:0',
            },
            {
              'id': '2-1',
              'type': 'invoice',
              'direction': 'out',
              'amount_msat': 1000000,
              'timestamp': 1789364186,
            },
          ],
          'total': 2,
        };
      case 'get_balance':
        return {'balance': 42000, 'onchain': 12000, 'lightning': 30000};
      case 'make_invoice':
        return {
          'invoice': 'lnbcrt1test${params['amount'] ?? 0}',
          'payment_hash': 'aabbccdd' * 8,
        };
      case 'pay_invoice':
        return {'preimage': 'ccddeeff' * 8, 'fees_paid': 7};
      case 'list_channels':
        return {
          'channels': [
            {
              'id': 'ch1',
              'short_channel_id': '1000x1x0',
              'peer_pubkey': '02${'bb' * 32}',
              'alias': 'peer-one',
              'state': 'Usable',
              'is_private': false,
              'local_balance': 60000,
              'remote_balance': 40000,
              'capacity': 100000,
              'confirmations': 6,
              'fee_base_msat': 1000,
              'fee_proportional_millionths': 10,
              'htlc_count': 2,
              'spendable_msat': 59000,
              'receivable_msat': 39000,
              'peer_connected': true,
              'status': ['CHANNELD_NORMAL:Funding transaction locked.'],
            },
          ],
        };
      case 'open_channel':
      case 'close_channel':
        return {};
      case 'make_new_address':
        final addrType = '${params['type'] ?? 'bech32'}';
        return {
          'address': addrType == 'p2tr'
              ? 'bc1pfaketest000000000000000000000000000'
              : 'bc1qfaketest000000000000000000000000000',
          'type': addrType,
        };
      case 'estimate_onchain_fees':
        return {'min': 1, 'economical': 2, 'priority': 4};
      case 'pay_onchain':
        return {'txid': 'dd' * 32};
      case 'list_addresses':
        return {
          'addresses': [
            {
              'address': 'bc1qaddr1',
              'type': 'bech32',
              'keyidx': 1,
              'has_funds': true,
            },
            {'address': 'bc1qaddr2', 'type': 'bech32', 'keyidx': 2},
          ],
        };
      case 'list_utxos':
        return {
          'utxos': [
            {
              'txid':
                  'b34ada856e581d18a5f6ef2718767b159aaa88f2e32abf34f97d89f037b10cd6',
              'vout': 1,
              'amount_msat': 19382000,
              'address': 'bc1p8ypv5',
              'status': 'confirmed',
              'blockheight': 971913,
              'reserved': false,
            },
            {
              'txid': 'cc99',
              'vout': 0,
              'amount_msat': 5000000,
              'status': 'unconfirmed',
              'reserved': true,
            },
          ],
        };
      case 'list_invoices':
        return {
          'invoices': [
            {
              'payment_hash': 'hp1',
              'label': 'nwcb-1',
              'amount_msat': 1000000,
              'amount_received_msat': 1000000,
              'status': 'paid',
              'description': 'prima',
              'paid_at': 1789400000,
              'expires_at': 1789978076,
              'created_index': 1,
            },
            {
              'payment_hash': 'hp2',
              'label': 'nwcb-2',
              'amount_msat': 2000000,
              'status': 'unpaid',
              'expires_at': 1000000,
              'created_index': 2,
            },
          ],
          'total': 2,
        };
      case 'lookup_invoice':
        return {
          'payment_hash': '${params['payment_hash'] ?? params['label']}',
          'label': 'nwcb-1',
          'amount_msat': 1000000,
          'status': 'paid',
          'paid_at': 1789400000,
        };
      case 'list_pays':
        return {
          'pays': [
            {
              'payment_hash': 'pay1',
              'destination': '02peer1',
              'amount_msat': 2000000,
              'amount_sent_msat': 2002000,
              'status': 'complete',
              'created_at': 1789364186,
              'completed_at': 1789364187,
              'created_index': 1,
            },
            {
              'payment_hash': 'pay2',
              'amount_msat': 1000000,
              'amount_sent_msat': 1000000,
              'status': 'failed',
              'created_at': 1789365000,
              'created_index': 2,
            },
          ],
          'total': 2,
        };
      case 'get_pending_htlcs':
        return {
          'htlcs': [
            {
              'id': 1,
              'short_channel_id': '1000x1x0',
              'payment_hash': 'h1',
              'amount_msat': 1500000,
              'direction': 'out',
              'state': 'SENT_ADD_HTLC',
              'expiry': 972200,
              'pending': true,
            },
            {
              'id': 0,
              'short_channel_id': '1000x1x0',
              'payment_hash': 'h2',
              'amount_msat': 1000000,
              'direction': 'in',
              'state': 'RCVD_REMOVE_ACK_REVOCATION',
              'expiry': 972026,
              'pending': false,
            },
          ],
        };
      case 'get_channel_fees':
        return {
          'id': 'ch1',
          'short_channel_id': '1000x1x0',
          'fee_base_msat': 2000,
          'fee_proportional_millionths': 25,
          'htlc_min_msat': 1000,
          'htlc_max_msat': 150000000,
          'cltv_delta': 34,
          'our_reserve_msat': 1500000,
          'to_self_delay': 144,
        };
      case 'set_channel_fees':
        return {
          'id': 'ch1',
          'fee_base_msat': 5000,
          'fee_proportional_millionths': 25,
          'htlc_min_msat': 1000,
          'htlc_max_msat': 150000000,
          'cltv_delta': 34,
          'warning': 'htlcmin raised by peer',
        };
      case 'list_peers':
        return {
          'peers': [
            {
              'id': '02${'dd' * 32}',
              'alias': 'peer-one',
              'connected': true,
              'num_channels': 1,
              'addresses': ['140.99.254.11:9735'],
              'remote_addr': '1.2.3.4:1691',
            },
            {'id': '03${'ee' * 32}', 'connected': false},
          ],
        };
      case 'connect_peer':
      case 'disconnect_peer':
        return {};
      // ── I3e ────────────────────────────────────────────────
      case 'get_node_stats':
        return const {
          'net_msat': 34382000,
          'credits_msat': 35606000,
          'debits_msat': 1224000,
          'tags': [
            {
              'tag': 'deposit',
              'credit_msat': 35606000,
              'debit_msat': 0,
              'entries': 2,
            },
          ],
          'plugins': [
            {'name': 'keysend', 'active': true, 'dynamic': false},
          ],
          'forward_count': 1,
        };
      case 'get_forwarding_history':
        return const {
          'forwards': [
            {
              'in_channel': '1000x1x0',
              'out_channel': '1001x2x0',
              'in_msat': 2000000,
              'out_msat': 1999000,
              'fee_msat': 1000,
              'status': 'settled',
              'received_time': 1789364186,
            },
          ],
          'total': 1,
        };
      case 'get_network_node':
        return {
          'node_id': params['pubkey'],
          'alias': 'Paperclip Pool',
          'color': 'f56835',
          'last_timestamp': 1789321362,
          'features': '808898880a8a59a1',
          'addresses': [
            {'type': 'ipv4', 'address': '140.99.254.11', 'port': 9735},
          ],
        };
      case 'query_routes':
        final amount = (params['amount'] as num?)?.toInt() ?? 0;
        return {
          'route': [
            {
              'id': params['destination'],
              'channel': '1000x1x0',
              'direction': 0,
              'amount_msat': amount + 1000,
              'delay': 9,
              'style': 'tlv',
            },
          ],
          'fee_msat': 1000,
          'total_delay': 9,
        };
      case 'keysend':
        final amount = (params['amount_msat'] as num?)?.toInt() ?? 0;
        return {
          'destination': params['destination'],
          'payment_hash': 'kk1',
          'payment_preimage': 'pp1',
          'status': 'complete',
          'amount_msat': amount,
          'amount_sent_msat': amount + 1000,
          // PERCHÉ: la fee la calcola il bridge (`amount_sent − amount`): qui
          // si simula la risposta già mappata, non quella grezza del nodo.
          'fee_msat': 1000,
          'created_at': 1789364186,
        };
    }
    return {};
  }

  /// Emette una notifica NCC (channel_event) firmata dal nodo.
  void emitNotification() {
    final clientPub = published.isNotEmpty ? published.last.pubkey : nodePubHex;
    final event = NostrEvent.unsigned(
      pubkey: nodePubHex,
      kind: NwcLightningService.nccNotificationKind,
      tags: [
        ['p', clientPub],
      ],
      content: '',
    ).sign(nodePrivHex);
    _controller.add(event);
  }
}

void main() {
  late FakeDlnNode node;
  late NwcLightningService service;
  late LightningConnection connection;

  setUp(() async {
    node = FakeDlnNode();
    service = NwcLightningService(
      transport: node,
      requestTimeout: const Duration(milliseconds: 400),
    );
    connection = LightningConnection(
      walletPubkey: node.nodePubHex,
      relays: const ['wss://relay.test'],
      secretHex: NostrCrypto.randomHex32(),
    );
    await service.connect(connection);
  });

  tearDown(() async {
    await service.disconnect();
  });

  group('connessione', () {
    test('connect → stato connected', () {
      expect(service.isConnected, isTrue);
      expect(service.connectionState, LightningConnectionState.connected);
      expect(service.connection, same(connection));
    });

    test('disconnect → stato disconnected', () async {
      await service.disconnect();
      expect(service.isConnected, isFalse);
      expect(service.connection, isNull);
    });

    test('riconnette da solo se il relay cade (prima di una richiesta)',
        () async {
      // Simula la caduta del WebSocket (standby, cambio rete…).
      await node.close();
      expect(node.isConnected, isFalse);

      // La prossima richiesta deve riconnettere e completare.
      expect(await service.getBalanceMsat(), 42000);
      expect(node.isConnected, isTrue);
    });

    test('socket troppo vecchio → riciclo preventivo (zombie)', () async {
      final serviceAlt = NwcLightningService(
        transport: node,
        requestTimeout: const Duration(milliseconds: 400),
        maxSocketAge: const Duration(milliseconds: 30),
      );
      await serviceAlt.connect(connection);
      final connectsBefore = node.connectCalls;

      // Il socket resta "connesso" ma supera l'età massima: la prossima
      // richiesta deve passare da una connessione fresca.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(await serviceAlt.getBalanceMsat(), 42000);
      expect(node.connectCalls, greaterThan(connectsBefore));

      await serviceAlt.disconnect();
    });

    test('relay irraggiungibile → CONNECT_FAILED con messaggio chiaro',
        () async {
      await node.close();
      node.failConnect = true;
      await expectLater(
        service.getBalanceMsat(),
        throwsA(
          isA<LightningException>().having(
            (e) => e.code,
            'code',
            'CONNECT_FAILED',
          ),
        ),
      );
    });
  });

  group('NWC (pagamenti)', () {
    test('getBalanceMsat legge il campo balance (msat)', () async {
      expect(await service.getBalanceMsat(), 42000);
    });

    test('getInfo ritorna i dati del nodo', () async {
      final info = await service.getInfo();
      expect(info.alias, 'test-node');
      expect(info.network, 'bitcoin');
    });

    test('makeInvoice invia amount in msat e ritorna la bolt11', () async {
      final invoice = await service.makeInvoice(
        amountMsat: 21000,
        description: 'test',
      );
      expect(invoice.bolt11, 'lnbcrt1test21000');
      expect(invoice.paymentHash.length, 64);

      final last = node.receivedRequests.last;
      expect(last['method'], 'make_invoice');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['amount'], 21000);
      expect(params['description'], 'test');
    });

    test('payInvoice ritorna preimage e fee', () async {
      final result = await service.payInvoice('lnbcrt1abc');
      expect(result.preimage.startsWith('ccddeeff'), isTrue);
      expect(result.feesPaidMsat, 7);
    });
  });

  group('NCC (canali)', () {
    test('listChannels mappa la risposta LdkChannelInfo', () async {
      final channels = await service.listChannels();
      expect(channels, hasLength(1));
      final c = channels.first;
      expect(c.id, 'ch1');
      expect(c.state, 'Usable');
      expect(c.isUsable, isTrue);
      expect(c.capacity, 100000);
      expect(c.localBalance, 60000);
    });

    test('listChannels mappa alias, fee, HTLC e stato peer (I2)', () async {
      final c = (await service.listChannels()).first;
      expect(c.peerAlias, 'peer-one');
      expect(c.peerLabel, 'peer-one');
      expect(c.feeBaseMsat, 1000);
      expect(c.feePpm, 10);
      expect(c.htlcCount, 2);
      expect(c.spendableMsat, 59000);
      expect(c.receivableMsat, 39000);
      expect(c.peerConnected, isTrue);
      expect(c.status?.first, contains('CHANNELD_NORMAL'));
    });

    test('openChannel invia pubkey+amount_sats (spec)', () async {
      await service.openChannel(nodeId: '02${'cc' * 32}', amountSats: 20000);
      final last = node.receivedRequests.last;
      expect(last['method'], 'open_channel');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['pubkey'], '02${'cc' * 32}');
      expect(params['amount_sats'], 20000);
    });

    test('closeChannel invia id+force', () async {
      await service.closeChannel(channelId: 'ch1', force: true);
      final last = node.receivedRequests.last;
      expect(last['method'], 'close_channel');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['id'], 'ch1');
      expect(params['force'], isTrue);
    });
  });

  group('NCC (peer)', () {
    test('listPeers mappa alias, stato, indirizzi e remote_addr', () async {
      final peers = await service.listPeers();
      expect(peers, hasLength(2));

      final p = peers.first;
      expect(p.id, '02${'dd' * 32}');
      expect(p.alias, 'peer-one');
      expect(p.label, 'peer-one');
      expect(p.connected, isTrue);
      expect(p.numChannels, 1);
      expect(p.addresses, ['140.99.254.11:9735']);
      expect(p.remoteAddr, '1.2.3.4:1691');
    });

    test('peer senza alias/indirizzi → label = pubkey, default sicuri',
        () async {
      final p = (await service.listPeers())[1];
      expect(p.label, p.id);
      expect(p.alias, isNull);
      expect(p.addresses, isEmpty);
      expect(p.remoteAddr, isNull);
      expect(p.connected, isFalse);
    });

    test('connectPeer invia id + host', () async {
      await service.connectPeer(
        nodeId: '02${'dd' * 32}',
        host: '1.2.3.4:9735',
      );
      final last = node.receivedRequests.last;
      expect(last['method'], 'connect_peer');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['id'], '02${'dd' * 32}');
      expect(params['host'], '1.2.3.4:9735');
    });

    test('connectPeer senza host non invia il campo host', () async {
      await service.connectPeer(nodeId: '02${'dd' * 32}');
      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params.containsKey('host'), isFalse);
    });

    test('disconnectPeer invia id + force', () async {
      await service.disconnectPeer(nodeId: '02${'dd' * 32}', force: true);
      final last = node.receivedRequests.last;
      expect(last['method'], 'disconnect_peer');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['id'], '02${'dd' * 32}');
      expect(params['force'], isTrue);
    });

    test('timeout su list_peers → retry automatico (è una lettura)', () async {
      node.silentOnce = true;
      expect(await service.listPeers(), hasLength(2));
      expect(
        node.receivedRequests.where((r) => r['method'] == 'list_peers').length,
        2,
      );
    });

    test('timeout su connect_peer → nessun retry (evita doppio connect)',
        () async {
      node.silentOnce = true;
      await expectLater(
        service.connectPeer(nodeId: '02${'dd' * 32}'),
        throwsA(
          isA<LightningException>().having((e) => e.code, 'code', 'TIMEOUT'),
        ),
      );
      expect(
        node.receivedRequests
            .where((r) => r['method'] == 'connect_peer')
            .length,
        1,
      );
    });

    test('lista peer senza autorizzazione → isPermissionDenied', () async {
      node.forcedErrorCode = 'RESTRICTED';
      await expectLater(
        service.listPeers(),
        throwsA(
          isA<LightningException>().having(
            (e) => e.isPermissionDenied,
            'isPermissionDenied',
            isTrue,
          ),
        ),
      );
    });
  });

  group('errori e notifiche', () {
    test('RESTRICTED → LightningException con isPermissionDenied', () async {
      node.forcedErrorCode = 'RESTRICTED';
      await expectLater(
        service.getBalanceMsat(),
        throwsA(
          isA<LightningException>()
              .having((e) => e.code, 'code', 'RESTRICTED')
              .having(
                (e) => e.isPermissionDenied,
                'isPermissionDenied',
                isTrue,
              ),
        ),
      );
    });

    test('nodo silenzioso → TIMEOUT', () async {
      node.silent = true;
      await expectLater(
        service.getBalanceMsat(),
        throwsA(
          isA<LightningException>().having((e) => e.code, 'code', 'TIMEOUT'),
        ),
      );
    });

    test('timeout su lettura → riciclo connessione e retry automatico',
        () async {
      node.silentOnce = true;

      // Il primo tentativo si perde, il retry (su connessione fresca)
      // risponde: l'utente non vede l'errore.
      expect(await service.getBalanceMsat(), 42000);
      expect(
        node.receivedRequests.where((r) => r['method'] == 'get_balance').length,
        2,
      );
    });

    test('timeout su pay_invoice → nessun retry (evita doppi pagamenti)',
        () async {
      node.silentOnce = true;

      await expectLater(
        service.payInvoice('lnbcrt1test'),
        throwsA(
          isA<LightningException>().having((e) => e.code, 'code', 'TIMEOUT'),
        ),
      );
      expect(
        node.receivedRequests.where((r) => r['method'] == 'pay_invoice').length,
        1,
      );
    });

    test('notifica dal nodo → segnale su notifications', () async {
      final future = service.notifications.first;
      node.emitNotification();
      await future.timeout(const Duration(seconds: 2));
    });

    test('richiesta senza connessione → NOT_CONNECTED', () async {
      await service.disconnect();
      await expectLater(
        service.getBalanceMsat(),
        throwsA(
          isA<LightningException>()
              .having((e) => e.code, 'code', 'NOT_CONNECTED'),
        ),
      );
    });
  });

  group('modelli', () {
    test('LightningChannel difensivo su JSON minimo', () {
      final c = LightningChannel.fromJson(const {'id': 'x'});
      expect(c.id, 'x');
      expect(c.state, 'Unknown');
      expect(c.capacity, 0);
      expect(c.isUsable, isFalse);
    });
  });

  group('NWC (on-chain del nodo)', () {
    test('getBalance espone il breakdown onchain/lightning', () async {
      final balance = await service.getBalance();
      expect(balance.balanceSats, 42);
      expect(balance.onchainSats, 12);
      expect(balance.lightningSats, 30);
    });

    test('makeNewAddress ritorna un indirizzo on-chain', () async {
      final address = await service.makeNewAddress();
      expect(address.address.startsWith('bc1q'), isTrue);
      expect(address.type, 'bech32');
      expect(node.receivedRequests.last['method'], 'make_new_address');
    });

    test('makeNewAddress con addressType p2tr → indirizzo taproot', () async {
      final address = await service.makeNewAddress(addressType: 'p2tr');
      expect(address.address.startsWith('bc1p'), isTrue);
      expect(address.type, 'p2tr');
      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params['type'], 'p2tr');
    });

    test('listAddresses mappa keyidx, tipo e fondi', () async {
      final addresses = await service.listAddresses();
      expect(addresses, hasLength(2));
      expect(addresses.first.keyIndex, 1);
      expect(addresses.first.hasFunds, isTrue);
      expect(addresses.first.address, isNotEmpty);
      expect(addresses.last.keyIndex, 2);
      expect(addresses.last.hasFunds, isNull);
    });

    test('listUtxos invia list_utxos e mappa gli output', () async {
      final utxos = await service.listUtxos();
      expect(utxos, hasLength(2));

      final confirmed = utxos.first;
      expect(confirmed.vout, 1);
      expect(confirmed.amountSats, 19382);
      expect(confirmed.isConfirmed, isTrue);
      expect(confirmed.address, 'bc1p8ypv5');
      expect(confirmed.blockHeight, 971913);
      expect(confirmed.reserved, isFalse);

      final pending = utxos.last;
      expect(pending.isConfirmed, isFalse);
      expect(pending.reserved, isTrue);
      expect(node.receivedRequests.last['method'], 'list_utxos');
    });

    test('timeout su list_utxos → retry automatico (lettura)', () async {
      node.silentOnce = true;
      expect(await service.listUtxos(), hasLength(2));
      expect(
        node.receivedRequests.where((r) => r['method'] == 'list_utxos').length,
        2,
      );
    });

    test('listInvoices invia limit/offset e mappa gli stati', () async {
      final invoices = await service.listInvoices(limit: 10, offset: 5);
      expect(invoices, hasLength(2));

      final paid = invoices.first;
      expect(paid.paymentHash, 'hp1');
      expect(paid.state, LightningInvoiceState.paid);
      expect(paid.amountSats, 1000);
      expect(paid.paidDate, isNotNull);
      expect(paid.description, 'prima');

      final expired = invoices.last;
      expect(expired.state, LightningInvoiceState.expired);
      expect(expired.amountSats, 2000);

      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(node.receivedRequests.last['method'], 'list_invoices');
      expect(params['limit'], 10);
      expect(params['offset'], 5);
    });

    test('lookupInvoice per payment_hash e per label', () async {
      final byHash = await service.lookupInvoice(paymentHash: 'hp1');
      expect(byHash.isPaid, isTrue);
      var params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params['payment_hash'], 'hp1');
      expect(params.containsKey('label'), isFalse);

      final byLabel = await service.lookupInvoice(label: 'nwcb-1');
      expect(byLabel.paymentHash, 'nwcb-1');
      params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params['label'], 'nwcb-1');
      expect(params.containsKey('payment_hash'), isFalse);
    });

    test('timeout su list_invoices → retry automatico (lettura)', () async {
      node.silentOnce = true;
      expect(await service.listInvoices(), hasLength(2));
      expect(
        node.receivedRequests
            .where((r) => r['method'] == 'list_invoices')
            .length,
        2,
      );
    });

    test('timeout su lookup_invoice → retry automatico (lettura)', () async {
      node.silentOnce = true;
      final invoice = await service.lookupInvoice(paymentHash: 'hp1');
      expect(invoice.isPaid, isTrue);
      expect(
        node.receivedRequests
            .where((r) => r['method'] == 'lookup_invoice')
            .length,
        2,
      );
    });

    test('listPays invia limit/offset e calcola la fee', () async {
      final pays = await service.listPays(limit: 10, offset: 2);
      expect(pays, hasLength(2));

      final complete = pays.first;
      expect(complete.paymentHash, 'pay1');
      expect(complete.isComplete, isTrue);
      expect(complete.amountSats, 2000);
      expect(complete.feeSats, 2);
      expect(complete.date, isNotNull);

      final failed = pays.last;
      expect(failed.isComplete, isFalse);
      expect(failed.feeSats, 0);

      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(node.receivedRequests.last['method'], 'list_pays');
      expect(params['limit'], 10);
      expect(params['offset'], 2);
    });

    test('listPendingHtlcs mappa direzione, stato e flag', () async {
      final htlcs = await service.listPendingHtlcs();
      expect(htlcs, hasLength(2));

      final pending = htlcs.first;
      expect(pending.pending, isTrue);
      expect(pending.state, 'SENT_ADD_HTLC');
      expect(pending.isIncoming, isFalse);
      expect(pending.amountSats, 1500);

      final settled = htlcs.last;
      expect(settled.pending, isFalse);
      expect(settled.isIncoming, isTrue);
      expect(node.receivedRequests.last['method'], 'get_pending_htlcs');
    });

    test('timeout su list_pays → retry automatico (lettura)', () async {
      node.silentOnce = true;
      expect(await service.listPays(), hasLength(2));
      expect(
        node.receivedRequests.where((r) => r['method'] == 'list_pays').length,
        2,
      );
    });

    test('timeout su get_pending_htlcs → retry automatico (lettura)', () async {
      node.silentOnce = true;
      expect(await service.listPendingHtlcs(), hasLength(2));
      expect(
        node.receivedRequests
            .where((r) => r['method'] == 'get_pending_htlcs')
            .length,
        2,
      );
    });

    test('getChannelFees invia l id e mappa la policy', () async {
      final fees = await service.getChannelFees(channelId: 'ch1');

      expect(node.receivedRequests.last['method'], 'get_channel_fees');
      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params['id'], 'ch1');

      expect(fees.id, 'ch1');
      expect(fees.feeBaseSats, 2);
      expect(fees.feePpm, 25);
      expect(fees.htlcMinSats, 1);
      expect(fees.htlcMaxSats, 150000);
      expect(fees.cltvDelta, 34);
      expect(fees.reserveSats, 1500);
      expect(fees.toSelfDelay, 144);
    });

    test('setChannelFees invia solo i valori presenti e riporta il warning',
        () async {
      final fees = await service.setChannelFees(
        channelId: 'ch1',
        baseMsat: 5000,
        ppm: 25,
      );

      final last = node.receivedRequests.last;
      expect(last['method'], 'set_channel_fees');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['id'], 'ch1');
      expect(params['base_msat'], 5000);
      expect(params['ppm'], 25);
      // Limiti non toccati → non inviati (il nodo li lascia invariati).
      expect(params.containsKey('htlc_min_msat'), isFalse);
      expect(params.containsKey('htlc_max_msat'), isFalse);

      expect(fees.feeBaseMsat, 5000);
      expect(fees.warning, 'htlcmin raised by peer');
    });

    test('timeout su set_channel_fees → NESSUN retry (è una scrittura)',
        () async {
      node.silentOnce = true;
      await expectLater(
        service.setChannelFees(channelId: 'ch1', ppm: 30),
        throwsA(
          isA<LightningException>().having((e) => e.code, 'code', 'TIMEOUT'),
        ),
      );
      expect(
        node.receivedRequests
            .where((r) => r['method'] == 'set_channel_fees')
            .length,
        1,
      );
    });

    test('getNodeStats mappa economia e plugin (NCC, con retry)', () async {
      node.silentOnce = true;
      final stats = await service.getNodeStats();

      expect(
        node.receivedRequests
            .where((r) => r['method'] == 'get_node_stats')
            .length,
        2,
      );
      // Il comando è NCC (kind 23198).
      expect(
        node.published.firstWhere((e) => e.kind == 23198).kind,
        23198,
      );
      expect(stats.netSats, 34382);
      expect(stats.tags.single.tag, 'deposit');
      expect(stats.plugins.single.name, 'keysend');
      expect(stats.forwardCount, 1);
    });

    test('listForwards invia la paginazione e mappa i forward', () async {
      final forwards = await service.listForwards(limit: 10, offset: 0);

      final last = node.receivedRequests.last;
      expect(last['method'], 'get_forwarding_history');
      expect((last['params'] as Map)['limit'], 10);
      expect((last['params'] as Map)['offset'], 0);

      expect(forwards.single.feeSats, 1);
      expect(forwards.single.isSettled, isTrue);
    });

    test('getNodeInfo invia pubkey e mappa alias e indirizzi', () async {
      final node0 = await service.getNodeInfo('02${'aa' * 32}');

      expect(node0.displayName, 'Paperclip Pool');
      expect(node0.addresses.single.label, '140.99.254.11:9735');
      expect(
        (node.receivedRequests.last['params'] as Map)['pubkey'],
        '02${'aa' * 32}',
      );
    });

    test('getRoute invia destinazione/importo/risk e mappa la rotta', () async {
      final route = await service.getRoute(
        destination: '02${'aa' * 32}',
        amountMsat: 1000000,
        riskFactor: 5,
      );

      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params['destination'], '02${'aa' * 32}');
      expect(params['amount'], 1000000);
      expect(params['risk_factor'], 5);

      expect(route.feeSats, 1);
      expect(route.hops.single.channel, '1000x1x0');
    });

    test('sendKeysend converte in msat e invia maxfee (NWC, senza retry)',
        () async {
      final result = await service.sendKeysend(
        destination: '02${'aa' * 32}',
        amountSats: 21,
        maxFeeMsat: 5000,
      );

      final last = node.receivedRequests.last;
      expect(last['method'], 'keysend');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['destination'], '02${'aa' * 32}');
      expect(params['amount_msat'], 21000);
      expect(params['maxfee_msat'], 5000);

      expect(result.isComplete, isTrue);
      expect(result.amountSats, 21);
      expect(result.feeSats, 1);
      expect(result.preimage, 'pp1');
    });

    test('timeout su sendKeysend → NESSUN retry (muove fondi)', () async {
      node.silentOnce = true;
      await expectLater(
        service.sendKeysend(
          destination: '02${'aa' * 32}',
          amountSats: 10,
        ),
        throwsA(
          isA<LightningException>().having((e) => e.code, 'code', 'TIMEOUT'),
        ),
      );
      expect(
        node.receivedRequests.where((r) => r['method'] == 'keysend').length,
        1,
      );
    });

    test('estimateOnchainFees mappa i tre livelli', () async {
      final fees = await service.estimateOnchainFees();
      expect(fees.minSatVb, 1);
      expect(fees.economicalSatVb, 2);
      expect(fees.prioritySatVb, 4);
      expect(fees.isEmpty, isFalse);
    });

    test('payOnchain invia amount_sats e feerate in sat/vB (spec)', () async {
      final result = await service.payOnchain(
        address: 'bc1qdest',
        amountSats: 5000,
        feeRateSatVb: 2,
      );
      expect(result.txid, 'dd' * 32);
      final last = node.receivedRequests.last;
      expect(last['method'], 'pay_onchain');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['address'], 'bc1qdest');
      expect(params['amount_sats'], 5000);
      // PERCHÉ: il client parla in sat/vB (spec); la conversione perkw per CLN
      // la fa il bridge.
      expect(params['feerate'], 2);
    });

    test('payOnchain senza fee → nessun feerate nel payload', () async {
      await service.payOnchain(address: 'bc1qdest', amountSats: 1000);
      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params.containsKey('feerate'), isFalse);
    });

    test('listAddresses mappa gli indirizzi', () async {
      final list = await service.listAddresses();
      expect(list, hasLength(2));
      expect(list.first.address, 'bc1qaddr1');
      expect(list.first.type, 'bech32');
    });

    test('timeout su estimate_onchain_fees → retry automatico (lettura)',
        () async {
      node.silentOnce = true;
      // Lettura: il retry su connessione fresca non fa vedere l'errore.
      final fees = await service.estimateOnchainFees();
      expect(fees.economicalSatVb, 2);
    });

    test('timeout su pay_onchain → nessun retry (evita doppi invii)', () async {
      node.silentOnce = true;
      await expectLater(
        service.payOnchain(address: 'bc1qdest', amountSats: 1000),
        throwsA(
          isA<LightningException>().having((e) => e.code, 'code', 'TIMEOUT'),
        ),
      );
      expect(
        node.receivedRequests.where((r) => r['method'] == 'pay_onchain').length,
        1,
      );
    });
  });

  group('NWC (movimenti del nodo)', () {
    test('getInfo espone identità estesa (I3)', () async {
      final info = await service.getInfo();
      expect(info.version, 'v26.06.7-blake2b.2');
      expect(info.color, '0203a0');
      expect(info.numPeers, 10);
      // I4a: campo additivo del bridge (peer CONNESSI, non registrati).
      expect(info.numPeersConnected, 3);
      expect(info.numActiveChannels, 1);
      expect(info.numPendingChannels, 0);
      expect(info.blockHeight, 100);
    });

    test('listTransactions invia limit/offset e mappa i movimenti', () async {
      final movements = await service.listTransactions(limit: 25, offset: 5);
      expect(movements, hasLength(2));

      final first = movements.first;
      expect(first.type, LightningMovementType.deposit);
      expect(first.isIncoming, isTrue);
      expect(first.amountSats, 5606);
      expect(first.blockHeight, 971877);
      expect(first.outpoint, 'aa:0');

      final second = movements.last;
      expect(second.type, LightningMovementType.invoice);
      expect(second.isIncoming, isFalse);
      expect(second.amountSats, 1000);

      final last = node.receivedRequests.last;
      expect(last['method'], 'list_transactions');
      final params = (last['params'] as Map).cast<String, dynamic>();
      expect(params['limit'], 25);
      expect(params['offset'], 5);
    });

    test('listTransactions con i default invia 50/0', () async {
      await service.listTransactions();
      final params =
          (node.receivedRequests.last['params'] as Map).cast<String, dynamic>();
      expect(params['limit'], 50);
      expect(params['offset'], 0);
    });

    test('timeout su list_transactions → retry automatico (lettura)', () async {
      node.silentOnce = true;
      expect(await service.listTransactions(), hasLength(2));
      expect(
        node.receivedRequests
            .where((r) => r['method'] == 'list_transactions')
            .length,
        2,
      );
    });

    test('movimenti senza autorizzazione → isPermissionDenied', () async {
      node.forcedErrorCode = 'RESTRICTED';
      await expectLater(
        service.listTransactions(),
        throwsA(
          isA<LightningException>().having(
            (e) => e.isPermissionDenied,
            'isPermissionDenied',
            isTrue,
          ),
        ),
      );
    });
  });
}
