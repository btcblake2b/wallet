import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

// ============================================================
// SIGHASH_UNIFIED — replay protection della chain bitcoin-blake2b
// ============================================================
// PERCHÉ: la chain blake2b (Bitcoin Knots, PR #357 "Consensus: Unified opt-in
// sighash") usa un sighash opt-in a bit 0x20. Il digest è SHA-256 taggato con
// tag "UnifiedSighash" ed è disgiunto da BIP-143/BIP-341: una firma UNIFIED non
// verifica su una chain senza il fork attivo, e una firma legacy non verifica
// sul messaggio UNIFIED. Questo chiude il replay attack tra le chain.
//
// Riferimento: src/script/interpreter.cpp:1491 (HASHER_UNIFIED_SIGHASH) e
// SignatureHashUnified (interpreter.cpp:1635-1750).
//
// L'app firma script type 1 (WITNESS_V0: P2WPKH e P2SH-P2WPKH) e script
// type 0 (legacy/P2PKH, BIP44), con sighash ALL (0x21) e bit 0x20 opt-in.
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
/// [scriptCode] scriptCode BIP-143 dell'input (per P2WPKH è il P2PKH script).
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

/// ScriptCode per il digest UNIFIED (BIP-143, script P2PKH dell'owner).
/// PERCHÉ: il builder di bitcoin_base usa senderPub.toAddress().toScriptPubKey()
/// sia per p2wpkh sia per p2wpkhInP2sh (vedi _findLockingScript) — deve essere
/// identico, altrimenti la firma non verifica.
Script _lockingScriptFor(UtxoWithAddress utxo) {
  return utxo.public().toAddress().toScriptPubKey();
}

/// ScriptPubKey REALE dell'output speso — per l'aggregato `sha_scripts`.
/// PERCHÉ: la spec committa gli scriptPubKey on-chain (0014... per P2WPKH,
/// a914...87 per P2SH-P2WPKH), NON lo scriptCode P2PKH derivato dalla chiave.
/// Il digest fallirebbe al nodo (mismatch su ogni input) se si usasse
/// _lockingScriptFor anche per l'aggregato.
Script _spentScriptFor(UtxoWithAddress utxo) {
  // PERCHÉ (BIP44): script type 0 → sha_scripts committa lo scriptPubKey
  // P2PKH reale (76a914…88ac), che coincide anche con lo scriptCode del
  // digest per questo tipo (nessuna firma incorporata da rimuovere).
  if (utxo.utxo.scriptType == P2pkhAddressType.p2pkh) {
    return utxo.ownerDetails.address.toScriptPubKey();
  }
  final segwit = utxo.public().toSegwitAddress().toScriptPubKey();
  if (utxo.utxo.scriptType == P2shAddressType.p2wpkhInP2sh) {
    return P2shAddress.fromScript(
      script: segwit,
      type: P2shAddressType.p2wpkhInP2sh,
    ).toScriptPubKey();
  }
  return segwit;
}

/// Costruisce e firma una transazione P2WPKH/P2SH-P2WPKH con SIGHASH_UNIFIED.
///
/// Sostituisce il flusso del builder standard (BIP-143) di bitcoin_base: la
/// transazione viene costruita manualmente (stesso BIP-69 ordering e stesso
/// montaggio witness/scriptSig) ma ogni input è firmato col digest UNIFIED.
///
/// [privateKeysByPublicKey] mappa publicKey hex → ECPrivate (come nel builder).
/// [fee] fee della transazione in satoshi: viene verificato che
/// sum(outputs) + fee == sum(inputs), come faceva il builder di bitcoin_base.
String buildAndSignUnifiedTx({
  required List<UtxoWithAddress> utxoWithAddresses,
  required List<BitcoinOutput> outputs,
  required Map<String, ECPrivate> privateKeysByPublicKey,
  required BigInt fee,

  /// Se true imposta su OGNI input la sequence RBF opt-in (0xfffffffd)
  /// PRIMA della firma: il digest UNIFIED committa `hashSequences`, quindi
  /// sequence in firma == sequence serializzata. Default false per non
  /// alterare i vettori di test esistenti.
  bool enableRBF = false,
}) {
  // STEP: 1 — ordina gli input BIP-69 (identico al builder _buildInputs)
  final ordered = List<UtxoWithAddress>.from(utxoWithAddresses)
    ..sort((a, b) {
      final c = a.utxo.txHash.compareTo(b.utxo.txHash);
      return c != 0 ? c : a.utxo.vout - b.utxo.vout;
    });

  // STEP: 2 — costruisce la transazione base (scriptSig vuoto)
  // PERCHÉ (S8 RBF): con enableRBF la tx è replaceable (BIP125) — ogni input
  // porta sequence non-final. Il digest viene calcolato DOPO (STEP 4) quindi
  // committa la sequence effettiva serializzata.
  final inputs = ordered
      .map((e) => e.utxo.toInput(enableRBF ? kReplaceByFeeSequence : null))
      .toList();
  final txOutputs = outputs.map((e) => e.toOutput).toList();
  final tx = BtcTransaction(inputs: inputs, outputs: txOutputs);

  // STEP: 3 — aggregati per il digest (ordine BIP-69 degli input)
  final spentAmounts = ordered.map((e) => e.utxo.value).toList();
  // PERCHÉ: sha_scripts committa gli scriptPubKey REALI degli output spesi
  // (0014.../a914...87), mentre lo scriptCode P2PKH (76a914...88ac) va solo in
  // coda al messaggio. Usare lo stesso script per entrambi rende il digest
  // diverso da quello del nodo → firma sempre invalida.
  final spentScripts = ordered.map((e) => _spentScriptFor(e)).toList();

  // PERCHÉ: verifica di coerenza input/output/fee (identica al builder
  // originale) — evita di serializzare una tx con fee implicito diverso.
  final sumInputs = spentAmounts.fold(BigInt.zero, (p, a) => p + a);
  final sumOutputs = txOutputs.fold(BigInt.zero, (p, o) => p + o.amount);
  if (sumOutputs + fee != sumInputs) {
    throw StateError(
      'Somma input/output non coerente con la fee: '
      'inputs=$sumInputs outputs=$sumOutputs fee=$fee',
    );
  }

  // STEP: 4 — firma ogni input col digest UNIFIED
  // PERCHÉ (BIP44): ogni input usa il proprio script_type (0 legacy P2PKH,
  // 1 segwit v0) e il proprio scriptCode; tutte le firme sono 0x21 = ALL|UNIFIED
  // (bit 0x20 opt-in di replay protection, come da spec).
  final hasSegwit = ordered.any((e) => e.utxo.isSegwit);
  final witnesses = <TxWitnessInput>[];
  for (var i = 0; i < ordered.length; i++) {
    final e = ordered[i];
    final isLegacy = !e.utxo.isSegwit;
    // scriptCode: per segwit v0 è il P2PKH derivato (BIP143); per legacy è lo
    // scriptPubKey P2PKH reale dell'output speso.
    final scriptCode = isLegacy ? _spentScriptFor(e) : _lockingScriptFor(e);
    final digest = computeUnifiedSighash(
      tx: tx,
      txInIndex: i,
      scriptCode: scriptCode,
      spentAmounts: spentAmounts,
      spentScripts: spentScripts,
      scriptType: isLegacy ? 0 : 1,
    );
    final signer = privateKeysByPublicKey[e.ownerDetails.publicKey!];
    if (signer == null) {
      throw StateError('Chiave privata non trovata per input $i.');
    }
    // PERCHÉ: sighash 0x21 = ALL|UNIFIED; signECDSA appende il byte alla firma
    final sig = signer.signECDSA(digest, sighash: kSighashAllUnified);
    if (isLegacy) {
      // PERCHÉ (BIP44): script type 0 → la firma va in scriptSig come push
      // [sig, pubkey] (niente witness). Serve la witness vuota solo se la tx
      // contiene anche input segwit (allineamento del formato witness).
      inputs[i].scriptSig =
          Script(script: [sig, e.ownerDetails.publicKey!]);
      if (hasSegwit) {
        witnesses.add(TxWitnessInput(stack: []));
      }
    } else {
      witnesses.add(TxWitnessInput(stack: [sig, e.ownerDetails.publicKey!]));
    }
  }

  // STEP: 5 — scriptSig per gli input P2SH-P2WPKH (redeemScript segwit)
  // PERCHÉ: il witness contiene [sig, pubkey]; lo scriptSig del nested segwit
  // deve contenere il segwit script (0014<hash>) per retro-compatibilità
  // (stesso comportamento di _addUnlockScriptScript del builder).
  for (var i = 0; i < ordered.length; i++) {
    final e = ordered[i];
    if (e.utxo.scriptType == P2shAddressType.p2wpkhInP2sh) {
      final redeem = e.public().toSegwitAddress().toScriptPubKey().toHex();
      inputs[i].scriptSig = Script(script: [redeem]);
    }
  }

  // STEP: 6 — monta witness (solo se la tx è segwit) e serializza
  // PERCHÉ (BIP44): una transazione tutta legacy non deve portare il marker
  // witness (0x0001): si serializza come tx classica senza witness.
  final txFinal = hasSegwit ? tx.copyWith(witnesses: witnesses) : tx;
  return txFinal.toHex();
}
