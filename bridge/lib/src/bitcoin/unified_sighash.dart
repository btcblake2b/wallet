import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

// ============================================================
// SIGHASH_UNIFIED — replay protection della chain bitcoin-blake2b
// ============================================================
// PERCHÉ (P9 swap): port allineato 1:1 di
// `mobile/lib/core/services/unified_sighash.dart` (funzione
// `computeUnifiedSighash`). Il servizio swap del bridge deve produrre firme
// valide sulla chain blake2b per il CLAIM dell'HTLC: il digest del fork NON è
// BIP-143 — è SIGHASH_UNIFIED (Knots PR #357). Il mobile resta la fonte
// primaria: se il digest cambia, aggiornare ENTRAMBE le copie; i vettori
// ufficiali presenti nei test dei due pacchetti fanno da guardia.
//
// Riferimento: src/script/interpreter.cpp:1491 (HASHER_UNIFIED_SIGHASH) e
// SignatureHashUnified (interpreter.cpp:1635-1750).
const int kSighashAllUnified = 0x21; // SIGHASH_ALL | SIGHASH_UNIFIED

/// Sequence RBF opt-in (BIP125): 0xfffffffd little-endian.
///
/// PERCHÉ: NON si usa `BitcoinOpCodeConst.replaceByFeeSequence` (0x00000001)
/// che attiva un BIP68 relative locktime di 1 blocco. 0xfffffffd segnala
/// "replaceable" senza vincoli temporali (bit 31 settato → fuori BIP68).
const List<int> kReplaceByFeeSequence = [0xfd, 0xff, 0xff, 0xff];

/// Concatena una lista di blocchi di byte.
// PERCHÉ: blockchain_utils non espone un helper concatBytesList pubblico;
// lo spread operator è il pattern usato anche da bitcoin_base.
List<int> _concat(List<List<int>> parts) => [for (final p in parts) ...p];

/// Reversa una lista di byte (per il txid little-endian).
List<int> _reverseBytes(List<int> bytes) => bytes.reversed.toList();

/// Calcola il digest SIGHASH_UNIFIED per uno script WITNESS_V0 (script_type 1).
///
/// [tx] transazione con input ordinati BIP-69 e scriptSig vuoto (lo scriptSig
/// non entra nel digest segwit).
/// [txInIndex] indice dell'input da firmare.
/// [scriptCode] scriptCode BIP-143 dell'input (per P2WPKH è il P2PKH script;
/// per il nostro HTLC è il witnessScript P2WSH).
/// [spentAmounts] valori (satoshi) di TUTTI gli input, nello stesso ordine di [tx].
/// [spentScripts] scriptPubKey di TUTTI gli input, nello stesso ordine di [tx].
///
/// Struttura del messaggio (interpreter.cpp:1635-1750, layout BIP341-like):
/// EPOCH(0) | nHashType | version | nLockTime | locktime esteso(0)
/// | hashPrevouts | hashSpentAmounts | hashSpentScripts | hashSequences
/// | hashOutputs | script_type(1) | nIn | scriptCode
List<int> computeUnifiedSighash({
  required BtcTransaction tx,
  required int txInIndex,
  required Script scriptCode,
  required List<BigInt> spentAmounts,
  required List<Script> spentScripts,

  /// Script type del digest: 0 = bare/P2SH/P2PKH (legacy), 1 = segwit v0.
  /// PERCHÉ (BIP44): i vettori ufficiali coprono tutti i tipi; l'app firma
  /// legacy (tipo 0) e segwit v0 (tipo 1) — il byte separa i messaggi.
  int scriptType = 1,
}) {
  final inputs = tx.inputs;
  final outputs = tx.outputs;

  // --- Hash aggregati con SHA256 SINGOLA (non double-SHA256) ---
  // PERCHÉ: PrecomputedTransactionData::Init (interpreter.cpp:1456-1468)
  // usa SHA256 singola delle concatenazioni, non sha256d come BIP-143.

  // 6a: m_prevouts_single_hash = SHA256(concat(outpoint))
  final prevouts = _concat([
    for (final i in inputs)
      [
        ..._reverseBytes(BytesUtils.fromHexString(i.txId)),
        ...IntUtils.toBytes(i.txIndex, length: 4, byteOrder: Endian.little),
      ],
  ]);
  final hashPrevouts = QuickCrypto.sha256Hash(prevouts);

  // 6b: m_spentamounts_single_hash = SHA256(concat(nValue 8B LE))
  final amounts = _concat([
    for (final a in spentAmounts)
      BigintUtils.toBytes(a, length: 8, order: Endian.little),
  ]);
  final hashSpentAmounts = QuickCrypto.sha256Hash(amounts);

  // 6c: m_spentscripts_single_hash = SHA256(concat(scriptPubKey varint-prefixed))
  final scripts = _concat([
    for (final s in spentScripts) IntUtils.prependVarint(s.toBytes()),
  ]);
  final hashSpentScripts = QuickCrypto.sha256Hash(scripts);

  // 6d: m_sequences_single_hash = SHA256(concat(nSequence 4B))
  final seqs = _concat([for (final i in inputs) i.sequence]);
  final hashSequences = QuickCrypto.sha256Hash(seqs);

  // 7: m_outputs_single_hash = SHA256(concat(CTxOut)) — con ALL committa tutti
  final outs = _concat([for (final o in outputs) o.toBytes()]);
  final hashOutputs = QuickCrypto.sha256Hash(outs);

  // --- Serializzazione del messaggio (ordine esatto della tabella §3) ---
  final msg = _concat([
    [0x00], // 1. EPOCH (costante, "stessa stanza che BIP341 si è lasciato")
    [kSighashAllUnified], // 2. nHashType COMPRENSIVO del bit 0x20
    tx.version, // 3. version (4B LE)
    tx.locktime, // 4. nLockTime (4B LE)
    [0x00], // 5. byte locktime esteso (5° byte, zero)
    hashPrevouts, // 6a
    hashSpentAmounts, // 6b
    hashSpentScripts, // 6c
    hashSequences, // 6d
    hashOutputs, // 7
    [scriptType], // 8. script_type (0 legacy/P2PKH, 1 WITNESS_V0, 2/3 taproot)
    IntUtils.toBytes(txInIndex, length: 4, byteOrder: Endian.little), // 9. nIn
    IntUtils.prependVarint(scriptCode.toBytes()), // 10. scriptCode
  ]);

  // digest = SHA256( SHA256("UnifiedSighash") || SHA256("UnifiedSighash") || msg )
  // PERCHÉ: TaggedHash("UnifiedSighash") = SHA256(tag) scritto DUE volte
  // (src/hash.cpp:85-92), poi una singola SHA-256 finale (interpreter.cpp:1747).
  final tagHash = QuickCrypto.sha256Hash('UnifiedSighash'.codeUnits);
  return QuickCrypto.sha256Hash(_concat([tagHash, tagHash, msg]));
}
