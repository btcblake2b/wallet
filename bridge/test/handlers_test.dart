import 'package:nwc_cln_bridge/src/cln/cln_api.dart';
import 'package:nwc_cln_bridge/src/handlers.dart';
import 'package:nwc_cln_bridge/src/protocol.dart';
import 'package:test/test.dart';

/// Nodo CLN finto: risponde con fixture e registra le chiamate.
class FakeCln implements ClnApi {
  FakeCln(this.responses);

  final Map<String, Map<String, dynamic>> responses;
  final List<String> calls = [];
  final List<Map<String, dynamic>> callParams = [];

  @override
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    calls.add(method);
    callParams.add(params);
    final r = responses[method];
    if (r == null) {
      throw RpcError('OTHER', 'comando non simulato: $method');
    }
    return r;
  }
}

/// Nodo CLN che fallisce i comandi indicati: serve a verificare la mappatura
/// dei messaggi CLN sui codici d'errore NIP-XX.
class ThrowingCln implements ClnApi {
  ThrowingCln(this.failures);

  /// comando CLN → messaggio d'errore del nodo.
  final Map<String, String> failures;

  @override
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    final msg = failures[method];
    if (msg != null) {
      throw RpcError('OTHER', msg);
    }
    return const {};
  }
}

/// FakeCln che finalizza lo splice solo dopo [securitiesNeeded] `splice_update`.
///
/// // PERCHÉ: CLN restituisce `commitments_secured` false finché il peer non ha
/// // risposto — firmare prima è rifiutato dal nodo.
class SlowSpliceCln implements ClnApi {
  SlowSpliceCln(this.responses, {this.securitiesNeeded = 2});

  final Map<String, Map<String, dynamic>> responses;
  final int securitiesNeeded;
  final List<String> calls = [];
  int updates = 0;

  @override
  Future<Map<String, dynamic>> call(
    String method, [
    Map<String, dynamic> params = const {},
  ]) async {
    calls.add(method);
    if (method == 'splice_update') {
      updates++;
      return {
        'psbt': 'cHNidP8UPD$updates',
        'commitments_secured': updates >= securitiesNeeded,
      };
    }
    final r = responses[method];
    if (r == null) {
      throw RpcError('OTHER', 'comando non simulato: $method');
    }
    return r;
  }
}

void main() {
  group('NwcHandlers', () {
    late FakeCln cln;
    late NwcHandlers handlers;

    Map<String, Map<String, dynamic>> baseResponses() => {
          'getinfo': {
            'id': '02aa',
            'alias': 'test-node',
            'blockheight': 100,
            'color': '0203a0',
            'version': 'v26.06.7-blake2b.2',
            'num_peers': 4,
            'num_active_channels': 1,
            'num_pending_channels': 0,
          },
          // Movimenti (I3): tag reali osservati sul nodo (bkpr).
          'bkpr-listaccountevents': {
            'events': [
              {
                'account': 'wallet',
                'type': 'chain',
                'tag': 'deposit',
                'credit_msat': 5606000,
                'debit_msat': 0,
                'outpoint': 'aa:0',
                'timestamp': 1000,
                'blockheight': 90,
              },
              {
                'account': 'wallet',
                'type': 'chain',
                'tag': 'withdrawal',
                'credit_msat': 0,
                'debit_msat': 2000000,
                'outpoint': 'bb:1',
                'timestamp': 2000,
                'blockheight': 95,
              },
              {
                'account': 'c1',
                'type': 'chain',
                'tag': 'channel_open',
                'credit_msat': 16000000,
                'debit_msat': 0,
                'outpoint': 'cc:0',
                'timestamp': 3000,
                'blockheight': 96,
              },
              {
                'account': 'c1',
                'type': 'channel',
                'tag': 'invoice',
                'credit_msat': 1000000,
                'debit_msat': 0,
                'timestamp': 4000,
              },
              {
                'account': 'c1',
                'type': 'onchain_fee',
                'tag': 'onchain_fee',
                'credit_msat': 12000,
                'debit_msat': 0,
                'timestamp': 5000,
                'blockheight': 96,
              },
              {
                'account': 'wallet',
                'type': 'chain',
                'tag': 'channel_close',
                'credit_msat': 1500000,
                'debit_msat': 0,
                'timestamp': 6000,
              },
            ],
          },
          'listfunds': {
            'outputs': [
              {
                'amount_msat': 5000000,
                'status': 'confirmed',
                'reserved': false,
                'address': 'bc1qonchain1',
              },
              {'amount_msat': 1000000, 'status': 'unconfirmed'},
              {
                'amount_msat': 2000000,
                'status': 'confirmed',
                'reserved': true,
                'address': 'bc1qonchain2',
              },
            ],
          },
          'listpeerchannels': {
            'channels': [
              {
                'channel_id': 'fx1',
                'peer_id': '02bb',
                'state': 'CHANNELD_NORMAL',
                'private': false,
                'to_us_msat': 15000000,
                'total_msat': 16000000,
                'funding_txid': 'aa',
                'short_channel_id': '100x1x1',
                // Forma REALE su CLN: scid alias, non il nome del peer.
                'alias': {'local': '111x1x1', 'remote': '222x2x2'},
                'fee_base_msat': 1000,
                'fee_proportional_millionths': 10,
                'spendable_msat': 14000000,
                'receivable_msat': 500000,
                'peer_connected': true,
                'htlcs': <Map<String, dynamic>>[],
                // Forma reale (I3d): policy annunciata + reserve/delay.
                'updates': {
                  'local': {
                    'fee_base_msat': 1000,
                    'fee_proportional_millionths': 10,
                    'htlc_minimum_msat': 1000,
                    'htlc_maximum_msat': 15000000,
                    'cltv_expiry_delta': 34,
                  },
                },
                'our_reserve_msat': 160000,
                'their_reserve_msat': 160000,
                'our_to_self_delay': 144,
                'minimum_htlc_in_msat': 1000,
                'maximum_htlc_out_msat': 15000000,
              },
              {
                'channel_id': 'fx2',
                'peer_id': '02cc',
                'state': 'CHANNELD_AWAITING_LOCKIN',
                'private': true,
                'to_us_msat': 0,
                'total_msat': 20000000,
              },
            ],
          },
          'listpeers': {
            'peers': [
              {
                'id': '02bb',
                'connected': true,
                'num_channels': 1,
                'netaddr': ['1.2.3.4:9735'],
                'remote_addr': '5.6.7.8:1691',
              },
              {
                'id': '02cc',
                'connected': false,
                'num_channels': 0,
                'netaddr': <String>[],
              },
            ],
          },
          'listinvoices': {
            'invoices': [
              {
                'payment_hash': 'paid1',
                'status': 'paid',
                'amount_received_msat': 2000000,
                'label': 'lbl1',
              },
              {'payment_hash': 'unpaid1', 'status': 'unpaid'},
            ],
          },
          'listpays': {
            'pays': [
              {
                'payment_hash': 'sent1',
                'status': 'complete',
                'amount_msat': 1000000,
                'amount_sent_msat': 1001000,
              },
            ],
          },
          'disconnect': {},
          'invoice': {
            'bolt11': 'lnbc1test',
            'payment_hash': 'ph',
            'expires_at': 1234,
          },
          'pay': {
            'payment_preimage': 'pre',
            'amount_sent_msat': 1001000,
            'amount_msat': 1000000,
          },
          'offer': {
            'offer_id': 'oid1',
            'active': true,
            'single_use': false,
            'bolt12': 'lno1offer',
          },
          // PERCHÉ (26/10): un'offerta non si paga: va prima convertita in
          // fattura BOLT12 (`lni1…`) e solo quella si passa a `pay`.
          'fetchinvoice': {'invoice': 'lni1fetched'},
          'connect': {},
          'fundchannel': {'txid': 'ftx', 'channel_id': 'fid'},
          'close': {'tx': 'ctx'},
          // SPLICE: flusso PSBT di CLN (init → update → sign → signed).
          'fundpsbt': {
            'psbt': 'cHNidP8FUND',
            'feerate_per_kw': 2000,
            'estimated_final_weight': 1410,
          },
          'splice_init': {'psbt': 'cHNidP8INIT'},
          'splice_update': {
            'psbt': 'cHNidP8UPD',
            'commitments_secured': true,
          },
          'signpsbt': {'signed_psbt': 'cHNidP8SIGNED'},
          'splice_signed': {'psbt': 'cHNidP8DONE', 'txid': 'stx1'},
          'newaddr': {'bech32': 'bc1qtestaddress000000000000000000000'},
          'withdraw': {'txid': 'wtx1'},
          'feerates': {
            'perkb': {
              'opening': 2000,
              'unilateral_close': 5000,
              'min_acceptable': 1000,
            },
          },
          'listaddresses': {
            'addresses': [
              {'keyidx': 1, 'bech32': 'bc1qaddr1'},
            ],
          },
          'setchannel': {'channel_id': 'fx1'},
        };

    setUp(() {
      cln = FakeCln(baseResponses());
      handlers = NwcHandlers(cln: cln);
    });

    test('get_info espone alias, pubkey e rete blake2b', () async {
      final r = await handlers.handle('get_info', {});
      expect(r['alias'], 'test-node');
      expect(r['pubkey'], '02aa');
      expect(r['network'], 'blake2b');
      expect(r['methods'], contains('pay_invoice'));
    });

    test('get_balance somma canali attivi + onchain confermato non riservato',
        () async {
      final r = await handlers.handle('get_balance', {});
      // 5_000_000 (onchain) + 15_000_000 (canale attivo) — esclusi unconfirmed
      // e reserved.
      expect(r['balance'], 20000000);
    });

    test('make_invoice ritorna bolt11 + payment_hash + amount (msat)',
        () async {
      final r = await handlers.handle(
        'make_invoice',
        {'amount': 1000000, 'description': 'test'},
      );
      expect(r['invoice'], 'lnbc1test');
      expect(r['payment_hash'], 'ph');
      expect(r['amount'], 1000000);
      expect(r['expires_at'], 1234);
      // La label generata è unica e prefissata.
      final params = cln.callParams.last;
      expect('${params['label']}', startsWith('nwcb-'));
    });

    test('make_invoice senza amount → errore', () async {
      expect(
        () => handlers.handle('make_invoice', {}),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
    });

    test('pay_invoice ritorna preimage e fee calcolate', () async {
      final r = await handlers.handle('pay_invoice', {'invoice': 'lnbc1x'});
      expect(r['preimage'], 'pre');
      expect(r['fees_paid'], 1000);
    });

    // ── BOLT12 (offers) ─────────────────────────────────────────────────────

    test('pay_invoice con offerta lno1 → fetchinvoice e poi pay della invoice',
        () async {
      final r = await handlers.handle('pay_invoice', {
        'invoice':
            'lno1qgsqvgnwgcg35z6ee2h3yczraddm72xrfua9uve2rlrm9deu7xyfzrc',
      });
      // 1) prima il fetch della fattura dall'offerta (importo libero: nessuno)
      final fetch = cln.callParams.firstWhere(
        (p) => p.containsKey('offer'),
        orElse: () => const <String, dynamic>{},
      );
      expect(
        fetch['offer'],
        'lno1qgsqvgnwgcg35z6ee2h3yczraddm72xrfua9uve2rlrm9deu7xyfzrc',
      );
      expect(fetch.containsKey('amount_msat'), isFalse);
      // 2) poi il pagamento della FATTURA: `pay` non conosce `bolt12`
      final pay = cln.callParams.last;
      expect(pay['bolt11'], 'lni1fetched');
      expect(pay.containsKey('bolt12'), isFalse);
      expect(r['preimage'], 'pre');
    });

    test('pay_invoice con offerta e amount_msat → importo al fetchinvoice',
        () async {
      await handlers
          .handle('pay_invoice', {'invoice': 'lno1abc', 'amount_msat': 21000});
      final fetch = cln.callParams.firstWhere(
        (p) => p.containsKey('offer'),
        orElse: () => const <String, dynamic>{},
      );
      expect(fetch['offer'], 'lno1abc');
      expect(fetch['amount_msat'], '21000');
      // La invoice risultante è già con importo: `pay` non riceve amount_msat.
      final pay = cln.callParams.last;
      expect(pay['bolt11'], 'lni1fetched');
      expect(pay.containsKey('amount_msat'), isFalse);
    });

    test('make_offer crea un codice riutilizzabile', () async {
      final r = await handlers.handle('make_offer', {
        'description': 'Caffè',
        'amount_msat': 5000000,
      });
      final params = cln.callParams.last;
      expect(params['description'], 'Caffè');
      expect(params['amount'], '5000000msat');
      expect(params['single_use'], false);
      expect(r['bolt12'], 'lno1offer');
      expect(r['offer_id'], 'oid1');
      expect(r['amount_msat'], 5000000);
    });

    test('make_offer senza importo → offerta a importo libero (`any`)', () async {
      // PERCHÉ `any` e non "campo assente": CLN rifiuta `offer` senza amount
      // (`missing required parameter: amount`) — è così che «codice
      // riutilizzabile» senza importo falliva in app.
      await handlers.handle('make_offer', {'description': 'Offerta libera'});
      expect(cln.callParams.last['amount'], 'any');
      expect(cln.callParams.last.containsKey('amount'), isTrue);
    });

    test('make_offer senza description → BAD_REQUEST', () async {
      await expectLater(
        handlers.handle('make_offer', {'amount_msat': 1000}),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
      expect(cln.calls, isEmpty);
    });

    test('list_channels mappa stato, saldi (msat) e privacy', () async {
      final r = await handlers.handle('list_channels', {});
      final channels = (r['channels'] as List).cast<Map<String, dynamic>>();
      expect(channels, hasLength(2));

      final c1 = channels.first;
      expect(c1['id'], 'fx1');
      expect(c1['state'], 'Usable');
      expect(c1['is_private'], false);
      expect(c1['local_balance'], 15000000);
      expect(c1['remote_balance'], 1000000);
      expect(c1['capacity'], 16000000);
      expect(c1['short_channel_id'], '100x1x1');

      final c2 = channels[1];
      expect(c2['state'], 'PendingOpen');
      expect(c2['is_private'], true);
      expect(c2.containsKey('short_channel_id'), isFalse);
    });

    test('open_channel con host fa connect poi fundchannel', () async {
      final r = await handlers.handle('open_channel', {
        'pubkey': '02bf',
        'amount': 16000,
        'host': 'lightning.example.com:9735',
      });
      expect(cln.calls, ['connect', 'fundchannel']);
      expect(
        cln.callParams.first['id'],
        '02bf@lightning.example.com:9735',
      );
      final fc = cln.callParams.last;
      expect(fc['id'], '02bf');
      expect(fc['amount'], '16000');
      expect(fc['announce'], true);
      expect(r['txid'], 'ftx');
    });

    test('open_channel private → announce false', () async {
      await handlers.handle('open_channel', {
        'pubkey': '02bf',
        'amount': 20000,
        'private': true,
      });
      expect(cln.callParams.last['announce'], false);
    });

    test('open_channel con utxos → fundchannel riceve gli output scelti (A8)',
        () async {
      const txid =
          'b34ada856e581d18a5f6ef2718767b159aaa88f2e32abf34f97d89f037b10cd6';
      await handlers.handle('open_channel', {
        'pubkey': '02bf',
        'amount': 20000,
        'utxos': [
          '$txid:0',
          {'txid': txid, 'vout': 1},
        ],
      });
      final fc = cln.callParams.last;
      expect(fc['utxos'], ['$txid:0', '$txid:1']);
    });

    test('open_channel senza utxos → parametro assente (auto)', () async {
      await handlers
          .handle('open_channel', {'pubkey': '02bf', 'amount': 20000});
      expect(cln.callParams.last.containsKey('utxos'), isFalse);
    });

    test('open_channel con utxo malformato → BAD_REQUEST, nodo non chiamato',
        () async {
      await expectLater(
        handlers.handle('open_channel', {
          'pubkey': '02bf',
          'amount': 20000,
          'utxos': ['non-un-txid:0'],
        }),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
      expect(cln.calls, isEmpty);
    });

    test('close_channel force → unilateraltimeout 0', () async {
      await handlers.handle('close_channel', {'id': 'fx1', 'force': true});
      expect(cln.callParams.last['unilateraltimeout'], 0);
    });

    test('close_channel normale → nessun timeout forzato', () async {
      await handlers.handle('close_channel', {'id': 'fx1'});
      expect(cln.callParams.last.containsKey('unilateraltimeout'), isFalse);
    });

    // ── SPLICE: ridimensiona un canale senza chiuderlo ──────────────────────

    test('splice_channel splice-in segue il flusso PSBT di CLN', () async {
      final r = await handlers.handle('splice_channel', {
        'id': 'fx1',
        'amount_sats': 100000,
      });
      expect(cln.calls, [
        'fundpsbt',
        'splice_init',
        'splice_update',
        'signpsbt',
        'splice_signed',
      ]);
      expect(cln.callParams[0]['satoshi'], '100000sat');
      expect(cln.callParams[0]['feerate'], 'normal');
      expect(cln.callParams[1]['channel_id'], 'fx1');
      expect(cln.callParams[1]['relative_amount'], 100000);
      expect(cln.callParams[1]['initialpsbt'], 'cHNidP8FUND');
      expect(cln.callParams[2]['psbt'], 'cHNidP8INIT');
      expect(cln.callParams[3]['psbt'], 'cHNidP8UPD');
      expect(cln.callParams[4]['psbt'], 'cHNidP8SIGNED');
      expect(r['txid'], 'stx1');
      expect(r['amount_sats'], 100000);
    });

    test('splice_channel con utxos → fundpsbt riceve gli output scelti',
        () async {
      const txid =
          'b34ada856e581d18a5f6ef2718767b159aaa88f2e32abf34f97d89f037b10cd6';
      await handlers.handle('splice_channel', {
        'id': 'fx1',
        'amount_sats': 50000,
        'utxos': ['$txid:2'],
      });
      expect(cln.callParams.first['utxos'], ['$txid:2']);
    });

    test('splice_channel splice-out → niente fundpsbt, amount negativo',
        () async {
      await handlers.handle('splice_channel', {
        'id': 'fx1',
        'amount_sats': -40000,
      });
      expect(cln.calls, [
        'splice_init',
        'splice_update',
        'signpsbt',
        'splice_signed',
      ]);
      expect(cln.callParams.first['relative_amount'], -40000);
      expect(cln.callParams.first.containsKey('initialpsbt'), isFalse);
    });

    test('splice_channel rifiuta utxos su splice-out', () async {
      await expectLater(
        handlers.handle('splice_channel', {
          'id': 'fx1',
          'amount_sats': -1000,
          'utxos': ['aa:0'],
        }),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
      expect(cln.calls, isEmpty);
    });

    test('splice_channel senza amount → BAD_REQUEST', () async {
      await expectLater(
        handlers.handle('splice_channel', {'id': 'fx1'}),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
    });

    test('splice_channel con feerate non valida → BAD_REQUEST', () async {
      await expectLater(
        handlers.handle('splice_channel', {
          'id': 'fx1',
          'amount_sats': 1000,
          'feerate': 'normal; rm -rf /',
        }),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
      expect(cln.calls, isEmpty);
    });

    test('splice_channel mappa il fallimento del nodo su CHANNEL_FAILED',
        () async {
      final failing = NwcHandlers(
        cln: ThrowingCln({
          'splice_init': 'Peer does not support splicing',
        }),
      );
      await expectLater(
        failing.handle('splice_channel', {'id': 'fx1', 'amount_sats': -1000}),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'CHANNEL_FAILED'),
        ),
      );
    });

    test('splice_channel: fondi on-chain insufficienti → INSUFFICIENT_BALANCE',
        () async {
      // Messaggio reale di `fundpsbt` quando il wallet on-chain non basta.
      final failing = NwcHandlers(
        cln: ThrowingCln({
          'fundpsbt':
              'Could not afford 30000sat using all 1 available UTXOS: '
                  '25298sat short',
        }),
      );
      await expectLater(
        failing.handle('splice_channel', {'id': 'fx1', 'amount_sats': 30000}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.code, 'code', 'INSUFFICIENT_BALANCE'),
        ),
      );
    });

    test('splice_channel fallito dopo il funding → libera gli input', () async {
      // `fundpsbt` riserva 72 blocchi: se lo splice si ferma dopo, senza
      // `unreserveinputs` l'on-chain del nodo resterebbe bloccato ~12 h.
      final fake = FakeCln(baseResponses())
        ..responses['unreserveinputs'] = {
          'reservations': <Map<String, dynamic>>[],
        };
      fake.responses.remove('splice_init');
      final h = NwcHandlers(cln: fake);

      await expectLater(
        h.handle('splice_channel', {'id': 'fx1', 'amount_sats': 100000}),
        throwsA(isA<RpcError>()),
      );

      expect(fake.calls, contains('unreserveinputs'));
      final index = fake.calls.indexOf('unreserveinputs');
      expect(fake.callParams[index]['psbt'], 'cHNidP8FUND');
    });

    test('splice_channel attende commitments_secured prima di firmare',
        () async {
      // CLN: "Can't sign a splice until the splice is finalized using
      // splice_update" — serve ripetere l'update finché il peer risponde.
      final cln = SlowSpliceCln(baseResponses());
      final h = NwcHandlers(
        cln: cln,
        spliceUpdatePollInterval: Duration.zero,
      );

      final r = await h.handle('splice_channel', {
        'id': 'fx1',
        'amount_sats': 100000,
      });

      expect(cln.calls.where((c) => c == 'splice_update').length, 2);
      expect(cln.calls, contains('signpsbt'));
      expect(cln.calls.last, 'splice_signed');
      expect(r['txid'], 'stx1');
    });

    test('splice non finalizzato entro il timeout → CHANNEL_FAILED', () async {
      final cln = SlowSpliceCln(baseResponses(), securitiesNeeded: 99);
      final h = NwcHandlers(
        cln: cln,
        spliceUpdatePollInterval: Duration.zero,
        spliceFinalizeTimeout: Duration.zero,
      );

      await expectLater(
        h.handle('splice_channel', {'id': 'fx1', 'amount_sats': 100000}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.code, 'code', 'CHANNEL_FAILED')
              .having((e) => e.message, 'message', contains('finalizzato')),
        ),
      );
      expect(cln.calls, isNot(contains('signpsbt')));
    });

    test('estimate_splice ricava la fee da feerate e peso', () async {
      final r = await handlers.handle('estimate_splice', {
        'amount_sats': 100000,
      });
      expect(cln.calls, ['fundpsbt']);
      // La stima NON deve riservare input (72 blocchi di default = ~12 h).
      expect(cln.callParams.single['reserve'], 0);
      // 2000 perkw * 1410 WU / 1000 = 2820 sat
      expect(r['fee_sats'], 2820);
      expect(r['amount_sats'], 100000);
      expect(r['feerate'], 'normal');
    });

    test('estimate_splice rifiuta importi non positivi', () async {
      await expectLater(
        handlers.handle('estimate_splice', {'amount_sats': -1}),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST'),
        ),
      );
      expect(cln.calls, isEmpty);
    });

    test('metodo sconosciuto → NOT_IMPLEMENTED', () async {
      expect(
        () => handlers.handle('frobnicate', {}),
        throwsA(
          isA<RpcError>().having((e) => e.code, 'code', 'NOT_IMPLEMENTED'),
        ),
      );
    });

    // ── NIP-XX: alias dei metodi, unità e codici d'errore ───────────────────

    test('get_forwarding_history è alias di list_forwards (+from/until)',
        () async {
      final h = NwcHandlers(
        cln: FakeCln({
          'listforwards': {
            'forwards': [
              {
                'in_channel': 'a',
                'out_channel': 'b',
                'in_msat': 10,
                'out_msat': 9,
                'fee_msat': 1,
                'received_time': 100,
                'status': 'settled',
              },
              {
                'in_channel': 'c',
                'out_channel': 'd',
                'in_msat': 20,
                'out_msat': 19,
                'fee_msat': 1,
                'received_time': 200,
                'status': 'settled',
              },
            ],
          },
        }),
      );
      final a = await h.handle('list_forwards', {});
      final b = await h.handle('get_forwarding_history', {});
      expect(b['forwards'], a['forwards']);
      expect(b['total'], a['total']);
      // Campi spec accanto ai nostri (il primo è il più recente: t=200).
      final f = (b['forwards'] as List).first as Map<String, dynamic>;
      expect(f['incoming_channel_id'], 'c');
      expect(f['outgoing_amount'], 19);
      expect(f['fee_earned'], 1);
      // Finestra temporale inclusiva.
      final window = await h.handle('get_forwarding_history', {
        'from': 100,
        'until': 100,
      });
      expect((window['forwards'] as List), hasLength(1));
      final empty = await h.handle('get_forwarding_history', {'from': 201});
      expect(empty['forwards'], isEmpty);
      expect(empty['total'], 0);
    });

    test('query_routes è alias di get_route e accetta amount (spec)', () async {
      final cln = FakeCln({
        'getroute': {
          'route': [
            {'id': '02cc', 'channel': '100x1x1', 'amount_msat': 1001000},
          ],
        },
      });
      final r = await NwcHandlers(cln: cln).handle('query_routes', {
        'destination': '02cc',
        'amount': 1000000,
      });
      expect(cln.callParams.last['amount_msat'], 1000000);
      expect(r['fee_msat'], 1000);
    });

    test('get_network_node è alias di get_node_info e accetta pubkey',
        () async {
      final cln = FakeCln({
        'listnodes': {
          'nodes': [
            {'nodeid': '02bb', 'alias': 'Paperclip'},
          ],
        },
      });
      final r = await NwcHandlers(cln: cln).handle(
        'get_network_node',
        {'pubkey': '02bb'},
      );
      expect(cln.callParams.last['id'], '02bb');
      expect(r['pubkey'], '02bb');
      expect(r['node_id'], r['pubkey']);
    });

    test('open_channel accetta amount_sats (spec)', () async {
      final cln = FakeCln({
        'fundchannel': {'txid': 'ftx'},
      });
      await NwcHandlers(cln: cln).handle('open_channel', {
        'pubkey': '02bf',
        'amount_sats': 16000,
      });
      expect(cln.callParams.last['amount'], '16000');
    });

    test('pay_onchain accetta amount_sats e feerate in sat/vB', () async {
      final cln = FakeCln({
        'withdraw': {'txid': 'wtx1'},
      });
      await NwcHandlers(cln: cln).handle('pay_onchain', {
        'address': 'bc1qdest',
        'amount_sats': 12345,
        'feerate': 2,
      });
      final params = cln.callParams.last;
      expect(params['satoshi'], '12345');
      // 2 sat/vB = 500 sat/kw (perkw) — conversione del bridge, non dell'app.
      expect(params['feerate'], '500perkw');
    });

    test('make_new_address accetta type p2wpkh (spec) → bech32', () async {
      final cln = FakeCln({
        'newaddr': {'bech32': 'bc1qspec'},
      });
      final r = await NwcHandlers(cln: cln).handle(
        'make_new_address',
        {'type': 'p2wpkh'},
      );
      expect(cln.callParams.last['addresstype'], 'bech32');
      expect(r['address'], 'bc1qspec');
    });

    test('make_new_address con type sconosciuto → BAD_REQUEST', () async {
      expect(
        () => handlers.handle('make_new_address', {'type': 'p2sh'}),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
      );
    });

    test('errori CLN mappati sui codici NIP-XX', () async {
      Future<void> expectCode(
        String method,
        Map<String, dynamic> params,
        String clnMethod,
        String message,
        String code,
      ) async {
        final h = NwcHandlers(cln: ThrowingCln({clnMethod: message}));
        await expectLater(
          h.handle(method, params),
          throwsA(isA<RpcError>().having((e) => e.code, 'code', code)),
        );
      }

      await expectCode(
        'close_channel',
        {'id': 'fx9'},
        'close',
        'Unknown channel fx9',
        'NOT_FOUND',
      );
      await expectCode(
        'connect_peer',
        {'id': '02bf', 'host': '1.2.3.4'},
        'connect',
        'Could not connect to peer',
        'CONNECTION_FAILED',
      );
      await expectCode(
        'open_channel',
        {'pubkey': '02bf', 'amount_sats': 1000},
        'fundchannel',
        'Could not fund channel',
        'CHANNEL_FAILED',
      );
      await expectCode(
        'pay_onchain',
        {'address': 'bc1q', 'amount_sats': 1},
        'withdraw',
        'Insufficient funds',
        'INSUFFICIENT_BALANCE',
      );
      await expectCode(
        'query_routes',
        {'destination': '02cc', 'amount': 1},
        'getroute',
        'Could not find a route',
        'NOT_FOUND',
      );
    });

    test('make_new_address mappa newaddr → address', () async {
      final r = await handlers.handle('make_new_address', {});
      expect(r['address'], 'bc1qtestaddress000000000000000000000');
      expect(cln.calls, contains('newaddr'));
    });

    test('pay_onchain con importo → withdraw con satoshi', () async {
      final r = await handlers.handle('pay_onchain', {
        'address': 'bc1qdest',
        'amount_sat': 12345,
        'feerate': '500perkw',
      });
      expect(r['txid'], 'wtx1');
      final params = cln.callParams.last;
      expect(params['destination'], 'bc1qdest');
      expect(params['satoshi'], '12345');
      expect(params['feerate'], '500perkw');
    });

    test('pay_onchain senza importo → withdraw all', () async {
      await handlers.handle('pay_onchain', {'address': 'bc1qdest'});
      final params = cln.callParams.last;
      expect(params['all'], true);
      expect(params.containsKey('satoshi'), isFalse);
    });

    test('pay_onchain accetta amount in msat (futuro dln)', () async {
      await handlers.handle('pay_onchain', {
        'address': 'bc1qdest',
        'amount': 2000000,
      });
      expect(cln.callParams.last['satoshi'], '2000');
    });

    test('pay_onchain senza address → errore', () async {
      expect(
        () => handlers.handle('pay_onchain', {}),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
      );
    });

    test('estimate_onchain_fees converte perkb → sat/vB', () async {
      final r = await handlers.handle('estimate_onchain_fees', {});
      expect(r['min'], 1);
      expect(r['economical'], 2);
      expect(r['priority'], 5);
    });

    test('list_addresses usa listaddresses quando disponibile', () async {
      final r = await handlers.handle('list_addresses', {});
      final list = (r['addresses'] as List).cast<Map<String, dynamic>>();
      expect(list.single['address'], 'bc1qaddr1');
      expect(list.single['type'], 'bech32');
      expect(list.single['keyidx'], 1);
      // Nessun output di listfunds punta a questo indirizzo.
      expect(list.single['has_funds'], isFalse);
    });

    test('list_addresses senza listaddresses → fallback listfunds', () async {
      final fallbackCln = FakeCln(baseResponses())
        ..responses.remove('listaddresses');
      final h = NwcHandlers(cln: fallbackCln);
      final r = await h.handle('list_addresses', {});
      expect((r['addresses'] as List), isNotEmpty);
      expect(fallbackCln.calls, contains('listfunds'));
    });

    test('get_balance espone breakdown onchain/lightning', () async {
      final r = await handlers.handle('get_balance', {});
      expect(r['onchain'], 5000000);
      expect(r['lightning'], 15000000);
      expect(r['balance'], 20000000);
    });

    test('get_info espone block_height (spec dln)', () async {
      final r = await handlers.handle('get_info', {});
      expect(r['block_height'], 100);
    });

    test('list_channels espone fee, htlc e saldi spendibili (senza alias)',
        () async {
      final r = await handlers.handle('list_channels', {});
      final c1 = (r['channels'] as List).first as Map;
      // L'alias di listpeerchannels è un oggetto di scid alias: non va esposto.
      expect(c1.containsKey('alias'), isFalse);
      expect(c1['fee_base_msat'], 1000);
      expect(c1['fee_proportional_millionths'], 10);
      expect(c1['spendable_msat'], 14000000);
      expect(c1['receivable_msat'], 500000);
      expect(c1['peer_connected'], true);
      expect(c1['htlc_count'], 0);
    });

    test('list_peers mappa peer e indirizzi (senza alias)', () async {
      final r = await handlers.handle('list_peers', {});
      final peers = (r['peers'] as List).cast<Map<String, dynamic>>();
      expect(peers, hasLength(2));
      final p1 = peers.first;
      expect(p1['id'], '02bb');
      expect(p1.containsKey('alias'), isFalse);
      expect(p1['connected'], true);
      expect(p1['num_channels'], 1);
      expect(p1['addresses'], ['1.2.3.4:9735']);
      expect(p1['remote_addr'], '5.6.7.8:1691');
      final p2 = peers[1];
      expect(p2['id'], '02cc');
      expect(p2['connected'], false);
      expect(p2.containsKey('alias'), isFalse);
    });

    test('connect_peer invia id+host a CLN', () async {
      final r = await handlers.handle('connect_peer', {
        'pubkey': '02bf',
        'host': '1.2.3.4',
      });
      expect(r['id'], '02bf');
      final params = cln.callParams.last;
      expect(params['id'], '02bf');
      expect(params['host'], '1.2.3.4');
    });

    test('connect_peer accetta la forma compatta pubkey@host:porta', () async {
      await handlers.handle('connect_peer', {'id': '02bf@1.2.3.4:9735'});
      final params = cln.callParams.last;
      expect(params['id'], '02bf');
      expect(params['host'], '1.2.3.4');
      expect(params['port'], 9735);
    });

    test('connect_peer senza id → errore', () async {
      expect(
        () => handlers.handle('connect_peer', {}),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
      );
    });

    test('disconnect_peer normale e forzato', () async {
      await handlers.handle('disconnect_peer', {'id': '02bf'});
      expect(cln.callParams.last['id'], '02bf');
      expect(cln.callParams.last.containsKey('force'), isFalse);

      await handlers.handle('disconnect_peer', {'id': '02bf', 'force': true});
      expect(cln.callParams.last['force'], true);
    });

    test('pollNotifications: primo giro silenzioso', () async {
      final h = NwcHandlers(cln: FakeCln(baseResponses()));
      expect(await h.pollNotifications(), isEmpty);
    });

    test('pollNotifications: payment_received sui nuovi invoice pagati',
        () async {
      final fake = FakeCln(baseResponses());
      final h = NwcHandlers(cln: fake);
      // Priming: il pagamento 'paid1' è già presente al primo giro.
      await h.pollNotifications();
      fake.responses['listinvoices'] = {
        'invoices': [
          {'payment_hash': 'paid1', 'status': 'paid'},
          {
            'payment_hash': 'paid2',
            'status': 'paid',
            'amount_received_msat': 3000000,
            'label': 'lbl2',
          },
        ],
      };
      final n = await h.pollNotifications();
      expect(n, hasLength(1));
      expect(n.single.type, 'payment_received');
      expect(n.single.isNcc, isFalse);
      expect(n.single.payload['payment_hash'], 'paid2');
      expect(n.single.payload['amount_msat'], 3000000);
      expect(n.single.payload['description'], 'lbl2');
    });

    test('pollNotifications: payment_sent con fee calcolate', () async {
      final fake = FakeCln(baseResponses());
      fake.responses['listpays'] = {'pays': <Map<String, dynamic>>[]};
      final h = NwcHandlers(cln: fake);
      await h.pollNotifications();
      fake.responses['listpays'] = {
        'pays': [
          {
            'payment_hash': 'sent2',
            'status': 'complete',
            'amount_msat': 2000000,
            'amount_sent_msat': 2003000,
          },
        ],
      };
      final n = await h.pollNotifications();
      expect(n.single.type, 'payment_sent');
      expect(n.single.payload['fees_msat'], 3000);
    });

    test('pollNotifications: nessun duplicato sugli stessi pagamenti',
        () async {
      final h = NwcHandlers(cln: FakeCln(baseResponses()));
      await h.pollNotifications();
      await h.pollNotifications();
      expect(await h.pollNotifications(), isEmpty);
    });

    test('pollNotifications: channel_opened sui canali comparsi', () async {
      final fake = FakeCln(baseResponses());
      fake.responses['listpeerchannels'] = {
        'channels': <Map<String, dynamic>>[],
      };
      final h = NwcHandlers(cln: fake);
      await h.pollNotifications();
      fake.responses['listpeerchannels'] = {
        'channels': [
          {'channel_id': 'new1', 'peer_id': '02ff', 'total_msat': 20000000},
        ],
      };
      final n = await h.pollNotifications();
      expect(n, hasLength(1));
      expect(n.single.type, 'channel_opened');
      expect(n.single.isNcc, isTrue);
      expect(n.single.payload['channel_id'], 'new1');
      expect(n.single.payload['capacity_msat'], 20000000);
    });

    test('pollNotifications: channel_closed quando il canale sparisce',
        () async {
      final fake = FakeCln(baseResponses());
      final h = NwcHandlers(cln: fake);
      await h.pollNotifications();
      fake.responses['listpeerchannels'] = {
        'channels': <Map<String, dynamic>>[],
      };
      final n = await h.pollNotifications();
      expect(n.where((e) => e.type == 'channel_closed'), isNotEmpty);
    });

    test('pollNotifications: channel_resized quando cambia la capacità',
        () async {
      final fake = FakeCln(baseResponses());
      final h = NwcHandlers(cln: fake);
      await h.pollNotifications();

      // Stesso channel id, capacità cresciuta: è il segnale di splice-in.
      fake.responses['listpeerchannels'] = {
        'channels': [
          {
            'channel_id': 'fx1',
            'peer_id': '02bb',
            'state': 'CHANNELD_NORMAL',
            'total_msat': 25000000,
          },
          // Il secondo canale resta invariato: nessuna notifica per lui.
          {
            'channel_id': 'fx2',
            'peer_id': '02cc',
            'state': 'CHANNELD_AWAITING_LOCKIN',
            'total_msat': 20000000,
          },
        ],
      };
      final n = await h.pollNotifications();

      expect(n, hasLength(1));
      expect(n.single.type, 'channel_resized');
      expect(n.single.isNcc, isTrue);
      expect(n.single.payload['channel_id'], 'fx1');
      expect(n.single.payload['capacity_msat'], 25000000);
      expect(n.single.payload['previous_capacity_msat'], 16000000);
      expect(n.single.payload['delta_msat'], 9000000);
    });

    test('pollNotifications: capacità invariata → nessuna notifica', () async {
      final fake = FakeCln(baseResponses());
      final h = NwcHandlers(cln: fake);
      await h.pollNotifications();
      expect(await h.pollNotifications(), isEmpty);
    });

    test('get_info espone identità estesa e list_transactions', () async {
      final r = await handlers.handle('get_info', {});
      expect(r['color'], '0203a0');
      expect(r['version'], 'v26.06.7-blake2b.2');
      expect(r['num_peers'], 4);
      // Fixture listpeers: 1 connesso (02bb) su 2 → conteggio "veri" peer.
      expect(r['num_peers_connected'], 1);
      expect(r['num_active_channels'], 1);
      expect(r['num_pending_channels'], 0);
      expect(r['methods'], contains('list_transactions'));
      expect(r['methods'], contains('list_utxos'));
    });

    test('get_info: num_peers_connected omesso se listpeers fallisce',
        () async {
      final fake = FakeCln(baseResponses())..responses.remove('listpeers');
      final h = NwcHandlers(cln: fake);
      final r = await h.handle('get_info', {});
      expect(r.containsKey('num_peers_connected'), isFalse);
      expect(r['num_peers'], 4); // il resto della risposta resta valido
    });

    test('list_transactions ordina e mappa i movimenti (bkpr)', () async {
      final r = await handlers.handle('list_transactions', {});
      expect(r['total'], 6);
      final list = (r['transactions'] as List).cast<Map<String, dynamic>>();
      expect(list, hasLength(6));

      // Dal più recente al più vecchio.
      expect(list.first['timestamp'], 6000);
      expect(list.first['type'], 'channel_close');
      expect(list.last['timestamp'], 1000);
      expect(list.last['type'], 'deposit');
      expect(list.last['direction'], 'in');
      expect(list.last['amount_msat'], 5606000);
      expect(list.last['outpoint'], 'aa:0');

      // Un debito → direction=out con importo assoluto.
      final withdrawal = list.firstWhere((m) => m['type'] == 'withdrawal');
      expect(withdrawal['direction'], 'out');
      expect(withdrawal['amount_msat'], 2000000);
      expect(withdrawal.containsKey('outpoint'), isTrue);

      // bkpr accredita il CONTO del canale: per l'utente l'apertura è un'uscita
      // (e la fee on-chain un costo), la chiusura un' entrata.
      final open = list.firstWhere((m) => m['type'] == 'channel_open');
      expect(open['direction'], 'out');
      expect(open['amount_msat'], 16000000);
      final fee = list.firstWhere((m) => m['type'] == 'onchain_fee');
      expect(fee['direction'], 'out');
      expect(fee['amount_msat'], 12000);
      final close = list.firstWhere((m) => m['type'] == 'channel_close');
      expect(close['direction'], 'in');
    });

    test('list_transactions pagina con limit/offset', () async {
      final p1 = await handlers.handle('list_transactions', {'limit': 2});
      expect((p1['transactions'] as List), hasLength(2));
      expect(p1['total'], 6);

      final p2 = await handlers.handle(
        'list_transactions',
        {'limit': 2, 'offset': 2},
      );
      final timestamps = (p2['transactions'] as List)
          .map((m) => (m as Map)['timestamp'])
          .toList();
      expect(timestamps, [4000, 3000]);

      final empty = await handlers.handle('list_transactions', {'offset': 99});
      expect((empty['transactions'] as List), isEmpty);
      expect(empty['total'], 6);
    });

    test('list_transactions: limit fuori scala viene limitato', () async {
      final big = await handlers.handle('list_transactions', {'limit': 9999});
      expect((big['transactions'] as List), hasLength(6));

      final zero = await handlers.handle('list_transactions', {'limit': 0});
      expect((zero['transactions'] as List), hasLength(1));
    });

    test('list_transactions: tag ignoto → other, default sugli assenti',
        () async {
      final custom = FakeCln({
        ...baseResponses(),
        'bkpr-listaccountevents': {
          'events': [
            {
              'account': 'wallet',
              'type': 'chain',
              'tag': 'spend',
              'debit_msat': 100,
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle(
        'list_transactions',
        {},
      );
      final m = (r['transactions'] as List).first as Map;
      expect(m['type'], 'other');
      expect(m['direction'], 'out');
      expect(m['amount_msat'], 100);
      expect(m['timestamp'], 0);
      expect(m.containsKey('blockheight'), isFalse);
    });

    test('list_transactions senza eventi → lista vuota', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'bkpr-listaccountevents': {'events': <Map<String, dynamic>>[]},
      });
      final r = await NwcHandlers(cln: custom).handle(
        'list_transactions',
        {},
      );
      expect(r['transactions'], isEmpty);
      expect(r['total'], 0);
    });

    test('list_addresses mappa la forma reale (keyidx + bech32) e i fondi',
        () async {
      // Fixture col payload REALE del nodo: `{keyidx, bech32}` (niente
      // `address`, niente `used`) + un output con fondi sul primo indirizzo.
      final custom = FakeCln({
        ...baseResponses(),
        'listaddresses': {
          'addresses': [
            {'keyidx': 1, 'bech32': 'bc1qaddr1'},
            {'keyidx': 2, 'bech32': 'bc1qaddr2'},
          ],
        },
        'listfunds': {
          'outputs': [
            {
              'txid': 'aa',
              'output': 0,
              'amount_msat': 5000000,
              'status': 'confirmed',
              'reserved': false,
              'address': 'bc1qaddr1',
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('list_addresses', {});
      final list = (r['addresses'] as List).cast<Map<String, dynamic>>();

      expect(list, hasLength(2));
      expect(list.first['address'], 'bc1qaddr1');
      expect(list.first['type'], 'bech32');
      expect(list.first['keyidx'], 1);
      expect(list.first['has_funds'], isTrue);
      expect(list.last['address'], 'bc1qaddr2');
      expect(list.last['has_funds'], isFalse);
    });

    test('list_addresses: indirizzo vuoto scartato', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listaddresses': {
          'addresses': [
            {'keyidx': 1},
            {'keyidx': 2, 'bech32': 'bc1qaddr2'},
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('list_addresses', {});
      final list = (r['addresses'] as List).cast<Map<String, dynamic>>();
      expect(list, hasLength(1));
      expect(list.first['address'], 'bc1qaddr2');
    });

    test('make_new_address: default bech32, con address_type p2tr → p2tr',
        () async {
      final clnDefault = FakeCln({
        ...baseResponses(),
        'newaddr': {'bech32': 'bc1qnew'},
      });
      final h1 = NwcHandlers(cln: clnDefault);
      final r1 = await h1.handle('make_new_address', {});
      expect(r1['address'], 'bc1qnew');
      expect(r1['type'], 'bech32');
      expect(clnDefault.callParams.last['addresstype'], 'bech32');

      final clnTaproot = FakeCln({
        ...baseResponses(),
        'newaddr': {'p2tr': 'bc1pnew'},
      });
      final h2 = NwcHandlers(cln: clnTaproot);
      final r2 = await h2.handle('make_new_address', {'address_type': 'p2tr'});
      expect(r2['address'], 'bc1pnew');
      expect(r2['type'], 'p2tr');
      expect(clnTaproot.callParams.last['addresstype'], 'p2tr');
    });

    test('list_utxos mappa gli output di listfunds', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listfunds': {
          'outputs': [
            {
              'txid': 'b34a',
              'output': 1,
              'amount_msat': 19382000,
              'scriptpubkey': '5120aa',
              'address': 'bc1p8ypv5',
              'status': 'confirmed',
              'blockheight': 971913,
              'reserved': false,
            },
            {
              'txid': 'cc99',
              'output': 0,
              'amount_msat': 5000000,
              'status': 'unconfirmed',
              'reserved': true,
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('list_utxos', {});
      final list = (r['utxos'] as List).cast<Map<String, dynamic>>();

      expect(list, hasLength(2));
      expect(list.first['txid'], 'b34a');
      expect(list.first['vout'], 1);
      expect(list.first['amount_msat'], 19382000);
      expect(list.first['address'], 'bc1p8ypv5');
      expect(list.first['status'], 'confirmed');
      expect(list.first['blockheight'], 971913);
      expect(list.first['reserved'], isFalse);

      // Output senza indirizzo/altezza: i campi opzionali non compaiono.
      expect(list.last['status'], 'unconfirmed');
      expect(list.last['reserved'], isTrue);
      expect(list.last.containsKey('address'), isFalse);
      expect(list.last.containsKey('blockheight'), isFalse);
    });

    test('list_utxos senza output → lista vuota', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listfunds': {'outputs': <Map<String, dynamic>>[]},
      });
      final r = await NwcHandlers(cln: custom).handle('list_utxos', {});
      expect(r['utxos'], isEmpty);
    });

    test('delete_invoice: rimuove una fattura unpaid (label+status)', () async {
      final custom = FakeCln({
        'listinvoices': {
          'invoices': [
            {
              'label': 'nwcb-x',
              'payment_hash': 'hx',
              'amount_msat': 1000000,
              'status': 'unpaid',
            },
          ],
        },
        'delinvoice': <String, dynamic>{},
      });
      final r = await NwcHandlers(cln: custom).handle(
        'delete_invoice',
        {'label': 'nwcb-x'},
      );
      expect(r['deleted'], true);
      expect(r['label'], 'nwcb-x');
      final i = custom.calls.indexOf('delinvoice');
      expect(i, greaterThanOrEqualTo(0));
      expect(custom.callParams[i]['label'], 'nwcb-x');
      expect(custom.callParams[i]['status'], 'unpaid');
    });

    test('delete_invoice: fattura scaduta → status expired', () async {
      final custom = FakeCln({
        'listinvoices': {
          'invoices': [
            {'label': 'nwcb-e', 'payment_hash': 'he', 'status': 'expired'},
          ],
        },
        'delinvoice': <String, dynamic>{},
      });
      await NwcHandlers(cln: custom).handle(
        'delete_invoice',
        {'payment_hash': 'he'},
      );
      final i = custom.calls.indexOf('delinvoice');
      expect(custom.callParams[i]['status'], 'expired');
    });

    test('delete_invoice: una fattura PAGATA viene rifiutata', () async {
      final custom = FakeCln({
        'listinvoices': {
          'invoices': [
            {'label': 'nwcb-p', 'payment_hash': 'hp', 'status': 'paid'},
          ],
        },
        'delinvoice': <String, dynamic>{},
      });
      await expectLater(
        NwcHandlers(cln: custom).handle('delete_invoice', {'label': 'nwcb-p'}),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
      );
      expect(custom.calls, isNot(contains('delinvoice')));
    });

    test('delete_invoice: non trovata / senza parametri', () async {
      final custom = FakeCln({
        'listinvoices': {'invoices': <dynamic>[]},
        'delinvoice': <String, dynamic>{},
      });
      await expectLater(
        NwcHandlers(cln: custom).handle('delete_invoice', {'label': 'ghost'}),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'NOT_FOUND')),
      );
      await expectLater(
        NwcHandlers(cln: custom).handle('delete_invoice', {}),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
      );
    });

    test('list_invoices: forma reale, ordine per created_index, senza bolt11',
        () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listinvoices': {
          'invoices': [
            {
              'label': 'nwcb-1',
              'payment_hash': 'h1',
              'amount_msat': 1000000,
              'status': 'unpaid',
              'description': 'probe-test',
              'expires_at': 1789978076,
              'created_index': 2,
              'bolt11': 'lnbc1vecchia',
            },
            {
              'label': 'nwcb-2',
              'payment_hash': 'h2',
              'amount_msat': 2000000,
              'status': 'unpaid',
              'expires_at': 1789979000,
              'created_index': 5,
              'bolt11': 'lnbc1nuova',
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('list_invoices', {});
      expect(r['total'], 2);
      final list = (r['invoices'] as List).cast<Map<String, dynamic>>();

      // Più recente per prima (created_index 5).
      expect(list.first['payment_hash'], 'h2');
      expect(list.last['payment_hash'], 'h1');
      expect(list.last['description'], 'probe-test');
      expect(list.last['amount_msat'], 1000000);
      expect(list.last['status'], 'unpaid');
      expect(list.last['expires_at'], 1789978076);
      // Il bolt11 non viene mai esposto (payload).
      expect(list.first.containsKey('bolt11'), isFalse);
    });

    test('list_invoices: fattura pagata con campi opzionali', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listinvoices': {
          'invoices': [
            {
              'label': 'nwcb-paid',
              'payment_hash': 'hp',
              'amount_msat': 1000000,
              'amount_received_msat': 1000000,
              'status': 'paid',
              'paid_at': 1789400000,
              'created_index': 7,
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('list_invoices', {});
      final inv = (r['invoices'] as List).first as Map;
      expect(inv['status'], 'paid');
      expect(inv['paid_at'], 1789400000);
      expect(inv['amount_received_msat'], 1000000);
    });

    test('list_invoices: paginazione con limit/offset', () async {
      Map<String, dynamic> inv(int i) => {
            'label': 'nwcb-$i',
            'payment_hash': 'h$i',
            'amount_msat': 1000 * i,
            'status': 'unpaid',
            'created_index': i,
          };
      final custom = FakeCln({
        ...baseResponses(),
        'listinvoices': {
          'invoices': [for (var i = 1; i <= 5; i++) inv(i)],
        },
      });
      final h = NwcHandlers(cln: custom);

      final p1 = await h.handle('list_invoices', {'limit': 2});
      expect((p1['invoices'] as List), hasLength(2));
      expect(p1['total'], 5);
      expect(((p1['invoices'] as List).first as Map)['payment_hash'], 'h5');

      final p2 = await h.handle('list_invoices', {'limit': 2, 'offset': 2});
      expect(((p2['invoices'] as List).first as Map)['payment_hash'], 'h3');

      final empty = await h.handle('list_invoices', {'offset': 99});
      expect((empty['invoices'] as List), isEmpty);
    });

    test('list_invoices senza fatture → lista vuota', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listinvoices': {'invoices': <Map<String, dynamic>>[]},
      });
      final r = await NwcHandlers(cln: custom).handle('list_invoices', {});
      expect(r['invoices'], isEmpty);
      expect(r['total'], 0);
    });

    test('lookup_invoice per payment_hash e per label', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listinvoices': {
          'invoices': [
            {
              'label': 'nwcb-1',
              'payment_hash': 'h1',
              'amount_msat': 1000000,
              'status': 'paid',
              'paid_at': 1789400000,
            },
          ],
        },
      });
      final h = NwcHandlers(cln: custom);

      final byHash = await h.handle('lookup_invoice', {'payment_hash': 'h1'});
      expect(byHash['status'], 'paid');
      expect(custom.callParams.last['payment_hash'], 'h1');

      final byLabel = await h.handle('lookup_invoice', {'label': 'nwcb-1'});
      expect(byLabel['payment_hash'], 'h1');
      expect(custom.callParams.last['label'], 'nwcb-1');
      expect(custom.callParams.last.containsKey('payment_hash'), isFalse);
    });

    test('lookup_invoice senza parametri → errore', () async {
      expect(
        () => handlers.handle('lookup_invoice', {}),
        throwsA(isA<RpcError>().having((e) => e.code, 'code', 'BAD_REQUEST')),
      );
    });

    test('lookup_invoice non trovata → errore chiaro', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listinvoices': {'invoices': <Map<String, dynamic>>[]},
      });
      expect(
        () => NwcHandlers(cln: custom)
            .handle('lookup_invoice', {'payment_hash': 'zz'}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.message, 'message', contains('non trovata')),
        ),
      );
    });

    test('list_pays mappa i pagamenti e calcola la fee', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listpays': {
          'pays': [
            {
              'payment_hash': 'p1',
              'destination': '02peer1',
              'amount_msat': 1000000,
              'amount_sent_msat': 1002000,
              'status': 'complete',
              'created_at': 1789364186,
              'completed_at': 1789364187,
              'created_index': 1,
              'preimage': 'aa',
            },
            {
              'payment_hash': 'p2',
              'destination': '02peer2',
              'amount_msat': 2000000,
              'status': 'failed',
              'created_at': 1789365000,
              'created_index': 3,
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('list_pays', {});
      expect(r['total'], 2);
      final list = (r['pays'] as List).cast<Map<String, dynamic>>();

      // Più recente per prima (created_index 3).
      expect(list.first['payment_hash'], 'p2');
      expect(list.first['status'], 'failed');

      final complete = list.last;
      expect(complete['payment_hash'], 'p1');
      expect(complete['amount_msat'], 1000000);
      expect(complete['amount_sent_msat'], 1002000);
      expect(complete['fee_msat'], 2000);
      expect(complete['completed_at'], 1789364187);
      // La preimage non esce mai dal bridge.
      expect(complete.containsKey('preimage'), isFalse);

      // Senza `amount_sent_msat` la fee è 0 (amount == sent).
      expect(list.first['fee_msat'], 0);
    });

    test('list_pays pagina con limit/offset', () async {
      Map<String, dynamic> pay(int i) => {
            'payment_hash': 'p$i',
            'amount_msat': 1000 * i,
            'amount_sent_msat': 1000 * i + 10,
            'status': 'complete',
            'created_index': i,
          };
      final custom = FakeCln({
        ...baseResponses(),
        'listpays': {
          'pays': [for (var i = 1; i <= 4; i++) pay(i)],
        },
      });
      final h = NwcHandlers(cln: custom);

      final p1 = await h.handle('list_pays', {'limit': 2});
      expect((p1['pays'] as List), hasLength(2));
      expect(((p1['pays'] as List).first as Map)['payment_hash'], 'p4');

      final empty = await h.handle('list_pays', {'offset': 99});
      expect((empty['pays'] as List), isEmpty);
      expect(empty['total'], 4);
    });

    test('list_pays senza pagamenti → lista vuota', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listpays': {'pays': <Map<String, dynamic>>[]},
      });
      final r = await NwcHandlers(cln: custom).handle('list_pays', {});
      expect(r['pays'], isEmpty);
      expect(r['total'], 0);
    });

    test('get_pending_htlcs: pending derivato dallo state', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listhtlcs': {
          'htlcs': [
            {
              'id': 0,
              'short_channel_id': '971913x788x0',
              'payment_hash': 'h1',
              'amount_msat': 1000000,
              'direction': 'out',
              'state': 'RCVD_REMOVE_ACK_REVOCATION',
              'expiry': 972026,
            },
            {
              'id': 1,
              'short_channel_id': '971913x788x0',
              'payment_hash': 'h2',
              'amount_msat': 2000000,
              'direction': 'in',
              'state': 'SENT_ADD_HTLC',
              'expiry': 972100,
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('get_pending_htlcs', {});
      final list = (r['htlcs'] as List).cast<Map<String, dynamic>>();

      expect(list, hasLength(2));
      // Un HTLC concluso NON è in corso…
      expect(list.first['state'], 'RCVD_REMOVE_ACK_REVOCATION');
      expect(list.first['pending'], isFalse);
      // …mentre uno senza ACK_REVOCATION sì.
      expect(list.last['state'], 'SENT_ADD_HTLC');
      expect(list.last['pending'], isTrue);
      expect(list.last['direction'], 'in');
      expect(list.last['short_channel_id'], '971913x788x0');
    });

    test('get_pending_htlcs senza HTLC → lista vuota', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listhtlcs': {'htlcs': <Map<String, dynamic>>[]},
      });
      final r = await NwcHandlers(cln: custom).handle('get_pending_htlcs', {});
      expect(r['htlcs'], isEmpty);
    });

    test('get_channel_fees legge la policy annunciata (updates.local)',
        () async {
      final r = await handlers.handle('get_channel_fees', {'id': 'fx1'});
      expect(r['id'], 'fx1');
      expect(r['short_channel_id'], '100x1x1');
      expect(r['fee_base_msat'], 1000);
      expect(r['fee_proportional_millionths'], 10);
      expect(r['htlc_min_msat'], 1000);
      expect(r['htlc_max_msat'], 15000000);
      expect(r['cltv_delta'], 34);
      expect(r['our_reserve_msat'], 160000);
      expect(r['to_self_delay'], 144);
    });

    test('get_channel_fees accetta anche lo short_channel_id', () async {
      final r = await handlers.handle('get_channel_fees', {'id': '100x1x1'});
      expect(r['id'], 'fx1');
    });

    test('get_channel_fees: canale inesistente e id mancante → errore',
        () async {
      expect(
        () => handlers.handle('get_channel_fees', {'id': 'zz'}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.message, 'message', contains('non trovato')),
        ),
      );
      expect(
        () => handlers.handle('get_channel_fees', {}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.message, 'message', contains('richiede id')),
        ),
      );
    });

    test('set_channel_fees invia solo i valori presenti e rilegge la policy',
        () async {
      final r = await handlers.handle('set_channel_fees', {
        'id': 'fx1',
        'base_msat': 2000,
        'ppm': 25,
        'htlc_max_msat': 14000000,
        'enforce_delay': 60,
      });

      final sent = cln.callParams.lastWhere((p) => p.containsKey('feebase'));
      expect(sent['id'], 'fx1');
      expect(sent['feebase'], 2000);
      expect(sent['feeppm'], 25);
      expect(sent['htlcmax'], 14000000);
      expect(sent['enforcedelay'], 60);
      // htlcmin non richiesto → non inviato (setchannel lo lascia invariato).
      expect(sent.containsKey('htlcmin'), isFalse);

      // La risposta è la policy RILETTA dal nodo (il fake non muta lo stato:
      // qui interessa che la rilettura avvenga sullo stesso id).
      expect(r['id'], 'fx1');
      expect(r['fee_base_msat'], 1000);
    });

    test('set_channel_fees: nessun valore o id mancante → errore', () async {
      expect(
        () => handlers.handle('set_channel_fees', {'id': 'fx1'}),
        throwsA(
          isA<RpcError>().having(
            (e) => e.message,
            'message',
            contains('almeno un valore'),
          ),
        ),
      );
      expect(
        () => handlers.handle('set_channel_fees', {'ppm': 10}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.message, 'message', contains('richiede id')),
        ),
      );
    });

    test('set_channel_fees riporta il warning del nodo', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'setchannel': {
          'channel_id': 'fx1',
          'warning': 'htlcmin raised by peer',
        },
      });
      final r = await NwcHandlers(cln: custom).handle('set_channel_fees', {
        'id': 'fx1',
        'htlc_min_msat': 1,
      });
      expect(r['warning'], 'htlcmin raised by peer');
    });

    // ── I3e: rete & diagnostica ────────────────────────────────────────────
    // Fixture basate sulle forme REALI osservate sul nodo (15/09/2026):
    // bkpr-listincome, plugin list, listnodes, getroute.
    Map<String, dynamic> incomeFixture() => {
          'income_events': [
            {
              'account': 'wallet',
              'tag': 'deposit',
              'credit_msat': 30000000,
              'debit_msat': 0,
              'timestamp': 1789328953,
            },
            {
              'account': 'wallet',
              'tag': 'deposit',
              'credit_msat': 5606000,
              'debit_msat': 0,
              'timestamp': 1789316694,
            },
            {
              'account': 'c1',
              'tag': 'invoice',
              'credit_msat': 0,
              'debit_msat': 1000000,
              'timestamp': 1789364187,
            },
            {
              'account': 'c1',
              'tag': 'onchain_fee',
              'credit_msat': 0,
              'debit_msat': 224000,
              'timestamp': 1789334167,
            },
          ],
        };

    test('get_node_stats aggrega bkpr per tag, plugin e forward', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'bkpr-listincome': incomeFixture(),
        'plugin': {
          'command': 'list',
          'plugins': [
            {
              'name': '/home/f/cln/usr/libexec/plugins/keysend',
              'active': true,
              'dynamic': false,
            },
            {
              'name': '/home/f/cln/usr/libexec/plugins/liquidity-ads',
              'active': false,
              'dynamic': true,
            },
          ],
        },
        'listforwards': {
          'forwards': [
            {'in_channel': 'a', 'out_channel': 'b', 'status': 'settled'},
          ],
        },
      });

      final r = await NwcHandlers(cln: custom).handle('get_node_stats', {});

      expect(r['credits_msat'], 35606000);
      expect(r['debits_msat'], 1224000);
      expect(r['net_msat'], 34382000);

      final tags = (r['tags'] as List).cast<Map<String, dynamic>>();
      // Il tag più pesante (netto assoluto) per primo.
      expect(tags.first['tag'], 'deposit');
      expect(tags.first['entries'], 2);
      expect(tags.first['credit_msat'], 35606000);
      expect(
        tags.map((t) => t['tag']),
        containsAll(['invoice', 'onchain_fee']),
      );

      final plugins = (r['plugins'] as List).cast<Map<String, dynamic>>();
      expect(plugins.first['name'], 'keysend');
      expect(plugins.first['active'], isTrue);
      expect(plugins.last['name'], 'liquidity-ads');
      expect(plugins.last['active'], isFalse);
      expect(r['forward_count'], 1);
    });

    test('get_node_stats: bkpr vuoto e comandi accessori assenti', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'bkpr-listincome': {'income_events': <dynamic>[]},
      });
      final r = await NwcHandlers(cln: custom).handle('get_node_stats', {});

      expect(r['net_msat'], 0);
      expect(r['tags'], isEmpty);
      // plugin/listforwards non simulati: le stats restano valide.
      expect(r['plugins'], isEmpty);
      expect(r['forward_count'], 0);
    });

    test('list_forwards mappa i forward e pagina', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listforwards': {
          'forwards': [
            {
              'in_channel': 'a',
              'out_channel': 'b',
              'in_msat': 2000000,
              'out_msat': 1993000,
              'fee_msat': 7000,
              'status': 'settled',
              'received_time': 1000,
              'resolved_time': 1001,
            },
            {
              'in_channel': 'c',
              'out_channel': 'd',
              'in_msat': 0,
              'out_msat': 0,
              'status': 'failed',
              'received_time': 2000,
            },
          ],
        },
      });
      final handlers = NwcHandlers(cln: custom);
      final r = await handlers.handle('list_forwards', {});

      expect(r['total'], 2);
      final list = (r['forwards'] as List).cast<Map<String, dynamic>>();
      // Più recente per primo; un forward fallito non ha ancora una fee.
      expect(list.first['status'], 'failed');
      expect(list.first['received_time'], 2000);
      expect(list.first.containsKey('fee_msat'), isFalse);
      expect(list.last['fee_msat'], 7000);
      expect(list.last['resolved_time'], 1001);

      final paged = await handlers.handle('list_forwards', {
        'limit': 1,
        'offset': 1,
      });
      expect((paged['forwards'] as List).single['fee_msat'], 7000);
    });

    test('list_forwards senza forwarding → lista vuota', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listforwards': {'forwards': <dynamic>[]},
      });
      final r = await NwcHandlers(cln: custom).handle('list_forwards', {});
      expect(r['forwards'], isEmpty);
      expect(r['total'], 0);
    });

    test('get_node_info mappa il nodo dal gossip (sempre con id)', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listnodes': {
          'nodes': [
            {
              'nodeid': '02bfcaa8328a89aa03ef55b3b810dc0',
              'alias': 'Paperclip Pool',
              'color': 'f56835',
              'last_timestamp': 1789321362,
              'features': '808898880a8a59a1',
              'addresses': [
                {'type': 'ipv4', 'address': '140.99.254.11', 'port': 9735},
              ],
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('get_node_info', {
        'node_id': '02bfcaa8328a89aa03ef55b3b810dc0',
      });

      expect(r['alias'], 'Paperclip Pool');
      expect(r['color'], 'f56835');
      expect(r['features'], '808898880a8a59a1');
      final addr = (r['addresses'] as List).single as Map;
      expect(addr['address'], '140.99.254.11');
      expect(addr['port'], 9735);
      // Il gossip si interroga SEMPRE per id (mai la rete intera).
      expect(custom.callParams.last['id'], '02bfcaa8328a89aa03ef55b3b810dc0');
    });

    test('get_node_info: nodo assente o id mancante → errore', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'listnodes': {'nodes': <dynamic>[]},
      });
      expect(
        () =>
            NwcHandlers(cln: custom).handle('get_node_info', {'node_id': 'zz'}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.message, 'message', contains('non trovato')),
        ),
      );
      expect(
        () => NwcHandlers(cln: custom).handle('get_node_info', {}),
        throwsA(
          isA<RpcError>().having(
            (e) => e.message,
            'message',
            contains('richiede pubkey'),
          ),
        ),
      );
    });

    test('get_route: fee dai hop e delay totale', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'getroute': {
          'route': [
            {
              'id': '02aa',
              'channel': '100x1x1',
              'direction': 0,
              'amount_msat': 1010000,
              'delay': 20,
              'style': 'tlv',
            },
            {
              'id': '02bb',
              'channel': '200x1x0',
              'direction': 1,
              'amount_msat': 1000000,
              'delay': 9,
              'style': 'tlv',
            },
          ],
        },
      });
      final r = await NwcHandlers(cln: custom).handle('get_route', {
        'destination': '02bb',
        'amount_msat': 1000000,
      });

      // Il primo hop porta l'importo maggiorato delle fee.
      expect(r['fee_msat'], 10000);
      expect(r['total_delay'], 20);
      expect((r['route'] as List).length, 2);
      expect(custom.callParams.last['riskfactor'], 10);
    });

    test('get_route: peer diretto → fee 0; params mancanti → errore', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'getroute': {
          'route': [
            {
              'id': '02aa',
              'channel': '100x1x1',
              'direction': 0,
              'amount_msat': 1000000,
              'delay': 9,
            },
          ],
        },
      });
      final handlers = NwcHandlers(cln: custom);
      final r = await handlers.handle('get_route', {
        'destination': '02aa',
        'amount_msat': 1000000,
      });
      expect(r['fee_msat'], 0);
      expect(r['total_delay'], 9);

      expect(
        () => handlers.handle('get_route', {'destination': '02aa'}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.message, 'message', contains('amount')),
        ),
      );
    });

    test('keysend invia maxfee e mappa la risposta di pay', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'keysend': {
          'destination': '02aa',
          'payment_hash': 'h1',
          'payment_preimage': 'p1',
          'status': 'complete',
          'amount_msat': 1000000,
          'amount_sent_msat': 1001000,
          'created_at': 1789364186,
        },
      });
      final r = await NwcHandlers(cln: custom).handle('keysend', {
        'destination': '02aa',
        'amount_msat': 1000000,
        'label': 'prova',
        'maxfee_msat': 5000,
      });

      expect(r['payment_hash'], 'h1');
      expect(r['payment_preimage'], 'p1');
      expect(r['fee_msat'], 1000);
      expect(r['status'], 'complete');

      final sent = custom.callParams.last;
      expect(sent['destination'], '02aa');
      expect(sent['amount_msat'], 1000000);
      expect(sent['maxfee'], 5000);
      expect(sent['label'], 'prova');
      // maxfee e maxfeepercent non convivono (dal man del nodo).
      expect(sent.containsKey('maxfeepercent'), isFalse);
    });

    test('keysend: maxfeepercent alternativo; preimage assente ok', () async {
      final custom = FakeCln({
        ...baseResponses(),
        'keysend': {
          'payment_hash': 'h2',
          'status': 'complete',
          'amount_msat': 500000,
          'amount_sent_msat': 500000,
        },
      });
      final handlers = NwcHandlers(cln: custom);
      final r = await handlers.handle('keysend', {
        'destination': '02aa',
        'amount_msat': 500000,
        'maxfeepercent': 0.5,
      });

      // Il nodo non ha ripetuto la destination: si ripiega sulla richiesta.
      expect(r['destination'], '02aa');
      expect(r.containsKey('payment_preimage'), isFalse);
      expect(custom.callParams.last['maxfeepercent'], 0.5);

      expect(
        () => handlers.handle('keysend', {'destination': '02aa'}),
        throwsA(
          isA<RpcError>()
              .having((e) => e.message, 'message', contains('amount_msat')),
        ),
      );
    });
  });
}
