// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unnecessary_brace_in_string_interps
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;

import '../models/wallet_record.dart';

// ──────────────────────────────────────────────────────────────
// JS interop bindings per Web Crypto API (NON usare `dynamic` o
// `dart:html`._SubtleCrypto perché minificano i nomi dei metodi).
// Usiamo @JS() che preserva i nomi JS esatti.
// ──────────────────────────────────────────────────────────────

@JS('crypto.subtle.importKey')
external JSPromise<JSObject> _jsImportKey(
  JSString format,
  JSArrayBuffer keyData,
  JSObject algorithm,
  JSBoolean extractable,
  JSArray<JSString> keyUsages,
);

@JS('crypto.subtle.encrypt')
external JSPromise<JSArrayBuffer> _jsEncrypt(
  JSObject algorithm,
  JSObject key,
  JSUint8Array data,
);

@JS('crypto.subtle.decrypt')
external JSPromise<JSArrayBuffer> _jsDecrypt(
  JSObject algorithm,
  JSObject key,
  JSUint8Array data,
);

// ──────────────────────────────────────────────────────────────
// Audit F1: PBKDF2 via Web Crypto API per il key-wrapping con password.
// La chiave AES del wallet NON deve più vivere in chiaro in localStorage:
// viene avvolta con un KEK derivato dalla password (PBKDF2-SHA256, 600k iter).
// ──────────────────────────────────────────────────────────────

@JS('crypto.subtle.importKey')
external JSPromise<JSObject> _jsImportKeyPbkdf2(
  JSString format,
  JSArrayBuffer keyData,
  JSObject algorithm,
  JSBoolean extractable,
  JSArray<JSString> keyUsages,
);

@JS('crypto.subtle.deriveBits')
external JSPromise<JSArrayBuffer> _jsDeriveBits(
  JSObject algorithm,
  JSObject key,
  JSNumber length,
);

/// Sollevata quando lo storage web è protetto da password ma non è stato
/// ancora sbloccato con [SecureSeedStorage.unlockWithPassword].
class StorageLockedException implements Exception {
  final String message;
  StorageLockedException(this.message);
  @override
  String toString() => 'StorageLockedException: $message';
}

/// Helper: converte [Uint8List] in [JSUint8Array] (built-in in dart:js_interop).
extension type _AesGcmParams._(JSObject _) implements JSObject {
  external factory _AesGcmParams({
    required JSString name,
    required JSUint8Array iv,
  });
}

// ──────────────────────────────────────────────────────────────
// IndexedDB backup layer: localStorage può essere azzerato dal
// browser durante aggiornamenti PWA; IndexedDB è persistente.
// I dati sono già cifrati AES-256-GCM, quindi sicuri anche in
// IndexedDB. Il backup è best-effort: se IndexedDB fallisce,
// l'operazione prosegue (i wallet rimangono in localStorage).
// ──────────────────────────────────────────────────────────────

class _BackupStore {
  _BackupStore();

  static const String _dbName = 'wallet_backup_db';
  static const String _storeName = 'wallet_entries';

  dynamic _db;
  bool _initFailed = false;

  Future<dynamic> _getDb() async {
    if (_initFailed) return null;
    if (_db != null) return _db;
    try {
      final idb = html.window.indexedDB;
      if (idb == null) {
        _initFailed = true;
        return null;
      }
      // Usa dynamic perché dart:html è deprecato e i tipi IDB non esistono più
      _db = await (idb as dynamic).open(
        _dbName,
        version: 1,
        onUpgradeNeeded: (dynamic e) {
          final db = (e.target as dynamic).transaction.db;
          if (!(db.objectStoreNames as dynamic).contains(_storeName)) {
            db.createObjectStore(_storeName);
          }
        },
      );
      // Gestisce chiusura improvvisa (es. aggiornamento)
      (_db as dynamic).onClose.listen((_) {
        _db = null;
      });
      return _db;
    } catch (e) {
      _initFailed = true;
      debugPrint('idx_backup: init failed: $e');
      return null;
    }
  }

  /// Salva una entry (key-value) nel backup IndexedDB.
  ///
  /// A differenza della versione precedente (fire-and-forget), questa
  /// versione **attende** il completamento della transazione e verifica
  /// che i dati siano stati effettivamente scritti.
  ///
  /// Timeout: 5 secondi per evitare blocchi indefiniti.
  Future<bool> backup(String key, String value) async {
    try {
      final db = await _getDb();
      if (db == null) return false;

      final tx = (db as dynamic).transaction(_storeName, 'readwrite');
      final store = tx.objectStore(_storeName);
      store.put({'key': key, 'value': value});

      // Attendi il completamento con timeout
      await (tx as dynamic).completed.timeout(const Duration(seconds: 5));

      // Verifica che la scrittura sia andata a buon fine
      final verifyTx = (db as dynamic).transaction(_storeName, 'readonly');
      final verifyStore = verifyTx.objectStore(_storeName);
      final result = await (verifyStore as dynamic)
          .getObject(key)
          .timeout(const Duration(seconds: 3));

      if (result != null && (result is Map) && result['value'] == value) {
        return true;
      }
      debugPrint('idx_backup: write verification failed for $key');
      return false;
    } catch (e) {
      debugPrint('idx_backup: write failed for $key: $e');
      return false;
    }
  }

  /// Recupera una entry dal backup IndexedDB.
  Future<String?> load(String key) async {
    try {
      final db = await _getDb();
      if (db == null) return null;
      final tx = (db as dynamic).transaction(_storeName, 'readonly');
      final store = tx.objectStore(_storeName);
      final result = await (store as dynamic).getObject(key);
      if (result == null) return null;
      return (result as Map)['value'] as String?;
    } catch (e) {
      debugPrint('idx_backup: read failed for $key: $e');
      return null;
    }
  }

  /// Rimuove una entry dal backup IndexedDB.
  Future<void> remove(String key) async {
    try {
      final db = await _getDb();
      if (db == null) return;
      final tx = (db as dynamic).transaction(_storeName, 'readwrite');
      final store = tx.objectStore(_storeName);
      (store as dynamic).delete(key);
      await (tx as dynamic).completed;
    } catch (e) {
      debugPrint('idx_backup: delete failed for $key: $e');
    }
  }
}

/// [SecureSeedStorage] per PWA con cifratura AES-256-GCM dei wallet.
///
/// Genera una chiave AES-256 casuale al primo avvio e la conserva in
/// localStorage con backup automatico su IndexedDB per sopravvivere
/// agli aggiornamenti PWA.
///
/// I wallet sono cifrati prima di essere scritti e decifrati dopo la
/// lettura. Il backup IndexedDB è trasparente e automatico.
///
/// Questo protegge da attacchi XSS passivi (lettura sola di localStorage)
/// e ispezione casuale, ma NON da XSS attivi che possono eseguire codice
/// arbitrario e leggere sia chiave che ciphertext.
class SecureSeedStorage {
  SecureSeedStorage();

  // Chiavi localStorage
  static const String _indexKey = 'wallet_index_v3'; // v3 = encrypted
  static const String _walletPrefix = 'wallet_record_v3_';
  static const String _encryptionKeyStorage = '_wallet_aes_key_v1';
  // Audit F1: blob della chiave avvolta con KEK derivato dalla password.
  // Formato: `iterations:salt_b64:nonce||ciphertext_b64` (AES-256-GCM).
  static const String _walletAesKeyWrapped = '_wallet_aes_key_wrapped_v1';
  static const int _wrapIterations = 600000;
  static const int _wrapSaltLength = 16;

  static const int _nonceLength = 12;

  final html.Storage _storage = html.window.localStorage;
  final _BackupStore _backup = _BackupStore();

  Uint8List? _cachedEncryptionKey;
  List<String>? _cachedIndex;

  // ──────────────────────────────────────────────────────────────
  // Gestione chiave di cifratura
  // ──────────────────────────────────────────────────────────────

  /// Recupera o genera la chiave AES-256 per cifrare i wallet.
  Uint8List _getOrCreateEncryptionKey() {
    if (_cachedEncryptionKey != null) return _cachedEncryptionKey!;

    // Audit F1: se il vault è protetto da password, la chiave in chiaro NON
    // esiste più. Senza sblocco (unlockWithPassword) l'accesso è negato.
    if (isKeyProtected) {
      throw StorageLockedException(
        'Storage cifrato con password: chiamare unlockWithPassword().',
      );
    }

    final storedBase64 = _storage[_encryptionKeyStorage];
    if (storedBase64 != null && storedBase64.isNotEmpty) {
      _cachedEncryptionKey = base64Decode(storedBase64);
      return _cachedEncryptionKey!;
    }

    // Genera nuova chiave AES-256 (32 byte)
    final random = Random.secure();
    final keyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = random.nextInt(256);
    }

    _storage[_encryptionKeyStorage] = base64Encode(keyBytes);
    _cachedEncryptionKey = keyBytes;
    debugPrint('storage: generated new AES-256 encryption key');
    // Backup chiave anche su IndexedDB (non cifrata ma IndexedDB è più
    // persistente di localStorage attraverso aggiornamenti PWA).
    // Ora usiamo un retry automatico in background.
    _backupKeyToIndexedDB(base64Encode(keyBytes));
    return keyBytes;
  }

  // ──────────────────────────────────────────────────────────────
  // Audit F1: password-based key-wrapping
  // ──────────────────────────────────────────────────────────────

  /// `true` se la chiave è avvolta con password (protezione attiva).
  bool get isKeyProtected {
    final blob = _storage[_walletAesKeyWrapped];
    return blob != null && blob.isNotEmpty;
  }

  /// Come [isKeyProtected], ma verifica anche il backup IndexedDB
  /// (localStorage può essere azzerato dagli aggiornamenti PWA).
  Future<bool> isKeyProtectedAsync() async {
    if (isKeyProtected) return true;
    final backup = await _backup.load(_walletAesKeyWrapped);
    return backup != null && backup.isNotEmpty;
  }

  /// PERCHÉ (hardening 2.4): WebCrypto e la persistenza sicura hanno senso solo
  /// in un secure context (HTTPS o localhost). Su HTTP il vault NON deve essere
  /// creato/sbloccato: meglio un errore chiaro di una falsa sensazione di
  /// sicurezza (su origini non sicure il browser può degradare le API crypto).
  static void _assertSecureContext() {
    if (html.window.isSecureContext != true) {
      throw StorageLockedException(
        'Contesto non sicuro (serve HTTPS): il vault chiavi non può essere usato.',
      );
    }
  }

  /// Avvolge la chiave AES corrente con un KEK derivato dalla password
  /// (PBKDF2-SHA256 600k + AES-256-GCM) e rimuove la chiave in chiaro da
  /// localStorage E IndexedDB. Idempotente: se già protetto, è un no-op.
  ///
  /// Il salt e le iterazioni sono salvati nel blob: migrazione sicura anche
  /// se i parametri di default cambieranno in futuro.
  Future<void> enablePasswordProtection(String password) async {
    _assertSecureContext();
    if (password.isEmpty || isKeyProtected) return;
    // La chiave corrente (o nuova se mai generata) viene AVVOLTA, non rigenerata:
    // i wallet esistenti restano decifrabili.
    final key = _getOrCreateEncryptionKey();
    final random = Random.secure();
    final salt = Uint8List(_wrapSaltLength);
    for (var i = 0; i < _wrapSaltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    final kek = await _deriveKeyWithPbkdf2(
      password,
      salt,
      iterations: _wrapIterations,
    );
    // Cifra la chiave (base64, ASCII) con AES-GCM usando il KEK.
    final wrapped = await _encrypt(base64Encode(key), kek);
    final blob = '$_wrapIterations:${base64Encode(salt)}:$wrapped';
    _storage[_walletAesKeyWrapped] = blob;
    // Backup del blob cifrato su IndexedDB (sopravvive agli azzeramenti PWA).
    await _backup.backup(_walletAesKeyWrapped, blob);
    // Rimuovi la chiave in chiaro ovunque.
    _storage.remove(_encryptionKeyStorage);
    await _backup.remove(_encryptionKeyStorage);
    // Retry di sicurezza: la scrittura del backup plaintext potrebbe essere
    // ancora in-flight (chiave generata da poco) — rimuovi anche dopo il delay.
    Future.delayed(const Duration(seconds: 2), () {
      _backup.remove(_encryptionKeyStorage);
    });
    // La chiave resta disponibile in memoria (sessione già sbloccata).
    _cachedEncryptionKey = key;
    debugPrint('storage: AES key wrapped with password protection (F1)');
  }

  /// Sblocca il vault: deriva il KEK dalla password e decifra la chiave AES.
  /// La chiave resta SOLO in memoria ([_cachedEncryptionKey]).
  Future<void> unlockWithPassword(String password) async {
    _assertSecureContext();
    if (_cachedEncryptionKey != null) return; // già sbloccato
    var blob = _storage[_walletAesKeyWrapped];
    if (blob == null || blob.isEmpty) {
      // localStorage azzerato → ripristina il blob cifrato da IndexedDB.
      blob = await _backup.load(_walletAesKeyWrapped);
      if (blob == null || blob.isEmpty) {
        throw StorageLockedException('Nessun blob cifrato trovato.');
      }
      _storage[_walletAesKeyWrapped] = blob;
    }
    final parts = blob.split(':');
    if (parts.length != 3) {
      throw const FormatException('Blob chiave cifrata corrotto');
    }
    final iterations = int.parse(parts[0]);
    final salt = base64Decode(parts[1]);
    final kek =
        await _deriveKeyWithPbkdf2(password, salt, iterations: iterations);
    final keyBase64 = await _decrypt(parts[2], kek);
    _cachedEncryptionKey = base64Decode(keyBase64);
  }

  /// Pulisce la chiave e l'indice dalla memoria (logout / lock / auto-lock 2.4).
  void lock() {
    // PERCHÉ (hardening 2.4): best-effort wipe del buffer prima del drop —
    // riduce la finestra in cui la chiave AES resta leggibile in un heap dump.
    final key = _cachedEncryptionKey;
    if (key != null) {
      key.fillRange(0, key.length, 0);
    }
    _cachedEncryptionKey = null;
    _cachedIndex = null;
  }

  /// Deriva un KEK (256 bit) dalla password con PBKDF2-HMAC-SHA256 via WebCrypto.
  Future<Uint8List> _deriveKeyWithPbkdf2(
    String password,
    Uint8List salt, {
    int iterations = _wrapIterations,
  }) async {
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    final saltCopy = Uint8List.fromList(salt);
    final keyMaterial = await _jsImportKeyPbkdf2(
      'raw'.toJS,
      passwordBytes.buffer.toJS,
      ({'name': 'PBKDF2'.toJS}).jsify() as JSObject,
      false.toJS,
      ['deriveBits'.toJS].toJS,
    ).toDart;
    final derivedBits = await _jsDeriveBits(
      ({
        'name': 'PBKDF2'.toJS,
        'salt': saltCopy.toJS,
        'iterations': iterations.toJS,
        'hash': 'SHA-256'.toJS,
      }).jsify() as JSObject,
      keyMaterial,
      (32 * 8).toJS,
    ).toDart;
    return derivedBits.toDart.asUint8List();
  }

  /// Backup della chiave AES su IndexedDB in modo asincrono ma tracciato.
  /// Non blocca l'operazione principale ma logga il risultato e ritenta.
  void _backupKeyToIndexedDB(String encodedKey) {
    _backup.backup(_encryptionKeyStorage, encodedKey).then((success) {
      if (success) {
        debugPrint('idx_backup: AES key backed up successfully');
      } else {
        debugPrint('idx_backup: AES key backup FAILED — will retry');
        // Retry una volta dopo 2 secondi
        Future.delayed(const Duration(seconds: 2), () {
          _backup.backup(_encryptionKeyStorage, encodedKey).then((retryOk) {
            if (retryOk) {
              debugPrint('idx_backup: AES key backup retry OK');
            } else {
              debugPrint('idx_backup: AES key backup DEFINITIVELY FAILED');
            }
          });
        });
      }
    });
  }

  // ──────────────────────────────────────────────────────────────
  // Cifratura / Decifratura AES-256-GCM via Web Crypto API
  // ──────────────────────────────────────────────────────────────

  Future<String> _encrypt(String plaintext, Uint8List key) async {
    final nonce = Uint8List(_nonceLength);
    final random = Random.secure();
    for (int i = 0; i < _nonceLength; i++) {
      nonce[i] = random.nextInt(256);
    }

    final cryptoKey = await _importAesKey(key);
    // Crea copie Uint8List per garantire buffer con dimensione esatta
    final nonceCopy = Uint8List.fromList(nonce);
    final plainCopy = Uint8List.fromList(utf8.encode(plaintext));
    // Chiamata JS interop: i nomi dei metodi sono preservati da @JS()
    final encrypted = await _jsEncrypt(
      _AesGcmParams(
        name: 'AES-GCM'.toJS,
        iv: nonceCopy.toJS,
      ),
      cryptoKey,
      plainCopy.toJS,
    ).toDart;

    // encrypted è JSArrayBuffer → ByteBuffer → Uint8List
    final cipherBytes = Uint8List.fromList(
      encrypted.toDart.asUint8List(),
    );
    // Formato: nonce (12 byte) || ciphertext + tag (variabile)
    final result = Uint8List(nonce.length + cipherBytes.length);
    result.setAll(0, nonce);
    result.setAll(nonce.length, cipherBytes);

    return base64Encode(result);
  }

  Future<String> _decrypt(String encoded, Uint8List key) async {
    final data = base64Decode(encoded);
    if (data.length <= _nonceLength) {
      throw const FormatException('Dati cifrati corrotti: troppo corti');
    }

    final nonce = Uint8List.sublistView(data, 0, _nonceLength);
    final ciphertext = Uint8List.sublistView(data, _nonceLength);

    final cryptoKey = await _importAesKey(key);
    // Crea copie Uint8List: .sublistView().buffer ha backing buffer più grande!
    final nonceCopy = Uint8List.fromList(nonce);
    final ciphertextCopy = Uint8List.fromList(ciphertext);
    // Chiamata JS interop: i nomi dei metodi sono preservati da @JS()
    final decrypted = await _jsDecrypt(
      _AesGcmParams(
        name: 'AES-GCM'.toJS,
        iv: nonceCopy.toJS,
      ),
      cryptoKey,
      ciphertextCopy.toJS,
    ).toDart;

    return utf8.decode(
      decrypted.toDart.asUint8List(),
    );
  }

  /// Importa una chiave AES nel formato Web Crypto API.
  ///
  /// Crea una copia dei keyBytes per garantire che il buffer passato a
  /// Web Crypto abbia la dimensione esatta (32 byte). In Dart web,
  /// [Uint8List.buffer] può restituire un buffer più grande se l'array
  /// è una view (es. da [base64Decode]), causando il fallimento di
  /// [CryptoSubtle.importKey] con "Error" non gestito.
  Future<JSObject> _importAesKey(Uint8List keyBytes) async {
    // Copia i byte per avere un buffer della dimensione esatta
    final keyCopy = Uint8List.fromList(keyBytes);
    // Chiamata JS interop: i nomi dei metodi sono preservati da @JS()
    final jsKey = await _jsImportKey(
      'raw'.toJS,
      keyCopy.buffer.toJS,
      ({'name': 'AES-GCM'.toJS}).jsify() as JSObject,
      false.toJS,
      ['encrypt'.toJS, 'decrypt'.toJS].toJS,
    ).toDart;
    return jsKey;
  }

  // ──────────────────────────────────────────────────────────────
  // Operazioni wallet (stessa API di secure_seed_storage_io.dart)
  // ──────────────────────────────────────────────────────────────

  Future<List<WalletRecord>> loadWallets() async {
    final key = _getOrCreateEncryptionKey();
    final t0 = DateTime.now().millisecondsSinceEpoch;

    // ── 1) Prova a caricare da localStorage (primario) ──
    final indexEncrypted = _storage[_indexKey];
    if (indexEncrypted != null && indexEncrypted.isNotEmpty) {
      try {
        final wallets = await _loadFromIndex(key, indexEncrypted);
        if (wallets.isNotEmpty) {
          final t1 = DateTime.now().millisecondsSinceEpoch;
          debugPrint('storage: loadWallets dt=${t1 - t0}ms (v3 encrypted)');
          return wallets;
        }
      } catch (e) {
        debugPrint('storage: loadWallets v3 failed, trying backup: $e');
      }
    }

    // ── 2) localStorage vuoto o corrotto → recupera da IndexedDB ──
    // Questo succede quando il browser azzera localStorage durante
    // aggiornamenti PWA. IndexedDB è più persistente.
    final backupIndex = await _backup.load(_indexKey);
    if (backupIndex != null && backupIndex.isNotEmpty) {
      try {
        final wallets = await _loadFromIndex(key, backupIndex);
        if (wallets.isNotEmpty) {
          debugPrint(
            'storage: RECOVERED ${wallets.length} wallet(s) from IndexedDB backup (localStorage was empty)!',
          );
          // Ripristina localStorage dal backup IndexedDB
          await _restoreLocalStorage(wallets, key);
          final t1 = DateTime.now().millisecondsSinceEpoch;
          debugPrint(
            'storage: loadWallets dt=${t1 - t0}ms (recovered from backup)',
          );
          return wallets;
        }
      } catch (e) {
        debugPrint('storage: backup recovery failed: $e');
      }
    }

    // ── 3) Tenta legacy migration da v1/v2 ──
    try {
      return await _migrateFromLegacy(key);
    } catch (e) {
      debugPrint('storage: migration failed: $e');
      return <WalletRecord>[];
    }
  }

  /// Carica wallet da un indice cifrato (già decifrato).
  Future<List<WalletRecord>> _loadFromIndex(
    Uint8List key,
    String indexEncrypted,
  ) async {
    final indexJson = await _decrypt(indexEncrypted, key);
    final ids = (jsonDecode(indexJson) as List<dynamic>).cast<String>();
    final wallets = <WalletRecord>[];
    for (final id in ids) {
      // Prova prima localStorage, poi IndexedDB
      var wrEncrypted = _storage['$_walletPrefix$id'];
      if (wrEncrypted == null || wrEncrypted.isEmpty) {
        wrEncrypted = await _backup.load('$_walletPrefix$id');
      }
      if (wrEncrypted != null && wrEncrypted.isNotEmpty) {
        try {
          final wrJson = await _decrypt(wrEncrypted, key);
          wallets.add(
            WalletRecord.fromMap(jsonDecode(wrJson) as Map<String, dynamic>),
          );
        } catch (e) {
          debugPrint('storage: failed to decrypt wallet $id, skipping: $e');
        }
      }
    }
    return wallets;
  }

  /// Ripristina localStorage dal backup IndexedDB.
  Future<void> _restoreLocalStorage(
    List<WalletRecord> wallets,
    Uint8List key,
  ) async {
    try {
      final backIndex = await _backup.load(_indexKey);
      if (backIndex != null) {
        _storage[_indexKey] = backIndex;
      }
      for (final w in wallets) {
        final backValue = await _backup.load('$_walletPrefix${w.walletId}');
        if (backValue != null) {
          _storage['$_walletPrefix${w.walletId}'] = backValue;
        }
      }
      debugPrint('storage: localStorage restored from IndexedDB backup');
    } catch (e) {
      debugPrint('storage: localStorage restore partially failed: $e');
    }
  }

  Future<List<WalletRecord>> _migrateFromLegacy(Uint8List key) async {
    // Prova v2 index non cifrato
    final indexRaw = _storage['wallet_index_v2'];
    if (indexRaw != null && indexRaw.isNotEmpty) {
      final ids = (jsonDecode(indexRaw) as List<dynamic>).cast<String>();
      final wallets = <WalletRecord>[];
      for (final id in ids) {
        final wr = _storage['wallet_record_v2_$id'];
        if (wr != null && wr.isNotEmpty) {
          wallets.add(
            WalletRecord.fromMap(jsonDecode(wr) as Map<String, dynamic>),
          );
        }
      }
      // Re-salva in formato cifrato
      if (wallets.isNotEmpty) {
        await _saveAllEncrypted(wallets, key);
      }
      debugPrint('storage: migrated ${wallets.length} wallets from v2');
      return wallets;
    }

    // Prova v1
    final oldRaw = _storage['wallet_records_v1'];
    if (oldRaw != null && oldRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(oldRaw) as List<dynamic>;
        final wallets = decoded
            .map((item) => WalletRecord.fromMap(item as Map<String, dynamic>))
            .toList();

        if (wallets.isNotEmpty) {
          await _saveAllEncrypted(wallets, key);
        }
        _storage.remove('wallet_records_v1');
        debugPrint('storage: migrated ${wallets.length} wallets from v1');
        return wallets;
      } catch (e) {
        debugPrint('storage: v1 migration error: $e');
      }
    }

    return <WalletRecord>[];
  }

  Future<void> _saveAllEncrypted(
    List<WalletRecord> wallets,
    Uint8List key,
  ) async {
    final ids = <String>[];
    for (final w in wallets) {
      final wrEncrypted = await _encrypt(jsonEncode(w.toMap()), key);
      _storage['$_walletPrefix${w.walletId}'] = wrEncrypted;
      // Backup IndexedDB — ora await con verifica
      final ok = await _backup.backup(
        '$_walletPrefix${w.walletId}',
        wrEncrypted,
      );
      if (!ok) {
        debugPrint(
          'idx_backup: _saveAllEncrypted backup FAILED for ${w.walletId}',
        );
      }
      ids.add(w.walletId);
    }
    final indexEncrypted = await _encrypt(jsonEncode(ids), key);
    _storage[_indexKey] = indexEncrypted;
    // Backup IndexedDB
    final ok = await _backup.backup(_indexKey, indexEncrypted);
    if (!ok) {
      debugPrint('idx_backup: _saveAllEncrypted index backup FAILED');
    }
    _cachedIndex = ids;
  }

  Future<void> upsertWallet(WalletRecord wallet) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final key = _getOrCreateEncryptionKey();

    final wrEncrypted = await _encrypt(jsonEncode(wallet.toMap()), key);
    _storage['$_walletPrefix${wallet.walletId}'] = wrEncrypted;
    // Backup IndexedDB — ora await con verifica
    // Non blocchiamo l'operazione principale: il backup è asincrono
    // ma logghiamo il risultato
    _backup.backup('$_walletPrefix${wallet.walletId}', wrEncrypted).then((ok) {
      if (!ok) {
        debugPrint(
          'idx_backup: upsert backup FAILED for ${wallet.walletId}',
        );
      }
    });

    // Aggiorna indice
    final ids = _cachedIndex ??
        (() {
          final indexEncrypted = _storage[_indexKey];
          if (indexEncrypted != null && indexEncrypted.isNotEmpty) {
            return <String>[];
          }
          return <String>[];
        })();

    // Ricarica indice esistente da storage
    List<String> currentIds;
    try {
      final indexEncrypted = _storage[_indexKey];
      if (indexEncrypted != null && indexEncrypted.isNotEmpty) {
        final indexJson = await _decrypt(indexEncrypted, key);
        currentIds = (jsonDecode(indexJson) as List<dynamic>).cast<String>();
      } else {
        currentIds = <String>[];
      }
    } catch (_) {
      currentIds = ids;
    }

    if (!currentIds.contains(wallet.walletId)) {
      currentIds.add(wallet.walletId);
      final indexEncrypted = await _encrypt(jsonEncode(currentIds), key);
      _storage[_indexKey] = indexEncrypted;
      // Backup IndexedDB
      _backup.backup(_indexKey, indexEncrypted).then((ok) {
        if (!ok) {
          debugPrint('idx_backup: upsert index backup FAILED');
        }
      });
      _cachedIndex = currentIds;
    } else {
      _cachedIndex = currentIds;
    }

    final t1 = DateTime.now().millisecondsSinceEpoch;
    debugPrint('storage: upsertWallet ${wallet.walletId} dt=${t1 - t0}ms');
  }

  Future<void> deleteWallet(String walletId) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final key = _getOrCreateEncryptionKey();

    _storage.remove('$_walletPrefix$walletId');
    // Rimuovi anche dal backup IndexedDB
    _backup.remove('$_walletPrefix$walletId').then(
          (_) {},
          onError: (Object e) => debugPrint('idx_backup: remove failed: $e'),
        );

    List<String> currentIds;
    try {
      final indexEncrypted = _storage[_indexKey];
      if (indexEncrypted != null && indexEncrypted.isNotEmpty) {
        final indexJson = await _decrypt(indexEncrypted, key);
        currentIds = (jsonDecode(indexJson) as List<dynamic>).cast<String>();
      } else {
        currentIds = <String>[];
      }
    } catch (_) {
      currentIds = <String>[];
    }

    if (currentIds.remove(walletId)) {
      final indexEncrypted = await _encrypt(jsonEncode(currentIds), key);
      _storage[_indexKey] = indexEncrypted;
      // Aggiorna anche backup IndexedDB
      _backup.backup(_indexKey, indexEncrypted).then((ok) {
        if (!ok) {
          debugPrint('idx_backup: delete index backup FAILED');
        }
      });
      _cachedIndex = currentIds;
    }

    final t1 = DateTime.now().millisecondsSinceEpoch;
    debugPrint('storage: deleteWallet $walletId dt=${t1 - t0}ms');
  }

  // Non più usato ma mantenuto per compatibilità interfaccia
  Future<void> saveWallets(List<WalletRecord> wallets) async {
    for (final wallet in wallets) {
      await upsertWallet(wallet);
    }
  }
}
