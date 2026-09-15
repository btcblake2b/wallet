import 'package:btc_blake2b_wallet/core/models/lightning_movement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LightningMovement', () {
    test('credit → entrata con importo convertito in sat', () {
      final m = LightningMovement.fromJson(const {
        'id': '1-0',
        'type': 'deposit',
        'direction': 'in',
        'amount_msat': 5606000,
        'timestamp': 1789316694,
        'blockheight': 971877,
        'outpoint': 'aa:0',
      });

      expect(m.id, '1-0');
      expect(m.type, LightningMovementType.deposit);
      expect(m.isIncoming, isTrue);
      expect(m.amountMsat, 5606000);
      expect(m.amountSats, 5606);
      expect(m.blockHeight, 971877);
      expect(m.outpoint, 'aa:0');
    });

    test('debito → uscita, importo comunque positivo', () {
      final m = LightningMovement.fromJson(const {
        'type': 'withdrawal',
        'direction': 'out',
        'amount_msat': 2000000,
      });

      expect(m.type, LightningMovementType.withdrawal);
      expect(m.isIncoming, isFalse);
      expect(m.amountSats, 2000);
    });

    test('data: secondi epoch UTC → DateTime locale', () {
      final m = LightningMovement.fromJson(const {'timestamp': 1789316694});
      expect(
        m.date.toUtc(),
        DateTime.fromMillisecondsSinceEpoch(1789316694 * 1000, isUtc: true),
      );
    });

    test('tag sconosciuto → other (mai un errore a schermo)', () {
      expect(
        LightningMovementType.fromValue('spend'),
        LightningMovementType.other,
      );
      expect(
        LightningMovement.fromJson(const {'type': 'routed'}).type,
        LightningMovementType.other,
      );
    });

    test('campi mancanti → default sicuri', () {
      final m = LightningMovement.fromJson(const {});

      expect(m.id, '');
      expect(m.type, LightningMovementType.other);
      // Un payload senza `direction` non deve trasformare un accredito in
      // un addebito: il default è "in entrata".
      expect(m.isIncoming, isTrue);
      expect(m.amountSats, 0);
      expect(m.timestamp, 0);
      expect(m.blockHeight, isNull);
      expect(m.outpoint, isNull);
      expect(m.description, isNull);
    });

    test('enum: value/fromValue fanno roundtrip', () {
      for (final type in LightningMovementType.values) {
        expect(LightningMovementType.fromValue(type.value), type);
      }
      expect(LightningMovementType.channelOpen.value, 'channel_open');
      expect(LightningMovementType.onchainFee.value, 'onchain_fee');
    });
  });
}
