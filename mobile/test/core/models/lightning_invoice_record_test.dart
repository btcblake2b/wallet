import 'package:btc_blake2b_wallet/core/models/lightning_invoice_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Scadenze costruite rispetto ad "adesso": il test non dipende dal calendario.
  int inFuture() =>
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  int inPast() =>
      DateTime.now()
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch ~/
      1000;

  group('LightningInvoiceRecord', () {
    test('fattura pagata: stato, importo e data di pagamento', () {
      final i = LightningInvoiceRecord.fromJson({
        'payment_hash': 'hp',
        'label': 'nwcb-1',
        'amount_msat': 1000000,
        'amount_received_msat': 1000000,
        'status': 'paid',
        'paid_at': 1789400000,
        'expires_at': inFuture(),
        'created_index': 3,
      });

      expect(i.isPaid, isTrue);
      expect(i.state, LightningInvoiceState.paid);
      expect(i.amountSats, 1000);
      expect(i.paidDate, isNotNull);
      expect(i.expiryDate, isNotNull);
    });

    test('non pagata con scadenza futura → in attesa', () {
      final i = LightningInvoiceRecord.fromJson({
        'payment_hash': 'hu',
        'label': 'nwcb-2',
        'amount_msat': 2000000,
        'status': 'unpaid',
        'expires_at': inFuture(),
      });

      expect(i.state, LightningInvoiceState.pending);
      expect(i.isPaid, isFalse);
      expect(i.paidDate, isNull);
    });

    test('non pagata con scadenza passata → scaduta (derivata)', () {
      // PERCHÉ: il nodo continua a dire `unpaid` anche dopo la scadenza —
      // la distinzione la fa l'app, e va bloccata da un test.
      final i = LightningInvoiceRecord.fromJson({
        'payment_hash': 'he',
        'amount_msat': 3000000,
        'status': 'unpaid',
        'expires_at': inPast(),
      });

      expect(i.state, LightningInvoiceState.expired);
    });

    test('stato non riconosciuto → unknown (mostrato grezzo)', () {
      final i = LightningInvoiceRecord.fromJson({
        'payment_hash': 'hx',
        'amount_msat': 1000,
        'status': 'canceled',
        'expires_at': inFuture(),
      });

      expect(i.state, LightningInvoiceState.unknown);
      expect(i.status, 'canceled');
    });

    test('campi mancanti → default sicuri', () {
      final i = LightningInvoiceRecord.fromJson(const {});

      expect(i.paymentHash, '');
      expect(i.label, '');
      expect(i.amountSats, 0);
      expect(i.status, 'unknown');
      expect(i.description, isNull);
      expect(i.expiryDate, isNull);
      expect(i.paidDate, isNull);
      expect(i.createdIndex, isNull);
    });

    test('description vuota → null (la UI non mostra righe vuote)', () {
      final i = LightningInvoiceRecord.fromJson(const {
        'description': '',
        'status': 'unpaid',
      });
      expect(i.description, isNull);
    });
  });
}
