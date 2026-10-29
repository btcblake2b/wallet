import 'package:btc_blake2b_wallet/core/services/fiat_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FiatCurrency', () {
    test('almeno 5 valute oltre a USD', () {
      expect(FiatCurrency.fxCurrencies.length, greaterThanOrEqualTo(5));
      for (final code in <String>['EUR', 'GBP', 'CHF', 'JPY', 'CAD']) {
        expect(
          FiatCurrency.fromCode(code),
          isNotNull,
          reason: 'valuta mancante: $code',
        );
      }
    });

    test('fromCode ignora maiuscole sbagliate e null', () {
      expect(FiatCurrency.fromCode(null), isNull);
      expect(FiatCurrency.fromCode(''), isNull);
      expect(FiatCurrency.fromCode('XXX'), isNull);
      expect(FiatCurrency.fromCode('CAD'), FiatCurrency.cad);
    });

    test('JPY non ha decimali, le altre sì', () {
      expect(FiatCurrency.jpy.decimals, 0);
      for (final c in FiatCurrency.values) {
        if (c == FiatCurrency.jpy) continue;
        expect(c.decimals, 2, reason: c.code);
      }
    });
  });

  group('formatMoney', () {
    test('USD: due decimali, simbolo dopo', () {
      expect(formatMoney(30, FiatCurrency.usd), r'0.30 $');
      expect(formatMoney(30000, FiatCurrency.usd), r'300.00 $');
      expect(formatMoney(0, FiatCurrency.usd), r'0.00 $');
    });

    test('EUR e GBP usano il proprio simbolo', () {
      expect(formatMoney(27, FiatCurrency.eur), '0.27 €');
      expect(formatMoney(45, FiatCurrency.gbp), '0.45 £');
      expect(formatMoney(100000, FiatCurrency.chf), '1 000.00 CHF');
    });

    test('JPY: nessun decimale e arrotondamento all\'intero', () {
      // 4.264,00 JPY → 4 264 ¥
      expect(formatMoney(426400, FiatCurrency.jpy), '4 264 ¥');
      // 42,5 JPY arrotonda a 43 (mai troncare un importo a metà)
      expect(formatMoney(4250, FiatCurrency.jpy), '43 ¥');
    });

    test('raggruppa le migliaia con uno spazio', () {
      expect(formatMoney(123456789, FiatCurrency.usd), r'1 234 567.89 $');
    });

    test('negativi', () {
      expect(formatMoney(-30, FiatCurrency.usd), r'-0.30 $');
    });
  });

  group('formatFxRate', () {
    test('mostra il cambio con i decimali utili', () {
      expect(formatFxRate(1000000), '1');
      expect(formatFxRate(896190), '0.89619');
      expect(formatFxRate(157775513), '157.77551');
    });

    test('cambio non valido → trattino', () {
      expect(formatFxRate(0), '—');
      expect(formatFxRate(-5), '—');
    });
  });
}
