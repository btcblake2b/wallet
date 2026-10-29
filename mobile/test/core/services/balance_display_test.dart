import 'package:btc_blake2b_wallet/core/services/balance_display.dart';
import 'package:btc_blake2b_wallet/core/services/fiat_price.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  setUp(() {
    // PERCHÉ: l'unità `fiat` dipende dal controvalore acceso (registro di
    // processo) → ogni test parte da uno stato noto.
    FiatPrice.instance = FiatPrice.inMemory();
    BalanceDisplay.instance = BalanceDisplay.inMemory();
  });

  tearDown(() {
    FiatPrice.instance = FiatPrice.inMemory();
    BalanceDisplay.resetForTest();
  });

  group('BalanceDisplay', () {
    test('default: XBT', () {
      expect(BalanceDisplay.instance.unitFor('w1'), BalanceUnit.xbt);
      expect(BalanceDisplay.instance.isFiat('w1'), isFalse);
    });

    test('senza prezzo: XBT → sats → XBT (il dollaro si salta)', () async {
      final sut = BalanceDisplay.instance;

      await sut.cycle('w1');
      expect(sut.unitFor('w1'), BalanceUnit.sats);

      await sut.cycle('w1');
      expect(sut.unitFor('w1'), BalanceUnit.xbt);
    });

    test('con prezzo: XBT → sats → dollari → XBT', () async {
      FiatPrice.instance = FiatPrice.inMemory(
        enabled: true,
        usdCentsPerXbt: 30000,
      );
      final sut = BalanceDisplay.instance;

      await sut.cycle('w1');
      expect(sut.unitFor('w1'), BalanceUnit.sats);

      await sut.cycle('w1');
      expect(sut.unitFor('w1'), BalanceUnit.fiat);
      expect(sut.isFiat('w1'), isTrue);

      await sut.cycle('w1');
      expect(sut.unitFor('w1'), BalanceUnit.xbt);
    });

    test('ogni wallet ha la sua unità (e il totale la sua)', () async {
      FiatPrice.instance = FiatPrice.inMemory(
        enabled: true,
        usdCentsPerXbt: 30000,
      );
      final sut = BalanceDisplay.instance;

      await sut.cycle('w1');

      expect(sut.unitFor('w1'), BalanceUnit.sats);
      expect(sut.unitFor('w2'), BalanceUnit.xbt);
      expect(sut.unitFor(BalanceDisplay.totalKey), BalanceUnit.xbt);
    });

    test('unitFor degrada a XBT se il controvalore viene spento', () async {
      FiatPrice.instance = FiatPrice.inMemory(
        enabled: true,
        usdCentsPerXbt: 30000,
      );
      final sut = BalanceDisplay.instance;
      await sut.cycle('w1');
      await sut.cycle('w1');
      expect(sut.unitFor('w1'), BalanceUnit.fiat);

      // Prezzo tolto (equivalente a spegnere il controvalore).
      FiatPrice.instance = FiatPrice.inMemory(usdCentsPerXbt: 30000);

      expect(sut.unitFor('w1'), BalanceUnit.xbt);
    });

    test('notifica gli ascoltatori a ogni cambio', () async {
      final sut = BalanceDisplay.instance;
      var calls = 0;
      sut.addListener(() => calls++);

      await sut.cycle('w1');
      await sut.cycle('w1');

      expect(calls, 2);
    });

    test('persiste l\'unità per chiave e la rilegge con init', () async {
      final storage = MockSecureStorage();
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => storage.readAll()).thenAnswer(
        (_) async => {'balance_unit_w1': 'sats'},
      );

      final sut = BalanceDisplay(storage: storage);
      await sut.cycle('w1');

      verify(() => storage.write(key: 'balance_unit_w1', value: 'sats'))
          .called(1);

      final reloaded = BalanceDisplay(storage: storage);
      await reloaded.init();
      expect(reloaded.unitFor('w1'), BalanceUnit.sats);
      expect(reloaded.unitFor('w2'), BalanceUnit.xbt);
    });

    test('storage rotto: init non lancia e resta sul default', () async {
      final storage = MockSecureStorage();
      when(() => storage.readAll()).thenThrow(Exception('storage'));

      final sut = BalanceDisplay(storage: storage);
      await sut.init();

      expect(sut.unitFor('w1'), BalanceUnit.xbt);
    });
  });

  group('formatSats', () {
    test('raggruppa le migliaia con uno spazio', () {
      expect(formatSats(0), '0');
      expect(formatSats(999), '999');
      expect(formatSats(1000), '1 000');
      expect(formatSats(1234567), '1 234 567');
      expect(formatSats(100000000), '100 000 000');
    });
  });

  group('formatBalanceValue', () {
    test('XBT: 8 decimali con il ticker', () {
      expect(formatBalanceValue(BalanceUnit.xbt, 100000), '0.00100000 BTC');
      expect(formatBalanceValue(BalanceUnit.xbt, 100000000), '1.00000000 BTC');
    });

    test('sats: valore intero raggruppato', () {
      expect(formatBalanceValue(BalanceUnit.sats, 100000), '100 000 sats');
    });

    test('dollari: centesimi formattati', () {
      expect(
        formatBalanceValue(BalanceUnit.fiat, 100000, fiatCents: 30),
        '0.30 \$',
      );
    });

    test('dollari senza prezzo: ricade su XBT (mai un numero finto)', () {
      expect(
        formatBalanceValue(BalanceUnit.fiat, 100000),
        '0.00100000 BTC',
      );
    });
  });
}
