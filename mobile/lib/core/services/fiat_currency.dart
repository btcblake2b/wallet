/// Valute fiat supportate per il controvalore.
///
/// // PERCHÉ un enum e non stringhe libere: il simbolo, i decimali e il codice
/// // per il cambio devono restare allineati in un solo punto. Le valute sono
/// // "le principali": USD (base), EUR, GBP, CHF, JPY, CAD.
///
/// // PERCHÉ tutto passa da USDT: non esiste un mercato EUR/XBT. Il prezzo di
/// // XBT è quotato in USDC da NeoXEX, quindi si converte XBT → USDT → valuta
/// // locale usando il cambio della valuta su USDT (mercato reale, non un
/// // tasso BCE).
enum FiatCurrency {
  usd(code: 'USD', symbol: r'$', decimals: 2),
  eur(code: 'EUR', symbol: '€', decimals: 2),
  gbp(code: 'GBP', symbol: '£', decimals: 2),
  chf(code: 'CHF', symbol: 'CHF', decimals: 2),
  jpy(code: 'JPY', symbol: '¥', decimals: 0),
  cad(code: 'CAD', symbol: r'C$', decimals: 2);

  const FiatCurrency({
    required this.code,
    required this.symbol,
    required this.decimals,
  });

  /// Codice ISO 4217 (anche chiave del cambio su USDT).
  final String code;

  /// Simbolo mostrato accanto al valore.
  final String symbol;

  /// Decimali della valuta (0 per JPY, 2 per le altre).
  final int decimals;

  /// Valuta di un codice ISO, oppure `null` se non supportata.
  static FiatCurrency? fromCode(String? code) {
    if (code == null) return null;
    for (final currency in FiatCurrency.values) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  /// Valute che richiedono un cambio (tutto tranne la base USD/USDT).
  static List<FiatCurrency> get fxCurrencies =>
      values.where((c) => c != FiatCurrency.usd).toList(growable: false);
}

/// Formatta un importo espresso in **centesimi** (1/100) nella valuta data.
///
/// // PERCHÉ il raggruppamento a spazi: i controvalori in JPY arrivano a
/// // cinque cifre e senza separatore si leggono male; uno spazio non entra in
/// // conflitto con il separatore decimale `.` in nessuna lingua.
String formatMoney(int cents, FiatCurrency currency) {
  final negative = cents < 0;
  final abs = negative ? -cents : cents;
  // JPY non ha centesimi: si arrotonda al valore intero.
  final whole = currency.decimals == 0 ? (abs + 50) ~/ 100 : abs ~/ 100;
  final fraction = abs % 100;
  final grouped = _groupThousands(whole.toString());
  final decimals =
      currency.decimals == 0 ? '' : '.${fraction.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}$grouped$decimals ${currency.symbol}';
}

/// Cambio in forma leggibile (`0.89619`), con al massimo [digits] decimali.
String formatFxRate(int microRate, {int digits = 5}) {
  if (microRate <= 0) return '—';
  final whole = microRate ~/ 1000000;
  final fraction = (microRate % 1000000)
      .toString()
      .padLeft(6, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  final trimmed =
      fraction.length > digits ? fraction.substring(0, digits) : fraction;
  return trimmed.isEmpty ? '$whole' : '$whole.$trimmed';
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
