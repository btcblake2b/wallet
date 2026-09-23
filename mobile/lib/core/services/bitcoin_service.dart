import 'dart:async';
import 'dart:convert';
import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/digests/ripemd160.dart';

import '../utils/crypto_utils.dart';
import '../utils/watch_only_derivation.dart';
import '../config/bitcoin_network_config.dart';
import '../models/transaction_record.dart';
import '../models/send_output.dart';
import '../models/utxo_info.dart';
import '../models/wallet_address.dart';
import '../models/wallet_balance.dart';
import '../models/wallet_snapshot.dart';
import 'address_pool.dart';
import 'explorer_api.dart';
import 'explorer_mirrors.dart';
import 'pending_send_registry.dart';
import 'rbf_params_registry.dart';
import 'swap/swap_script.dart';
import 'unified_sighash.dart';

// PERCHÉ: UtxoInfo ora vive in core/models (evita import circolare con
// WalletSnapshot); il ri-export mantiene compatibili i consumer che importano
// bitcoin_service.dart per usare il tipo.
export '../models/utxo_info.dart' show UtxoInfo;

String get _kBaseUrl => BitcoinNetworkConfig.blockstreamApiBaseUrl;

// PERCHÉ: User-Agent condiviso (stessa costante di ExplorerApi): tutte le
// richieste a mempool.guide si identificano come app BtcBlake2bWallet.
const Map<String, String> _kApiHeaders = {'User-Agent': kExplorerUserAgent};

// PERCHÉ: Circuit breaker previene chiamate a cascata quando Blockstream API è down.
// Stati: CLOSED (normale) → OPEN (dopo 3 fallimenti consecutivi) → HALF_OPEN (dopo 30s, testa con 1 richiesta)
class CircuitBreakerOpenException implements Exception {
  final String message;
  CircuitBreakerOpenException(this.message);
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}

enum _CBState { closed, open, halfOpen }

class _CircuitBreaker {
  _CBState _state = _CBState.closed;
  int _failures = 0;
  DateTime? _openedAt;
  static const _maxFailures = 3;
  static const _resetTimeout = Duration(seconds: 30);

  Future<T> call<T>(Future<T> Function() operation) async {
    if (_state == _CBState.open) {
      if (_openedAt != null &&
          DateTime.now().difference(_openedAt!) > _resetTimeout) {
        _state = _CBState.halfOpen;
        debugPrint('[AuditFix] Circuit breaker: half-open, testing...');
      } else {
        throw CircuitBreakerOpenException(
          'Circuit breaker OPEN — API temporaneamente non disponibile',
        );
      }
    }
    try {
      final result = await operation();
      // Success: reset
      _failures = 0;
      _state = _CBState.closed;
      return result;
    } catch (e) {
      _failures++;
      if (_failures >= _maxFailures) {
        _state = _CBState.open;
        _openedAt = DateTime.now();
        debugPrint('[AuditFix] Circuit breaker: OPEN ($_failures failures)');
      }
      rethrow;
    }
  }
}

class FeeEstimates {
  final int lowSatVb;
  final int normalSatVb;
  final int highSatVb;
  FeeEstimates({
    required this.lowSatVb,
    required this.normalSatVb,
    required this.highSatVb,
  });

  /// Tier di ALTA priorità: il massimo tra la stima alta e il pavimento di rete.
  ///
  /// // PERCHÉ (18/09/2026): quando il mercato è al minimo `highSatVb` vale
  /// // quanto gli altri tier (1 sat/vB) e scegliere "Alta" non cambierebbe
  /// // nulla; il pavimento di rete (bitcoin_network_config) garantisce la
  /// // priorità. Se il mercato sale, prevale la stima dell'API.
  int get prioritySatVb {
    final floor = BitcoinNetworkConfig.priorityFeeFloorSatVb;
    return highSatVb > floor ? highSatVb : floor;
  }
}

class BuildTxData {
  final String mnemonic;

  /// // PERCHÉ (P3): lista di destinatari — il caso singolo è una lista di un
  /// // elemento, così la firma UNIFIED (già multi-output) è l'unica via.
  final List<SendOutput> outputs;
  final int feeRateSatVb;
  final List<UtxoInfo> utxos;
  final String derivationPath;
  final bool enableRBF;
  BuildTxData({
    required this.mnemonic,
    required this.outputs,
    required this.feeRateSatVb,
    required this.utxos,
    required this.derivationPath,
    this.enableRBF = true,
  });
}

class SendResult {
  final String txid;
  final int feePaid;
  SendResult({required this.txid, required this.feePaid});
}

class BuildTxSweepData {
  final String mnemonic;
  final String toAddress;
  final int feeRateSatVb;
  final List<UtxoInfo> utxos;
  final String derivationPath;
  final bool enableRBF;
  BuildTxSweepData({
    required this.mnemonic,
    required this.toAddress,
    required this.feeRateSatVb,
    required this.utxos,
    required this.derivationPath,
    this.enableRBF = true,
  });
}

class _InputKey {
  final ECPrivate privateKey;
  final ECPublic publicKey;
  final BitcoinBaseAddress nativeSegwitAddress;

  _InputKey({
    required this.privateKey,
    required this.publicKey,
    required this.nativeSegwitAddress,
  });
}

_InputKey _deriveInputKey(
  bip32.BIP32 root,
  String accountPath,
  UtxoInfo utxo,
) {
  final path = utxo.ownerDerivationPath ?? '$accountPath/0/0';
  final child = root.derivePath(path);
  final privateKey = ECPrivate.fromBytes(child.privateKey!);
  final publicKey = ECPublic.fromBytes(child.publicKey);
  return _InputKey(
    privateKey: privateKey,
    publicKey: publicKey,
    nativeSegwitAddress: publicKey.toSegwitAddress(),
  );
}

/// Indirizzo di change per l'account: stesso tipo (native/nested/legacy) del
/// path.
/// PERCHÉ (BIP49/BIP44): il change deve avere lo stesso tipo dell'account,
/// altrimenti lo scan del wallet non lo riscopre mai (P2SH `3…` o P2PKH `1…`).
BitcoinBaseAddress _changeAddressFor(_InputKey key, String accountPath) {
  final type = WalletScriptType.fromDerivationPath(accountPath);
  if (type.isLegacy) {
    // BIP44: change P2PKH derivato dalla stessa chiave.
    return P2pkhAddress.fromHash160(addrHash: _pubKeyHash160Hex(key.publicKey));
  }
  if (type.isNested) {
    final segwit = key.publicKey.toSegwitAddress().toScriptPubKey();
    return P2shAddress.fromScript(
      script: segwit,
      type: P2shAddressType.p2wpkhInP2sh,
    );
  }
  return key.nativeSegwitAddress;
}

/// HASH160 (sha256→ripemd160) esadecimale di una chiave pubblica compressa.
String _pubKeyHash160Hex(ECPublic publicKey) {
  final sha = crypto.sha256.convert(_hexToBytes(publicKey.toHex())).bytes;
  final ripemd = RIPEMD160Digest();
  final hash = ripemd.process(Uint8List.fromList(sha));
  return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// PERCHÉ (audit MED-3): tipo reale dello script di un UTXO. Quando l'API
/// `/tx/:txid` degrada, `scriptPubKeyType` è null: lo si inferisce dal
/// prefisso dello scriptPubKey on-chain o dall'indirizzo owner. Firmare un
/// UTXO P2SH/P2PKH come fosse native produce firme invalide (NULLFAIL); se
/// il tipo è davvero indeterminabile restituisce null (fail-closed).
String? _resolveScriptType(UtxoInfo u) {
  if (u.scriptPubKeyType != null) return u.scriptPubKeyType;
  final hex = u.scriptPubKeyHex ?? '';
  if (hex.isNotEmpty) {
    if (hex.startsWith('0014')) return 'v0_p2wpkh';
    if (hex.startsWith('a914') && hex.endsWith('87')) return 'p2sh';
    if (hex.startsWith('76a914') && hex.endsWith('88ac')) return 'p2pkh';
  }
  final owner = u.ownerAddress;
  if (owner != null) {
    if (owner.startsWith('bc1')) return 'v0_p2wpkh';
    if (owner.startsWith('3')) return 'p2sh';
    if (owner.startsWith('1')) return 'p2pkh';
  }
  return null;
}

/// PERCHÉ (audit MED-2): primo indice NON usato della catena change `/1/N`.
/// Se tra gli UTXO passati c'è già `/1/3`, il prossimo change va su `/1/4`
/// (niente riuso dell'indirizzo di change).
int _nextChangeIndex(Iterable<UtxoInfo> utxos, String accountPath) {
  final prefix = '$accountPath/1/';
  var next = 0;
  for (final u in utxos) {
    final p = u.ownerDerivationPath;
    if (p == null || !p.startsWith(prefix)) continue;
    final idx = int.tryParse(p.substring(prefix.length));
    if (idx != null && idx >= next) next = idx + 1;
  }
  return next;
}

bool _isSpendableByKey(UtxoInfo utxo, ECPublic publicKey) {
  // PERCHÉ (audit MED-3): tipo reale anche quando l'API /tx è degradata
  // (type null). Prima si assumeva native P2WPKH → per account BIP44/49
  // l'UTXO veniva firmato col tipo sbagliato (NULLFAIL). Se il tipo è
  // davvero ignoto, l'UTXO NON è spendibile (fail-closed).
  final type = _resolveScriptType(utxo);
  if (type == 'v0_p2wpkh') return true;
  if (type == null) return false;

  try {
    final hex = utxo.scriptPubKeyHex ?? '';
    if (type == 'p2pkh') {
      // PERCHÉ (BIP44): script 76a914{20-byte-hash160}88ac — il wallet è
      // spendibile solo se l'hash coincide con la chiave derivata (compressa).
      if (hex.length != 50 ||
          !hex.startsWith('76a914') ||
          !hex.endsWith('88ac')) {
        return false;
      }
      return hex.substring(6, 46) == _pubKeyHash160Hex(publicKey);
    }
    if (type != 'p2sh') return false;

    if (hex.length != 46 || !hex.startsWith('a914') || !hex.endsWith('87')) {
      return false;
    }
    final scriptHashHex = hex.substring(4, 44);
    final pubKeyHash = _pubKeyHash160Hex(publicKey);
    final redeem = <int>[0x00, 0x14, ..._hexToBytes(pubKeyHash)];
    final redeemSha = crypto.sha256.convert(redeem).bytes;
    final ripemd = RIPEMD160Digest();
    final redeemHash = ripemd.process(Uint8List.fromList(redeemSha));
    final redeemHashHex =
        redeemHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return redeemHashHex == scriptHashHex;
  } catch (_) {
    return false;
  }
}

/// Costruisce l'`UtxoWithAddress` bitcoin_base per un UTXO del wallet,
/// scegliendo scriptType/ownerAddr dal tipo di script on-chain.
/// PERCHÉ (BIP44/BIP49): ogni tipo (p2wpkh/p2sh/p2pkh) ha il proprio
/// scriptType e il proprio indirizzo owner — necessari alla firma unificata.
UtxoWithAddress _utxoWithAddressFor(UtxoInfo u, _InputKey key) {
  // PERCHÉ (audit MED-3): tipo risolto (può arrivare da scriptPubKeyHex o
  // ownerAddress quando l'API /tx è degradata e `scriptPubKeyType` è null).
  final type = _resolveScriptType(u);
  BitcoinAddressType scriptType = SegwitAddressType.p2wpkh;
  BitcoinBaseAddress ownerAddr = key.nativeSegwitAddress;
  if (type == 'p2sh') {
    scriptType = P2shAddressType.p2wpkhInP2sh;
    if (u.scriptPubKeyAddress != null) {
      ownerAddr = BitcoinAddress(
        u.scriptPubKeyAddress!,
        network: BitcoinNetworkConfig.bitcoinBaseNetwork,
      ).baseAddress;
    }
  } else if (type == 'p2pkh') {
    scriptType = P2pkhAddressType.p2pkh;
    if (u.scriptPubKeyAddress != null) {
      // PERCHÉ: l'indirizzo `1…` restituito dall'API permette di ricostruire
      // lo scriptPubKey P2PKH esatto committato nel digest unificato.
      ownerAddr = BitcoinAddress(
        u.scriptPubKeyAddress!,
        network: BitcoinNetworkConfig.bitcoinBaseNetwork,
      ).baseAddress;
    } else {
      ownerAddr = P2pkhAddress.fromHash160(
        addrHash: _pubKeyHash160Hex(key.publicKey),
      );
    }
  }
  return UtxoWithAddress(
    utxo: BitcoinUtxo(
      txHash: u.txid,
      value: BigInt.from(u.valueSat),
      vout: u.vout,
      scriptType: scriptType,
    ),
    ownerDetails: UtxoAddressDetails(
      publicKey: key.publicKey.toHex(),
      address: ownerAddr,
    ),
  );
}

/// Stima i vB (vsize) di una transazione: header 10 + Σ input (peso
/// vB-equivalente PER TIPO, witness discount incluso) + 43 vB per output
/// (caso peggiore: P2WSH/P2TR, script di 34 byte).
/// PERCHÉ (audit MED-1): per gli input segwit il peso NON è solo la parte
/// base: va sommata la witness (sig+pub) divisa per 4. Prima si stimava un
/// P2WPKH a 41 vB ma una tx reale 1-in/1-out pesa ~112 vB (non 82): con fee
/// 1 sat/vB la tx finiva sotto il min-relay. Misurato su tx firmate reali:
/// native ≈ 68 vB/input, nested ≈ 91 vB/input, legacy ≈ 148 vB/input.
/// Aggiunti 3 vB fissi per tx con witness (marker/flag/count + margine) per
/// non sotto-stimare mai la fee.
///
/// // PERCHÉ 43 vB/output (18/09/2026): con 31 vB/out il funding di uno swap
/// // (output HTLC P2WSH) risultava stimato 143 vB contro 152 reali → a
/// // 1 sat/vB la fee effettiva scendeva a 0,94 sat/vB, sotto il minimo di
/// // inclusione della chain, e la tx è rimasta ferma per blocchi. Meglio
/// // sovrastimare ~12 vB per output (≈24-36 sat) che rischiare una tx
/// // sotto soglia: la fee EFFETTIVA non deve mai scendere sotto il tier scelto.
int estimateTxVbytes(Iterable<UtxoInfo> utxos, int outputCount) {
  var size = 10;
  var hasSegwit = false;
  for (final u in utxos) {
    switch (_resolveScriptType(u)) {
      case 'p2sh':
        size += 91; // nested segwit: base 64 + witness ~27 (108/4)
        hasSegwit = true;
      case 'p2pkh':
        size += 148; // legacy: scriptSig senza witness discount
      default:
        size += 68; // native P2WPKH: base 41 + witness ~27 (108/4)
        hasSegwit = true;
    }
  }
  if (hasSegwit) size += 3;
  return size + 43 * outputCount;
}

Uint8List _hexToBytes(String hex) {
  final result = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < result.length; i++) {
    result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return result;
}

// Top-level isolate function for sweep (send max)
String _buildAndSignTxSweep(BuildTxSweepData data) {
  final seed = bip39.mnemonicToSeed(data.mnemonic);

  final networkType = BitcoinNetworkConfig.bip32NetworkType;
  final root = bip32.BIP32.fromSeed(seed, networkType);
  final destAddress = BitcoinAddress(
    data.toAddress,
    network: BitcoinNetworkConfig.bitcoinBaseNetwork,
  ).baseAddress;

  final selectedUtxos = <({UtxoInfo utxo, _InputKey key})>[];
  for (final u in data.utxos) {
    final inputKey = _deriveInputKey(root, data.derivationPath, u);
    if (_isSpendableByKey(u, inputKey.publicKey)) {
      selectedUtxos.add((utxo: u, key: inputKey));
    }
  }

  if (selectedUtxos.isEmpty) {
    throw Exception('Nessun UTXO spendibile trovato per sweep.');
  }

  final totalIn = selectedUtxos.fold<int>(0, (p, e) => p + e.utxo.valueSat);
  final txSize = estimateTxVbytes(
    selectedUtxos.map((e) => e.utxo),
    1,
  );
  final fee = txSize * data.feeRateSatVb;
  final amount = totalIn - fee;
  if (amount <= 546) {
    throw Exception('Importo risultante troppo basso dopo fee.');
  }

  final privateKeysByPublicKey = <String, ECPrivate>{};
  final utxoWithAddresses = selectedUtxos.map((entry) {
    privateKeysByPublicKey[entry.key.publicKey.toHex()] = entry.key.privateKey;
    return _utxoWithAddressFor(entry.utxo, entry.key);
  }).toList();

  final outputs = <BitcoinOutput>[
    BitcoinOutput(address: destAddress, value: BigInt.from(amount)),
  ];

  // PERCHÉ: firma con SIGHASH_UNIFIED (0x20) per la replay protection tra le
  // chain blake2b — il builder di bitcoin_base calcola solo BIP-143, quindi la
  // tx è costruita manualmente in unified_sighash.dart (Knots PR #357).
  // FLOW: Invio Transazione Wallet (Sweep)
  // STEP: 1 — costruzione + firma UNIFIED
  return buildAndSignUnifiedTx(
    utxoWithAddresses: utxoWithAddresses,
    outputs: outputs,
    privateKeysByPublicKey: privateKeysByPublicKey,
    fee: BigInt.from(fee),
    enableRBF: data.enableRBF,
  );
}

// ---------- Top-level isolate function ----------
String _buildAndSignTx(BuildTxData data) {
  final seed = bip39.mnemonicToSeed(data.mnemonic);

  // Derive key using same path as crypto_utils.dart
  final networkType = BitcoinNetworkConfig.bip32NetworkType;
  final root = bip32.BIP32.fromSeed(seed, networkType);

  // FLOW: Invio Transazione Wallet
  // STEP: 1 — validazione destinatari (P3: N output, minimo dust per riga)
  // PERCHÉ (P3): il servizio è chiamabile da test e da percorsi futuri → la
  // guardia dust non può vivere solo nella UI.
  if (data.outputs.isEmpty) {
    throw Exception('Nessun destinatario specificato.');
  }
  for (final o in data.outputs) {
    if (o.isDust) {
      throw Exception(
        'Importo sotto il minimo dust (${SendOutput.dustLimitSats} sat) '
        'per ${o.address}.',
      );
    }
  }
  final recipientCount = data.outputs.length;
  final totalOut = data.outputs.fold<int>(0, (sum, o) => sum + o.amountSats);

  // PERCHÉ (audit MED-2): il change va sulla catena INTERNA /1/N (BIP44),
  // mai sull'indirizzo esterno /0/0 (address reuse totale). Si usa il primo
  // indice /1 non ancora presente tra gli UTXO spendibili passati.
  final changeIndex = _nextChangeIndex(data.utxos, data.derivationPath);
  final changeKey = _deriveInputKey(
    root,
    data.derivationPath,
    UtxoInfo(
      txid: '',
      vout: 0,
      valueSat: 0,
      ownerDerivationPath: '${data.derivationPath}/1/$changeIndex',
    ),
  );
  // PERCHÉ (BIP49): il change mantiene il tipo dell'account di origine.
  final changeAddress = _changeAddressFor(changeKey, data.derivationPath);

  // Destination addresses — P3: N output, uno per destinatario.
  final destOutputs = <BitcoinOutput>[
    for (final o in data.outputs)
      BitcoinOutput(
        address: BitcoinAddress(
          o.address,
          network: BitcoinNetworkConfig.bitcoinBaseNetwork,
        ).baseAddress,
        value: BigInt.from(o.amountSats),
      ),
  ];

  // Select UTXOs (greedy: take until enough). Support native P2WPKH and P2SH-P2WPKH.
  final selectedUtxos = <({UtxoInfo utxo, _InputKey key})>[];
  int totalIn = 0;
  const int dustLimit = 546;

  // DEBUG: log all received UTXOs (only in debug mode)
  if (kDebugMode) {
    debugPrint('[DEBUG _buildAndSignTx] received utxos: ${data.utxos.length}');
    debugPrint(
      '[DEBUG _buildAndSignTx] destinatari: $recipientCount, totale: $totalOut sat',
    );
    for (final u in data.utxos) {
      debugPrint(
        '[DEBUG _buildAndSignTx]   UTXO: txid=${u.txid.substring(0, 8)}... vout=${u.vout} value=${u.valueSat} type=${u.scriptPubKeyType} addr=${u.ownerAddress}',
      );
    }
  }

  for (final u in data.utxos) {
    final inputKey = _deriveInputKey(root, data.derivationPath, u);
    if (!_isSpendableByKey(u, inputKey.publicKey)) continue;

    selectedUtxos.add((utxo: u, key: inputKey));
    totalIn += u.valueSat;

    // Estimate assuming N+1 outputs (destinatari + change)
    var outputCount = recipientCount + 1;
    var estimatedSize = estimateTxVbytes(
      selectedUtxos.map((e) => e.utxo),
      outputCount,
    );
    var estimatedFee = estimatedSize * data.feeRateSatVb;
    var estimatedChange = totalIn - totalOut - estimatedFee;

    // If estimated change would be dust, re-estimate without change output
    if (estimatedChange <= dustLimit) {
      outputCount = recipientCount;
      estimatedSize = estimateTxVbytes(
        selectedUtxos.map((e) => e.utxo),
        outputCount,
      );
      estimatedFee = estimatedSize * data.feeRateSatVb;
      estimatedChange = totalIn - totalOut - estimatedFee;
    }

    if (totalIn >= totalOut + estimatedFee && estimatedChange >= 0) {
      break;
    }
  }

  // Final calculation: determine actual output count (prefer N+1 outputs)
  var txSize = estimateTxVbytes(
    selectedUtxos.map((e) => e.utxo),
    recipientCount + 1,
  );
  var fee = txSize * data.feeRateSatVb;
  var change = totalIn - totalOut - fee;

  // If change would be dust or negative (N+1-output fee too high), drop change
  if (change < dustLimit) {
    txSize = estimateTxVbytes(
      selectedUtxos.map((e) => e.utxo),
      recipientCount,
    );
    fee = txSize * data.feeRateSatVb;
    change = totalIn - totalOut - fee;
  }

  // DEBUG: log UTXO selection and fee/change calculation (only in debug mode)
  if (kDebugMode) {
    debugPrint(
      '[DEBUG _buildAndSignTx] selectedUtxos: ${selectedUtxos.length}',
    );
    debugPrint('[DEBUG _buildAndSignTx] totalIn: $totalIn sats');
    debugPrint('[DEBUG _buildAndSignTx] amount: $totalOut sats');
    debugPrint('[DEBUG _buildAndSignTx] feeRate: ${data.feeRateSatVb} sat/vB');
    debugPrint(
      '[DEBUG _buildAndSignTx] txSize: $txSize vB, outputs: ${change > 546 ? recipientCount + 1 : recipientCount}',
    );
    debugPrint('[DEBUG _buildAndSignTx] fee: $fee sats');
    debugPrint('[DEBUG _buildAndSignTx] change: $change sats');
  }

  if (change < 0) {
    if (kDebugMode) {
      debugPrint(
        '[DEBUG _buildAndSignTx] ERROR: Fondi insufficienti (incluse fee)',
      );
    }
    throw Exception('Fondi insufficienti (incluse fee).');
  }

  // Build utxo list for bitcoin_base
  if (selectedUtxos.isEmpty) {
    throw Exception(
      'Nessun UTXO spendibile trovato: nessun UTXO compatibile (P2WPKH o P2SH-P2WPKH o P2PKH).',
    );
  }

  final privateKeysByPublicKey = <String, ECPrivate>{};
  final utxoWithAddresses = selectedUtxos.map((entry) {
    privateKeysByPublicKey[entry.key.publicKey.toHex()] = entry.key.privateKey;
    return _utxoWithAddressFor(entry.utxo, entry.key);
  }).toList();

  // Build outputs: N destinatari + eventuale change
  final outputs = <BitcoinOutput>[...destOutputs];

  // Add change output if above dust (546 sats)
  // PERCHÉ (P3): comportamento IDENTICO al mono-destinatario — se il change non
  // supera dust, il residuo finisce nella fee (niente output polvere).
  final actualFee = change > 546 ? fee : totalIn - totalOut;
  if (change > 546) {
    outputs.add(
      BitcoinOutput(
        address: changeAddress,
        value: BigInt.from(change),
      ),
    );
  }

  // Build tx + firma con SIGHASH_UNIFIED (replay protection chain blake2b).
  // PERCHÉ: il builder di bitcoin_base firma solo con BIP-143; la firma
  // UNIFIED è implementata in unified_sighash.dart (Bitcoin Knots PR #357).
  // FLOW: Invio Transazione Wallet
  // STEP: 2 — costruzione + firma UNIFIED
  return buildAndSignUnifiedTx(
    utxoWithAddresses: utxoWithAddresses,
    outputs: outputs,
    privateKeysByPublicKey: privateKeysByPublicKey,
    fee: BigInt.from(actualFee),
    enableRBF: data.enableRBF,
  );
}

/// Dati per la tx di refund HTLC (P9) — gira nell'isolate di `compute`.
class BuildRefundTxData {
  const BuildRefundTxData({
    required this.mnemonic,
    required this.refundDerivationPath,
    required this.paymentHashHex,
    required this.claimPubkeyHex,
    required this.refundPubkeyHex,
    required this.cltvHeight,
    required this.witnessScriptHex,
    required this.fundingTxid,
    required this.fundingVout,
    required this.fundingAmountSats,
    required this.destinationAddress,
    required this.feeRateSatVb,
  });

  final String mnemonic;
  final String refundDerivationPath;
  final String paymentHashHex;
  final String claimPubkeyHex;
  final String refundPubkeyHex;
  final int cltvHeight;
  final String witnessScriptHex;
  final String fundingTxid;
  final int fundingVout;
  final int fundingAmountSats;
  final String destinationAddress;
  final int feeRateSatVb;
}

// ---------- Top-level isolate function (refund swap P9) ----------
String _buildAndSignRefundTx(BuildRefundTxData data) {
  final seed = bip39.mnemonicToSeed(data.mnemonic);
  final root = bip32.BIP32.fromSeed(
    seed,
    BitcoinNetworkConfig.bip32NetworkType,
  );
  // PERCHÉ: chiave DEDICATA dello swap (m/84'/coin'/2'/0/x) — l'HTLC non
  // tocca mai le chiavi dell'account principale (0').
  final child = root.derivePath(data.refundDerivationPath);
  final refundKey = ECPrivate.fromBytes(child.privateKey!);
  final feeSats = kSwapRefundTxVbytes * data.feeRateSatVb;
  // FLOW: Pagamento LN via swap (P9) — app
  // STEP: 5 — costruzione + firma UNIFIED della tx di refund
  return buildSignedRefundTxHex(
    refundKey: refundKey,
    scriptParams: SwapScriptParams(
      paymentHashHex: data.paymentHashHex,
      claimPubkeyHex: data.claimPubkeyHex,
      refundPubkeyHex: data.refundPubkeyHex,
      cltvHeight: data.cltvHeight,
    ),
    witnessScriptHex: data.witnessScriptHex,
    fundingTxid: data.fundingTxid,
    fundingVout: data.fundingVout,
    fundingAmountSats: data.fundingAmountSats,
    destinationAddress: data.destinationAddress,
    feeSats: feeSats,
  );
}

/// Dati per la derivazione della pubkey di refund swap (P9).
class SwapRefundKeyData {
  const SwapRefundKeyData({
    required this.mnemonic,
    required this.refundDerivationPath,
  });

  final String mnemonic;
  final String refundDerivationPath;
}

// ---------- Top-level isolate function (pubkey refund swap P9) ----------
String _deriveSwapRefundPubkey(SwapRefundKeyData data) {
  final seed = bip39.mnemonicToSeed(data.mnemonic);
  final root = bip32.BIP32.fromSeed(
    seed,
    BitcoinNetworkConfig.bip32NetworkType,
  );
  final child = root.derivePath(data.refundDerivationPath);
  // PERCHÉ: pubkey COMPRESSA (33B) — è il formato richiesto dall'HTLC.
  return ECPublic.fromBytes(child.publicKey).toHex();
}

// ---------- BitcoinService ----------
class BitcoinService {
  // PERCHÉ: Circuit breaker condiviso per tutte le chiamate API Blockstream.
  // Previene chiamate a cascata quando l'API è down.
  final _CircuitBreaker _cb = _CircuitBreaker();

  // PERCHÉ: breaker DEDICATO al broadcast — un broadcast fallito (tx
  // rifiutata / API giù) non deve aprire il breaker delle letture (saldo,
  // storico) e viceversa: stati isolati, stessa soglia 3 fallimenti / 30s.
  final _CircuitBreaker _cbBroadcast = _CircuitBreaker();

  // PERCHÉ (P1.2): client HTTP iniettabile per testare i metodi di rete con
  // MockClient, senza colpire le API Blockstream reali durante la suite.
  final http.Client _client;

  // PERCHÉ (2026-09-16): host corrente delle letture on-chain (sticky). Dopo
  // un failover riuscito resta l'host che ha risposto, così lo scan gap-limit
  // non ripaga il timeout del primario a ogni richiesta.
  String _activeBaseUrl = _kBaseUrl;

  BitcoinService({http.Client? client}) : _client = client ?? http.Client();

  /// GET con failover fra gli host Esplora configurati.
  ///
  /// Ritorna la prima risposta 200; se nessun host risponde 200 ritorna la
  /// risposta dell'host corrente (semantica dei chiamanti invariata: es.
  /// "HTTP 500"); se nessun host risponde affatto rilancia l'errore di
  /// trasporto ricevuto.
  Future<http.Response> _getWithFailover(
    String path, {
    required Duration timeout,
  }) async {
    // FLOW: Lettura on-chain con failover Esplora
    // PERCHÉ: la lista arriva dalla politica di processo — se l'utente ha
    // disattivato i mirror, un eventuale host sticky su mirror non è più
    // permesso e si torna al primario già da questa richiesta.
    final allowed = ExplorerMirrors.instance.readHosts;
    if (!allowed.contains(_activeBaseUrl)) {
      _activeBaseUrl = allowed.first;
    }
    final hosts = <String>[
      _activeBaseUrl,
      ...allowed.where((h) => h != _activeBaseUrl),
    ];
    http.Response? reportedResponse;
    Object? reportedError;

    // STEP: 1 — host in ordine di priorità (sticky per primo).
    for (final host in hosts) {
      final isCurrentHost = host == _activeBaseUrl;
      http.Response response;
      try {
        response = await _client
            .get(Uri.parse('$host/$path'), headers: _kApiHeaders)
            .timeout(timeout);
      } on Exception catch (e) {
        // PERCHÉ: errore di trasporto (timeout/rete) → host successivo.
        reportedError ??= e;
        continue;
      }
      if (response.statusCode == 200) {
        // STEP: 2 — host sticky: le richieste successive restano qui.
        if (!isCurrentHost) {
          debugPrint('[BitcoinService] failover attivo su $host (/$path)');
          _activeBaseUrl = host;
        }
        return response;
      }
      // PERCHÉ: 404 e altri esiti definitivi NON fanno failover — è una
      // risposta valida del servizio (tx sconosciuta, indirizzo senza dati).
      if (!_isFailoverStatusCode(response.statusCode)) return response;
      reportedResponse ??= response; // 429/500/502/503 → host successivo
    }
    if (reportedResponse != null) return reportedResponse;
    throw reportedError ?? Exception('Errore fetch $path');
  }

  /// True se lo status HTTP giustifica il tentativo su un altro host.
  static bool _isFailoverStatusCode(int statusCode) =>
      statusCode == 429 ||
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503;

  String generateMnemonic() => bip39.generateMnemonic();

  Future<String> deriveAddressFromMnemonic(String mnemonic) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final result = await compute(
      deriveBitcoinAddress,
      AddressDerivationData(mnemonic, null, 1),
    );
    final t1 = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint('bitcoin: deriveAddressFromMnemonic dt=${t1 - t0}ms');
    }
    return result;
  }

  Future<WalletDerivationResult> deriveWalletDataFromMnemonic(
    String mnemonic, {
    String? derivationPath,
    int addressCount = 100,
  }) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    final result = await compute(
      deriveWalletData,
      AddressDerivationData(mnemonic, derivationPath, addressCount),
    );
    final t1 = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint(
        'bitcoin: deriveWalletDataFromMnemonic dt=${t1 - t0}ms (addresses=$addressCount)',
      );
    }
    return result;
  }

  /// Deriva (primo) indirizzo e fingerprint da un xpub di account (watch-only).
  ///
  /// PERCHÉ (P1 watch-only): validazione + derivazione in `compute`, come
  /// [deriveWalletDataFromMnemonic] — usato dall'import per popolare
  /// `publicAddress`/`masterFingerprint` del WalletRecord senza seed.
  Future<WatchOnlyDerivationResult> deriveWatchOnlyData({
    required String accountXpub,
    WalletScriptType scriptType = WalletScriptType.p2wpkh,
    int addressCount = 1,
  }) async {
    return compute(
      deriveWatchOnlyAddresses,
      WatchOnlyDerivationData(
        accountXpub: accountXpub,
        scriptType: scriptType,
        addressCount: addressCount,
      ),
    );
  }

  Future<String> signMessage(String mnemonic, String message) async {
    return compute(signBitcoinMessage, MessageSignData(mnemonic, message));
  }

  Future<bool> verifyMessage(
    String address,
    String message,
    String signature,
  ) async {
    return compute(
      verifyBitcoinMessage,
      MessageVerifyData(address, message, signature),
    );
  }

  /// Scansiona ENTRAMBE le catene (external /0/N e change /1/N) con gap-limit
  /// BIP44: si ferma dopo [gapLimit] indirizzi vuoti consecutivi per catena
  /// (cap [maxAddresses]). L'ownerDerivationPath include il ramo (/0 o /1).
  /// Returns a map address -> list of UtxoInfo (solo indirizzi con UTXO).
  ///
  /// // PERCHÉ (P8-b): la derivazione è LAZY a blocchi (gap-limit) — prima si
  /// derivavano 100+100 indirizzi a ogni snapshot, mentre lo scan si ferma
  /// molto prima nel caso tipico.
  Future<Map<String, List<UtxoInfo>>> scanDerivedAddressesForUtxos(
    String mnemonic, {
    String? derivationPath,
    int gapLimit = 20,
    int maxAddresses = 100,
  }) async {
    final pool = _newPool(
      mnemonic: mnemonic,
      derivationPath: derivationPath,
      maxAddresses: maxAddresses,
    );
    return _scanPoolForUtxos(
      pool: pool,
      derivationPath:
          derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath,
      gapLimit: gapLimit,
    );
  }

  /// Costruisce un pool di derivazione: hot dal seed, watch-only dall'xpub.
  AddressPool _newPool({
    String? mnemonic,
    String? accountXpub,
    WalletScriptType scriptType = WalletScriptType.p2wpkh,
    String? derivationPath,
    int maxAddresses = 100,
  }) {
    return AddressPool(
      maxAddresses: maxAddresses,
      requestFor: (start, count) => AddressBlockRequest(
        mnemonic: mnemonic,
        accountXpub: accountXpub,
        scriptType: scriptType,
        derivationPath: derivationPath,
        start: start,
        count: count,
      ),
    );
  }

  /// Scan UTXO con gap-limit su un [pool] di indirizzi derivati a blocchi.
  ///
  /// // PERCHÉ (P8-b): il criterio di gap è IDENTICO a prima (batch da
  /// // [gapLimit], stop al primo gap, cap `pool.maxAddresses`); cambia solo
  /// // QUANDO si deriva — il blocco successivo si chiede al pool solo se il
  /// // gap non è ancora chiuso. Vale sia per hot sia per watch-only.
  Future<Map<String, List<UtxoInfo>>> _scanPoolForUtxos({
    required AddressPool pool,
    required String derivationPath,
    int gapLimit = 20,
  }) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;
    // PERCHÉ (S7): il tip height si fetca UNA volta e si passa a tutti i
    // fetchUtxos paralleli — evita N chiamate duplicate a /blocks/tip/height.
    final tipHeight = await _fetchTipHeight();

    Future<Map<String, List<UtxoInfo>>> scanChain(int chainIndex) async {
      final found = <String, List<UtxoInfo>>{};
      var consecutiveEmpty = 0;
      var start = 0;
      while (consecutiveEmpty < gapLimit && start < pool.maxAddresses) {
        // Deriva il blocco corrente solo se serve davvero.
        await pool.ensure(start + gapLimit);
        final chainAddrs = chainIndex == 0 ? pool.external : pool.change;
        if (start >= chainAddrs.length) break; // cap raggiunto
        final end = (start + gapLimit) > chainAddrs.length
            ? chainAddrs.length
            : start + gapLimit;
        final batch = chainAddrs.sublist(start, end);
        // PERCHÉ (F5): un errore di fetch NON equivale a "indirizzo vuoto" —
        // mascherarlo con [] produrrebbe un saldo parziale o 0 presentato
        // come vero. L'errore si propaga: lo snapshot fallisce e la UI
        // mostra "non disponibile" (mai 0 come confermato).
        final batchResults = await Future.wait(
          batch.map((a) => fetchUtxos(a, tipHeight: tipHeight)),
        );
        var stop = false;
        for (var j = 0; j < batch.length; j++) {
          final idx = start + j;
          final utxos = batchResults[j];
          if (utxos.isEmpty) {
            consecutiveEmpty++;
            if (consecutiveEmpty >= gapLimit) {
              stop = true;
              break;
            }
          } else {
            consecutiveEmpty = 0;
            // PERCHÉ: per un wallet hot il ramo /1 è obbligatorio per firmare
            // UTXO di change (_deriveInputKey usa ownerDerivationPath). Per un
            // watch-only è solo metadato (nessuna firma possibile).
            final ownerPath = '$derivationPath/$chainIndex/$idx';
            found[batch[j]] = utxos
                .map(
                  (u) => u.copyWith(
                    ownerAddress: batch[j],
                    ownerDerivationPath: ownerPath,
                  ),
                )
                .toList();
          }
        }
        if (stop) break;
        start = end;
      }
      return found;
    }

    final chainResults = await Future.wait([scanChain(0), scanChain(1)]);
    final found = <String, List<UtxoInfo>>{};
    for (final chainResult in chainResults) {
      found.addAll(chainResult);
    }

    final t1 = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint(
        'bitcoin: _scanPoolForUtxos dt=${t1 - t0}ms (gap=$gapLimit, '
        'derivati=${pool.derivedCount}, blocchi=${pool.derivationRuns}, '
        'found=${found.length})',
      );
    }
    return found;
  }

  Future<List<UtxoInfo>> fetchSpendableWalletUtxos(
    String mnemonic, {
    String? derivationPath,
    int gapLimit = 20,
    int maxAddresses = 100,
  }) async {
    final found = await scanDerivedAddressesForUtxos(
      mnemonic,
      derivationPath: derivationPath,
      gapLimit: gapLimit,
      maxAddresses: maxAddresses,
    );
    final utxos = found.values.expand((items) => items).toList();
    utxos.sort((a, b) => b.valueSat.compareTo(a.valueSat));
    return utxos;
  }

  /// Elenco degli indirizzi del wallet (ricezione `/0` e resto `/1`) con stato
  /// e saldo per indirizzo — base della schermata "Indirizzi".
  ///
  /// // PERCHÉ (P7): schermata di sola LETTURA. Il criterio di gap è diverso da
  /// quello del saldo: qui conta l'ATTIVITÀ (`tx_count`), non la presenza di
  /// UTXO — un indirizzo usato e poi speso non ha UTXO ma NON è un indirizzo
  /// nuovo, altrimenti verrebbe mostrato come "mai usato" (dato falso).
  /// La logica del saldo resta intatta: nessuna modifica a scan/snapshot.
  ///
  /// Un errore di rete si PROPAGA (mai un saldo 0 spacciato per vero — F5).
  /// Deriva dal seed (hot) oppure dall'xpub (watch-only), come i flussi P1.
  Future<List<WalletAddress>> fetchWalletAddresses({
    String? mnemonic,
    String? accountXpub,
    WalletScriptType scriptType = WalletScriptType.p2wpkh,
    String? derivationPath,
    int gapLimit = 20,
    int maxAddresses = 100,
  }) async {
    final t0 = DateTime.now().millisecondsSinceEpoch;

    // STEP: 1 — pool di derivazione lazy (hot da seed, watch-only da xpub):
    // si deriva un blocco per ramo alla volta, solo finché il gap è aperto.
    final basePath = mnemonic != null
        ? (derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath)
        : scriptType.accountPath();
    final pool = _newPool(
      mnemonic: mnemonic,
      accountXpub: accountXpub,
      scriptType: scriptType,
      derivationPath: derivationPath,
      maxAddresses: maxAddresses,
    );

    // STEP: 2 — stato on-chain per indirizzo, con gap-limit sull'attività.
    // Batch da [gapLimit] in parallelo, come lo scan UTXO (stesso ordine di
    // grandezza di richieste che l'app fa già per il saldo).
    Future<List<WalletAddress>> scanBranch(
      WalletAddressBranch branch,
      int chainIndex,
    ) async {
      final out = <WalletAddress>[];
      var idle = 0;
      var start = 0;
      while (idle < gapLimit && start < pool.maxAddresses) {
        await pool.ensure(start + gapLimit);
        final addresses = chainIndex == 0 ? pool.external : pool.change;
        if (start >= addresses.length) break; // cap raggiunto
        final end = (start + gapLimit) > addresses.length
            ? addresses.length
            : start + gapLimit;
        final batch = addresses.sublist(start, end);
        final infos = await Future.wait(batch.map(fetchAddressInfo));
        var stop = false;
        for (var j = 0; j < batch.length; j++) {
          final balance = (infos[j]['balance'] as num?)?.toInt() ?? 0;
          final txCount = (infos[j]['tx_count'] as num?)?.toInt() ?? 0;
          out.add(
            WalletAddress(
              address: batch[j],
              branch: branch,
              index: start + j,
              derivationPath: '$basePath/$chainIndex/${start + j}',
              balanceSats: balance,
              txCount: txCount,
            ),
          );
          if (txCount == 0 && balance == 0) {
            idle++;
            if (idle >= gapLimit) {
              stop = true;
              break;
            }
          } else {
            idle = 0;
          }
        }
        if (stop) break;
        start = end;
      }
      return out;
    }

    final branches = await Future.wait([
      scanBranch(WalletAddressBranch.external, 0),
      scanBranch(WalletAddressBranch.change, 1),
    ]);

    final t1 = DateTime.now().millisecondsSinceEpoch;
    debugPrint(
      '[LoopEngineer] fetchWalletAddresses dt=${t1 - t0}ms '
      '(ricezione=${branches[0].length}, resto=${branches[1].length})',
    );
    return [...branches[0], ...branches[1]];
  }

  /// Saldo (chain+mempool) e tx_count di un singolo indirizzo.
  ///
  /// PERCHÉ (F5, 2026-09-08): un errore di rete/API NON è un saldo 0 — un
  /// saldo 0 è REALE solo quando l'API risponde 200. Su errore l'eccezione
  /// tipizzata ([ApiException] o [CircuitBreakerOpenException]) si propaga
  /// al chiamante, che decide come mostrare lo stato "non disponibile"
  /// (mai un numero finto presentato come vero).
  Future<Map<String, dynamic>> fetchAddressInfo(String address) async {
    if (address.isEmpty) return {'balance': 0, 'tx_count': 0};
    // PERCHÉ: Circuit breaker — previene chiamate a cascata se API down
    return _cb.call(() async {
      // FLOW: Visualizzazione Saldo Wallet
      // STEP: 1 — saldo da mempool.guide (Esplora-compatibile, unica fonte).
      // PERCHÉ: dal 2026-09-08 le letture on-chain usano SOLO mempool.guide —
      // il backend personale watch-only è stato rimosso dall'app. Una sola
      // richiesta per indirizzo (nessun doppio salto di fallback).
      final explorer = ExplorerApi(client: _client, maxAttempts: 3);
      return explorer.fetchAddressInfo(address);
    });
  }

  /// Saldo totale del wallet: Σ UTXO spendibili su ENTRAMBE le catene
  /// (external + change) con gap-limit — come calcola BlueWallet.
  /// PERCHÉ: fetchAddressInfo guarda solo il primo indirizzo; qui si sommano
  /// TUTTI gli UTXO del wallet (fix saldo home/detail vs BlueWallet).
  Future<WalletBalance> fetchWalletBalance(
    String mnemonic, {
    String? derivationPath,
    int gapLimit = 20,
    int maxAddresses = 100,
  }) async {
    final found = await scanDerivedAddressesForUtxos(
      mnemonic,
      derivationPath: derivationPath,
      gapLimit: gapLimit,
      maxAddresses: maxAddresses,
    );
    var total = 0;
    var txCount = 0;
    for (final utxos in found.values) {
      txCount += utxos.length;
      for (final u in utxos) {
        total += u.valueSat;
      }
    }
    return WalletBalance(balanceSats: total, txCount: txCount);
  }

  /// Snapshot del wallet (saldo + UTXO [+ storico]) — fonte unica per Home e
  /// Detail.
  ///
  /// PERCHÉ: compone lo scan UTXO (saldo autorevole, esclude coinbase orfane)
  /// e, solo se richiesto, lo storico. `includeHistory: false` è usato dalla
  /// Home all'avvio: lo storico (seconda derivazione BIP32 + fetch per
  /// indirizzo) è pesante e farebbe "frizzare" l'UI all'apertura dell'app —
  /// viene caricato lazy al primo ingresso nel Detail. Uno snapshot senza
  /// storico ha `transactions == null` (isComplete false) e il Detail lo
  /// completa in background.
  Future<WalletSnapshot> fetchWalletSnapshot(
    String mnemonic, {
    String? derivationPath,
    int gapLimit = 20,
    int maxAddresses = 100,
    int limit = 25,
    bool includeHistory = true,
  }) async {
    // PERCHÉ (P8-b): UN pool per snapshot — scan UTXO e storico condividono la
    // stessa derivazione (prima erano due derive complete di 100+100 indirizzi).
    final pool = _newPool(
      mnemonic: mnemonic,
      derivationPath: derivationPath,
      maxAddresses: maxAddresses,
    );
    final found = await _scanPoolForUtxos(
      pool: pool,
      derivationPath:
          derivationPath ?? BitcoinNetworkConfig.defaultDerivationPath,
      gapLimit: gapLimit,
    );

    var total = 0;
    var utxoCount = 0;
    for (final utxos in found.values) {
      utxoCount += utxos.length;
      for (final u in utxos) {
        total += u.valueSat;
      }
    }
    final allUtxos = found.values.expand((items) => items).toList()
      ..sort((a, b) => b.valueSat.compareTo(a.valueSat));

    List<TransactionRecord>? transactions;
    if (includeHistory) {
      transactions = await _safeWalletHistory(
        pool,
        gapLimit: gapLimit,
        limit: limit,
      );
    }

    return WalletSnapshot(
      balanceSats: total,
      txCount: transactions?.length ?? utxoCount,
      utxos: allUtxos,
      transactions: transactions,
      fetchedAt: DateTime.now(),
    );
  }

  /// Snapshot di un wallet WATCH-ONLY (xpub, sola lettura): stessa struttura
  /// di [fetchWalletSnapshot] ma gli indirizzi si derivano dalla chiave
  /// pubblica estesa invece che dal seed — nessuna chiave privata coinvolta.
  ///
  /// PERCHÉ (P1 watch-only): riusa la stessa logica di scan/history
  /// (_scanPoolForUtxos / _historyFromPool) → saldo,
  /// UTXO e storico coerenti con i wallet hot. Il [scriptType] serve perché
  /// lo stesso xpub può essere monitorato con encoding diversi (BIP84/49/44).
  // FLOW: Visualizzazione Saldo Wallet (watch-only)
  // STEP: 1 — derivazione indirizzi da xpub
  // STEP: 2 — scan UTXO con gap-limit
  // STEP: 3 — storico opzionale + snapshot
  Future<WalletSnapshot> fetchWatchOnlySnapshot({
    required String accountXpub,
    WalletScriptType scriptType = WalletScriptType.p2wpkh,
    int gapLimit = 20,
    int maxAddresses = 100,
    int limit = 25,
    bool includeHistory = true,
  }) async {
    // STEP: 1 — pool lazy dall'xpub (nessun seed, nessuna chiave privata)
    final pool = _newPool(
      accountXpub: accountXpub,
      scriptType: scriptType,
      derivationPath: scriptType.accountPath(),
      maxAddresses: maxAddresses,
    );

    // STEP: 2 — scan UTXO con gap-limit (stesso helper del percorso hot)
    final found = await _scanPoolForUtxos(
      pool: pool,
      derivationPath: scriptType.accountPath(),
      gapLimit: gapLimit,
    );

    var total = 0;
    var utxoCount = 0;
    for (final utxos in found.values) {
      utxoCount += utxos.length;
      for (final u in utxos) {
        total += u.valueSat;
      }
    }
    final allUtxos = found.values.expand((items) => items).toList()
      ..sort((a, b) => b.valueSat.compareTo(a.valueSat));

    List<TransactionRecord>? transactions;
    if (includeHistory) {
      // STEP: 3 — storico "safe": mai fa fallire lo snapshot
      try {
        transactions = await _historyFromPool(
          pool: pool,
          gapLimit: gapLimit,
          limit: limit,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('fetchWatchOnlySnapshot: storico non disponibile: $e');
        }
        transactions = const [];
      }
    }

    return WalletSnapshot(
      balanceSats: total,
      txCount: transactions?.length ?? utxoCount,
      utxos: allUtxos,
      transactions: transactions,
      fetchedAt: DateTime.now(),
    );
  }

  /// Storico "safe": mai fa fallire lo snapshot (catch interno → lista vuota).
  /// Storico "safe" dal pool condiviso: mai fa fallire lo snapshot.
  ///
  /// // PERCHÉ (P8-b): riceve il pool dello snapshot — la derivazione fatta per
  /// // lo scan UTXO viene riusata (prima lo storico ri-derivava per conto suo).
  Future<List<TransactionRecord>> _safeWalletHistory(
    AddressPool pool, {
    int gapLimit = 20,
    int limit = 25,
  }) async {
    try {
      return await _historyFromPool(
        pool: pool,
        gapLimit: gapLimit,
        limit: limit,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchWalletSnapshot: storico non disponibile: $e');
      }
      return const [];
    }
  }

  /// Storico su un [pool] di indirizzi derivati a blocchi (gap-limit).
  ///
  /// // PERCHÉ (P8-b): stessa logica di gap di `_fetchHistoryForAddressLists`,
  /// // ma gli indirizzi si chiedono al pool condiviso con lo scan UTXO.
  /// Il set usato per il ricalcolo del netto è quello derivato finora: un
  /// indirizzo oltre il gap-limit non è visibile nemmeno dal saldo (stessa
  /// regola BIP44), quindi il comportamento resta coerente.
  Future<List<TransactionRecord>> _historyFromPool({
    required AddressPool pool,
    int gapLimit = 20,
    int limit = 25,
  }) async {
    final tipHeight = await _fetchTipHeight();

    Future<List<Map<String, dynamic>>> fetchChainTxs(int chainIndex) async {
      final collected = <Map<String, dynamic>>[];
      var consecutiveEmpty = 0;
      var start = 0;
      while (consecutiveEmpty < gapLimit && start < pool.maxAddresses) {
        await pool.ensure(start + gapLimit);
        final chainAddrs = chainIndex == 0 ? pool.external : pool.change;
        if (start >= chainAddrs.length) break; // cap raggiunto
        final end = (start + gapLimit) > chainAddrs.length
            ? chainAddrs.length
            : start + gapLimit;
        final batch = chainAddrs.sublist(start, end);
        final batchResults = await Future.wait(
          batch.map((addr) => _fetchAddressTxsJson(addr, limit: limit)),
        );
        var stop = false;
        for (var j = 0; j < batch.length; j++) {
          final txs = batchResults[j];
          if (txs.isEmpty) {
            consecutiveEmpty++;
            if (consecutiveEmpty >= gapLimit) {
              stop = true;
              break;
            }
          } else {
            consecutiveEmpty = 0;
            collected.addAll(txs);
          }
        }
        if (stop) break;
        start = end;
      }
      return collected;
    }

    final chainTxLists = await Future.wait([
      fetchChainTxs(0),
      fetchChainTxs(1),
    ]);

    // Set COMPLETO degli indirizzi noti (dopo l'estensione del pool): serve per
    // attribuire correttamente vin/vout di una tx che tocca più nostre chiavi.
    final walletAddresses = {...pool.external, ...pool.change};

    final byTxid = <String, Map<String, dynamic>>{};
    for (final txs in chainTxLists) {
      for (final json in txs) {
        final txid = json['txid'] as String? ?? '';
        if (txid.isNotEmpty) byTxid[txid] = json;
      }
    }

    final records = byTxid.values
        .map(
          (json) => TransactionRecord.fromExplorerJson(
            json,
            walletAddresses: walletAddresses,
            tipHeight: tipHeight,
          ),
        )
        .toList();
    records.sort(_compareByTimestamp);
    return _appendPendingState(records);
  }

  Future<List<UtxoInfo>> fetchUtxos(String address, {int? tipHeight}) async {
    // PERCHÉ: Circuit breaker — fetchUtxos lancia eccezioni se API down
    return _cb.call(() async {
      final t0 = DateTime.now().millisecondsSinceEpoch;

      // PERCHÉ (S7): conferme reali = tip − block_height + 1. Il chiamante
      // (scanDerivedAddressesForUtxos) riusa il suo; qui una sola fetch se
      // assente (fallback onesto: _fetchTipHeight ritorna null su errore).
      final tip = tipHeight ?? await _fetchTipHeight();

      final response = await _getWithFailover(
        'address/$address/utxo',
        timeout: const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        throw Exception('Errore fetch UTXO: HTTP ${response.statusCode}');
      }
      final list = jsonDecode(response.body) as List<dynamic>;

      // Parallelizza le richieste per i dettagli delle tx
      final futures = <Future<UtxoInfo>>[];
      for (final u in list) {
        final m = u as Map<String, dynamic>;
        final txid = m['txid'] as String;
        final vout = m['vout'] as int;
        final value = m['value'] as int;

        futures.add(
          _fetchTxOutScript(txid, vout, value, address, tipHeight: tip),
        );
      }

      final results = await Future.wait(futures, eagerError: false);

      final t1 = DateTime.now().millisecondsSinceEpoch;
      if (kDebugMode) {
        debugPrint(
          'bitcoin: fetchUtxos($address) dt=${t1 - t0}ms utxos=${results.length}',
        );
      }
      return results;
    });
  }

  Future<UtxoInfo> _fetchTxOutScript(
    String txid,
    int vout,
    int value,
    String address, {
    int? tipHeight,
  }) async {
    try {
      final txResp = await _getWithFailover(
        'tx/$txid',
        timeout: const Duration(seconds: 5),
      );
      if (txResp.statusCode == 200) {
        final txJson = jsonDecode(txResp.body) as Map<String, dynamic>;
        final vouts = txJson['vout'] as List<dynamic>;
        if (vout < vouts.length) {
          final v = vouts[vout] as Map<String, dynamic>;
          final scriptHex = v['scriptpubkey'] as String?;
          final scriptType = v['scriptpubkey_type'] as String?;
          final scriptAddr = v['scriptpubkey_address'] as String?;

          // PERCHÉ (S7): stesso pattern di TransactionRecord.fromExplorerJson —
          // l'API /utxo non espone le conferme: servono status + tip height.
          final status = txJson['status'] as Map<String, dynamic>? ?? const {};
          final confirmed = status['confirmed'] as bool? ?? false;
          final blockHeight = status['block_height'] as int?;
          final int? confirmations;
          if (!confirmed) {
            confirmations = 0;
          } else if (tipHeight != null && blockHeight != null) {
            confirmations = tipHeight - blockHeight + 1;
          } else {
            confirmations = 1;
          }

          return UtxoInfo(
            txid: txid,
            vout: vout,
            valueSat: value,
            scriptPubKeyHex: scriptHex,
            scriptPubKeyType: scriptType,
            scriptPubKeyAddress: scriptAddr,
            ownerAddress: address,
            confirmations: confirmations,
          );
        }
      }
    } catch (_) {
      // ignore and fall back to basic entry
    }
    return UtxoInfo(
      txid: txid,
      vout: vout,
      valueSat: value,
      ownerAddress: address,
    );
  }

  /// Altezza corrente del tip (null se la rete/API non risponde).
  ///
  /// // PERCHÉ: le tx con nLockTime (refund swap, P9) sono trasmissibili solo
  /// // dall'altezza del timelock; il servizio swap usa questo check per dare
  /// // un messaggio chiaro invece dell'errore grezzo del nodo.
  Future<int?> fetchTipHeight() => _fetchTipHeight();

  /// Altezza del blocco tip, per calcolare le conferme reali.
  /// Fallback: null (le confermate mostreranno 1+).
  Future<int?> _fetchTipHeight() async {
    try {
      final response = await _getWithFailover(
        'blocks/tip/height',
        timeout: const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        return int.tryParse(response.body.trim());
      }
    } catch (_) {}
    return null;
  }

  /// Fetch grezzo delle transazioni di un indirizzo (formato Esplora).
  /// // PERCHÉ: su errore restituisce lista vuota (coerente con
  /// fetchAddressInfo) — l'API può fallire per casi particolari (es. indirizzi
  /// coinbase) e la UI deve mostrare l'empty state senza bloccare il wallet.
  Future<List<Map<String, dynamic>>> _fetchAddressTxsJson(
    String address, {
    int limit = 25,
  }) async {
    return _cb.call(() async {
      try {
        final response = await _getWithFailover(
          'address/$address/txs',
          timeout: const Duration(seconds: 10),
        );
        if (response.statusCode != 200) return const [];
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.take(limit).map((e) => e as Map<String, dynamic>).toList();
      } catch (_) {
        return const [];
      }
    });
  }

  /// Storico transazioni di un singolo indirizzo (in/out rispetto ad esso).
  Future<List<TransactionRecord>> fetchTransactionHistory(
    String address, {
    int limit = 25,
  }) async {
    final tipHeight = await _fetchTipHeight();
    final txs = await _fetchAddressTxsJson(address, limit: limit);
    final records = txs
        .map(
          (json) => TransactionRecord.fromExplorerJson(
            json,
            walletAddresses: {address},
            tipHeight: tipHeight,
          ),
        )
        .toList();
    records.sort(_compareByTimestamp);
    // PERCHÉ (audit P1-c): riconcilia le tx inviate in sessione (pending →
    // confermata/espulsa) prima di restituire lo storico.
    return _appendPendingState(records);
  }

  /// Storico completo del wallet (indirizzo principale + change addresses).
  /// // PERCHÉ: una transazione può toccare più indirizzi del wallet (change);
  /// il netto va ricalcolato sul set completo per non mostrare doppioni o
  /// importi parziali. Fetch concorrente + dedup per txid. Scansiona ENTRAMBE
  /// le catene con gap-limit BIP44 (fix storico vs BlueWallet).
  ///
  /// PERCHÉ (P1 watch-only): deriva dal mnemonic e delega a
  /// [_fetchHistoryForAddressLists] — il percorso watch-only riusa la stessa
  /// logica su liste derivate dall'xpub.
  Future<List<TransactionRecord>> fetchWalletHistory(
    String mnemonic, {
    String? derivationPath,
    int gapLimit = 20,
    int maxAddresses = 100,
    int limit = 25,
  }) async {
    final derivation = await deriveWalletDataFromMnemonic(
      mnemonic,
      derivationPath: derivationPath,
      addressCount: maxAddresses,
    );
    return _fetchHistoryForAddressLists(
      externalAddresses: derivation.addresses,
      changeAddresses: derivation.changeAddresses,
      gapLimit: gapLimit,
      limit: limit,
    );
  }

  /// Storico su liste di indirizzi GIÀ derivate (external + change): fetch
  /// concorrente con gap-limit, dedup per txid e netto ricalcolato sul set
  /// completo di indirizzi del wallet.
  ///
  /// PERCHÉ (P1 watch-only): identica logica di fetchWalletHistory ma parte
  /// da indirizzi derivati da un xpub invece che da un mnemonic.
  Future<List<TransactionRecord>> _fetchHistoryForAddressLists({
    required List<String> externalAddresses,
    required List<String> changeAddresses,
    int gapLimit = 20,
    int limit = 25,
  }) async {
    final tipHeight = await _fetchTipHeight();
    // PERCHÉ: il set include anche la catena change — senza, il netto delle tx
    // outgoing è calcolato lordo (senza credito del change) e le tx su
    // indirizzi change sparirebbero dallo storico.
    final walletAddresses = {
      ...externalAddresses,
      ...changeAddresses,
    };

    Future<List<Map<String, dynamic>>> fetchChainTxs(List<String> addrs) async {
      final collected = <Map<String, dynamic>>[];
      var consecutiveEmpty = 0;
      for (var start = 0;
          start < addrs.length && consecutiveEmpty < gapLimit;
          start += gapLimit) {
        final batch = addrs.skip(start).take(gapLimit).toList();
        final batchResults = await Future.wait(
          batch.map((addr) => _fetchAddressTxsJson(addr, limit: limit)),
        );
        var stop = false;
        for (var j = 0; j < batch.length; j++) {
          final txs = batchResults[j];
          if (txs.isEmpty) {
            consecutiveEmpty++;
            if (consecutiveEmpty >= gapLimit) {
              stop = true;
              break;
            }
          } else {
            consecutiveEmpty = 0;
            collected.addAll(txs);
          }
        }
        if (stop) break;
      }
      return collected;
    }

    final chainTxLists = await Future.wait([
      fetchChainTxs(externalAddresses),
      fetchChainTxs(changeAddresses),
    ]);

    final byTxid = <String, Map<String, dynamic>>{};
    for (final txs in chainTxLists) {
      for (final json in txs) {
        final txid = json['txid'] as String? ?? '';
        if (txid.isNotEmpty) byTxid[txid] = json;
      }
    }

    final records = byTxid.values
        .map(
          (json) => TransactionRecord.fromExplorerJson(
            json,
            walletAddresses: walletAddresses,
            tipHeight: tipHeight,
          ),
        )
        .toList();
    records.sort(_compareByTimestamp);
    // PERCHÉ (audit P1-c): riconcilia le tx inviate in sessione (pending →
    // confermata/espulsa) prima di restituire lo storico.
    return _appendPendingState(records);
  }

  /// Ordina le transazioni per timestamp desc; le pending (timestamp null) in fondo.
  static int _compareByTimestamp(TransactionRecord a, TransactionRecord b) {
    final ta = a.timestamp?.millisecondsSinceEpoch ?? -1;
    final tb = b.timestamp?.millisecondsSinceEpoch ?? -1;
    return tb.compareTo(ta);
  }

  /// Riconcilia lo stato delle tx inviate da questa app (sessione).
  ///
  /// PERCHÉ (audit P1-c): una tx outgoing che il nodo non conosce più è stata
  /// espulsa o sostituita dal mempool → va mostrata come tale (mai sparire in
  /// silenzio, mai spacciata per confermata). Se è confermata si smette di
  /// tracciarla. Fail-open: su errore di rete NON si fabbrica alcuna riga.
  Future<List<TransactionRecord>> _appendPendingState(
    List<TransactionRecord> records,
  ) async {
    final tracked = PendingSendRegistry.activeTxids;
    if (tracked.isEmpty) return records;

    final byTxid = <String, TransactionRecord>{
      for (final r in records) r.txid: r,
    };
    final result = <TransactionRecord>[...records];

    for (final txid in tracked) {
      final rec = byTxid[txid];
      if (rec != null) {
        // PERCHÉ: se compare nello storico con conferme → confermata.
        if (rec.confirmations > 0 && !rec.isPending) {
          PendingSendRegistry.markConfirmed(txid);
        }
        continue;
      }

      // Già marcata espulsa: rigenera la riga finché non risulta confermata
      // (reorg che la re-include) o la sessione finisce.
      if (PendingSendRegistry.isEvicted(txid)) {
        final probe = await _probeSentTx(txid);
        if (probe.confirmed) {
          PendingSendRegistry.markConfirmed(txid);
        } else if (probe.notFound) {
          result.add(_evictedRecord(txid));
        }
        continue;
      }

      // Assente dallo storico dell'esploratore: interroga il nodo.
      final probe = await _probeSentTx(txid);
      if (probe.notFound) {
        // PERCHÉ: 404 = il nodo non conosce più la tx → espulsa/sostituita.
        PendingSendRegistry.markEvicted(txid);
        result.add(_evictedRecord(txid));
      } else if (probe.confirmed) {
        PendingSendRegistry.markConfirmed(txid);
      }
      // pending o errore → nessun cambio di stato (fail-open).
    }

    return result;
  }

  /// Riga sintetica per una tx outgoing espulsa/sostituita.
  TransactionRecord _evictedRecord(String txid) {
    // PERCHÉ: i fondi non sono stati spesi davvero (tx mai confermata);
    // l'importo mostrato è quello noto al momento dell'invio.
    return TransactionRecord(
      txid: txid,
      direction: TxDirection.outgoing,
      amountSats: PendingSendRegistry.amountOf(txid),
      isEvicted: true,
    );
  }

  /// Interroga il nodo su una tx: 404 → `notFound`; 200 confermata →
  /// `confirmed`; altri errori → nessun flag (fail-open: NON concludere che
  /// sia persa solo perché l'API è giù o rate-limited).
  Future<({bool notFound, bool confirmed})> _probeSentTx(String txid) async {
    try {
      final status =
          await ExplorerApi(client: _client, maxAttempts: 3).txStatus(txid);
      return (notFound: false, confirmed: status?.confirmed ?? false);
    } on ApiException catch (e) {
      return (notFound: e.isNotFound, confirmed: false);
    }
  }

  Future<FeeEstimates> fetchFeeEstimates() async {
    // PERCHÉ: Circuit breaker — previene chiamate a cascata se API down
    return _cb.call(() async {
      try {
        // Mempool.space fee estimates (stessa rotta Esplora sui mirror)
        final response = await _getWithFailover(
          'v1/fees/recommended',
          timeout: const Duration(seconds: 10),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return FeeEstimates(
            lowSatVb: (data['economyFee'] as num).round(),
            normalSatVb: (data['hourFee'] as num).round(),
            highSatVb: (data['fastestFee'] as num).round(),
          );
        }
      } catch (_) {}
      // Fallback fees
      final fallback = BitcoinNetworkConfig.fallbackFeeEstimates;
      return FeeEstimates(
        lowSatVb: fallback.low,
        normalSatVb: fallback.normal,
        highSatVb: fallback.high,
      );
    });
  }

  Future<String> broadcastTransaction(String rawHex) async {
    // PERCHÉ: breaker dedicato al broadcast (azione critica): se l'API è giù
    // il POST fallisce e il SUO breaker si apre dopo 3 tentativi — senza
    // bloccare le letture (saldo/storico) e viceversa.
    return _cbBroadcast.call(() async {
      // STEP: 1 — host abilitati al broadcast (mempool.guide, kilombino).
      // PERCHÉ (2026-09-16): il failover scatta SOLO se il POST non ha
      // ricevuto alcuna risposta HTTP (errore di trasporto): una risposta di
      // errore (400 tx invalida, 500…) è un esito definitivo e non va
      // ritentata altrove. La lista esclude maveth.ca, che risponde 404 su
      // POST /tx (verificato il 2026-09-16).
      // PERCHÉ: lista di broadcast dalla politica di processo — se i mirror
      // sono disattivati resta il solo primario (nessuna tx ai mirror).
      final hosts = ExplorerMirrors.instance.broadcastHosts;
      Object? lastTransportError;
      for (final host in hosts) {
        http.Response response;
        try {
          response = await _client
              .post(
                Uri.parse('$host/tx'),
                headers: {..._kApiHeaders, 'Content-Type': 'text/plain'},
                body: rawHex,
              )
              .timeout(const Duration(seconds: 30));
        } on Exception catch (e) {
          // Nessuna risposta HTTP → la tx non è stata relayata: si prova
          // l'host successivo.
          lastTransportError = e;
          continue;
        }
        if (response.statusCode == 200) {
          return response.body.trim(); // txid
        }
        throw Exception(
          'Broadcast fallito (${response.statusCode}): ${response.body}',
        );
      }
      throw lastTransportError ??
          Exception('Broadcast fallito: nessun host disponibile');
    });
  }

  /// Build, sign and broadcast verso UN destinatario (percorso storico).
  ///
  /// PERCHÉ (P3): il caso singolo è una lista di un elemento — la logica vive in
  /// [buildSignAndSendBatch]. Il wrapper conserva firma e comportamento identici
  /// a prima, così `send_screen` (N=1) e i test esistenti non cambiano.
  ///
  /// PERCHÉ (S8 RBF): [enableRBF] default true — ogni nuova tx dell'app è
  /// replaceable (BIP125), prerequisito per un eventuale bump fee futuro.
  Future<SendResult> buildSignAndSend({
    required String mnemonic,
    required String toAddress,
    required int amountSats,
    required int feeRateSatVb,
    required List<UtxoInfo> utxos,
    required String derivationPath,
    bool enableRBF = true,
  }) {
    return buildSignAndSendBatch(
      mnemonic: mnemonic,
      outputs: [SendOutput(address: toAddress, amountSats: amountSats)],
      feeRateSatVb: feeRateSatVb,
      utxos: utxos,
      derivationPath: derivationPath,
      enableRBF: enableRBF,
    );
  }

  /// Deriva la pubkey di refund dello swap (33B compressa, hex) dal mnemonic.
  ///
  /// // PERCHÉ: la richiesta di quote richiede la refund_pubkey PRIMA della
  /// // creazione della sessione; l'app la deriva dal seed dell'utente (mai
  /// // chiederla all'esterno) usando SEMPRE l'account dedicato 2'.
  Future<String> deriveSwapRefundPubkey({
    required String mnemonic,
    required String refundDerivationPath,
  }) =>
      compute(
        _deriveSwapRefundPubkey,
        SwapRefundKeyData(
          mnemonic: mnemonic,
          refundDerivationPath: refundDerivationPath,
        ),
      );

  /// Costruisce e firma (SENZA trasmettere) la tx di REFUND dell'HTLC swap.
  ///
  /// // FLOW: Pagamento LN via swap (P9) — app
  /// // STEP: recupero — se il pagamento LN non riesce entro il CLTV, l'utente
  /// // spende l'HTLC col ramo OP_ELSE firmando con la chiave DEDICATA dello
  /// // swap ([refundDerivationPath], account 2'): mai l'account principale.
  ///
  /// Ritorna la raw hex: broadcast e txid restano al chiamante (il servizio
  /// swap, che conosce il ciclo di vita della sessione).
  Future<String> buildSignedRefundTx({
    required String mnemonic,
    required String refundDerivationPath,
    required String paymentHashHex,
    required String claimPubkeyHex,
    required String refundPubkeyHex,
    required int cltvHeight,
    required String witnessScriptHex,
    required String fundingTxid,
    required int fundingVout,
    required int fundingAmountSats,
    required String destinationAddress,
    required int feeRateSatVb,
  }) {
    return compute(
      _buildAndSignRefundTx,
      BuildRefundTxData(
        mnemonic: mnemonic,
        refundDerivationPath: refundDerivationPath,
        paymentHashHex: paymentHashHex,
        claimPubkeyHex: claimPubkeyHex,
        refundPubkeyHex: refundPubkeyHex,
        cltvHeight: cltvHeight,
        witnessScriptHex: witnessScriptHex,
        fundingTxid: fundingTxid,
        fundingVout: fundingVout,
        fundingAmountSats: fundingAmountSats,
        destinationAddress: destinationAddress,
        feeRateSatVb: feeRateSatVb,
      ),
    );
  }

  /// Build, sign and broadcast verso N destinatari in UNA sola transazione.
  ///
  /// // PERCHÉ (P3): una tx = una fee (il vantaggio del batch). Il controllo
  /// // dust vive QUI oltre che in UI: un output < 546 sat non è spendibile e il
  /// // nodo rifiuterebbe la tx DOPO il broadcast.
  /// FLOW: Invio Transazione Wallet (batch)
  /// STEP: 1 — validazione destinatari (conteggio + dust)
  /// STEP: 2 — build + firma UNIFIED nell'isolate
  /// STEP: 3 — broadcast + registrazione (pending / RBF)
  Future<SendResult> buildSignAndSendBatch({
    required String mnemonic,
    required List<SendOutput> outputs,
    required int feeRateSatVb,
    required List<UtxoInfo> utxos,
    required String derivationPath,
    bool enableRBF = true,
  }) async {
    if (outputs.isEmpty) {
      throw ArgumentError('Serve almeno un destinatario.');
    }
    for (final o in outputs) {
      if (o.isDust) {
        throw ArgumentError(
          'Importo sotto il minimo dust (${SendOutput.dustLimitSats} sat) '
          'per ${o.address}.',
        );
      }
    }
    final totalOut = outputs.fold<int>(0, (sum, o) => sum + o.amountSats);
    final recipientCount = outputs.length;

    final data = BuildTxData(
      mnemonic: mnemonic,
      outputs: List<SendOutput>.unmodifiable(outputs),
      feeRateSatVb: feeRateSatVb,
      utxos: utxos,
      derivationPath: derivationPath,
      enableRBF: enableRBF,
    );

    // Log derivation path and derived first address to help debugging mismatched UTXOs
    // PERCHÉ (audit F8): logging solo in debug mode — in release debugPrint
    // resta visibile in logcat e non deve esporre indirizzi/firme.
    if (kDebugMode) {
      try {
        debugPrint(
          'bitcoin: buildSignAndSendBatch derivationPath=$derivationPath '
          'utxos=${utxos.length} destinatari=$recipientCount',
        );
        final derived = await compute(
          deriveBitcoinAddress,
          AddressDerivationData(mnemonic, derivationPath, 1),
        );
        debugPrint(
          'bitcoin: derived address for path $derivationPath -> $derived',
        );
      } catch (e) {
        debugPrint('bitcoin: error deriving address for logging: $e');
      }
    }

    final rawHex = await compute(_buildAndSignTx, data);

    // DEBUG: log raw transaction hex (first 100 chars) — solo in debug (F8)
    if (kDebugMode) {
      debugPrint(
        '[DEBUG buildSignAndSend] rawTx hex (first 100): ${rawHex.substring(0, rawHex.length < 100 ? rawHex.length : 100)}',
      );
    }

    // Stima la fee mostrata con la STESSA logica del builder, ma con N
    // destinatari: prima era hardcoded a 1 → fee sotto-stimata su un batch.
    final selectedCount = _countUsedUtxos(
      utxos,
      totalOut,
      feeRateSatVb,
      recipientCount: recipientCount,
    );
    // Compute approximate totalIn for the estimated selected utxos
    final totalInSelected =
        utxos.take(selectedCount).fold<int>(0, (p, e) => p + e.valueSat);
    var displayTxSize = estimateTxVbytes(
      utxos.take(selectedCount),
      recipientCount + 1,
    );
    var fee = displayTxSize * feeRateSatVb;
    var change = totalInSelected - totalOut - fee;
    if (change < SendOutput.dustLimitSats) {
      displayTxSize = estimateTxVbytes(
        utxos.take(selectedCount),
        recipientCount,
      );
      fee = displayTxSize * feeRateSatVb;
      change = totalInSelected - totalOut - fee;
    }

    final txid = await broadcastTransaction(rawHex);
    // PERCHÉ (audit P1-c): ricorda la tx inviata per rilevare eviction/
    // sostituzione — solo sessione, niente chiavi, niente persistenza.
    // PERCHÉ (P3): per un batch si registra il TOTALE inviato (la riga
    // sintetica in UI mostra la somma dei destinatari).
    PendingSendRegistry.register(txid, amountSats: totalOut);
    if (enableRBF) {
      // PERCHÉ (S8 RBF, incremento B): salva i parametri per il bump fee —
      // stessi input/destinatari con fee maggiore; MAI seed/chiavi.
      RbfParamsRegistry.register(
        txid,
        RbfTxParams(
          kind: RbfTxKind.send,
          outputs: List<SendOutput>.from(outputs),
          derivationPath: derivationPath,
          originalFeeRateSatVb: feeRateSatVb,
          utxos: List<UtxoInfo>.from(utxos),
        ),
      );
    }
    return SendResult(txid: txid, feePaid: fee);
  }

  /// Sweep all spendable UTXOs to `toAddress` using given fee rate.
  ///
  /// PERCHÉ (S8 RBF): [enableRBF] default true (replaceable), come la spesa.
  Future<SendResult> sweepAll({
    required String mnemonic,
    required String toAddress,
    required int feeRateSatVb,
    required List<UtxoInfo> utxos,
    required String derivationPath,
    bool enableRBF = true,
  }) async {
    final data = BuildTxSweepData(
      mnemonic: mnemonic,
      toAddress: toAddress,
      feeRateSatVb: feeRateSatVb,
      utxos: utxos,
      derivationPath: derivationPath,
      enableRBF: enableRBF,
    );

    final rawHex = await compute(_buildAndSignTxSweep, data);

    // Compute fee for display using the same type-aware estimator as the builder.
    // PERCHÉ (audit LOW-5): include anche i P2PKH (sweep legacy) — il filtro
    // precedente li escludeva e sotto-stimava la fee mostrata all'utente.
    final spendable = utxos.where((u) {
      final t = _resolveScriptType(u);
      return t == 'v0_p2wpkh' || t == 'p2sh' || t == 'p2pkh';
    }).toList();
    final fee = estimateTxVbytes(spendable, 1) * feeRateSatVb;

    final txid = await broadcastTransaction(rawHex);
    // PERCHÉ (audit P1-c): anche lo sweep va tracciato — importo stimato
    // (totale input − fee) solo per la riga sintetica di UI.
    final totalIn = spendable.fold<int>(0, (p, u) => p + u.valueSat);
    PendingSendRegistry.register(txid, amountSats: totalIn - fee);
    if (enableRBF) {
      // PERCHÉ (S8 RBF, incremento B): anche lo sweep è bumpabile con gli
      // stessi input e fee maggiore (MAI seed/chiavi, solo sessione).
      RbfParamsRegistry.register(
        txid,
        RbfTxParams(
          kind: RbfTxKind.sweep,
          toAddress: toAddress,
          amountSats: 0,
          derivationPath: derivationPath,
          originalFeeRateSatVb: feeRateSatVb,
          utxos: List<UtxoInfo>.from(utxos),
        ),
      );
    }
    return SendResult(txid: txid, feePaid: fee);
  }

  /// RBF BIP125 (S8/B): ricostruisce la stessa transazione (stessi input,
  /// stesso destinatario/importo) con una fee maggiore e la broadcasta.
  ///
  /// PERCHÉ: la tx originale è replaceable (enableRBF=true, incremento A);
  /// alzare la fee riduce il change (output interno) lasciando invariato
  /// l'importo al destinatario → replacement valido con nuovo txid.
  ///
  /// L'autenticazione (biometria/password) è a monte (UI): qui arriva il
  /// mnemonic già sbloccato, come in [buildSignAndSend]. MAI cache del seed.
  Future<SendResult> bumpFee({
    required String mnemonic,
    required String txid,
    required int newFeeRateSatVb,
  }) async {
    final params = RbfParamsRegistry.of(txid);
    if (params == null) {
      throw StateError(
        'Transazione non tracciata in questa sessione: impossibile aumentare '
        "la fee (servono i parametri dell'invio originale).",
      );
    }
    if (newFeeRateSatVb <= params.originalFeeRateSatVb) {
      throw ArgumentError(
        'La nuova fee ($newFeeRateSatVb sat/vB) deve essere maggiore di '
        'quella originale (${params.originalFeeRateSatVb} sat/vB).',
      );
    }

    final SendResult result;
    if (params.kind == RbfTxKind.sweep) {
      result = await sweepAll(
        mnemonic: mnemonic,
        toAddress: params.toAddress,
        feeRateSatVb: newFeeRateSatVb,
        utxos: params.utxos,
        derivationPath: params.derivationPath,
        enableRBF: true,
      );
    } else {
      // PERCHÉ (P3): anche una tx batch è sostituibile — il bump ripaga TUTTI
      // i destinatari originali (effectiveOutputs), non solo il primo.
      result = await buildSignAndSendBatch(
        mnemonic: mnemonic,
        outputs: params.effectiveOutputs,
        feeRateSatVb: newFeeRateSatVb,
        utxos: params.utxos,
        derivationPath: params.derivationPath,
        enableRBF: true,
      );
    }

    // PERCHÉ: l'originale è stata sostituita dal replacement → niente più
    // bump su di essa; il nuovo txid è già registrato dal broadcast.
    RbfParamsRegistry.remove(txid);
    return result;
  }

  /// Stima quanti UTXO bastano per coprire [totalOut] + fee.
  ///
  /// // PERCHÉ (P3): [recipientCount] era hardcoded a 1 destinatario — su un
  /// // batch il conteggio degli input (e quindi la fee mostrata) sarebbe stato
  /// // sotto-stimato, perché ogni output aggiunge ~31 vB alla tx.
  int _countUsedUtxos(
    List<UtxoInfo> utxos,
    int totalOut,
    int feeRateSatVb, {
    int recipientCount = 1,
  }) {
    const int dustLimit = 546;
    int totalIn = 0;
    int count = 0;
    for (final u in utxos) {
      count++;
      totalIn += u.valueSat;

      var outputCount = recipientCount + 1;
      var estimatedSize = estimateTxVbytes(utxos.take(count), outputCount);
      var estimatedFee = estimatedSize * feeRateSatVb;
      var estimatedChange = totalIn - totalOut - estimatedFee;

      if (estimatedChange <= dustLimit) {
        outputCount = recipientCount;
        estimatedSize = estimateTxVbytes(utxos.take(count), outputCount);
        estimatedFee = estimatedSize * feeRateSatVb;
        estimatedChange = totalIn - totalOut - estimatedFee;
      }

      if (totalIn >= totalOut + estimatedFee && estimatedChange >= 0) break;
    }
    return count;
  }
}
