import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/bitcoin_network_config.dart';

/// Politica di processo sull'uso dei mirror Esplora comunitari (failover).
///
/// PERCHÉ (2026-09-16): la scelta "usa solo mempool.guide" deve essere visibile
/// sia al layer rete (`ExplorerApi`, `BitcoinService`) sia alla UI
/// (Impostazioni). Un'iniezione per-istanza non basterebbe: il
/// [BitcoinService] viene creato una sola volta nel bootstrap dell'app e vive
/// per tutta la sessione. Da qui l'istanza di processo [instance], unico punto
/// di verità — stesso criterio dei registri statici già presenti nel progetto
/// (`PendingSendRegistry`, `BalanceCache`).
///
/// ON (default) → quando mempool.guide è indisponibile l'app può ripiegare sui
/// mirror comunitari. OFF → una sola fonte per letture E broadcast: nessun dato
/// (IP, indirizzo, tx) viene inviato ai mirror.
class ExplorerMirrors extends ChangeNotifier {
  ExplorerMirrors({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Istanza di processo. I test la sostituiscono con uno storage mockato.
  static ExplorerMirrors instance = ExplorerMirrors();

  final FlutterSecureStorage _storage;

  static const String _key = 'explorer_mirrors_enabled';

  bool _enabled = true;

  /// True = fallback sui mirror comunitari consentito.
  bool get enabled => _enabled;

  /// Host per le LETTURE (saldo, UTXO, storico, tip, tx status, fee).
  List<String> get readHosts => _enabled
      ? BitcoinNetworkConfig.explorerApiBaseUrls
      : <String>[BitcoinNetworkConfig.primaryExplorerApiBaseUrl];

  /// Host per il BROADCAST (`POST /tx`).
  List<String> get broadcastHosts => _enabled
      ? BitcoinNetworkConfig.broadcastApiBaseUrls
      : <String>[BitcoinNetworkConfig.primaryExplorerApiBaseUrl];

  /// Legge la preferenza persistita.
  /// PERCHÉ fail-open: uno storage illeggibile non deve né bloccare l'avvio né
  /// cambiare in silenzio il comportamento → si resta sul default ON.
  Future<void> init() async {
    try {
      final stored = await _storage.read(key: _key);
      _enabled = stored != 'false';
    } catch (_) {
      _enabled = true;
    }
    notifyListeners();
  }

  /// Abilita/disabilita i mirror e persiste la scelta (best-effort).
  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    try {
      await _storage.write(key: _key, value: value ? 'true' : 'false');
    } catch (_) {
      // PERCHÉ: la preferenza resta valida per la sessione anche se la
      // persistenza fallisce (stesso criterio di ThemeProvider).
    }
    debugPrint('[ExplorerMirrors] mirror comunitari: ${value ? 'ON' : 'OFF'}');
    notifyListeners();
  }

  /// Ripristina l'istanza di default (solo test: nessuna persistenza reale).
  @visibleForTesting
  static void resetForTest() {
    instance = ExplorerMirrors();
  }
}
