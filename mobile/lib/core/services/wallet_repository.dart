import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:uuid/uuid.dart';

import '../config/bitcoin_network_config.dart';
import '../models/wallet_record.dart';
import 'address_pool.dart';
import 'bitcoin_service.dart';
import 'crypto_service.dart';
import 'device_service.dart';
import 'gap_window_policy.dart';
import 'restore_scanner.dart';
import 'secure_seed_storage.dart';
import 'wallet_index_policy.dart';

/// Indirizzo di ricezione risolto, con il record aggiornato da persistere.
///
/// // PERCHÉ (ADR 30/10-7 §1): l'indice e il record viaggiano insieme
/// // all'indirizzo — chi riceve questo oggetto sa esattamente cosa è stato
/// // consumato e può aggiornare la UI senza rileggere lo storage.
class ReceiveAddressResult {
  const ReceiveAddressResult({
    required this.address,
    required this.index,
    required this.record,
    required this.persisted,
    required this.isFresh,
  });

  final String address;
  final int index;

  /// Record dopo l'operazione (avanzato, se [persisted]).
  final WalletRecord record;

  /// True se l'indice è stato avanzato **e** persistito prima di derivare.
  final bool persisted;

  /// True se questo indirizzo è stato assegnato **da questa chiamata**.
  ///
  /// // PERCHÉ (ADR 30/10-12): sul conflitto idempotente l'indirizzo esiste già
  /// // (doppio tap) e la UI non deve presentarlo come «nuovo indirizzo» — la
  /// // distinzione tra «nuovo» e «già assegnato» non si può dedurre dall'indice.
  final bool isFresh;

  /// Path BIP32 completo dell'indirizzo (`…/0/N`), utile a UI e test.
  String get derivationPath {
    final account =
        record.derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath;
    return '$account/0/$index';
  }
}

/// Il wallet è in stato `legacy` e la rotazione è attiva: serve una conferma
/// esplicita dell'utente all'adozione del primo indice persistito.
///
/// // PERCHÉ (ADR 30/10-7 §2): non si adotta di nascosto un formato nuovo —
/// // l'utente vede il passaggio e può rimandare.
class WalletIndicesAdoptionRequiredException implements Exception {
  const WalletIndicesAdoptionRequiredException(this.walletId);

  final String walletId;

  @override
  String toString() => 'WalletIndicesAdoptionRequiredException($walletId)';
}

/// Il restore è stato richiesto senza una scansione conclusa.
///
/// // PERCHÉ (ADR 31/10-18 §3): «applicare» un risultato non conclusivo
/// // equivarrebbe a dichiarare il restore riuscito senza aver verificato
/// // nulla — fail-open sul percorso di recupero.
class IncompleteRestoreException implements Exception {
  const IncompleteRestoreException(this.walletId, this.result);

  final String walletId;

  /// Risultato parziale completo: la UI ha `probed/requested` **e** l'esito,
  /// quindi può dire «parziale, 12/20» senza una seconda chiamata.
  final RestoreScanResult result;

  GapWindowOutcome get outcome => result.outcome;

  @override
  String toString() =>
      'IncompleteRestoreException($walletId, ${result.outcome.name})';
}

/// Il wallet non ha `accountXpub` e non è stata fornita la seed.
///
/// // PERCHÉ un tipo dedicato (ADR 02/11-28 §1): prima era uno `StateError`, che
/// // in produzione diventa «Errore imprevisto». Il caso è noto e ha un'azione
/// // precisa (sbloccare il vault per derivare e salvare l'xpub), quindi la UI
/// // deve poterlo distinguere da `corrupt`/`anomalous`.
class SeedUnavailableException implements Exception {
  const SeedUnavailableException(this.walletId);

  final String walletId;

  @override
  String toString() => 'SeedUnavailableException($walletId)';
}

/// La seed nel vault **non corrisponde** al wallet: `/0/0` derivato dallo xpub
/// appena calcolato è diverso dalla `publicAddress` che il wallet ha già usato.
///
/// // PERCHÉ esiste (ADR 02/11-33 §1): il backfill persiste l'`accountXpub`
/// // **per sempre**. Con una seed sbagliata (import errato, vault manomesso,
/// // migrazione a metà) l'xpub salvato produrrebbe indirizzi diversi da quelli
/// // con storia on-chain: non riuso, ma fondi non più raggiungibili dal flusso
/// // di ricezione — e in silenzio. L'oracolo gratuito è `publicAddress`: è
/// // l'alias di `/0/0` ed è una verità già mostrata all'utente.
///
/// Fail-closed: si lancia **prima** di scrivere, quindi `accountXpub` resta
/// null e il wallet resta recuperabile (nessun dato sbagliato persistito).
class SeedWalletMismatchException implements Exception {
  const SeedWalletMismatchException({
    required this.walletId,
    required this.recordAddress,
    required this.derivedAddress,
  });

  final String walletId;

  /// `publicAddress` del record (alias di `/0/0`).
  final String recordAddress;

  /// `/0/0` derivato dall'xpub appena calcolato dalla seed del vault.
  final String derivedAddress;

  @override
  String toString() => 'SeedWalletMismatchException($walletId, '
      'record=$recordAddress, derived=$derivedAddress)';
}

/// Esito dell'applicazione di un restore.
class RestoreApplyResult {
  const RestoreApplyResult({
    required this.record,
    required this.persisted,
    required this.recordAboveScan,
    required this.delta,
  });

  final WalletRecord record;
  final bool persisted;

  /// True se il record era **più avanti** della scansione: l'indice adottato è
  /// quello del record e gli indirizzi in mezzo non saranno mostrati.
  final bool recordAboveScan;

  /// **Firmato**: `record − scan`. Positivo = record avanti (contraddizione da
  /// mostrare), negativo = la scansione ha trovato più uso (crescita normale),
  /// zero = allineati.
  final int delta;
}

/// Repository wallet 100% locale (fork blake2b — nessun backend Firebase).
///
/// PERCHÉ: senza trasferimento wallet e senza sync cloud, ogni operazione
/// (crea, importa, elimina) è esclusivamente locale sul device.
class WalletRepository {
  WalletRepository({
    required SecureSeedStorage secureSeedStorage,
    required DeviceService deviceService,
    required CryptoService cryptoService,
    required BitcoinService bitcoinService,
    Uuid? uuid,
  })  : _secureSeedStorage = secureSeedStorage,
        _deviceService = deviceService,
        _cryptoService = cryptoService,
        _bitcoinService = bitcoinService,
        _uuid = uuid ?? const Uuid();

  final SecureSeedStorage _secureSeedStorage;
  final DeviceService _deviceService;
  final CryptoService _cryptoService;
  final BitcoinService _bitcoinService;
  final Uuid _uuid;

  // FLOW: Gestione Wallet
  Future<WalletRecord> createWallet({String? derivationPath}) async {
    final deviceId = await _deviceService.getOrCreateDeviceId();
    final createdAt = DateTime.now().toUtc();
    final walletId = _uuid.v4();

    // STEP: 1 — generazione seed + derivazione + crittografia locale
    final mnemonic = _bitcoinService.generateMnemonic();
    // STEP: 2
    final encryptedSeed = await _cryptoService.encryptSeed(
      seedPhrase: mnemonic,
      deviceId: deviceId,
    );
    // Per la creazione la derivazione iniziale è leggera (solo primo indirizzo)
    // per minimizzare il lavoro CPU su web.
    // PERCHÉ (multi-tipo): se l'utente sceglie un tipo diverso dal default
    // BIP84, si deriva sul path del tipo scelto (es. m/49'… o m/44'…).
    // STEP: 3
    final derivationResult = derivationPath == null
        ? await _bitcoinService.deriveWalletDataFromMnemonic(
            mnemonic,
            addressCount: 1,
          )
        : await _bitcoinService.deriveWalletDataFromMnemonic(
            mnemonic,
            derivationPath: derivationPath,
            addressCount: 1,
          );

    final wallet = WalletRecord(
      walletId: walletId,
      encryptedSeed: encryptedSeed,
      publicAddress: derivationResult.publicAddress,
      deviceId: deviceId,
      createdAt: createdAt,
      masterFingerprint: derivationResult.masterFingerprint,
      derivationPath: derivationResult.derivationPath,
      // PERCHÉ (26/10): salvare l'xpub alla creazione fa sì che saldo,
      // indirizzi e storico si leggano SENZA decifrare la seed.
      accountXpub: derivationResult.xpub,
    );

    // STEP: 4 — persistenza locale (nessuna registrazione cloud).
    await _secureSeedStorage.upsertWallet(wallet);

    return wallet;
  }

  Future<List<WalletRecord>> loadWallets() {
    return _secureSeedStorage.loadWallets();
  }

  /// Decripta il seed di un wallet HOT. Per un wallet watch-only non esiste
  /// alcun seed → errore chiaro (mai una chiave privata in memoria).
  Future<String> decryptSeed(WalletRecord wallet) async {
    if (wallet.kind == WalletKind.watchOnly) {
      throw StateError(
        'Il wallet watch-only non ha un seed da decriptare.',
      );
    }
    return _cryptoService.decryptSeed(
      encryptedSeed: wallet.encryptedSeed,
      deviceId: wallet.deviceId,
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Web password-protection (audit F1)
  // ──────────────────────────────────────────────────────────────

  /// Web: `true` se il vault chiavi (storage wallet + CryptoService) è
  /// protetto da password. Su native è sempre `false`.
  Future<bool> isWebKeyProtected() async {
    final storageProtected = await _secureSeedStorage.isKeyProtectedAsync();
    final cryptoProtected = await _cryptoService.isWebKeyVaultProtected();
    return storageProtected || cryptoProtected;
  }

  /// Web: avvolge TUTTE le chiavi locali (AES storage, master key, ED25519)
  /// con un KEK derivato dalla password e rimuove le versioni in chiaro.
  Future<void> enablePasswordProtection(String password) async {
    await _secureSeedStorage.enablePasswordProtection(password);
    await _cryptoService.enableWebPasswordProtection(password);
  }

  /// Web: sblocca il vault chiavi con la password (le chiavi restano in memoria).
  Future<void> unlockWebStorage(String password) async {
    await _secureSeedStorage.unlockWithPassword(password);
    await _cryptoService.unlockWebStorage(password);
  }

  /// Web (hardening 2.4): blocca il vault azzerando le chiavi in memoria.
  /// Chiamato dall'auto-lock (inattività / pagina nascosta) e dal menu "Blocca".
  /// Su native è un no-op: il keyring OS protegge le chiavi a riposo e non
  /// esiste uno stato "sbloccato in RAM" governato dall'app.
  Future<void> lockWebStorage() async {
    _secureSeedStorage.lock();
    _cryptoService.lockWebStorage();
  }

  /// Web: dimentica SUBITO le chiavi sbloccate appena l'operazione sensibile è
  /// finita (firma, scansione UTXO, creazione PSBT).
  ///
  /// // PERCHÉ (R1, 26/10): la finestra in cui le chiavi stanno in RAM deve
  /// // durare quanto l'operazione, non quanto l'utente resta sulla schermata.
  /// // Prima restava aperta fino all'auto-lock (10 min di inattività) anche
  /// // dopo un invio concluso. Il prossimo gesto sensibile richiederà di nuovo
  /// // la password: è il comportamento voluto, non un fastidio.
  /// Su native è un no-op (il keyring è del sistema operativo).
  Future<void> forgetWebKeysNow() => lockWebStorage();

  Future<WalletRecord> updateWallet(WalletRecord wallet) async {
    await _secureSeedStorage.upsertWallet(wallet);
    return wallet;
  }

  // ──────────────────────────────────────────────────────────────
  // Indirizzi di ricezione (A2 — rotazione + write-ahead)
  // ──────────────────────────────────────────────────────────────

  /// Coda di serializzazione per wallet: due richieste concorrenti (doppio tap,
  /// retry della UI) non devono leggere lo stesso indice e poi sovrascriversi.
  final Map<String, Future<void>> _indexQueues = {};

  /// Risolve il prossimo indirizzo di ricezione secondo la tabella di verità
  /// flag × stato (ADR 30/10-7 §2) e, se la rotazione è attiva, applica
  /// **write-ahead + compare-and-set**: persiste `N+1` **prima** di derivare e
  /// restituire `/0/N`.
  ///
  /// // PERCHÉ (ADR 30/10-7 §1): l'ordine inverso esporrebbe un indirizzo che il
  /// // record non conosce — al riavvio l'indice ripartirebbe da `N` e l'indirizzo
  /// // verrebbe riusato. Se il persist fallisce, nessun indirizzo viene mostrato.
  ///
  /// [adoptLegacy] è la conferma esplicita dell'utente per la prima adozione di
  /// un wallet legacy; [mnemonic] serve solo ai wallet senza `accountXpub`.
  Future<ReceiveAddressResult> nextReceiveAddress(
    WalletRecord wallet, {
    required bool rotationEnabled,
    bool adoptLegacy = false,
    String? mnemonic,
  }) {
    return _serializeByWallet(
      wallet.walletId,
      () => _nextReceiveAddress(
        wallet.walletId,
        rotationEnabled: rotationEnabled,
        adoptLegacy: adoptLegacy,
        mnemonic: mnemonic,
      ),
    );
  }

  Future<ReceiveAddressResult> _nextReceiveAddress(
    String walletId, {
    required bool rotationEnabled,
    required bool adoptLegacy,
    required String? mnemonic,
  }) async {
    // La decisione si prende sul record PERSISTITO: la copia in memoria della
    // UI può essere vecchia di un'operazione.
    var record = await _readWallet(walletId);
    final mode = WalletIndexPolicy.resolve(
      rotationEnabled: rotationEnabled,
      state: record.indicesState,
    );

    switch (mode) {
      case ReceiveAddressMode.blocked:
        // Fa lanciare l'eccezione dedicata (corrotto o anomalo).
        record.requireNextReceiveIndex();
        throw StateError('stato indici non utilizzabile per $walletId');
      case ReceiveAddressMode.legacyPublicAddress:
        return ReceiveAddressResult(
          address: record.publicAddress,
          index: 0,
          record: record,
          persisted: false,
          isFresh: false,
        );
      case ReceiveAddressMode.readOnlyIndex:
        final readOnlyIndex = record.requireNextReceiveIndex();
        return ReceiveAddressResult(
          address: _deriveAddressAt(record, readOnlyIndex, mnemonic),
          index: readOnlyIndex,
          record: record,
          persisted: false,
          isFresh: false,
        );
      case ReceiveAddressMode.needsAdoption:
        if (!adoptLegacy) {
          throw WalletIndicesAdoptionRequiredException(walletId);
        }
        record = record.confirmResetIndices(
          newReceive: 0,
          newChange: record.requireNextChangeIndex(),
        );
      case ReceiveAddressMode.rotate:
        break;
    }

    return _rotateAndDerive(record, mnemonic);
  }

  Future<ReceiveAddressResult> _rotateAndDerive(
    WalletRecord record,
    String? mnemonic,
  ) async {
    // PERCHÉ (ADR 02/11-32 §1 e §4): il chiamante che passa [mnemonic] ha già
    // sbloccato il vault, quindi questa è l'ULTIMA volta che la seed serve per
    // derivare. L'xpub si calcola qui e viaggia **nella stessa scrittura** che
    // avanza l'indice (write-ahead): una sola `upsert`, nessuno stato parziale.
    var base = record;
    if (!record.hasAccountXpub &&
        record.kind != WalletKind.watchOnly &&
        mnemonic != null &&
        mnemonic.isNotEmpty) {
      base = record.copyWith(
        accountXpub: await _deriveAccountXpub(record, mnemonic),
      );
    }

    final index = base.requireNextReceiveIndex();
    final WalletRecord advanced;
    try {
      advanced = base.advanceReceiveIndex(expected: index);
    } on IndexConflictException {
      // Un'altra richiesta ha già consumato questo indice: non si ritenta (un
      // retry consumerebbe un secondo indirizzo) — si restituisce quello già
      // assegnato, che è la risposta attesa da un doppio tap.
      final fresh = await _readWallet(record.walletId);
      // PERCHÉ fail-closed (ADR 30/10-12): tra il read iniziale e il conflitto
      // il record può essere diventato corrotto/anomalo (reset concorrente,
      // restore, disco). In quel caso `N-1` non è un indirizzo assegnato: è un
      // indirizzo inventato da uno stato non valido.
      if (fresh.indicesState != IndicesState.valid) {
        fresh.requireNextReceiveIndex();
        throw StateError(
          'stato indici non utilizzabile per ${fresh.walletId}',
        );
      }
      final assigned = fresh.requireNextReceiveIndex() - 1;
      if (assigned < 0) rethrow;
      return ReceiveAddressResult(
        address: _deriveAddressAt(fresh, assigned, mnemonic),
        index: assigned,
        record: fresh,
        persisted: false,
        isFresh: false,
      );
    }

    // STEP: write-ahead — se questa scrittura fallisce, eccezione e nessun
    // indirizzo mostrato (un indirizzo non registrato sarebbe riusabile).
    await _secureSeedStorage.upsertWallet(advanced);

    return ReceiveAddressResult(
      address: _deriveAddressAt(advanced, index, mnemonic),
      index: index,
      record: advanced,
      persisted: true,
      isFresh: true,
    );
  }

  /// Avanza l'indice di ricezione passando dalla coda (per i chiamanti che
  /// devono consumare un indirizzo già derivato, es. re-uso dopo un conflitto).
  ///
  /// // PERCHÉ esiste (ADR 31/10-15): stessa regola del resto — **nessuna
  /// // mutazione degli indici fuori dal repository**, altrimenti la coda è
  /// // decorativa.
  Future<WalletRecord> advanceReceiveIndex(
    WalletRecord wallet, {
    required int expected,
  }) {
    return _serializeByWallet(wallet.walletId, () async {
      final record = await _readWallet(wallet.walletId);
      record.requireNextReceiveIndex();
      final advanced = record.advanceReceiveIndex(expected: expected);
      await _secureSeedStorage.upsertWallet(advanced);
      return advanced;
    });
  }

  /// Avanza il floor del resto passando **dalla coda del repository**.
  /// // PERCHÉ (ADR 30/10-12): il CAS vive nel modello, ma se i servizi
  /// // chiamassero `record.advanceChangeIndex()` su un record letto dallo
  /// // storage bypasserebbero la coda — e la coda diventerebbe decorativa.
  /// // Invariante: **nessuna mutazione degli indici fuori dal repository**.
  ///
  /// Sul conflitto propaga [IndexConflictException]: per il resto non esiste
  /// un «già assegnato» da riusare, quindi il chiamante **non deve
  /// broadcastare** (sicuro, e l'utente può ripetere l'invio).
  Future<WalletRecord> advanceChangeIndex(
    WalletRecord wallet, {
    required int expected,
  }) {
    return _serializeByWallet(wallet.walletId, () async {
      final record = await _readWallet(wallet.walletId);
      // Fail-closed sugli stati non validi, prima di qualunque scrittura.
      record.requireNextChangeIndex();
      final advanced = record.advanceChangeIndex(expected: expected);
      await _secureSeedStorage.upsertWallet(advanced);
      return advanced;
    });
  }

  /// Deriva un singolo indirizzo di ricezione all'indice [index].
  ///
  /// // PERCHÉ xpub-first: se il wallet ha l'`accountXpub` si deriva **senza**
  /// // decifrare la seed (watch-only e hot hanno lo stesso percorso); la seed
  /// // serve solo ai record più vecchi che non hanno l'xpub.
  String _deriveAddressAt(
    WalletRecord wallet,
    int index,
    String? mnemonic,
  ) {
    final path =
        wallet.derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath;
    final useXpub = wallet.hasAccountXpub;
    final effectiveMnemonic = useXpub ? null : mnemonic;
    if (!useXpub && (effectiveMnemonic == null || effectiveMnemonic.isEmpty)) {
      throw SeedUnavailableException(wallet.walletId);
    }

    final block = deriveAddressBlock(
      AddressBlockRequest(
        mnemonic: effectiveMnemonic,
        accountXpub: useXpub ? wallet.accountXpub : null,
        scriptType: WalletScriptType.fromDerivationPath(path),
        derivationPath: path,
        start: index,
        count: 1,
      ),
    );
    return block.external.single;
  }

  /// Applica l'esito di una scansione del gap al wallet.
  ///
  /// Accetta il **risultato**, non un indice: se la scansione non è conclusa
  /// ([RestoreScanResult.isConclusive] falso) lancia [IncompleteRestoreException].
  ///
  /// // PERCHÉ il tipo e non un `int?` (ADR 31/10-19 §2): con `int?` la
  /// // chiamata illegale compilava e il `null` era gestito a runtime. Lo stato
  /// // leggibile dal tipo non esiste — stessa disciplina applicata a
  /// // `IndicesState.corrupt`, che non è rappresentabile senza reset esplicito.
  ///
  /// // PERCHÉ (ADR 31/10-18 §5): se il record è **più avanti** della scansione
  /// // vince il record — sicuro, ma è una contraddizione da mostrare
  /// // (`recordAboveScan`), altrimenti gli indirizzi in mezzo non verranno mai
  /// // mostrati e nessuno lo saprà.
  Future<RestoreApplyResult> applyRestore(
    String walletId,
    RestoreScanResult scanResult,
  ) {
    return _serializeByWallet(walletId, () async {
      final scanned = scanResult.scannedIndex;
      if (!scanResult.isConclusive || scanned == null) {
        throw IncompleteRestoreException(walletId, scanResult);
      }

      final record = await _readWallet(walletId);
      // Lancia (Corrupt/Anomalous) prima di qualunque scrittura.
      final resolved = WalletIndexPolicy.resolveRestoredReceiveIndexFor(
        record: record,
        scanned: scanned,
      );
      final current = record.requireNextReceiveIndex();
      // delta firmato: positivo = record avanti, negativo = scansione avanti.
      final delta = current - scanned;

      if (resolved == current) {
        return RestoreApplyResult(
          record: record,
          recordAboveScan: delta > 0,
          delta: delta,
          persisted: false,
        );
      }

      final updated = record.copyWith(nextReceiveIndex: resolved);
      await _secureSeedStorage.upsertWallet(updated);
      return RestoreApplyResult(
        record: updated,
        recordAboveScan: delta > 0,
        delta: delta,
        persisted: true,
      );
    });
  }

  Future<WalletRecord> _readWallet(String walletId) async {
    final wallets = await _secureSeedStorage.loadWallets();
    for (final wallet in wallets) {
      if (wallet.walletId == walletId) return wallet;
    }
    throw StateError('Wallet $walletId non trovato.');
  }

  /// Serializza le operazioni sugli indici dello stesso wallet.
  Future<T> _serializeByWallet<T>(
    String walletId,
    Future<T> Function() action,
  ) {
    final previous = _indexQueues[walletId] ?? Future<void>.value();
    final completer = Completer<void>();
    _indexQueues[walletId] = completer.future;

    return previous.then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) completer.complete();
      if (identical(_indexQueues[walletId], completer.future)) {
        _indexQueues.remove(walletId);
      }
    });
  }

  // FLOW: Etichette e note
  /// Imposta la nota utente di una transazione e la persiste col wallet.
  ///
  /// // PERCHÉ: la nota vive nel record del wallet (`tx_notes`, chiave = txid) —
  /// stesso pattern di `utxoLabels`: nessuno storage nuovo, nessun backend,
  /// nessun segreto. Una nota vuota (o di soli spazi) RIMUOVE la chiave, così
  /// un wallet senza note resta byte-identico a un wallet mai etichettato.
  ///
  /// Lancia [ArgumentError] se [txid] è vuoto.
  // STEP: 1 — persistenza locale della nota (nessuna chiamata di rete)
  Future<WalletRecord> setTransactionNote(
    WalletRecord wallet,
    String txid,
    String note,
  ) async {
    if (txid.isEmpty) {
      throw ArgumentError.value(txid, 'txid', 'txid vuoto');
    }
    // PERCHÉ: `txNotes` è immutabile nel record → si lavora su una copia.
    final notes = Map<String, String>.from(wallet.txNotes);
    final trimmed = note.trim();
    if (trimmed.isEmpty) {
      notes.remove(txid);
    } else {
      notes[txid] = trimmed;
    }
    final updated = wallet.copyWith(txNotes: notes);
    await updateWallet(updated);
    if (kDebugMode) {
      final shortId = txid.length > 8 ? txid.substring(0, 8) : txid;
      debugPrint(
        '[LoopEngineer] nota tx $shortId… '
        '${trimmed.isEmpty ? 'rimossa' : 'salvata'} (${notes.length} note)',
      );
    }
    return updated;
  }

  Future<void> deleteWallet(String walletId) async {
    await _secureSeedStorage.deleteWallet(walletId);
  }

  // ──────────────────────────────────────────────────────────────
  // Backup & Recovery
  // ──────────────────────────────────────────────────────────────

  /// Marca il seed phrase come "backup confermato" dall'utente.
  /// Non esegue alcun backup automatico — è una conferma manuale.
  Future<WalletRecord> confirmSeedBackup(WalletRecord wallet) async {
    final updated = wallet.copyWith(
      seedBackupConfirmed: true,
    );
    await _secureSeedStorage.upsertWallet(updated);
    return updated;
  }

  /// Ricava e salva l'[WalletRecord.accountXpub] di un wallet HOT creato prima
  /// che il campo esistesse (migrazione una volta sola).
  ///
  /// // PERCHÉ (26/10): senza questo, solo i wallet nuovi leggerebbero senza
  /// // seed e i wallet già installati continuerebbero a richiedere la
  /// // password a ogni apertura. La migrazione costa una decifratura UNA volta
  /// // e poi le letture non toccano più le chiavi.
  ///
  /// // INVARIANTE (ADR 02/11-32 §1): per la **derivazione degli indirizzi**
  /// // questa è l'unica operazione che decifra la seed. Dopo un successo il
  /// // wallet è xpub-only per sempre; la seed resta leggibile solo per firmare.
  ///
  /// No-op (nessun I/O) se il wallet ha già l'xpub o è watch-only. Gli errori
  /// di decifratura risalgono al chiamante: è lui a sapere se il vault è
  /// bloccato e a decidere di riprovare più tardi.
  ///
  /// // PERCHÉ la coda + la rilettura (ADR 02/11-32 §2): il [wallet] del
  /// // chiamante può essere stantio e scriverlo sovrascriverebbe un indice
  /// // avanzato nel frattempo — regressione, cioè possibile riuso di un
  /// // indirizzo. Il valore invece è deterministico (stessa seed, stesso path
  /// // ⇒ stesso xpub), quindi non serve un CAS sul valore.
  Future<WalletRecord> backfillAccountXpub(WalletRecord wallet) {
    return _serializeByWallet(wallet.walletId, () async {
      final record = await _readWallet(wallet.walletId);
      if (record.hasAccountXpub || record.kind == WalletKind.watchOnly) {
        return record;
      }
      final mnemonic = await decryptSeed(record);
      final xpub = await _deriveAccountXpub(record, mnemonic);
      final updated = record.copyWith(accountXpub: xpub);
      // Unica scrittura: se fallisce non resta stato parziale e l'xpub rimane
      // null (fail-closed: la richiesta successiva ripropone `seedRequired`).
      await _secureSeedStorage.upsertWallet(updated);
      if (kDebugMode) {
        debugPrint('[LoopEngineer] xpub salvato per ${record.walletId}');
      }
      return updated;
    });
  }

  /// Deriva l'account xpub (m/…'/0') da una seed **già decifrata**, verificando
  /// che la seed corrisponda al wallet.
  ///
  /// // PERCHÉ due chiamanti (ADR 02/11-32 §1): il backfill esplicito e
  /// // [nextReceiveAddress] condividono **la stessa** derivazione, così il
  /// // percorso e il tipo di indirizzo non possono divergere fra i due.
  ///
  /// // PERCHÉ la verifica (ADR 02/11-33 §1): `publicAddress` è l'alias di
  /// // `/0/N=0` ed è una verità già mostrata all'utente. Se `/0/0` derivato
  /// // dall'xpub non coincide, la seed nel vault non è quella del wallet: si
  /// // lancia PRIMA di scrivere, così non si persiste un xpub sbagliato.
  Future<String> _deriveAccountXpub(
    WalletRecord record,
    String mnemonic,
  ) async {
    // Stesso path del wallet: un wallet m/49' deve salvare l'xpub del suo
    // account, non quello di default. La rete non è per-wallet
    // (`BitcoinNetworkConfig.current` è una costante di build).
    final derived = await _bitcoinService.deriveWalletDataFromMnemonic(
      mnemonic,
      derivationPath: record.derivationPath,
      addressCount: 1,
    );

    final path = record.derivationPath;
    final firstAddress = deriveAddressBlock(
      AddressBlockRequest(
        accountXpub: derived.xpub,
        scriptType: WalletScriptType.fromDerivationPath(path),
        derivationPath: path,
        start: 0,
        count: 1,
      ),
    ).external.single;

    if (firstAddress != record.publicAddress) {
      throw SeedWalletMismatchException(
        walletId: record.walletId,
        recordAddress: record.publicAddress,
        derivedAddress: firstAddress,
      );
    }
    return derived.xpub;
  }

  /// Importa un wallet da una mnemonic phrase (e derivazione path opzionale).
  /// Il wallet viene salvato esclusivamente in locale.
  Future<WalletRecord> importWallet({
    required String mnemonic,
    String? derivationPath,
  }) async {
    // Validate mnemonic via bip39 elsewhere if needed.
    final deviceId = await _deviceService.getOrCreateDeviceId();
    // Encrypt the seed (mnemonic) for secure storage.
    final encryptedSeed = await _cryptoService.encryptSeed(
      seedPhrase: mnemonic,
      deviceId: deviceId,
    );
    // Derive wallet data (address, fingerprint, etc.) using optional derivationPath.
    final derivationResult = await _bitcoinService.deriveWalletDataFromMnemonic(
      mnemonic,
      derivationPath: derivationPath,
    );
    final wallet = WalletRecord(
      walletId: _uuid.v4(),
      encryptedSeed: encryptedSeed,
      publicAddress: derivationResult.publicAddress,
      deviceId: deviceId,
      createdAt: DateTime.now().toUtc(),
      masterFingerprint: derivationResult.masterFingerprint,
      derivationPath: derivationResult.derivationPath,
      // PERCHÉ (26/10): stesso motivo della creazione — l'xpub è pubblico e
      // rende superflua la decifratura per le sole letture.
      accountXpub: derivationResult.xpub,
    );

    try {
      // PERCHÉ: persistenza locale pura — nessuna registrazione cloud.
      await _secureSeedStorage.upsertWallet(wallet);
    } catch (e) {
      // Cleanup on failure.
      await _secureSeedStorage.deleteWallet(wallet.walletId);
      if (kDebugMode) {
        debugPrint('wallet_repo: import fallita: $e');
      }
      rethrow;
    }
    return wallet;
  }

  /// Importa un wallet WATCH-ONLY da una chiave pubblica estesa (xpub).
  ///
  /// PERCHÉ (P1): nessun seed da generare/cifrare — l'xpub è una chiave
  /// PUBBLICA (sicura da salvare). Il wallet non potrà firmare: solo
  /// monitorare saldo/storico. `encryptedSeed` resta `''` (mai usato) e
  /// [decryptSeed] lancia un errore chiaro per questo tipo.
  // FLOW: Import Wallet Watch-only
  // STEP: 1 — validazione xpub + derivazione primo indirizzo (compute)
  // STEP: 2 — persistenza locale
  Future<WalletRecord> importWatchOnly({
    required String accountXpub,
    required WalletScriptType scriptType,
  }) async {
    final deviceId = await _deviceService.getOrCreateDeviceId();

    // STEP: 1 — valida e deriva (lancia FormatException/StateError se l'xpub
    // è invalido, di rete errata o è una chiave privata xprv).
    final derivation = await _bitcoinService.deriveWatchOnlyData(
      accountXpub: accountXpub,
      scriptType: scriptType,
      addressCount: 1,
    );

    final wallet = WalletRecord(
      walletId: _uuid.v4(),
      encryptedSeed: '',
      publicAddress: derivation.publicAddress,
      deviceId: deviceId,
      createdAt: DateTime.now().toUtc(),
      masterFingerprint: derivation.fingerprint,
      derivationPath: scriptType.accountPath(),
      kind: WalletKind.watchOnly,
      accountXpub: accountXpub,
    );

    // STEP: 2 — persistenza locale (stesso store dei wallet hot).
    await _secureSeedStorage.upsertWallet(wallet);
    return wallet;
  }
}
