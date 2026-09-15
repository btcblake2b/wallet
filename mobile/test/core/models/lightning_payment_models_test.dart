import 'package:btc_blake2b_wallet/core/models/lightning_htlc.dart';
import 'package:btc_blake2b_wallet/core/models/lightning_payment_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningPaymentRecord', () {
    test('pagamento completato: importo, fee e data', () {
      final p = LightningPaymentRecord.fromJson(const {
        'payment_hash': 'p1',
        'destination': '02peer1',
        'amount_msat': 2000000,
        'amount_sent_msat': 2002000,
        'status': 'complete',
        'created_at': 1789364186,
        'completed_at': 1789364187,
      });

      expect(p.isComplete, isTrue);
      expect(p.amountSats, 2000);
      expect(p.feeSats, 2);
      expect(p.destination, '02peer1');
      // La data è quella di completamento, convertita in locale.
      expect(
        p.date?.toUtc(),
        DateTime.fromMillisecondsSinceEpoch(1789364187 * 1000, isUtc: true),
      );
    });

    test('pagamento fallito e senza completed_at → usa created_at', () {
      final p = LightningPaymentRecord.fromJson(const {
        'payment_hash': 'p2',
        'amount_msat': 1000000,
        'amount_sent_msat': 1000000,
        'status': 'failed',
        'created_at': 1789365000,
      });

      expect(p.isComplete, isFalse);
      expect(p.feeSats, 0);
      expect(
        p.date?.toUtc(),
        DateTime.fromMillisecondsSinceEpoch(1789365000 * 1000, isUtc: true),
      );
    });

    test('campi mancanti → default sicuri', () {
      final p = LightningPaymentRecord.fromJson(const {});

      expect(p.paymentHash, '');
      expect(p.amountSats, 0);
      expect(p.feeSats, 0);
      expect(p.status, 'unknown');
      expect(p.destination, isNull);
      expect(p.date, isNull);
    });
  });

  group('LightningHtlc', () {
    test('HTLC in corso: flag dal bridge', () {
      final h = LightningHtlc.fromJson(const {
        'payment_hash': 'h1',
        'amount_msat': 1500000,
        'direction': 'out',
        'state': 'SENT_ADD_HTLC',
        'short_channel_id': '1000x1x0',
        'expiry': 972200,
        'pending': true,
      });

      expect(h.pending, isTrue);
      expect(h.isIncoming, isFalse);
      expect(h.amountSats, 1500);
      expect(h.shortChannelId, '1000x1x0');
      expect(h.expiry, 972200);
      expect(h.state, 'SENT_ADD_HTLC');
    });

    test('senza flag: pending derivato dallo state', () {
      // Concluso → non in corso.
      expect(
        LightningHtlc.fromJson(const {'state': 'RCVD_REMOVE_ACK_REVOCATION'})
            .pending,
        isFalse,
      );
      // Ciclo non chiuso → in corso.
      expect(
        LightningHtlc.fromJson(const {'state': 'SENT_ADD_HTLC'}).pending,
        isTrue,
      );
    });

    test('direzione in → entrante; campi mancanti → default sicuri', () {
      final h = LightningHtlc.fromJson(const {'direction': 'in'});
      expect(h.isIncoming, isTrue);
      expect(h.amountSats, 0);
      expect(h.id, isNull);
      expect(h.expiry, isNull);
      expect(h.state, 'unknown');
    });
  });
}
