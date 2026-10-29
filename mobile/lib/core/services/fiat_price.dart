import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'fiat_currency.dart';
import 'fx_rates.dart';

/// Controvalore indicativo in USD del saldo XBT.
///
/// // PERCHÉ (leva 5, 27/10): le persone non usano ciò di cui non vedono il
/// // valore. Il vecchio layer CoinGecko è stato rimosso il 07/09 perché il
/// // prezzo BTC è **sbagliato** per questa rete (nessun mercato), e oggi le
/// // piazze XBT (NonKYC, SafeTrade) NON espongono un'API pubblica
/// // raggiungibile: sondate il 27/10 — 404 su NonKYC, 403/WAF su SafeTrade.
/// // Un wallet non deve né grattare HTML né fingere un prezzo di mercato.
/// //
/// // Quindi: prezzo **impostato dall'utente** (quello che vede sulla piazza
/// // che usa) OPPURE letto on-demand da NeoXEX (l'unica piazza XBT con API
/// // pubblica, verificata il 29/10: `neoxa.exchange/api/exchange/trades`).
/// // Zero telemetria, nessun polling: la lettura avviene SOLO quando l'utente
/// // la chiede (toggle "prezzo automatico" nelle Impostazioni).
///
/// // PERCHÉ tutto in CENTESIMI interi: il denaro non si calcola in virgola
/// // mobile. `centsFor` fa una sola moltiplicazione intera e arrotonda per
/// // difetto (mai un controvalore gonfiato).
class FiatPrice extends ChangeNotifier {
  FiatPrice({FlutterSecureStorage? storage, http.Client? client})
      : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  /// Istanza con stato in memoria, per i test dei widget.
  ///
  /// // PERCHÉ esiste: nei test widget non c'è un handler per il canale di
  /// // `flutter_secure_storage`, quindi `setEnabled`/`setUsdCentsPerXbt`
  /// // resterebbero appesi su un Future che non si completa mai (visto il
  /// // 27/10: `pumpAndSettle` andato in timeout a 10 minuti). Qui lo stato è
  /// // già quello che serve al test e non si tocca la persistenza.
  @visibleForTesting
  FiatPrice.inMemory({
    bool enabled = false,
    int? usdCentsPerXbt,
    FiatCurrency currency = FiatCurrency.usd,
  })  : _storage = const FlutterSecureStorage(),
        _client = http.Client(),
        _enabled = enabled && usdCentsPerXbt != null,
        _usdCentsPerXbt = usdCentsPerXbt,
        _currency = currency;

  /// Istanza di processo (stesso criterio di [InfoHints]/[ExplorerMirrors]):
  /// il controvalore serve in schermate costruite senza contesto condiviso.
  static FiatPrice instance = FiatPrice();

  final FlutterSecureStorage _storage;

  /// Client HTTP iniettabile (pattern già usato in [ExplorerApi]) per testare
  /// con MockClient senza colpire la rete reale.
  final http.Client _client;

  static const String _enabledKey = 'fiat_price_enabled';
  static const String _centsKey = 'fiat_usd_cents_per_xbt';
  static const String _autoKey = 'fiat_price_auto';
  static const String _currencyKey = 'fiat_price_currency';

  /// Satoshi in 1 XBT.
  static const int satsPerXbt = 100000000;

  /// Endpoint pubblico NeoXEX: ultimo trade XBT/USDC (la piazza identifica
  /// Bitcoin BLAKE2b col token `BTCB2`). Verificato il 29/10/2026.
  static const String neoxexTradesEndpoint =
      'https://neoxa.exchange/api/exchange/trades/BTCB2_USDC?limit=1';

  /// Timeout della richiesta al prezzo NeoXEX.
  static const Duration neoxexTimeout = Duration(seconds: 10);

  bool _enabled = false;
  int? _usdCentsPerXbt;
  bool _auto = false;
  FiatCurrency _currency = FiatCurrency.usd;

  /// True = l'app mostra il controvalore (default OFF).
  ///
  /// // PERCHÉ default OFF: senza prezzo impostato non c'è nulla da mostrare;
  /// // e una preferenza che non fa richieste di rete deve essere esplicita.
  bool get enabled => _enabled && _usdCentsPerXbt != null;

  /// Prezzo corrente, in centesimi di dollaro (USDC) per 1 XBT.
  int? get usdCentsPerXbt => _usdCentsPerXbt;

  /// Prezzo in dollari, per la UI di impostazione (es. `300.0`).
  double? get usdPerXbt =>
      _usdCentsPerXbt == null ? null : _usdCentsPerXbt! / 100.0;

  /// True = il prezzo viene letto da NeoXEX (on-demand) invece che digitato.
  bool get auto => _auto;

  /// Valuta in cui si mostra il controvalore.
  FiatCurrency get currency => _currency;

  /// True se la valuta scelta ha un cambio disponibile (USD è la base).
  bool get hasCurrencyRate => FxRates.instance.hasRate(_currency);

  /// Controvalore in **centesimi della valuta scelta** per [sats].
  ///
  /// Ritorna `null` se il controvalore è spento, senza prezzo o se manca il
  /// cambio della valuta (in quel caso la UI deve chiedere un refresh: mai un
  /// importo calcolato con un cambio inventato).
  int? centsFor(int sats) {
    if (!enabled || sats <= 0) return null;
    final usdCents = (sats * _usdCentsPerXbt!) ~/ satsPerXbt;
    final rate = FxRates.instance.microRateFor(_currency);
    if (rate == null) return null;
    return (usdCents * rate) ~/ FxRates.scale;
  }

  /// Legge le preferenze persistite (best-effort: uno storage illeggibile
  /// lascia il default OFF, mai un prezzo inventato).
  Future<void> init() async {
    try {
      _enabled = await _storage.read(key: _enabledKey) == 'true';
      _auto = await _storage.read(key: _autoKey) == 'true';
      _currency = FiatCurrency.fromCode(
            await _storage.read(key: _currencyKey),
          ) ??
          FiatCurrency.usd;
      final cents = int.tryParse(
        await _storage.read(key: _centsKey) ?? '',
      );
      _usdCentsPerXbt = (cents != null && cents > 0) ? cents : null;
    } catch (e) {
      debugPrint('[LoopEngineer] FiatPrice.init error: $e');
      _enabled = false;
      _auto = false;
      _currency = FiatCurrency.usd;
      _usdCentsPerXbt = null;
    }
    debugPrint(
      '[LoopEngineer] FiatPrice.init: enabled=$_enabled auto=$_auto '
      'currency=${_currency.code} cents=$_usdCentsPerXbt',
    );
    notifyListeners();
  }

  /// Imposta il prezzo (in centesimi per XBT). `null`/`<= 0` = nessun prezzo,
  /// che equivale a spegnere il controvalore.
  Future<void> setUsdCentsPerXbt(int? cents) async {
    final clean = (cents != null && cents > 0) ? cents : null;
    if (clean == _usdCentsPerXbt) return;
    _usdCentsPerXbt = clean;
    if (clean == null) _enabled = false;
    try {
      await _storage.write(
        key: _centsKey,
        value: clean == null ? '' : '$clean',
      );
      if (clean == null) {
        await _storage.write(key: _enabledKey, value: 'false');
      }
    } catch (e) {
      // PERCHÉ: la scelta resta valida per la sessione anche se non persiste.
      debugPrint('[LoopEngineer] FiatPrice.setUsdCentsPerXbt error: $e');
    }
    notifyListeners();
  }

  /// Mostra/nasconde il controvalore. Senza prezzo non si accende.
  Future<void> setEnabled(bool value) async {
    final next = value && _usdCentsPerXbt != null;
    if (next == _enabled) return;
    _enabled = next;
    try {
      await _storage.write(key: _enabledKey, value: next ? 'true' : 'false');
    } catch (e) {
      debugPrint('[LoopEngineer] FiatPrice.setEnabled error: $e');
    }
    notifyListeners();
  }

  /// Attiva/disattiva la lettura automatica del prezzo da NeoXEX.
  ///
  /// // PERCHÉ: l'auto NON accende il controvalore da sola — serve comunque
  /// // il toggle "mostra controvalore". Se non c'è ancora un prezzo, il primo
  /// // fetch on-demand lo riempie; se il fetch fallisce, il prezzo manuale
  /// // (se esiste) resta quello mostrato.
  Future<void> setAuto(bool value) async {
    if (value == _auto) return;
    _auto = value;
    try {
      await _storage.write(key: _autoKey, value: value ? 'true' : 'false');
    } catch (e) {
      debugPrint('[LoopEngineer] FiatPrice.setAuto error: $e');
    }
    notifyListeners();
  }

  /// Imposta la valuta del controvalore.
  ///
  /// // PERCHÉ non scarica qui i cambi: la richiesta di rete la orchestra la UI
  /// // (Impostazioni), che sa mostrare un errore leggibile se Coinbase non
  /// // risponde. Qui si registra solo la scelta.
  Future<void> setCurrency(FiatCurrency currency) async {
    if (currency == _currency) return;
    _currency = currency;
    try {
      await _storage.write(key: _currencyKey, value: currency.code);
    } catch (e) {
      debugPrint('[LoopEngineer] FiatPrice.setCurrency error: $e');
    }
    notifyListeners();
  }

  /// Legge l'ultimo trade XBT/USDC da NeoXEX e aggiorna il prezzo.
  ///
  /// Ritorna `true` se il prezzo è stato aggiornato. Non lancia mai: un
  /// errore di rete lascia il prezzo precedente (mai un numero inventato).
  ///
  /// // PERCHÉ on-demand e non polling: il controvalore è indicativo e la
  /// // privacy policy dichiara ogni host contattato — una richiesta a ogni
  /// // apertura della card sarebbe telemetria non richiesta.
  Future<bool> refreshFromNeoxex() async {
    try {
      final response = await _client
          .get(Uri.parse(neoxexTradesEndpoint))
          .timeout(neoxexTimeout);
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return false;
      if (data['success'] != true || data['pair'] != 'BTCB2_USDC') {
        return false;
      }
      final trades = data['trades'];
      if (trades is! List || trades.isEmpty) return false;
      final trade = trades.first;
      if (trade is! Map<String, dynamic>) return false;
      final price = trade['price'];
      if (price is! num || price <= 0) return false;
      // PERCHÉ: il prezzo arriva con 8+ decimali (es. 272.96083251); il
      // controvalore vive in centesimi interi → si tronca, mai si arrotonda
      // (un controvalore gonfiato sarebbe peggio di uno approssimato).
      final cents = (price * 100).floor();
      if (cents <= 0) return false;
      await setUsdCentsPerXbt(cents);
      return true;
    } catch (e) {
      debugPrint('[LoopEngineer] FiatPrice.refreshFromNeoxex error: $e');
      return false;
    }
  }

  /// Ripristina l'istanza di default (solo test: nessuna persistenza reale).
  @visibleForTesting
  static void resetForTest() {
    instance = FiatPrice();
  }
}

/// Converte un prezzo scritto dall'utente ("300", "300.5", "300,50") in
/// centesimi interi. `null` se non è un prezzo valido (> 0, max 2 decimali).
///
/// // PERCHÉ a mano e non `double.parse(s) * 100`: in virgola mobile
/// // `1.15 * 100` vale 114.99999… e arrotondato dà 115 solo per fortuna —
/// // con altri valori sbaglia di un centesimo. Qui si lavora sulle cifre.
int? parseUsdToCents(String raw) {
  final cleaned = raw
      .trim()
      .replaceAll(' ', '')
      .replaceAll('USD', '')
      .replaceAll('\$', '')
      .replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final parts = cleaned.split('.');
  if (parts.length > 2) return null;
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first);
  if (whole == null || whole < 0) return null;
  final fractionRaw = parts.length == 2 ? parts[1] : '';
  if (fractionRaw.length > 2) return null;
  final fraction =
      fractionRaw.isEmpty ? 0 : int.tryParse(fractionRaw.padRight(2, '0'));
  if (fraction == null) return null;
  final cents = whole * 100 + fraction;
  return cents > 0 ? cents : null;
}
