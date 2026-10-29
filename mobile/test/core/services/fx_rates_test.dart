import 'dart:convert';

import 'package:btc_blake2b_wallet/core/services/fiat_currency.dart';
import 'package:btc_blake2b_wallet/core/services/fx_rates.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Payload ridotto con la stessa forma di quello reale di Coinbase
/// (`data.currency` + `data.rates` con valori STRINGA).
String _payload(Map<String, String> rates) => jsonEncode({
      'data': {
        'currency': 'USDT',
        'rates': {
          // Valute extra non supportate: devono essere ignorate.
          'BTC': '0.0000101',
          'XXX': '1',
          ...rates,
        },
      },
    });

void main() {
  group('FxRates', () {
    test('parsa i cambi delle valute supportate in micro unità', () async {
      final mock = MockClient((request) async {
        expect(request.url.toString(), FxRates.endpoint);
        return http.Response(
          _payload({
            'EUR': '0.89619',
            'GBP': '0.7497',
            'CHF': '0.827011394',
            'JPY': '157.775513344284',
            'CAD': '1.39593453266666669996',
          }),
          200,
        );
      });
      final sut = FxRates.inMemory(client: mock);

      final ok = await sut.refresh();

      expect(ok, isTrue);
      expect(sut.microRateFor(FiatCurrency.eur), 896190);
      expect(sut.microRateFor(FiatCurrency.jpy), 157775513);
      expect(sut.microRateFor(FiatCurrency.cad), 1395935);
      expect(sut.fetchedAt, isNotNull);
      // USD è la base: sempre 1:1 anche senza payload.
      expect(sut.microRateFor(FiatCurrency.usd), FxRates.scale);
    });

    test('scarta cambi assurdi (0, negativi, fuori scala)', () async {
      final mock = MockClient(
        (_) async => http.Response(
          _payload({'EUR': '0', 'GBP': '-1', 'CHF': '99999999'}),
          200,
        ),
      );
      final sut = FxRates.inMemory(client: mock);

      final ok = await sut.refresh();

      expect(ok, isFalse);
      expect(sut.microRateFor(FiatCurrency.eur), isNull);
      expect(sut.microRateFor(FiatCurrency.gbp), isNull);
      expect(sut.microRateFor(FiatCurrency.chf), isNull);
    });

    test('HTTP != 200 → false, nessun cambio inventato', () async {
      final sut = FxRates.inMemory(
        client: MockClient((_) async => http.Response('err', 503)),
      );

      expect(await sut.refresh(), isFalse);
      expect(sut.microRateFor(FiatCurrency.eur), isNull);
    });

    test('payload con coppia sbagliata → false', () async {
      final sut = FxRates.inMemory(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': {
                'currency': 'BTC',
                'rates': {'EUR': '0.9'},
              },
            }),
            200,
          ),
        ),
      );

      expect(await sut.refresh(), isFalse);
    });

    test('errore di rete → false, mai un\'eccezione', () async {
      final sut = FxRates.inMemory(
        client: MockClient((_) async => throw http.ClientException('down')),
      );

      expect(await sut.refresh(), isFalse);
    });

    test('un refresh fallito non cancella i cambi già in memoria', () async {
      var fail = false;
      final sut = FxRates.inMemory(
        client: MockClient((_) async {
          if (fail) throw http.ClientException('down');
          return http.Response(_payload({'EUR': '0.9'}), 200);
        }),
      );

      expect(await sut.refresh(), isTrue);
      fail = true;
      expect(await sut.refresh(), isFalse);

      expect(sut.microRateFor(FiatCurrency.eur), 900000);
    });

    test('persiste e rilegge i cambi con init', () async {
      final storage = MockSecureStorage();
      String? storedRates;
      String? storedAt;
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        final key = invocation.namedArguments[#key] as String;
        final value = invocation.namedArguments[#value] as String;
        if (key == 'fx_usdt_rates_v1') storedRates = value;
        if (key == 'fx_usdt_rates_at') storedAt = value;
      });
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final sut = FxRates(
        storage: storage,
        client: MockClient(
          (_) async => http.Response(_payload({'EUR': '0.89619'}), 200),
        ),
      );
      expect(await sut.refresh(), isTrue);
      expect(storedRates, contains('EUR'));

      when(() => storage.read(key: 'fx_usdt_rates_v1'))
          .thenAnswer((_) async => storedRates);
      when(() => storage.read(key: 'fx_usdt_rates_at'))
          .thenAnswer((_) async => storedAt);

      final reloaded = FxRates(storage: storage);
      await reloaded.init();

      expect(reloaded.microRateFor(FiatCurrency.eur), 896190);
      expect(reloaded.fetchedAt, isNotNull);
    });

    test('init con storage rotto → nessun cambio, nessuna eccezione', () async {
      final storage = MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(Exception('storage'));

      final sut = FxRates(storage: storage);
      await sut.init();

      expect(sut.microRateFor(FiatCurrency.eur), isNull);
    });
  });
}
