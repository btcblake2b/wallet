import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'fiat_currency.dart';

/// Cambi USDT → valute fiat, letti on-demand da Coinbase.
///
/// // PERCHÉ esiste: il prezzo di XBT è quotato in USDC (NeoXEX) e non esiste
/// // una coppia EUR/XBT, quindi il controvalore in euro (o altra valuta) si
/// // ottiene convertendo: XBT → USDT → EUR col cambio **USDT/EUR reale**.
/// // Coinbase espone il cambio di tutte le valute in una sola richiesta
/// // (`exchange-rates?currency=USDT`, circa 20 KB), senza API key.
///
/// // PERCHÉ i cambi sono in MICRO unità intere (rate x 1.000.000): l'aritmetica
/// // del denaro resta intera. Il calcolo finale è `cents * microRate ~/ 1e6`.
///
/// // PERCHÉ i cambi si persistono: dopo un riavvio il controvalore nella
/// // valuta scelta deve comparire subito, senza rete; il refresh resta
/// // esplicito (nessun polling).
class FxRates extends ChangeNotifier {
  FxRates({
    FlutterSecureStorage? storage,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    bool persist = true,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _persist = persist;

  /// Istanza con stato in memoria, per i test (nessuna scrittura).
  @visibleForTesting
  FxRates.inMemory({http.Client? client})
      : _storage = const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _persist = false,
        timeout = const Duration(seconds: 10);

  /// Istanza di processo (stesso criterio di [FiatPrice]).
  static FxRates instance = FxRates();

  /// Endpoint pubblico: cambi di TUTTE le valute rispetto a 1 USDT.
  static const String endpoint =
      'https://api.coinbase.com/v2/exchange-rates?currency=USDT';

  /// Fattore di scala dei cambi (rate x 1.000.000).
  static const int scale = 1000000;

  static const String _ratesKey = 'fx_usdt_rates_v1';
  static const String _atKey = 'fx_usdt_rates_at';

  final FlutterSecureStorage _storage;
  final http.Client _client;
  final bool _persist;

  final Duration timeout;

  final Map<FiatCurrency, int> _microRates = {};
  DateTime? _fetchedAt;

  /// Cambio (micro unità per 1 USDT) della valuta, oppure `null` se non ancora
  /// scaricato. USD/USDT vale sempre 1:1 (è la base).
  int? microRateFor(FiatCurrency currency) =>
      currency == FiatCurrency.usd ? scale : _microRates[currency];

  /// Quando i cambi sono stati letti l'ultima volta (null = mai).
  DateTime? get fetchedAt => _fetchedAt;

  /// True se c'è un cambio per la valuta richiesta.
  bool hasRate(FiatCurrency currency) => microRateFor(currency) != null;

  /// Legge i cambi persistiti (best-effort: senza storage si resta senza cambi
  /// e la UI chiede un refresh — mai un cambio inventato).
  Future<void> init() async {
    try {
      final raw = await _storage.read(key: _ratesKey);
      final at = DateTime.tryParse(await _storage.read(key: _atKey) ?? '');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final currency = FiatCurrency.fromCode(entry.key);
            final value = entry.value;
            if (currency == null || value is! int || value <= 0) continue;
            _microRates[currency] = value;
          }
          _fetchedAt = at;
        }
      }
    } catch (e) {
      debugPrint('[FxRates] init error: $e');
    }
    notifyListeners();
  }

  /// Scarica i cambi aggiornati. Ritorna `true` se almeno una valuta è stata
  /// aggiornata. Non lancia mai: un errore lascia i cambi precedenti.
  Future<bool> refresh() async {
    try {
      final response = await _client.get(Uri.parse(endpoint)).timeout(timeout);
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return false;
      final payload = data['data'];
      if (payload is! Map<String, dynamic>) return false;
      if (payload['currency'] != 'USDT') return false;
      final rates = payload['rates'];
      if (rates is! Map<String, dynamic>) return false;

      var updated = 0;
      for (final currency in FiatCurrency.fxCurrencies) {
        final raw = rates[currency.code];
        final value = raw is String ? double.tryParse(raw) : raw as num?;
        if (value == null || !value.isFinite) continue;
        // PERCHÉ i limiti: un cambio a 0 o assurdo (payload rotto/attacco)
        // produrrebbe un controvalore senza senso — meglio scartarlo.
        if (value <= 0 || value > 1000000) continue;
        _microRates[currency] = (value * scale).round();
        updated++;
      }
      if (updated == 0) return false;

      _fetchedAt = DateTime.now();
      await _persistRates();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[FxRates] refresh error: $e');
      return false;
    }
  }

  /// Imposta un cambio a mano (solo test).
  @visibleForTesting
  void setRateForTest(FiatCurrency currency, double rate) {
    _microRates[currency] = (rate * scale).round();
    notifyListeners();
  }

  Future<void> _persistRates() async {
    if (!_persist) return;
    try {
      await _storage.write(
        key: _ratesKey,
        value: jsonEncode({
          for (final entry in _microRates.entries) entry.key.code: entry.value,
        }),
      );
      await _storage.write(
        key: _atKey,
        value: (_fetchedAt ?? DateTime.now()).toIso8601String(),
      );
    } catch (e) {
      // PERCHÉ: i cambi restano validi per la sessione anche se non persistono.
      debugPrint('[FxRates] persist error: $e');
    }
  }

  /// Ripristina l'istanza di default (solo test).
  @visibleForTesting
  static void resetForTest() {
    instance = FxRates();
  }
}
