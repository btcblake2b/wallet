import 'dart:convert';

import 'package:btc_blake2b_wallet/core/services/fiat_currency.dart';
import 'package:btc_blake2b_wallet/core/services/fiat_price.dart';
import 'package:btc_blake2b_wallet/core/services/fx_rates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('parseUsdToCents', () {
    test('interi e decimali, virgola o punto', () {
      expect(parseUsdToCents('300'), 30000);
      expect(parseUsdToCents('300.5'), 30050);
      expect(parseUsdToCents('300,50'), 30050);
      expect(parseUsdToCents(' 1.15 '), 115);
      expect(parseUsdToCents('0.01'), 1);
    });

    test('1.15 non diventa 114 per errore di virgola mobile', () {
      // PERCHÉ: `(1.15 * 100).round()` passa per 114.99999…; la conversione
      // sulle CIFRE dà esattamente 115.
      expect(parseUsdToCents('1.15'), 115);
      expect(parseUsdToCents('2.675'), isNull); // 3 decimali: rifiutato
    });

    test('rifiuta valori non validi', () {
      for (final bad in <String>[
        '',
        '   ',
        'abc',
        '0',
        '-5',
        '1.2.3',
        '1.234',
      ]) {
        expect(parseUsdToCents(bad), isNull, reason: 'input: "$bad"');
      }
      // PERCHÉ "1." è accettato: mentre si scrive "1.5" si passa da "1." —
      // rifiutarlo a metà digitazione non protegge da nulla.
      expect(parseUsdToCents('1.'), 100);
    });
  });

  group('FiatPrice', () {
    late MockSecureStorage storage;
    late FiatPrice sut;

    setUp(() {
      storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      sut = FiatPrice(storage: storage);
    });

    test('default: spento, nessun controvalore', () {
      expect(sut.enabled, isFalse);
      expect(sut.centsFor(100000000), isNull);
    });

    test('prezzo impostato ma switch spento → nessun controvalore', () async {
      await sut.setUsdCentsPerXbt(30000);
      expect(sut.enabled, isFalse);
      expect(sut.centsFor(100000000), isNull);
    });

    test('acceso: 1 XBT a 300 USD e importi frazionari', () async {
      await sut.setUsdCentsPerXbt(30000);
      await sut.setEnabled(true);

      expect(sut.enabled, isTrue);
      expect(sut.centsFor(100000000), 30000); // 1 XBT = 300.00 $
      expect(sut.centsFor(50000000), 15000); // 0.5 → 150.00 $
      // 8.500 sat con 1 XBT = 300 $ → 2 cent (arrotonda per difetto)
      expect(sut.centsFor(8500), 2);
      expect(sut.centsFor(0), isNull);
    });

    test('non si accende senza prezzo', () async {
      await sut.setEnabled(true);
      expect(sut.enabled, isFalse);
    });

    test('prezzo azzerato → switch si spegne da solo', () async {
      await sut.setUsdCentsPerXbt(30000);
      await sut.setEnabled(true);
      await sut.setUsdCentsPerXbt(null);

      expect(sut.usdCentsPerXbt, isNull);
      expect(sut.enabled, isFalse);
      expect(sut.centsFor(100000000), isNull);
    });

    test('init legge le preferenze persistite', () async {
      when(() => storage.read(key: 'fiat_price_enabled'))
          .thenAnswer((_) async => 'true');
      when(() => storage.read(key: 'fiat_usd_cents_per_xbt'))
          .thenAnswer((_) async => '26400');

      await sut.init();

      expect(sut.usdCentsPerXbt, 26400);
      expect(sut.enabled, isTrue);
    });

    test('init con storage rotto → resta spento (mai un prezzo inventato)',
        () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(Exception('storage'));

      await sut.init();

      expect(sut.enabled, isFalse);
      expect(sut.usdCentsPerXbt, isNull);
    });

    test('auto: default spento, setAuto persiste e notifica', () async {
      expect(sut.auto, isFalse);

      await sut.setAuto(true);

      expect(sut.auto, isTrue);
      // l'auto da sola non accende il controvalore
      expect(sut.enabled, isFalse);
    });

    test('init legge anche la preferenza auto', () async {
      when(() => storage.read(key: 'fiat_price_enabled'))
          .thenAnswer((_) async => 'true');
      when(() => storage.read(key: 'fiat_usd_cents_per_xbt'))
          .thenAnswer((_) async => '26400');
      when(() => storage.read(key: 'fiat_price_auto'))
          .thenAnswer((_) async => 'true');

      await sut.init();

      expect(sut.auto, isTrue);
      expect(sut.enabled, isTrue);
    });
  });

  group('refreshFromNeoxex', () {
    late MockSecureStorage storage;
    late FiatPrice sut;

    setUp(() {
      storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
    });

    FiatPrice sutWith(MockClient mock) =>
        FiatPrice(storage: storage, client: mock);

    test('parsa l\'ultimo trade e aggiorna il prezzo in centesimi', () async {
      final mock = MockClient((request) async {
        expect(request.url.toString(), FiatPrice.neoxexTradesEndpoint);
        return http.Response(
          jsonEncode({
            'success': true,
            'pair': 'BTCB2_USDC',
            'trades': [
              {
                'trade_id': 'TRD-X',
                'side': 'sell',
                'quantity': 0.02,
                'price': 272.96083251,
                'total': 5.46,
                'executed_at': '2026-10-29T07:14:55.047Z',
              },
            ],
          }),
          200,
        );
      });
      sut = sutWith(mock);

      final ok = await sut.refreshFromNeoxex();

      expect(ok, isTrue);
      // 272.96083251 * 100 = 27296.083251 → troncato a 27296 centesimi.
      expect(sut.usdCentsPerXbt, 27296);
      expect(sut.enabled, isFalse); // serve comunque il toggle "mostra"
    });

    test('risposta non 200 → false e prezzo invariato', () async {
      final mock = MockClient((_) async => http.Response('err', 503));
      sut = sutWith(mock);
      await sut.setUsdCentsPerXbt(30000);

      final ok = await sut.refreshFromNeoxex();

      expect(ok, isFalse);
      expect(sut.usdCentsPerXbt, 30000);
    });

    test('payload malformato → false e prezzo invariato', () async {
      final mock = MockClient(
        (_) async => http.Response(jsonEncode({'success': false}), 200),
      );
      sut = sutWith(mock);
      await sut.setUsdCentsPerXbt(30000);

      final ok = await sut.refreshFromNeoxex();

      expect(ok, isFalse);
      expect(sut.usdCentsPerXbt, 30000);
    });

    test('errore di rete → false, mai un\'eccezione', () async {
      final mock = MockClient((_) async => throw http.ClientException('down'));
      sut = sutWith(mock);
      await sut.setUsdCentsPerXbt(30000);

      final ok = await sut.refreshFromNeoxex();

      expect(ok, isFalse);
      expect(sut.usdCentsPerXbt, 30000);
    });
  });

  group('valute (29/10)', () {
    late MockSecureStorage storage;
    late FiatPrice sut;

    setUp(() {
      storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      FxRates.instance = FxRates.inMemory();
      sut = FiatPrice(storage: storage);
    });

    tearDown(FxRates.resetForTest);

    test('default USD, 1:1 con il prezzo base', () async {
      await sut.setUsdCentsPerXbt(30000);
      await sut.setEnabled(true);

      expect(sut.currency, FiatCurrency.usd);
      expect(sut.centsFor(FiatPrice.satsPerXbt), 30000);
      // 100.000 sat a 300 $/XBT = 0,30 $ = 30 centesimi.
      expect(sut.centsFor(100000), 30);
    });

    test('EUR: converte col cambio USDT/EUR', () async {
      FxRates.instance.setRateForTest(FiatCurrency.eur, 0.89619);
      await sut.setUsdCentsPerXbt(30000);
      await sut.setEnabled(true);
      await sut.setCurrency(FiatCurrency.eur);

      // 1 XBT = 300 $ × 0,89619 = 268,85 € (troncato a 26885 centesimi).
      expect(sut.centsFor(FiatPrice.satsPerXbt), 26885);
      // 0,001 XBT = 0,30 $ × 0,89619 = 0,268857 € → 26 centesimi.
      expect(sut.centsFor(100000), 26);
    });

    test('JPY: il cambio grande resta intero corretto', () async {
      FxRates.instance.setRateForTest(FiatCurrency.jpy, 157.775513);
      await sut.setUsdCentsPerXbt(30000);
      await sut.setEnabled(true);
      await sut.setCurrency(FiatCurrency.jpy);

      // 300 $ × 157,775513 = 47 332,65 JPY → 4 733 265 centesimi.
      expect(sut.centsFor(FiatPrice.satsPerXbt), 4733265);
    });

    test('senza il cambio della valuta → null (mai un importo inventato)',
        () async {
      await sut.setUsdCentsPerXbt(30000);
      await sut.setEnabled(true);
      await sut.setCurrency(FiatCurrency.eur);

      expect(sut.hasCurrencyRate, isFalse);
      expect(sut.centsFor(FiatPrice.satsPerXbt), isNull);
      expect(sut.centsFor(100000), isNull);
    });

    test('setCurrency persiste la scelta', () async {
      await sut.setCurrency(FiatCurrency.gbp);

      expect(sut.currency, FiatCurrency.gbp);
      verify(() => storage.write(key: 'fiat_price_currency', value: 'GBP'))
          .called(1);
    });

    test('init rilegge la valuta persistita (e ignora codici ignoti)',
        () async {
      when(() => storage.read(key: 'fiat_price_enabled'))
          .thenAnswer((_) async => 'true');
      when(() => storage.read(key: 'fiat_usd_cents_per_xbt'))
          .thenAnswer((_) async => '30000');
      when(() => storage.read(key: 'fiat_price_currency'))
          .thenAnswer((_) async => 'CHF');

      await sut.init();
      expect(sut.currency, FiatCurrency.chf);

      when(() => storage.read(key: 'fiat_price_currency'))
          .thenAnswer((_) async => 'XYZ');
      await sut.init();
      expect(sut.currency, FiatCurrency.usd);
    });
  });
}
