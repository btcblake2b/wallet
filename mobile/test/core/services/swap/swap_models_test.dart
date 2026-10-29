import 'package:btc_blake2b_wallet/core/services/swap/swap_consts.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vettori condivisi: una sessione completa e coerente col protocollo.
SwapSession buildSession({
  String swapId = 'aa11bb22cc33dd44',
  SwapClientState state = SwapClientState.awaitingFunding,
}) =>
    SwapSession(
      swapId: swapId,
      invoice: 'lnbc50u1p3xyz...',
      paymentHashHex: 'ab' * 32,
      fundingAmountSats: 5250,
      cltvHeight: 972144,
      fundingDeadlineHeight: 971998,
      claimPubkeyHex: '02${'11' * 32}',
      refundPubkeyHex: '02${'22' * 32}',
      refundKeyIndex: 3,
      htlcAddress: 'bc1qexamplewitnessscripthashaddress',
      witnessScriptHex: '63a820${'ab' * 32}882102${'11' * 32}',
      providerPubkey: 'cd' * 32,
      relays: const ['wss://relay.primal.net'],
      state: state,
      createdAt: 1758100000,
      updatedAt: 1758100010,
    );

void main() {
  group('SwapProvider', () {
    const pubkey = '8f228419ffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

    test('fromUri: relay multipli, v e network validati', () {
      final uri = Uri(
        scheme: SwapConsts.uriScheme,
        host: pubkey,
        queryParameters: <String, dynamic>{
          'v': '1',
          'network': 'blake2b',
          'relay': ['wss://a.example', 'wss://b.example'],
        },
      ).toString();
      final provider = SwapProvider.fromUri(uri);
      expect(provider.providerPubkey, pubkey);
      expect(provider.relays, ['wss://a.example', 'wss://b.example']);
      expect(provider.network, 'blake2b');
    });

    test('toUri → fromUri: round-trip fedele', () {
      const original = SwapProvider(
        providerPubkey: pubkey,
        relays: ['wss://a.example', 'wss://b.example'],
      );
      final restored = SwapProvider.fromUri(original.toUri());
      expect(restored.providerPubkey, original.providerPubkey);
      expect(restored.relays, original.relays);
      expect(restored.network, original.network);
    });

    test('fromUri: schema errato → FormatException', () {
      expect(
        () => SwapProvider.fromUri('nostr+walletconnect://$pubkey?relay=wss://a'),
        throwsFormatException,
      );
    });

    test('fromUri: pubkey non valida → FormatException', () {
      expect(
        () => SwapProvider.fromUri('nostr+swap://notahex?relay=wss://a'),
        throwsFormatException,
      );
    });

    test('fromUri: senza relay → FormatException', () {
      expect(
        () => SwapProvider.fromUri('nostr+swap://$pubkey?v=1'),
        throwsFormatException,
      );
    });

    test('fromUri: versione protocollo diversa → FormatException', () {
      expect(
        () => SwapProvider.fromUri('nostr+swap://$pubkey?v=2&relay=wss://a'),
        throwsFormatException,
      );
    });
  });

  group('SwapQuote', () {
    Map<String, dynamic> quoteJson() => {
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
          'witness_script_hex': '63a82000',
          'network': 'blake2b',
        };

    test('fromJson/toJson: round-trip', () {
      final quote = SwapQuote.fromJson(quoteJson());
      expect(quote.quoteId, 'deadbeefcafe');
      expect(quote.fundingAmountSats, 5250);
      expect(quote.cltvHeight, 972144);
      expect(quote.claimPubkeyHex, '02${'11' * 32}');
      expect(quote.isExpiredAt(1758100599), false);
      expect(quote.isExpiredAt(1758100600), true);
      final round = SwapQuote.fromJson(quote.toJson());
      expect(round.quoteId, quote.quoteId);
      expect(round.fundingAmountSats, quote.fundingAmountSats);
    });

    test('fromJson: campo mancante → FormatException', () {
      final json = quoteJson()..remove('htlc_address');
      expect(() => SwapQuote.fromJson(json), throwsFormatException);
    });
  });

  group('SwapProviderInfo (swap_info)', () {
    Map<String, dynamic> infoJson() => {
          'network': 'blake2b',
          'min_sats': 5000,
          'max_sats': 250000,
          'min_sendable_sats': 4750,
          'max_sendable_sats': 23750,
          'available_sats': 24000,
          'spendable_sats': 30000,
          'outstanding_sats': 0,
          'service_fee_sats': 0,
          'claim_fee_sats': 250,
          'active_sessions': 0,
        };

    test('fromJson: limiti e liquidità (senza verdetto)', () {
      final info = SwapProviderInfo.fromJson(infoJson())!;
      expect(info.minSendableSats, 4750);
      expect(info.maxSendableSats, 23750);
      expect(info.availableSats, 24000);
      expect(info.canSend(5000), true);
      expect(info.canSend(4749), false);
      expect(info.canSend(23751), false);
      expect(info.check, isNull);
    });

    test('fromJson: verdetto sul destinatario raggiungibile', () {
      final json = infoJson()
        ..['check'] = {
          'valid': true,
          'reachable': true,
          'payee': '03${'22' * 31}',
          'amount_sats': 5000,
          'funding_amount_sats': 5250,
        };
      final info = SwapProviderInfo.fromJson(json)!;
      expect(info.check!.valid, true);
      expect(info.check!.reachable, true);
      expect(info.check!.amountSats, 5000);
      expect(info.check!.payee, '03${'22' * 31}');
      expect(info.check!.reason, isNull);
    });

    test('fromJson: destinatario non raggiungibile porta il motivo', () {
      final json = infoJson()
        ..['check'] = {
          'valid': true,
          'reachable': false,
          'reason': 'PEER_UNREACHABLE',
          'message': 'nessuna rotta trovata verso il destinatario.',
        };
      final info = SwapProviderInfo.fromJson(json)!;
      expect(info.check!.reachable, false);
      expect(info.check!.reason, 'PEER_UNREACHABLE');
      expect(info.check!.message, contains('rotta'));
    });

    test('fromJson: payload senza limiti → null (provider incompatibile)', () {
      expect(SwapProviderInfo.fromJson({'network': 'blake2b'}), isNull);
    });

    test('check: payload senza verdetto resta null', () {
      expect(SwapPeerCheck.fromJson(null), isNull);
      expect(SwapPeerCheck.fromJson('nope'), isNull);
    });
  });

  group('SwapStatus', () {
    test('fromJson: stato, funding e errore', () {
      final status = SwapStatus.fromJson({
        'swap_id': 'aa' * 16,
        'state': 'paymentFailed',
        'htlc_address': 'bc1qexample',
        'witness_script_hex': '63a82000',
        'funding_amount_sats': 5250,
        'cltv_height': 972144,
        'funding_deadline_height': 971998,
        'funding_txid': 'ff' * 32,
        'funding_vout': 1,
        'funding_height': 972010,
        'funding_confirmations': 3,
        'created_at': 1758100000,
        'updated_at': 1758100100,
        'error': {'code': 'PAYMENT_FAILED', 'message': 'route non trovata'},
      });
      expect(status.state, SwapClientState.paymentFailed);
      expect(status.state.isRefundable, true);
      expect(status.fundingTxid, 'ff' * 32);
      expect(status.fundingVout, 1);
      expect(status.fundingConfirmations, 3);
      expect(status.errorCode, 'PAYMENT_FAILED');
      expect(status.errorMessage, 'route non trovata');
    });

    test('fromJson: stato sconosciuto → awaitingFunding (tollerante)', () {
      final status = SwapStatus.fromJson({
        'swap_id': 'aa' * 16,
        'state': 'nuovoStatoFuturo',
        'htlc_address': 'bc1qexample',
        'witness_script_hex': '63a82000',
        'funding_amount_sats': 5250,
        'cltv_height': 972144,
        'funding_deadline_height': 971998,
        'created_at': 1758100000,
        'updated_at': 1758100100,
      });
      expect(status.state, SwapClientState.awaitingFunding);
    });
  });

  group('SwapClientState', () {
    test('wireName/fromWireName su tutti gli stati', () {
      for (final state in SwapClientState.values) {
        expect(SwapClientState.fromWireName(state.wireName), state);
      }
    });

    test('classificazione (attivo/terminale/refundable)', () {
      expect(SwapClientState.claiming.isActive, true);
      expect(SwapClientState.completed.isTerminal, true);
      expect(SwapClientState.refunded.isTerminal, true);
      expect(SwapClientState.expired.isRefundable, true);
      expect(SwapClientState.paymentFailed.isRefundable, true);
      expect(SwapClientState.completed.isRefundable, false);
    });
  });

  group('SwapSession', () {
    test('toJson/fromJson: round-trip completo', () {
      final session = buildSession()
          .copyWith(fundingTxid: 'ff' * 32, fundingVout: 0, updatedAt: 99);
      final restored = SwapSession.fromJson(session.toJson());
      expect(restored.swapId, session.swapId);
      expect(restored.refundKeyIndex, 3);
      expect(restored.fundingTxid, 'ff' * 32);
      expect(restored.fundingVout, 0);
      expect(restored.updatedAt, 99);
      expect(restored.relays, session.relays);
      expect(restored.needsAttention, true);
    });

    test('copyWith: i campi non passati restano invariati', () {
      final session = buildSession();
      final updated = session.copyWith(state: SwapClientState.completed);
      expect(updated.state, SwapClientState.completed);
      expect(updated.swapId, session.swapId);
      expect(updated.refundKeyIndex, session.refundKeyIndex);
    });

    test('amountSats: round-trip, fallback da amount_msat, null sui vecchi', () {
      // Sessione "nuova": importo invoice noto.
      final withSats = SwapSession.fromJson({
        ...buildSession().toJson(),
        'amount_sats': 5001,
      });
      expect(withSats.amountSats, 5001);
      expect(SwapSession.fromJson(withSats.toJson()).amountSats, 5001);

      // Blob del PROVIDER: porta `amount_msat` → arrotondato per eccesso.
      final fromBlob = SwapSession.fromJson({
        ...buildSession().toJson(),
        'amount_msat': 5001000,
      });
      expect(fromBlob.amountSats, 5001);

      // Sessioni salvate prima del 07/10/2026: nessun importo → UI degrada.
      expect(buildSession().amountSats, isNull);
    });

    test('copyWith conserva l importo invoice', () {
      final session = SwapSession.fromJson({
        ...buildSession().toJson(),
        'amount_sats': 5001,
      });
      expect(
        session.copyWith(state: SwapClientState.paid).amountSats,
        5001,
      );
    });
  });

  group('SwapRecoveryBlob', () {
    test('encode/decode: round-trip fedele', () {
      final session = buildSession(state: SwapClientState.paymentFailed);
      final blob = SwapRecoveryBlob.encode(session);
      expect(blob.startsWith(SwapConsts.recoveryPrefix), true);
      final restored = SwapRecoveryBlob.decode(blob);
      expect(restored.swapId, session.swapId);
      expect(restored.refundKeyIndex, session.refundKeyIndex);
      expect(restored.witnessScriptHex, session.witnessScriptHex);
      expect(restored.state, SwapClientState.paymentFailed);
    });

    test('decode: prefisso mancante → FormatException', () {
      expect(
        () => SwapRecoveryBlob.decode('nonswaprecover1.abc'),
        throwsFormatException,
      );
    });

    test('decode: base64 non valido → FormatException', () {
      expect(
        () => SwapRecoveryBlob.decode('${SwapConsts.recoveryPrefix}!!notbase64!!'),
        throwsFormatException,
      );
    });
  });
}
