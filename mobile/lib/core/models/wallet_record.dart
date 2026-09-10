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

class WalletRecord {
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
  });

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

  /// Chiave pubblica estesa di account (es. `xpub…`, BIP44/49/84) — presente
  /// SOLO per [WalletKind.watchOnly]. Mai una chiave privata.
  final String? accountXpub;

  /// Whether the user has confirmed they've saved the seed phrase
  /// (e.g. written it down or stored it securely).
  final bool seedBackupConfirmed;

  /// User-defined labels for spendable outputs, keyed by `txid:vout`.
  /// Stored with the wallet so labels survive refreshes and app restarts.
  final Map<String, String> utxoLabels;

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
      accountXpub:
          clearAccountXpub ? null : (accountXpub ?? this.accountXpub),
      seedBackupConfirmed: seedBackupConfirmed ?? this.seedBackupConfirmed,
      utxoLabels: utxoLabels ?? this.utxoLabels,
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
    };
  }

  factory WalletRecord.fromMap(Map<String, dynamic> map) {
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
      utxoLabels: _parseUtxoLabels(map['utxo_labels']),
    );
  }

  static Map<String, String> _parseUtxoLabels(Object? raw) {
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
