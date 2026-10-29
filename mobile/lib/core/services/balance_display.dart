import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/bitcoin_network_config.dart';
import 'fiat_currency.dart';
import 'fiat_price.dart';

/// Unità con cui la UI mostra un saldo.
enum BalanceUnit {
  /// 0,00100000 BTC (default storico dell'app).
  xbt,

  /// 100 000 sats — l'unità in cui si ragiona sui fee.
  sats,

  /// Controvalore in dollari (richiede un prezzo: vedi [FiatPrice]).
  fiat,
}

/// Unità di visualizzazione dei saldi, **per wallet**.
///
/// // PERCHÉ un registro di processo (come [InfoHints]/[FiatPrice]): la stessa
/// // scelta deve valere sia nella riga del wallet in home sia nella card del
/// // dettaglio, che sono widget diversi e senza contesto condiviso. La chiave è
/// // il `walletId`, quindi ogni wallet ha la propria unità e cambiarla su uno
/// // non tocca gli altri; il totale in home usa [totalKey].
///
/// // PERCHÉ si persiste: una preferenza che sopravvive al riavvio è il
/// // comportamento atteso da chi tocca il saldo (BlueWallet fa lo stesso).
class BalanceDisplay extends ChangeNotifier {
  BalanceDisplay({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        _persist = true;

  /// Istanza con stato in memoria, per i test dei widget.
  ///
  /// // PERCHÉ esiste: nei test widget il canale di `flutter_secure_storage`
  /// // non ha handler, quindi una `write` resterebbe appesa e `pumpAndSettle`
  /// // andrebbe in timeout (lezione già pagata con FiatPrice il 27/10).
  @visibleForTesting
  BalanceDisplay.inMemory()
      : _storage = const FlutterSecureStorage(),
        _persist = false;

  /// Istanza di processo.
  static BalanceDisplay instance = BalanceDisplay();

  /// Chiave del totale dei saldi in home (non è un wallet).
  static const String totalKey = '__total__';

  static const String _keyPrefix = 'balance_unit_';

  final FlutterSecureStorage _storage;

  /// False solo nelle istanze da test: nessuna scrittura sullo storage.
  final bool _persist;

  final Map<String, BalanceUnit> _units = {};

  /// Unità corrente per [key] (walletId oppure [totalKey]).
  ///
  /// // PERCHÉ il degrado a XBT: se il controvalore viene spento o il prezzo
  /// // cancellato, un'unità `fiat` rimasta salvata mostrerebbe un "$" senza
  /// // numero. Si torna al default invece di mostrare un valore inventato.
  BalanceUnit unitFor(String key) {
    final unit = _units[key] ?? BalanceUnit.xbt;
    if (unit == BalanceUnit.fiat && !FiatPrice.instance.enabled) {
      return BalanceUnit.xbt;
    }
    return unit;
  }

  /// True se [key] sta mostrando il controvalore in dollari.
  bool isFiat(String key) => unitFor(key) == BalanceUnit.fiat;

  /// Passa all'unità successiva: XBT → sats → $ → XBT.
  ///
  /// // PERCHÉ il salto del dollaro quando non c'è un prezzo: ciclare su
  /// // un'unità senza valore mostrerebbe "—" e sembrerebbe un guasto.
  Future<void> cycle(String key, {bool? fiatAvailable}) async {
    final canShowFiat = fiatAvailable ?? FiatPrice.instance.enabled;
    final next = switch (unitFor(key)) {
      BalanceUnit.xbt => BalanceUnit.sats,
      BalanceUnit.sats => canShowFiat ? BalanceUnit.fiat : BalanceUnit.xbt,
      BalanceUnit.fiat => BalanceUnit.xbt,
    };
    if (_units[key] == next) return;
    _units[key] = next;
    if (_persist) {
      try {
        await _storage.write(key: '$_keyPrefix$key', value: next.name);
      } catch (e) {
        // PERCHÉ: la scelta resta valida per la sessione anche se non persiste
        // (stesso criterio di FiatPrice/ExplorerMirrors).
        debugPrint('[BalanceDisplay] persist error: $e');
      }
    }
    notifyListeners();
  }

  /// Legge le preferenze persistite (best-effort: uno storage illeggibile
  /// lascia i default XBT).
  Future<void> init() async {
    try {
      final all = await _storage.readAll();
      for (final entry in all.entries) {
        if (!entry.key.startsWith(_keyPrefix)) continue;
        final name = entry.value;
        for (final unit in BalanceUnit.values) {
          if (unit.name == name) {
            _units[entry.key.substring(_keyPrefix.length)] = unit;
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('[BalanceDisplay] init error: $e');
    }
    notifyListeners();
  }

  /// Ripristina l'istanza di default (solo test: nessuna persistenza reale).
  @visibleForTesting
  static void resetForTest() {
    instance = BalanceDisplay();
  }
}

/// Satoshi formattati per la UI: `1 234 567`.
///
/// // PERCHÉ lo spazio e non il separatore del locale: il numero va accanto a
/// // "sats" dentro righe strette (card del wallet), dove un separatore
/// // localizzato (`.` o `,`) si confonde con il decimale di BTC mostrato sopra.
String formatSats(int sats) {
  final digits = sats.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${sats < 0 ? '-' : ''}$buffer';
}

/// Valore del saldo nell'unità richiesta, pronto da mostrare.
///
/// [fiatCents] è il controvalore già calcolato (`FiatPrice.centsFor`) **nella
/// valuta selezionata**; se manca (prezzo o cambio assenti) si ricade su XBT —
/// mai un importo finto. [currency] default = valuta scelta dall'utente.
String formatBalanceValue(
  BalanceUnit unit,
  int sats, {
  int? fiatCents,
  FiatCurrency? currency,
}) {
  switch (unit) {
    case BalanceUnit.xbt:
      return '${(sats / FiatPrice.satsPerXbt).toStringAsFixed(8)} '
          '${BitcoinNetworkConfig.ticker}';
    case BalanceUnit.sats:
      return '${formatSats(sats)} sats';
    case BalanceUnit.fiat:
      if (fiatCents == null) {
        return '${(sats / FiatPrice.satsPerXbt).toStringAsFixed(8)} '
            '${BitcoinNetworkConfig.ticker}';
      }
      return formatMoney(
        fiatCents,
        currency ?? FiatPrice.instance.currency,
      );
  }
}
