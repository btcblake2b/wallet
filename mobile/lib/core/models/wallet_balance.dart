/// Modelli dati dell'API Esplora-compatibile della rete bitcoin-blake2b
/// (mempool.guide, unica fonte per le letture on-chain dal 2026-09-08).
/// Valori in SATOSHI (interi): per la UI convertire dividendo per 1e8.
/// Stile: pattern canonico del progetto — classi manuali, const constructor,
/// final fields, fallback sicuri. Niente Freezed/JsonSerializable.
library;

import 'dart:convert';

import '../config/bitcoin_network_config.dart';

/// Saldo di un indirizzo: catena confermata + mempool, in satoshi.
class WalletBalance {
  const WalletBalance({required this.balanceSats, required this.txCount});

  /// Saldo spendibile in satoshi (funded − spent, catena + mempool).
  final int balanceSats;

  /// Numero totale di transazioni (catena + mempool).
  final int txCount;

  WalletBalance copyWith({int? balanceSats, int? txCount}) {
    return WalletBalance(
      balanceSats: balanceSats ?? this.balanceSats,
      txCount: txCount ?? this.txCount,
    );
  }

  /// Calcola il saldo dal formato Esplora-compatibile del servizio.
  ///
  /// PERCHÉ: `funded_txo_sum`/`spent_txo_sum`/`tx_count` possono mancare o
  /// essere di tipo non-int nel JSON → `_asInt` con fallback a 0 (fail-safe).
  factory WalletBalance.fromChainStats({
    required Map<String, dynamic> chainStats,
    required Map<String, dynamic> mempoolStats,
  }) {
    final funded = _asInt(chainStats['funded_txo_sum']) +
        _asInt(mempoolStats['funded_txo_sum']);
    final spent = _asInt(chainStats['spent_txo_sum']) +
        _asInt(mempoolStats['spent_txo_sum']);
    final txCount =
        _asInt(chainStats['tx_count']) + _asInt(mempoolStats['tx_count']);
    return WalletBalance(balanceSats: funded - spent, txCount: txCount);
  }

  /// Formatta satoshi → ticker della rete corrente con 8 decimali
  /// (es. `0.99999856 BTC` su mainnet, `0.99999856 tBTC` su testnet).
  /// PERCHÉ: il ticker deriva da BitcoinNetworkConfig — non hardcodare tBTC.
  static String formatTbtc(int sats) =>
      '${(sats / 100000000).toStringAsFixed(8)} ${BitcoinNetworkConfig.ticker}';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'balance_sats': balanceSats,
      'tx_count': txCount,
    };
  }

  factory WalletBalance.fromMap(Map<String, dynamic> map) {
    return WalletBalance(
      balanceSats: map['balance_sats'] as int? ?? 0,
      txCount: map['tx_count'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WalletBalance.fromJson(String source) {
    return WalletBalance.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  /// Converte un valore JSON in int con fallback a 0.
  /// PERCHÉ: usa `is num` invece di `as num?` — un cast su un valore di tipo
  /// inatteso (es. String) lancerebbe TypeError; `is` torna 0 (fail-safe).
  static int _asInt(Object? value) => value is num ? value.toInt() : 0;
}

/// Stato di una transazione dal servizio
/// (`status.confirmed` / `status.block_height` / `status.block_hash`).
class TxStatus {
  const TxStatus({required this.confirmed, this.blockHeight, this.blockHash});

  final bool confirmed;
  final int? blockHeight;
  final String? blockHash;

  TxStatus copyWith({
    bool? confirmed,
    int? blockHeight,
    String? blockHash,
    bool clearBlockHeight = false,
    bool clearBlockHash = false,
  }) {
    return TxStatus(
      confirmed: confirmed ?? this.confirmed,
      blockHeight: clearBlockHeight ? null : (blockHeight ?? this.blockHeight),
      blockHash: clearBlockHash ? null : (blockHash ?? this.blockHash),
    );
  }

  /// PERCHÉ: `status` può mancare (tx non trovata / non ancora confermata)
  /// → fallback sicuro `confirmed=false`, blocchi null.
  factory TxStatus.fromMap(Map<String, dynamic> map) {
    final status = map['status'] as Map<String, dynamic>? ?? const {};
    return TxStatus(
      confirmed: status['confirmed'] as bool? ?? false,
      blockHeight: (status['block_height'] as num?)?.toInt(),
      blockHash: status['block_hash'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    // PERCHÉ: simmetria con fromMap — i campi vivono sotto la chiave `status`
    // (formato API), così toMap/fromMap fanno round-trip corretto.
    return <String, dynamic>{
      'status': <String, dynamic>{
        'confirmed': confirmed,
        'block_height': blockHeight,
        'block_hash': blockHash,
      },
    };
  }

  String toJson() => jsonEncode(toMap());

  factory TxStatus.fromJson(String source) {
    return TxStatus.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
