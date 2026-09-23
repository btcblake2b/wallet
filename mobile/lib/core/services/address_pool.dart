import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';

import '../config/bitcoin_network_config.dart';
import '../utils/crypto_utils.dart';

/// Richiesta di derivazione di un **blocco** di indirizzi `[start, start+count)`
/// per entrambe le catene (ricezione `/0` e resto `/1`).
///
/// // PERCHÉ (P8-b): la derivazione BIP32 è il costo dominante del primo
/// // snapshot (secondi sul device). Derivare "a blocchi" permette di fermarsi
/// // al gap-limit senza pagare 100+100 indirizzi a ogni apertura.
class AddressBlockRequest {
  const AddressBlockRequest({
    this.mnemonic,
    this.accountXpub,
    this.scriptType = WalletScriptType.p2wpkh,
    this.derivationPath,
    required this.start,
    required this.count,
  });

  /// Seed del wallet hot. In alternativa [accountXpub] (watch-only).
  final String? mnemonic;

  /// Chiave pubblica estesa di account (watch-only, profondità 3).
  final String? accountXpub;

  /// Tipo di indirizzo — usato SOLO per il percorso watch-only: per l'hot il
  /// tipo si deduce dal `purpose` di [derivationPath] (come in
  /// `deriveWalletData`), così non può divergere dal path.
  final WalletScriptType scriptType;

  /// Path di derivazione (`m/84'/0'/0'` per default).
  final String? derivationPath;

  /// Primo indice del blocco (incluso).
  final int start;

  /// Quanti indirizzi derivare, per catena.
  final int count;
}

/// Indirizzi derivati di un blocco, per entrambe le catene.
class AddressBlockResult {
  const AddressBlockResult({required this.external, required this.change});

  /// Indirizzi di ricezione (`/0/start … /0/start+count-1`).
  final List<String> external;

  /// Indirizzi di resto (`/1/start … /1/start+count-1`).
  final List<String> change;
}

/// Deriva il blocco richiesto (top-level: gira in `compute`, CPU-bound).
///
/// Equivalente per costruzione a `deriveWalletData`/`deriveWatchOnlyAddresses`
/// sullo stesso intervallo di indici — l'equivalenza è coperta dai test.
AddressBlockResult deriveAddressBlock(AddressBlockRequest request) {
  final path =
      request.derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath;

  final bip32.BIP32 account;
  final String mnemonic = request.mnemonic ?? '';
  if (mnemonic.isNotEmpty) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(
      seed,
      BitcoinNetworkConfig.bip32NetworkType,
    );
    account = root.derivePath(path);
  } else {
    final xpub = request.accountXpub ?? '';
    if (xpub.isEmpty) {
      throw const FormatException('Serve un mnemonic o un account xpub.');
    }
    account = bip32.BIP32.fromBase58(
      xpub,
      BitcoinNetworkConfig.bip32NetworkType,
    );
    // PERCHÉ: un wallet watch-only non deve MAI derivare da una chiave privata.
    if (account.privateKey != null) {
      throw StateError(
        'Inserisci una chiave pubblica estesa (xpub), non una privata (xprv).',
      );
    }
  }

  // PERCHÉ: per il wallet hot il tipo di indirizzo segue il path (BIP84/BIP49/
  // BIP44) come nella derivazione completa; per l'xpub lo decide il chiamante.
  final type = mnemonic.isNotEmpty
      ? WalletScriptType.fromDerivationPath(path)
      : request.scriptType;

  // I due rami si derivano UNA volta sola e si riusano (come in
  // `deriveWalletData` dopo P8-b/opzione A).
  final externalChain = account.derive(0);
  final changeChain = account.derive(1);

  final external = <String>[];
  final change = <String>[];
  for (var i = 0; i < request.count; i++) {
    final index = request.start + i;
    external.add(
      pubKeyToAddressForType(externalChain.derive(index).publicKey, type: type),
    );
    change.add(
      pubKeyToAddressForType(changeChain.derive(index).publicKey, type: type),
    );
  }
  return AddressBlockResult(external: external, change: change);
}

/// Pool di indirizzi derivati **a blocchi**, con memoizzazione.
///
/// // PERCHÉ (P8-b): i cicli che consumano indirizzi (scan UTXO, storico) hanno
/// // già un gap-limit BIP44: chiedono blocchi man mano e il pool deriva solo
/// // ciò che serve. Nel caso tipico si derivano ~21 indirizzi per ramo invece
/// // di 100 — e il pool è condiviso fra scan e storico, che prima derivano
/// // due volte lo stesso set.
class AddressPool {
  AddressPool({
    required AddressBlockRequest Function(int start, int count) requestFor,
    this.maxAddresses = 100,
    this.useIsolate = true,
  }) : _requestFor = requestFor;

  final AddressBlockRequest Function(int start, int count) _requestFor;

  /// Cap di indirizzi per ramo (100 come nella derivazione completa attuale).
  final int maxAddresses;

  /// `false` nei test: deriva nello stesso isolate (deterministico e veloce).
  final bool useIsolate;

  final List<String> _external = [];
  final List<String> _change = [];

  /// Coda che serializza le richieste di blocco.
  Future<void> _queue = Future<void>.value();

  int _runs = 0;

  /// Indirizzi di ricezione derivati finora (gap aperti inclusi).
  List<String> get external => List.unmodifiable(_external);

  /// Indirizzi di resto derivati finora.
  List<String> get change => List.unmodifiable(_change);

  /// Quanti indirizzi per ramo sono già disponibili.
  int get derivedCount => _external.length;

  /// Quanti blocchi sono stati effettivamente derivati (test/diagnostica).
  int get derivationRuns => _runs;

  /// Garantisce almeno [needed] indirizzi per ramo (mai oltre [maxAddresses]).
  ///
  /// // PERCHÉ serializzato: i due rami (ricezione/resto) girano in parallelo e
  /// chiedono blocchi insieme — senza coda, due derivazioni concorrenti
  /// appenderrebbero in ordine non deterministico.
  Future<void> ensure(int needed) {
    final run = _queue.then((_) => _ensure(needed));
    // La coda non deve rompersi se un blocco fallisce.
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _ensure(int needed) async {
    final want = needed < 0
        ? 0
        : (needed > maxAddresses ? maxAddresses : needed);
    if (want <= _external.length) return;

    final start = _external.length;
    final request = _requestFor(start, want - start);
    final result = useIsolate
        ? await compute(deriveAddressBlock, request)
        : deriveAddressBlock(request);
    _external.addAll(result.external);
    _change.addAll(result.change);
    _runs++;
  }
}
