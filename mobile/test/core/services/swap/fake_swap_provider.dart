import 'dart:async';
import 'dart:convert';

import 'package:btc_blake2b_wallet/core/services/nostr/nostr_crypto.dart';
import 'package:btc_blake2b_wallet/core/services/nostr/nostr_event.dart';
import 'package:btc_blake2b_wallet/core/services/nostr/nostr_transport.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_consts.dart';

/// Provider finto CONDIVISO dai test swap: parla il protocollo vero
/// (decifra le richieste NIP-04, risponde cifrato e firmato, emette
/// notifiche kind 23292).
///
/// // PERCHÉ: un unico fake per client e servizio evita derive divergenti
/// // del wire format nei test.
class FakeSwapProvider implements NostrTransport {
  FakeSwapProvider() {
    providerPubHex = NostrCrypto.derivePublicKey(providerPrivHex);
  }

  final String providerPrivHex = NostrCrypto.randomHex32();
  late final String providerPubHex;

  final StreamController<NostrEvent> _controller =
      StreamController<NostrEvent>.broadcast();
  bool _connected = false;
  DateTime? _connectedSince;

  /// Se true, non risponde mai (test del timeout).
  bool silent = false;

  /// Se true, NON risponde alla prossima richiesta (risposta persa).
  bool silentOnce = false;

  /// Se true, connect fallisce (test CONNECT_FAILED).
  bool failConnect = false;

  /// Relay che falliscono la connessione (test failover multi-relay).
  final Set<String> badRelays = {};

  int connectCalls = 0;
  final List<NostrEvent> published = [];
  final List<Map<String, dynamic>> receivedRequests = [];

  /// Genera la risposta: `{'result': {...}}` oppure `{'error': {...}}`.
  Map<String, dynamic> Function(String method, Map<String, dynamic> params)?
      responder;

  @override
  bool get isConnected => _connected;

  @override
  DateTime? get connectedSince => _connectedSince;

  @override
  Future<void> connect(String relayUrl) async {
    if (failConnect || badRelays.contains(relayUrl)) {
      throw Exception('relay down (test)');
    }
    connectCalls++;
    _connected = true;
    _connectedSince = DateTime.now();
  }

  @override
  Future<void> close() async {
    // // PERCHÉ (test): lo stream resta aperto — il client si riconnette
    // più volte e deve poter ri-sottoscrivere.
    _connected = false;
    _connectedSince = null;
  }

  @override
  Stream<NostrEvent> subscribe(List<Map<String, dynamic>> filters) =>
      _controller.stream;

  @override
  Future<void> publish(NostrEvent event) async {
    published.add(event);
    if (event.kind != SwapConsts.requestKind) return;
    final plaintext = NostrCrypto.nip04Decrypt(
      privkeyHex: providerPrivHex,
      pubkeyHex: event.pubkey,
      payload: event.content,
    );
    final request = (jsonDecode(plaintext) as Map).cast<String, dynamic>();
    receivedRequests.add(request);
    if (silent) return;
    if (silentOnce) {
      silentOnce = false;
      return;
    }
    final method = '${request['method']}';
    final params =
        (request['params'] as Map?)?.cast<String, dynamic>() ?? const {};
    final out = responder?.call(method, params);
    final body = <String, dynamic>{
      'v': SwapConsts.protocolVersion,
      'id': request['id'],
    };
    if (out != null && out['error'] != null) {
      body['error'] = out['error'];
    } else {
      body['result'] = (out?['result'] as Map?) ?? <String, dynamic>{};
    }
    _emit(clientPub: event.pubkey, requestEventId: event.id, body: body);
  }

  /// Notifica push di stato (kind 23292).
  void emitNotification(String clientPub, Map<String, dynamic> result) => _emit(
        clientPub: clientPub,
        kind: SwapConsts.notificationKind,
        body: {
          'v': SwapConsts.protocolVersion,
          'id': result['swap_id'],
          'result': result,
        },
      );

  void _emit({
    required String clientPub,
    String? requestEventId,
    required Map<String, dynamic> body,
    int kind = SwapConsts.responseKind,
  }) {
    final content = NostrCrypto.nip04Encrypt(
      privkeyHex: providerPrivHex,
      pubkeyHex: clientPub,
      plaintext: jsonEncode(body),
    );
    final event = NostrEvent.unsigned(
      pubkey: providerPubHex,
      kind: kind,
      tags: [
        ['p', clientPub],
        if (requestEventId != null) ['e', requestEventId],
      ],
      content: content,
    ).sign(providerPrivHex);
    _controller.add(event);
  }
}

/// Risposta standard di `swap_quote` (campi del wire provider).
Map<String, dynamic> quoteResult({
  String? witnessScriptHex,
  String state = 'awaitingFunding',
}) =>
    {
      'quote_id': 'deadbeefcafe',
      'expires_at': 1758100600,
      'payment_hash': 'ab' * 32,
      'amount_msat': 5000000,
      'amount_sats': 5000,
      'service_fee_sats': 0,
      'claim_fee_sats': 250,
      'funding_amount_sats': 5250,
      'cltv_height': 972144,
      'claim_pubkey': '02${'11' * 32}',
      'refund_pubkey': '02${'22' * 32}',
      'htlc_address': 'bc1qexample',
      'witness_script_hex': witnessScriptHex ?? '00',
      'network': 'blake2b',
    };

/// Risposta standard di create/funding/status.
Map<String, dynamic> statusResult({
  String state = 'awaitingFunding',
  String? fundingTxid,
  int? fundingVout,
  String? claimTxid,
}) =>
    {
      'swap_id': 'aa' * 16,
      'state': state,
      'htlc_address': 'bc1qexample',
      'witness_script_hex': '00',
      'funding_amount_sats': 5250,
      'cltv_height': 972144,
      'funding_deadline_height': 971998,
      'created_at': 1758100000,
      'updated_at': 1758100010,
      if (fundingTxid != null) 'funding_txid': fundingTxid,
      if (fundingVout != null) 'funding_vout': fundingVout,
      if (claimTxid != null) 'claim_txid': claimTxid,
    };
