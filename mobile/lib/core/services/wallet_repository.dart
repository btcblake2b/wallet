import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:uuid/uuid.dart';

import '../config/bitcoin_network_config.dart';
import '../models/wallet_record.dart';
import 'bitcoin_service.dart';
import 'crypto_service.dart';
import 'device_service.dart';
import 'secure_seed_storage.dart';

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

  Future<WalletRecord> updateWallet(WalletRecord wallet) async {
    await _secureSeedStorage.upsertWallet(wallet);
    return wallet;
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
