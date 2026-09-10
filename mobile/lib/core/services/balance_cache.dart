import 'package:flutter/foundation.dart';

import '../models/wallet_snapshot.dart';

/// Cache in-memory degli snapshot wallet (per indirizzo), condivisa tra Home e
/// Detail.
///
/// PERCHÉ: la Home mostra i saldi e il Detail mostra saldo+UTXO+storico senza
/// rifetch a ogni navigazione. Politica refresh minima:
/// - all'avvio dell'app (Home) si popola lo snapshot;
/// - il Detail usa lo snapshot se fresco (TTL), altrimenti aggiorna in
///   background;
/// - il bottone "Aggiorna" / il pull-to-refresh forzano un nuovo fetch;
/// - `getOrFetch` deduplica i fetch concorrenti per lo stesso wallet (niente
///   doppie chiamate di rete tra Home e Detail);
/// - ogni scrittura notifica i listener (la Home si riallinea senza fetch).
/// Persiste finché l'app è viva.
///
/// TTL condiviso: entro questo tempo lo snapshot è considerato "fresco" e non
/// viene rifatto il fetch all'apertura del Detail.
const kSnapshotTtl = Duration(minutes: 5);

/// Sottoclasse che espone `notifyListeners` (protected) come metodo pubblico,
/// così il bus statico può notificare senza violare la visibilità del membro.
class _CacheNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class BalanceCache {
  BalanceCache._();

  static final Map<String, WalletSnapshot> _snapshots = {};

  /// Fetch in corso per indirizzo → dedup (evita race condition tra Home che
  /// carica all'avvio e Detail che si apre: il secondo attende il primo).
  static final Map<String, Future<WalletSnapshot>> _inFlight = {};

  /// Bus di notifica (stesso pattern di LocaleProvider/ThemeProvider): chi
  /// scrive uno snapshot avvisa i listener (es. Home) senza accoppiamento.
  static final _CacheNotifier _bus = _CacheNotifier();

  static WalletSnapshot? snapshotOf(String address) => _snapshots[address];

  /// True se esiste già un fetch in corso per questo indirizzo.
  static bool isFetching(String address) => _inFlight.containsKey(address);

  /// Salva lo snapshot e notifica i listener (Home si riallinea da qui).
  static void putSnapshot(String address, WalletSnapshot snapshot) {
    _snapshots[address] = snapshot;
    _bus.notify();
  }

  /// Salva più snapshot in un colpo e notifica una sola volta.
  static void putSnapshots(Map<String, WalletSnapshot> values) {
    _snapshots.addAll(values);
    _bus.notify();
  }

  /// Ritorna lo snapshot esistente se presente e fresco (rispetto a TTL),
  /// altrimenti NULL → il chiamante decide se fare fetch.
  static WalletSnapshot? freshSnapshot(String address) {
    final snapshot = _snapshots[address];
    if (snapshot == null) return null;
    return snapshot.isFresh(kSnapshotTtl) ? snapshot : null;
  }

  /// Fetch con dedup: se un fetch per `address` è già in corso, attende quello
  /// invece di lanciarne un secondo (niente doppia chiamata di rete).
  ///
  /// Al completamento salva lo snapshot in cache e notifica i listener.
  static Future<WalletSnapshot> getOrFetch(
    String address,
    Future<WalletSnapshot> Function() loader,
  ) {
    final inFlight = _inFlight[address];
    if (inFlight != null) return inFlight;

    final future = loader().then((snapshot) {
      putSnapshot(address, snapshot);
      return snapshot;
    });
    _inFlight[address] = future;
    // PERCHÉ: pulizia del dedup a prescindere dall'esito (successo o errore),
    // così un fetch fallito non blocca i tentativi successivi. `.ignore()`
    // evita un "unhandled async error" sul future derivato da whenComplete.
    future.whenComplete(() {
      if (identical(_inFlight[address], future)) {
        _inFlight.remove(address);
      }
    }).ignore();
    return future;
  }

  static void addListener(VoidCallback listener) => _bus.addListener(listener);

  static void removeListener(VoidCallback listener) =>
      _bus.removeListener(listener);

  /// Azzera la cache (usato nei test per l'isolamento tra testWidgets).
  @visibleForTesting
  static void resetForTest() {
    _snapshots.clear();
    _inFlight.clear();
  }
}
