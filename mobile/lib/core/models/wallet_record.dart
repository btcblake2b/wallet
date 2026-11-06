import 'dart:convert';

/// Tipo di wallet.
/// PERCHÉ: un wallet watch-only contiene SOLO la chiave pubblica estesa
/// (xpub): può monitorare saldo/storico ma non firmare. Il flag distingue i
/// percorsi che richiedono il seed (decrypt, invio, backup) da quelli di
/// sola lettura. Default `hot` = comportamento attuale, zero breaking.
enum WalletKind {
  hot,
  watchOnly;

  String get value => name;

  static WalletKind fromValue(String value) {
    return WalletKind.values.firstWhere(
      (k) => k.name == value,
      orElse: () => WalletKind.hot,
    );
  }
}

/// Il record è in formato con indici persistiti, ma i valori non sono leggibili.
///
/// // PERCHÉ (ADR 30/10-5): fail closed. Un indice corrotto reso come 0 porta a
/// // `/0/0`, cioè a `publicAddress` già usato: sarebbe address reuse, non un
/// // recupero gentile. Chi legge deve chiedere una scelta esplicita all'utente
/// // (ripartire da 0 con conferma, importare un backup, annullare).
class CorruptWalletIndicesException implements Exception {
  const CorruptWalletIndicesException([this.walletId]);

  final String? walletId;

  @override
  String toString() =>
      'CorruptWalletIndicesException(${walletId ?? 'wallet sconosciuto'})';
}

/// Stato degli indici persistiti di un wallet: un solo campo, tre stati reali.
///
/// // PERCHÉ (ADR 30/10-6): con `schemaVersion` + un flag booleano era
/// // rappresentabile uno stato illegale (schema 1 + corrotto). L'enum lo rende
/// // impossibile e `schemaVersion` diventa derivabile invece che memorizzato.
/// // Mappatura: nessun indice mai scritto → [legacyUninitialized] (derivare da
/// // /0/0 è sicuro: nulla è mai stato mostrato); indici leggibili → [valid];
/// // indici scritti ma illeggibili → [corrupt] (fail closed).
enum IndicesState {
  legacyUninitialized,
  valid,
  corrupt,
  anomalous;

  String get value => name;

  /// Null se il valore persistito non è uno stato noto (campo assente o record
  /// scritto da una build futura): chi chiama decide il fallback.
  static IndicesState? fromValue(Object? raw) {
    if (raw is! String) return null;
    for (final state in IndicesState.values) {
      if (state.name == raw) return state;
    }
    return null;
  }
}

/// Il record contiene un indice leggibile ma fuori scala (oltre
/// `maxDerivationIndex`): plausibile, non economico, e in pratica sintomo di
/// manomissione o bug.
///
/// // PERCHÉ (ADR 30/10-8): fail-closed come per il corrotto, ma con un
/// // messaggio diverso — «indice anomalo, verifica il backup» è un'informazione
/// // utile, «stato indici non disponibile» no. Nessuna conferma per-operazione
/// // (UX rotta) e nessun terzo indice persistito.
class AnomalousWalletIndexException implements Exception {
  const AnomalousWalletIndexException(this.walletId, this.index);

  final String? walletId;
  final int index;

  @override
  String toString() =>
      'AnomalousWalletIndexException(${walletId ?? 'wallet sconosciuto'}, $index)';
}

/// Indice proposto fuori dai limiti: nessun record valido può avere questo
/// valore, nemmeno dopo una conferma esplicita dell'utente.
class InvalidWalletIndexException implements Exception {
  const InvalidWalletIndexException(this.message);

  final String message;

  @override
  String toString() => 'InvalidWalletIndexException($message)';
}

/// Il record non è più all'indice atteso: qualcuno lo ha già avanzato (doppio
/// tap, seconda schermata, retry dopo un persist fallito).
///
/// // PERCHÉ (ADR 30/10-7): l'avanzamento è un compare-and-set — senza questo
/// // controllo un doppio tap consumerebbe due indirizzi per un solo gesto.
class IndexConflictException implements Exception {
  const IndexConflictException({required this.expected, required this.actual});

  final int expected;
  final int actual;

  @override
  String toString() =>
      'IndexConflictException(atteso: $expected, trovato: $actual)';
}

class WalletRecord {
  /// Versione dello schema scritta dalla build corrente (vedi [schemaVersion]).
  static const int currentSchemaVersion = 2;

  /// Versione dei record scritti prima degli indici persistiti.
  static const int legacySchemaVersion = 1;

  /// Tetto di **plausibilità** di un indice persistito.
  ///
  /// // PERCHÉ: un valore assurdo (overflow, record manomesso) farebbe derivare
  /// // centinaia di migliaia di chiavi al primo scan. Oltre questa soglia il
  /// // dato è trattato come corrotto (fail closed), non «clampato».
  static const int maxSaneIndex = 1000000;

  /// Tetto di **costo**: oltre questo indice il valore è plausibile ma derivare
  /// è caro, quindi serve una conferma esplicita del chiamante.
  ///
  /// // PERCHÉ (ADR 30/10-6): «valido» e «usabile» non sono la stessa cosa —
  /// // [maxSaneIndex] protegge dalla manomissione, questo dal costo.
  static const int maxDerivationIndex = 10000;

  const WalletRecord({
    required this.walletId,
    required this.encryptedSeed,
    required this.publicAddress,
    required this.deviceId,
    required this.createdAt,
    this.name,
    this.displayInHomeScreen = true,
    this.masterFingerprint,
    this.derivationPath,
    this.kind = WalletKind.hot,
    this.accountXpub,
    this.seedBackupConfirmed = false,
    this.utxoLabels = const {},
    this.txNotes = const {},
    this.indicesState = IndicesState.valid,
    int nextReceiveIndex = 0,
    int nextChangeIndex = 0,
  })  : assert(
          nextReceiveIndex >= 0 && nextReceiveIndex <= maxSaneIndex,
          'indice di ricezione fuori dai limiti',
        ),
        assert(
          nextChangeIndex >= 0 && nextChangeIndex <= maxSaneIndex,
          'indice di resto fuori dai limiti',
        ),
        _nextReceiveIndex = nextReceiveIndex,
        _nextChangeIndex = nextChangeIndex;

  final String walletId;
  final String encryptedSeed;
  final String publicAddress;
  final String deviceId;
  final DateTime createdAt;
  final String? name;
  final bool displayInHomeScreen;
  final String? masterFingerprint;
  final String? derivationPath;

  /// Tipo di wallet: [WalletKind.hot] (seed, può firmare) o
  /// [WalletKind.watchOnly] (solo xpub, sola lettura).
  final WalletKind kind;

  /// Chiave pubblica estesa di account (es. `xpub…`, BIP44/49/84).
  ///
  /// // PERCHÉ (26/10): per i wallet HOT questo campo è la chiave che rende
  /// // «leggere senza chiavi private». Saldata alla creazione/import (o
  /// // ricavata una volta dal seed per i wallet più vecchi), permette di
  /// // derivare indirizzi, saldo e storico senza decifrare la seed: le chiavi
  /// // servono solo per firmare, mostrare la seed e fare il backup.
  /// Mai una chiave privata (deriva sempre da `neutered()`).
  final String? accountXpub;

  /// True se il wallet può essere letto senza seed (xpub disponibile).
  ///
  /// // PERCHÉ: una sola condizione condivisa da Home, Detail, Indirizzi e
  /// // Ricevi — se ognuna controllasse `null`/stringa vuota per conto suo, un
  /// // wallet con xpub vuoto ricadrebbe nel percorso "decifra la seed" in
  /// // alcuni punti e non in altri.
  bool get hasAccountXpub =>
      accountXpub != null && accountXpub!.trim().isNotEmpty;

  /// Whether the user has confirmed they've saved the seed phrase
  /// (e.g. written it down or stored it securely).
  final bool seedBackupConfirmed;

  /// User-defined labels for spendable outputs, keyed by `txid:vout`.
  /// Stored with the wallet so labels survive refreshes and app restarts.
  final Map<String, String> utxoLabels;

  /// Note libere dell'utente per singola transazione, chiave = `txid`.
  ///
  /// // PERCHÉ: stesso pattern di [utxoLabels] — la nota vive nel record del
  /// wallet, quindi sopravvive a refresh e riavvii senza storage aggiuntivo e
  /// senza backend. Non è materiale sensibile: è un'annotazione dell'utente.
  final Map<String, String> txNotes;

  /// Stato degli indici di derivazione persistiti (single source of truth).
  final IndicesState indicesState;

  /// Prossimo indice di ricezione (`/0/N`).
  ///
  /// // PERCHÉ privato: i consumatori devono passare da
  /// // [requireNextReceiveIndex] — leggere il valore grezzo su un record
  /// // corrotto darebbe 0, cioè `/0/0` già usato. Con il campo privato è il
  /// // compilatore a impedirlo, non un test di lint.
  final int _nextReceiveIndex;

  /// Floor del prossimo indice di resto (`/1/N`). Privato per lo stesso motivo.
  final int _nextChangeIndex;

  /// Versione di schema **derivata** dallo stato: niente secondo campo da tenere
  /// allineato (era la fonte dello stato illegale).
  int get schemaVersion => indicesState == IndicesState.legacyUninitialized
      ? legacySchemaVersion
      : currentSchemaVersion;

  /// True se una build precedente ha già scritto indici per questo wallet.
  bool get hasPersistedIndices =>
      indicesState != IndicesState.legacyUninitialized;

  /// Vero se gli indici sono leggibili ma fuori scala (oltre
  /// [maxDerivationIndex]): fail-closed con messaggio dedicato.
  bool get isAnomalous => indicesState == IndicesState.anomalous;

  /// Indice di ricezione **utilizzabile**, o eccezione se il dato non lo è.
  int requireNextReceiveIndex() => _requireUsable(_nextReceiveIndex);

  /// Floor del resto **utilizzabile**, o eccezione se il dato non lo è.
  ///
  /// // PERCHÉ fail-closed su ENTRAMBI: il record è un'unità — se uno dei due
  /// // indici non è affidabile, l'altro non basta a garantire che non si riusi
  /// // un indirizzo (ricezione e resto condividono lo stesso account).
  int requireNextChangeIndex() => _requireUsable(_nextChangeIndex);

  int _requireUsable(int value) {
    switch (indicesState) {
      case IndicesState.corrupt:
        throw CorruptWalletIndicesException(walletId);
      case IndicesState.anomalous:
        throw AnomalousWalletIndexException(walletId, value);
      case IndicesState.legacyUninitialized:
      case IndicesState.valid:
        return value;
    }
  }

  /// Unico percorso pubblico verso [IndicesState.valid]: da corrotto (conferma
  /// dell'utente dopo un guasto) e da legacy (prima scrittura degli indici).
  ///
  /// // PERCHÉ (ADR 30/10-9): da [IndicesState.anomalous] il reset è **rifiutato**.
  /// // L'indice anomalo è noto (es. 15.000 incassi reali): ripartire da 0 non è
  /// // recupero, è reuse informato. Le uscite da `anomalous` sono altre: restore
  /// // da backup o intervento manuale documentato.
  WalletRecord confirmResetIndices({
    required int newReceive,
    required int newChange,
  }) {
    if (indicesState == IndicesState.anomalous) {
      throw AnomalousWalletIndexException(walletId, _nextReceiveIndex);
    }
    if (indicesState == IndicesState.valid) {
      throw const InvalidWalletIndexException(
        'reset non necessario: stato valid',
      );
    }
    if (newReceive < 0 || newReceive > maxDerivationIndex) {
      throw InvalidWalletIndexException('ricezione: $newReceive');
    }
    if (newChange < 0 || newChange > maxDerivationIndex) {
      throw InvalidWalletIndexException('resto: $newChange');
    }
    return WalletRecord(
      walletId: walletId,
      encryptedSeed: encryptedSeed,
      publicAddress: publicAddress,
      deviceId: deviceId,
      createdAt: createdAt,
      name: name,
      displayInHomeScreen: displayInHomeScreen,
      masterFingerprint: masterFingerprint,
      derivationPath: derivationPath,
      kind: kind,
      accountXpub: accountXpub,
      seedBackupConfirmed: seedBackupConfirmed,
      utxoLabels: utxoLabels,
      txNotes: txNotes,
      indicesState: IndicesState.valid,
      nextReceiveIndex: newReceive,
      nextChangeIndex: newChange,
    );
  }

  /// Avanza l'indice di ricezione con semantica compare-and-set.
  ///
  /// // PERCHÉ (ADR 30/10-7): write-ahead — il chiamante persiste `N+1` prima
  /// // di derivare e mostrare `/0/N`. Se tra lettura e scrittura qualcun altro
  /// // ha avanzato il record, [expected] non coincide e si propaga
  /// // [IndexConflictException]: mai due indirizzi consumati per un gesto.
  WalletRecord advanceReceiveIndex({required int expected}) {
    if (indicesState != IndicesState.valid) {
      throw InvalidWalletIndexException(
        'avanzamento richiede stato valid, attuale: ${indicesState.name}',
      );
    }
    final current = requireNextReceiveIndex();
    if (current != expected) {
      throw IndexConflictException(expected: expected, actual: current);
    }
    if (current >= maxDerivationIndex) {
      throw InvalidWalletIndexException('ricezione: $current');
    }
    return copyWith(nextReceiveIndex: current + 1);
  }

  /// Avanza il floor del resto, con la stessa semantica compare-and-set.
  ///
  /// // PERCHÉ (ADR 30/10-8 §2): write-ahead prima del broadcast. Se il
  /// // broadcast fallisce il floor resta avanzato e l'indirizzo non è usato:
  /// // un drift sicuro, voluto, non un bug (un riuso sarebbe peggio). Il floor
  /// // si applica sempre — anche con la feature flag spenta — perché non è
  /// // rotazione ma un invariante.
  WalletRecord advanceChangeIndex({required int expected}) {
    if (indicesState != IndicesState.valid) {
      throw InvalidWalletIndexException(
        'avanzamento richiede stato valid, attuale: ${indicesState.name}',
      );
    }
    final current = requireNextChangeIndex();
    if (current != expected) {
      throw IndexConflictException(expected: expected, actual: current);
    }
    if (current >= maxDerivationIndex) {
      throw InvalidWalletIndexException('resto: $current');
    }
    return copyWith(nextChangeIndex: current + 1);
  }

  /// Nota dell'utente per [txid], oppure `null` se assente o vuota.
  /// // PERCHÉ: una nota di soli spazi equivale a nessuna nota, così la UI non
  /// deve ripetere il controllo in ogni punto di lettura.
  String? noteFor(String txid) {
    final note = txNotes[txid];
    if (note == null) return null;
    final trimmed = note.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  WalletRecord copyWith({
    String? walletId,
    String? encryptedSeed,
    String? publicAddress,
    String? deviceId,
    DateTime? createdAt,
    String? name,
    bool? displayInHomeScreen,
    String? masterFingerprint,
    String? derivationPath,
    WalletKind? kind,
    String? accountXpub,
    bool clearAccountXpub = false,
    bool? seedBackupConfirmed,
    Map<String, String>? utxoLabels,
    Map<String, String>? txNotes,
    int? nextReceiveIndex,
    int? nextChangeIndex,
  }) {
    return WalletRecord(
      walletId: walletId ?? this.walletId,
      encryptedSeed: encryptedSeed ?? this.encryptedSeed,
      publicAddress: publicAddress ?? this.publicAddress,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      displayInHomeScreen: displayInHomeScreen ?? this.displayInHomeScreen,
      masterFingerprint: masterFingerprint ?? this.masterFingerprint,
      derivationPath: derivationPath ?? this.derivationPath,
      kind: kind ?? this.kind,
      accountXpub: clearAccountXpub ? null : (accountXpub ?? this.accountXpub),
      seedBackupConfirmed: seedBackupConfirmed ?? this.seedBackupConfirmed,
      utxoLabels: utxoLabels ?? this.utxoLabels,
      txNotes: txNotes ?? this.txNotes,
      // PERCHÉ: lo stato NON è un parametro di copyWith — da corrotto a valido
      // si passa solo da [confirmResetIndices]. Così un copyWith distratto non
      // può dichiarare sano un record che non lo è.
      indicesState: indicesState,
      nextReceiveIndex: nextReceiveIndex ?? _nextReceiveIndex,
      nextChangeIndex: nextChangeIndex ?? _nextChangeIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wallet_id': walletId,
      'encrypted_seed': encryptedSeed,
      'public_address': publicAddress,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'display_in_home_screen': displayInHomeScreen,
      'master_fingerprint': masterFingerprint,
      'derivation_path': derivationPath,
      'kind': kind.value,
      'account_xpub': accountXpub,
      'seed_backup_confirmed': seedBackupConfirmed,
      'utxo_labels': utxoLabels,
      'tx_notes': txNotes,
      'schema_version': schemaVersion,
      'next_receive_index': _nextReceiveIndex,
      'next_change_index': _nextChangeIndex,
      'indices_state': indicesState.value,
    };
  }

  factory WalletRecord.fromMap(Map<String, dynamic> map) {
    final persistedVersion = _parseSchemaVersion(map['schema_version']);
    final hasIndexKeys = map.containsKey('next_receive_index') ||
        map.containsKey('next_change_index');
    // null = valore non utilizzabile (assente, negativo, non numerico, oltre
    // la soglia di plausibilità).
    final receive = _parseIndex(map['next_receive_index']);
    final change = _parseIndex(map['next_change_index']);
    final state = _resolveIndicesState(
      rawState: map['indices_state'],
      legacyCorruptFlag: map['indices_corrupt'] == true,
      persistedVersion: persistedVersion,
      hasIndexKeys: hasIndexKeys,
      indicesReadable: receive != null && change != null,
      indicesWithinBudget: receive != null &&
          change != null &&
          receive <= maxDerivationIndex &&
          change <= maxDerivationIndex,
    );

    return WalletRecord(
      walletId: map['wallet_id'] as String? ?? '',
      encryptedSeed: map['encrypted_seed'] as String? ?? '',
      publicAddress: map['public_address'] as String? ?? '',
      // PERCHÉ: il campo legacy `state` (locked/unlocked) è stato rimosso —
      // i record salvati dalle versioni precedenti vengono migrati ignorandolo.
      deviceId: map['device_id'] as String? ?? '',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now().toUtc(),
      name: map['name'] as String?,
      displayInHomeScreen: map['display_in_home_screen'] as bool? ?? true,
      masterFingerprint: map['master_fingerprint'] as String?,
      derivationPath: map['derivation_path'] as String?,
      kind: WalletKind.fromValue(map['kind'] as String? ?? ''),
      accountXpub: map['account_xpub'] as String?,
      seedBackupConfirmed: map['seed_backup_confirmed'] as bool? ?? false,
      utxoLabels: _parseStringMap(map['utxo_labels']),
      // PERCHÉ: i record scritti dalle versioni precedenti non hanno
      // `tx_notes` → mappa vuota, nessuna migrazione e nessun crash.
      txNotes: _parseStringMap(map['tx_notes']),
      indicesState: state,
      nextReceiveIndex: receive ?? 0,
      nextChangeIndex: change ?? 0,
    );
  }

  /// Risolve lo stato dagli indizi persistiti, senza mai produrre uno stato
  /// illegale: `legacy` + `corrupt` non esiste (se non è mai stato scritto
  /// nulla, non c'è nulla da corrompere).
  ///
  /// // PERCHÉ (ADR 30/10-6): uno stato esplicito incoerente con i dati
  /// // (`valid` senza indici leggibili) degrada a [IndicesState.corrupt] —
  /// // fail closed, non «fidati dell'etichetta».
  static IndicesState _resolveIndicesState({
    required Object? rawState,
    required bool legacyCorruptFlag,
    required int persistedVersion,
    required bool hasIndexKeys,
    required bool indicesReadable,
    required bool indicesWithinBudget,
  }) {
    // Il valore vince sull'etichetta: leggibile entro budget = valido,
    // leggibile ma fuori scala = anomalo, non leggibile = corrotto.
    final derived = !indicesReadable
        ? IndicesState.corrupt
        : (indicesWithinBudget ? IndicesState.valid : IndicesState.anomalous);

    final explicit = IndicesState.fromValue(rawState);
    if (explicit == IndicesState.legacyUninitialized) {
      // Etichetta legacy con indici scritti: non si crede all'etichetta.
      return hasIndexKeys ? derived : IndicesState.legacyUninitialized;
    }
    if (explicit == IndicesState.corrupt) return IndicesState.corrupt;
    if (explicit != null) return derived;
    // Record scritti prima di `indices_state` (v2 con il vecchio flag booleano).
    if (legacyCorruptFlag) return IndicesState.corrupt;
    if (persistedVersion >= currentSchemaVersion) return derived;
    // v1 o senza versione: indici presenti e leggibili = record già migrato.
    return hasIndexKeys ? derived : IndicesState.legacyUninitialized;
  }

  /// Legge un indice persistito: `null` se il valore non è utilizzabile.
  ///
  /// // PERCHÉ: `fromMap` non può lanciare (renderebbe illeggibile l'intero
  /// // wallet), ma il chiamante deve sapere che il valore non è affidabile —
  /// // lo stato `corrupt` viaggia nel record, non viene inghiottito.
  static int? _parseIndex(Object? raw) {
    if (raw == null) return null;
    final value = raw is num ? raw.toInt() : int.tryParse('$raw'.trim());
    if (value == null || value < 0 || value > maxSaneIndex) return null;
    return value;
  }

  /// Legge la versione di schema: assente o non valida = 1 (record legacy).
  static int _parseSchemaVersion(Object? raw) {
    final value = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
    if (value == null || value < 1) return 1;
    return value;
  }

  /// Parsa una mappa stringa→stringa persistita (etichette UTXO, note tx).
  /// // PERCHÉ: un valore assente o di tipo inatteso deve degradare a mappa
  /// vuota, mai far fallire il caricamento dell'intero wallet.
  static Map<String, String> _parseStringMap(Object? raw) {
    if (raw is! Map) return <String, String>{};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WalletRecord.fromJson(String source) {
    return WalletRecord.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}
