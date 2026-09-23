import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:pointycastle/digests/ripemd160.dart';

import '../../config/bitcoin_network_config.dart';
import '../unified_sighash.dart';
import 'unified_psbt_signer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PSBT (P4 — M0): crea / firma / finalizza su chain bitcoin-blake2b
// ─────────────────────────────────────────────────────────────────────────────
// // FLOW: PSBT a due dispositivi (watch-only ↔ hot)
// // STEP: 1 create (solo chiavi pubbliche) → 2 export base64 (QR/file)
// // STEP: 3 sign (il seed NON lascia il dispositivo) → 4 finalize + broadcast
//
// PERCHÉ le entry si scrivono a mano: il signer della libreria calcola un
// digest BIP-143 e verifica la firma; qui il digest è SIGHASH_UNIFIED
// (`unified_sighash.dart`, 166 vettori ufficiali). Vedi `unified_psbt_signer.dart`.
//
// SCOPE M0 (dichiarato, non implicito):
// - input supportati: **solo segwit v0 P2WPKH** (BIP84). Gli input legacy
//   richiedono `PSBT_IN_NON_WITNESS_UTXO` (la tx precedente COMPLETA) e i
//   P2SH-P2WPKH richiedono il redeemScript: entrambi rifiutati esplicitamente.
// - nessuna UI qui: questo file è pura logica, testabile senza widget.

/// Un output di una PSBT, in forma leggibile per la revisione umana.
class PsbtOutputSummary {
  const PsbtOutputSummary({required this.address, required this.amount});

  /// Indirizzo di destinazione (null se lo script non ne ha uno, es. OP_RETURN).
  final String? address;

  /// Importo in satoshi.
  final BigInt amount;
}

/// Riepilogo di una PSBT: **tutto** ciò che l'utente deve vedere prima di
/// firmare (mai firmare alla cieca — pilastro "sicurezza first").
class PsbtSummary {
  const PsbtSummary({
    required this.inputSats,
    required this.outputs,
    required this.totalInputs,
    required this.signableInputs,
  });

  final BigInt inputSats;
  final List<PsbtOutputSummary> outputs;
  final int totalInputs;

  /// Input per cui la PSBT dichiara una derivazione BIP32 (firmabili).
  final int signableInputs;

  BigInt get outputSats =>
      outputs.fold(BigInt.zero, (sum, o) => sum + o.amount);

  /// Fee che verrà pagata (input − output).
  BigInt get feeSats => inputSats - outputSats;
}

/// Crea una PSBT (BIP-174 v0) NON firmata.
///
/// [utxoWithAddresses] vengono ordinati BIP-69 esattamente come
/// `buildAndSignUnifiedTx` (stesso ordine = stessa transazione = test di
/// equivalenza possibile).
/// [fee] è in satoshi e viene verificato: `Σ output + fee == Σ input`.
/// [bip32DerivationByPublicKey] è opzionale (chiave = pubkey hex): senza,
/// la PSBT resta firmabile solo da chi conosce già i path (nostro caso M0).
String createPsbtBase64({
  required List<UtxoWithAddress> utxoWithAddresses,
  required List<BitcoinOutput> outputs,
  required BigInt fee,
  bool enableRBF = true,
  Map<String, PsbtInputBip32DerivationPath>? bip32DerivationByPublicKey,
}) {
  if (utxoWithAddresses.isEmpty) {
    throw StateError('PSBT: nessun input (nessun UTXO selezionato).');
  }
  if (outputs.isEmpty) {
    throw StateError('PSBT: nessun output.');
  }

  // STEP: 1 — ordine input BIP-69 (identico al builder UNIFIED)
  final ordered = List<UtxoWithAddress>.from(utxoWithAddresses)
    ..sort((a, b) {
      final byHash = a.utxo.txHash.compareTo(b.utxo.txHash);
      return byHash != 0 ? byHash : a.utxo.vout - b.utxo.vout;
    });

  final builder = PsbtBuilderV0.create();

  // STEP: 2 — input: witnessUtxo = l'output SPESO reale (script on-chain)
  var inputSats = BigInt.zero;
  for (final utxo in ordered) {
    if (utxo.utxo.scriptType != SegwitAddressType.p2wpkh) {
      throw StateError(
        'PSBT M0: supportati solo input P2WPKH (segwit v0). '
        'Tipo riscontrato: ${utxo.utxo.scriptType}.',
      );
    }
    builder.addInput(
      PsbtTransactionInput.witnessV0(
        outIndex: utxo.utxo.vout,
        txId: utxo.utxo.txHash,
        amount: utxo.utxo.value,
        scriptPubKey: spentScriptFor(utxo),
        sequence: enableRBF ? kReplaceByFeeSequence : null,
        bip32derivationPath: <PsbtInputBip32DerivationPath>[
          if (bip32DerivationByPublicKey?[utxo.ownerDetails.publicKey]
              case final derivation?)
            derivation,
        ],
      ),
    );
    inputSats += utxo.utxo.value;
  }

  // STEP: 3 — output, nell'ordine ricevuto (destinatari, poi change)
  for (final output in outputs) {
    builder.addOutput(
      PsbtTransactionOutput.witnessV0(
        amount: output.value,
        address: output.address,
      ),
    );
  }

  // STEP: 4 — chiusura comune (fee, locktime, serializzazione)
  return _finishPsbt(builder, inputSats, outputs, fee, enableRBF);
}

/// Input di una PSBT descritto dai dati on-chain: **nessuna chiave privata**.
///
/// // PERCHÉ: è la forma che serve a un wallet watch-only (solo xpub) per
/// costruire una PSBT — gli input arrivano dalla scansione della rete
/// (`UtxoInfo`), non dalla derivazione di chiavi.
class PsbtInputSpec {
  const PsbtInputSpec({
    required this.txid,
    required this.vout,
    required this.valueSats,
    required this.scriptPubKeyHex,
    required this.publicKeyHex,
    this.derivationPath,
  });

  final String txid;
  final int vout;
  final int valueSats;

  /// scriptPubKey REALE dell'output speso (`0014…` per P2WPKH).
  /// Usato come **verifica**: l'hash160 deve corrispondere a [publicKeyHex].
  final String scriptPubKeyHex;

  /// Path BIP32 dell'input (es. `m/84'/0'/0'/0/3`), se noto: diventa il
  /// metadato `PSBT_IN_BIP32_DERIVATION` che dice al firmatario quale chiave
  /// usare.
  final String? derivationPath;

  /// Pubkey compressa hex dell'input (obbligatoria).
  ///
  /// // PERCHÉ è la fonte dello script: la libreria riconosce solo gli script
  /// prodotti dalle proprie API di indirizzo (`ECPublic.toSegwitAddress()`),
  /// non quelli costruiti byte-a-byte. [scriptPubKeyHex] resta come controllo
  /// di coerenza indipendente (hash160), che è la protezione che conta.
  final String publicKeyHex;
}

/// Crea una PSBT (BIP-174 v0) NON firmata da input descritti on-chain.
///
/// // PERCHÉ esiste accanto a [createPsbtBase64]: quest'ultima richiede
/// `UtxoWithAddress` (chiavi pubbliche derivate), mentre un wallet watch-only
/// conosce solo gli UTXO letti dalla rete. Entrambe convergono su
/// [_finishPsbt], quindi fee/ordine/locktime restano identici.
String createPsbtFromInputs({
  required List<PsbtInputSpec> inputs,
  required List<BitcoinOutput> outputs,
  required BigInt fee,
  bool enableRBF = true,
  List<int>? masterFingerprint,
}) {
  if (inputs.isEmpty) {
    throw StateError('PSBT: nessun input (nessun UTXO selezionato).');
  }
  if (outputs.isEmpty) {
    throw StateError('PSBT: nessun output.');
  }

  final builder = PsbtBuilderV0.create();
  final ordered = List<PsbtInputSpec>.from(inputs)
    ..sort((a, b) {
      final byHash = a.txid.compareTo(b.txid);
      return byHash != 0 ? byHash : a.vout - b.vout;
    });

  var inputSats = BigInt.zero;
  for (final input in ordered) {
    final scriptHex = input.scriptPubKeyHex.toLowerCase();
    // // PERCHÉ controllo di forma esplicito: uno script P2WPKH è ESATTAMENTE
    // `0014` + 20 byte (44 caratteri). Un input con hex troncato/corrotto deve
    // fallire QUI, con un messaggio che dice quale input è il problema.
    if (scriptHex.length != 44 || !scriptHex.startsWith('0014')) {
      throw StateError(
        'PSBT M0: serve uno script P2WPKH (`0014` + 20 byte) per l input '
        '${input.txid}:${input.vout}; ricevuto un hex di ${scriptHex.length} '
        'caratteri: ${input.scriptPubKeyHex}',
      );
    }
    final publicKeyBytes = BytesUtils.fromHexString(input.publicKeyHex);
    final publicKey = ECPublic.fromBytes(publicKeyBytes);
    // // PERCHÉ verifica di proprietà: l'hash160 della chiave che stiamo
    // mettendo nella PSBT deve essere QUELLO dello script on-chain. Se non
    // coincidono, l'input non è nostro (o l'API ha restituito dati stantii):
    // firmarlo produrrebbe una transazione non valida.
    if (_pubKeyHash160Hex(publicKey) != scriptHex.substring(4)) {
      throw StateError(
        'PSBT: lo script on-chain dell input ${input.txid}:${input.vout} non '
        'corrisponde alla chiave indicata — input non spendibile da questa '
        'chiave.',
      );
    }
    builder.addInput(
      PsbtTransactionInput.witnessV0(
        outIndex: input.vout,
        txId: input.txid,
        amount: BigInt.from(input.valueSats),
        scriptPubKey: publicKey.toSegwitAddress().toScriptPubKey(),
        sequence: enableRBF ? kReplaceByFeeSequence : null,
        bip32derivationPath: <PsbtInputBip32DerivationPath>[
          if (_derivationFor(input, masterFingerprint) case final derivation?)
            derivation,
        ],
      ),
    );
    inputSats += BigInt.from(input.valueSats);
  }

  for (final output in outputs) {
    builder.addOutput(
      PsbtTransactionOutput.witnessV0(
        amount: output.value,
        address: output.address,
      ),
    );
  }

  return _finishPsbt(builder, inputSats, outputs, fee, enableRBF);
}

/// Metadato BIP32 per un input, se path e pubkey sono noti (e c'è il fingerprint
/// del master: senza, la derivazione non è verificabile dal firmatario).
PsbtInputBip32DerivationPath? _derivationFor(
  PsbtInputSpec input,
  List<int>? masterFingerprint,
) {
  final path = input.derivationPath;
  if (path == null || masterFingerprint == null) {
    return null;
  }
  if (masterFingerprint.length != 4) return null;
  try {
    return PsbtInputBip32DerivationPath(
      fingerprint: masterFingerprint,
      indexes: Bip32PathParser.parse(path).elems,
      publicKey: BytesUtils.fromHexString(input.publicKeyHex),
    );
  } catch (_) {
    // // PERCHÉ fallback silenzioso ma esplicito: un path malformato non deve
    // impedire la creazione della PSBT (la firma funziona anche dal
    // witnessUtxo); il metadato è un di più, non un requisito.
    return null;
  }
}

/// Chiusura comune della creazione: controllo fee, correzione locktime, base64.
String _finishPsbt(
  PsbtBuilderV0 builder,
  BigInt inputSats,
  List<BitcoinOutput> outputs,
  BigInt fee,
  bool enableRBF,
) {
  final outputSats = outputs.fold(BigInt.zero, (sum, o) => sum + o.value);
  // // PERCHÉ: serializzare una PSBT con fee implicito diverso da quello
  // mostrato all'utente sarebbe la prima causa di spesa "onesta" sbagliata.
  if (outputSats + fee != inputSats) {
    throw StateError(
      'Somma input/output non coerente con la fee: '
      'inputs=$inputSats outputs=$outputSats fee=$fee',
    );
  }
  if (kDebugMode) {
    debugPrint(
      '[LoopEngineer] PSBT creata: ${builder.psbtInputs().length} input, '
      '${outputs.length} output, fee=$fee sat, RBF=$enableRBF',
    );
  }
  return _withDefaultLocktime(builder.toBase64(), builder);
}

/// Ripristina nLockTime = 0 (default) sulla PSBT appena creata.
///
/// // PERCHÉ (bug della libreria, bitcoin_base 7.0.0): `addInput` deriva il
/// locktime dalle sequence (`PsbtUtils.getCurrentInputslocktime`) e interpreta
/// `0xfffffffd` — la sequence RBF, con bit 31 settato = NESSUN relative
/// locktime BIP68 — come un relative locktime, scrivendo `nLockTime =
/// 0xfffffffd` nella transazione. Una tx con nLockTime nel futuro (2106) NON è
/// final e verrebbe **rifiutata dal nodo** al broadcast: silenzioso in locale,
/// fatale in uso reale.
/// La correzione usa solo API pubbliche: `Psbt.fromBase64` → si sostituisce
/// l'entry della transazione non firmata → `toBase64`.
String _withDefaultLocktime(String psbtBase64, PsbtBuilderV0 builder) {
  final unsignedTx = builder.buildUnsignedTransaction();
  if (BytesUtils.toHexString(unsignedTx.locktime) == '00000000') {
    return psbtBase64;
  }

  final psbt = Psbt.fromBase64(psbtBase64);
  final globals = <PsbtGlobalData>[
    for (final entry in psbt.global.entries)
      if (entry is PsbtGlobalUnsignedTransaction)
        PsbtGlobalUnsignedTransaction(
          unsignedTx.copyWith(
            locktime: BitcoinOpCodeConst.defaultTxLocktime,
          ),
        )
      else
        entry,
  ];
  final fixed = Psbt(
    global: PsbtGlobal(version: psbt.global.version, entries: globals),
    input: psbt.input,
    output: psbt.output,
  );
  if (kDebugMode) {
    debugPrint(
      '[LoopEngineer] PSBT: locktime corretto da '
      '${BytesUtils.toHexString(unsignedTx.locktime)} a 00000000',
    );
  }
  return fixed.toBase64();
}

/// Firma TUTTI gli input con SIGHASH_UNIFIED (`0x21`).
///
/// [privateKeysByPublicKey] mappa pubkey hex → chiave privata: il seed resta
/// nel dispositivo che firma e non viene mai scritto nella PSBT.
/// La chiave di ogni input viene scelta tramite la derivazione BIP32 dichiarata
/// nella PSBT stessa (è il meccanismo standard: l'input "sa" da quale path
/// proviene).
String signPsbtBase64({
  required String psbtBase64,
  required Map<String, ECPrivate> privateKeysByPublicKey,
}) {
  final builder = PsbtBuilder.fromBase64<PsbtBuilderV0>(psbtBase64);
  final inputs = builder.psbtInputs();
  // // PERCHÉ: la transazione non firmata è calcolata UNA volta e riusata per
  // ogni digest — è anche il riferimento del self-check finale.
  final tx = builder.buildUnsignedTransaction();
  final unsignedHexBefore = tx.toHex();

  // STEP: 1 — aggregati del digest: TUTTI gli input, ordine della transazione
  final spentAmounts = <BigInt>[];
  final spentScripts = <Script>[];
  for (var i = 0; i < inputs.length; i++) {
    final witnessUtxo = inputs[i].witnessUtxo;
    if (witnessUtxo == null) {
      throw StateError(
        'PSBT: input $i senza witnessUtxo — input legacy o PSBT non valida.',
      );
    }
    spentAmounts.add(witnessUtxo.amount);
    spentScripts.add(witnessUtxo.scriptPubKey);
  }

  // STEP: 2 — firma UNIFIED di ogni input tramite l'hook `signInput`.
  //
  // // PERCHÉ l'hook e non la costruzione manuale delle entry: in
  // bitcoin_base 7.0.0 `toPsbtInputs()` non include `partialSigs` e
  // `updateInput()` non scrive entry — `signInput` è l'unico percorso che le
  // serializza davvero. Il digest BIP-143 che la libreria calcola internamente
  // e passa al signer viene IGNORATO da [UnifiedPsbtSigner], che firma il
  // digest UNIFIED; `createSignature` non verifica crittograficamente (non
  // riceve il digest), quindi il valore di `sighash` serve solo a dichiarare
  // 0x21 nell'entry PSBT_IN_SIGHASH_TYPE.
  for (var i = 0; i < inputs.length; i++) {
    final input = inputs[i];
    final publicKeyHex = _publicKeyForSigning(
      input,
      privateKeysByPublicKey,
      index: i,
    );
    final key = privateKeysByPublicKey[publicKeyHex]!;
    final digest = unifiedPsbtDigest(
      tx: tx,
      index: i,
      scriptCode: unifiedScriptCodeForPubkey(key.getPublic()),
      spentAmounts: spentAmounts,
      spentScripts: spentScripts,
    );
    builder.signInput(
      index: i,
      signer: (params) => PsbtSignerResponse(
        signers: <PsbtBtcSigner>[
          UnifiedPsbtSigner(privateKey: key, unifiedDigest: digest),
        ],
        sighash: kSighashAllUnified,
      ),
    );
  }

  // STEP: 3 — self-check fail-fast
  // // PERCHÉ: la transazione NON firmata non deve cambiare durante la firma. Se
  // cambiasse (es. per una diversa interpretazione dell'outpoint) il txid
  // firmato non corrisponderebbe più a quello revisionato dall'utente. Meglio
  // un'eccezione qui che una firma inutile al broadcast.
  final unsignedHexAfter = builder.buildUnsignedTransaction().toHex();
  if (unsignedHexBefore != unsignedHexAfter) {
    throw StateError(
      'PSBT: la firma ha modificato la transazione non firmata. '
      'prima=$unsignedHexBefore dopo=$unsignedHexAfter',
    );
  }

  if (kDebugMode) {
    debugPrint('[LoopEngineer] PSBT firmata: ${inputs.length} input UNIFIED');
  }
  return builder.toBase64();
}

/// Finalizza una PSBT firmata e restituisce l'hex pronto per il broadcast.
///
/// // PERCHÉ la finalizzazione è NOSTRA (hook `onFinalizeInput`) e non quella
/// interna della libreria: `PsbtUtils._finalizeNonScriptSpent` cerca l'hash160
/// della pubkey come STRINGA esadecimale dentro `script.script` (lista di byte)
/// → `indexOf` non trova mai nulla e ogni input P2WPKH/P2PKH viene rifiutato
/// con "Signature public key does not match the scriptPubKey" (verificato su
/// bitcoin_base 7.0.0). L'hook è il punto di estensione previsto dalla
/// libreria: forniamo noi il witness, che è esattamente ciò che il builder
/// diretto già monta in produzione.
String finalizePsbtToTxHex(String psbtBase64) {
  final builder = PsbtBuilder.fromBase64<PsbtBuilderV0>(psbtBase64);
  final hex = builder
      .finalizeAll(
        onFinalizeInput: (params) => _finalizeWitnessV0(params),
      )
      .toHex();
  if (kDebugMode) {
    debugPrint('[LoopEngineer] PSBT finalizzata: ${hex.length ~/ 2} byte');
  }
  return hex;
}

/// Witness P2WPKH = `[firma, pubkey]` — identico a `buildAndSignUnifiedTx`.
///
/// // PERCHÉ: la firma contiene già il byte sighash 0x21 (appendato da
/// `signECDSA`): il witness va montato così com'è, senza riserializzare.
PsbtFinalizeResponse _finalizeWitnessV0(PsbtFinalizeParams params) {
  final input = params.inputData;
  final scriptHex = input.scriptPubKey.toHex();
  if (scriptHex.length != 44 || !scriptHex.startsWith('0014')) {
    // P2SH-P2WPKH richiede anche il redeemScript nello scriptSig: fuori M0.
    throw StateError(
      'PSBT: finalizzazione M0 supportata solo per input P2WPKH '
      '(input ${params.index}, script ${input.scriptPubKey}).',
    );
  }
  final partialSigs = input.partialSigs ?? const <PsbtInputPartialSig>[];
  if (partialSigs.isEmpty) {
    throw StateError('PSBT: input ${params.index} senza firma — non firmata.');
  }
  final signature = partialSigs.first;
  return PsbtFinalizeResponse(
    finalizeInput: PsbtFinalizeInput(
      witness: TxWitnessInput(
        stack: <String>[signature.signatureHex(), signature.publicKey.toHex()],
      ),
    ),
  );
}

/// Riepilogo per la revisione umana (destinatari, importi, fee).
PsbtSummary summarizePsbt(String psbtBase64) {
  final builder = PsbtBuilder.fromBase64<PsbtBuilderV0>(psbtBase64);
  final inputs = builder.psbtInputs();

  var inputSats = BigInt.zero;
  var signable = 0;
  for (final input in inputs) {
    inputSats += input.witnessUtxo?.amount ?? BigInt.zero;
    if (input.bip32derivationPath?.isNotEmpty ?? false) signable++;
  }

  final outputs = <PsbtOutputSummary>[
    for (final output in builder.psbtOutputs())
      PsbtOutputSummary(
        // // PERCHÉ: `BitcoinBaseAddress` espone `toAddress(network)`, non un
        // getter: serve la rete configurata per rendere la stringa.
        address: output.address?.toAddress(
          BitcoinNetworkConfig.bitcoinBaseNetwork,
        ),
        amount: output.amount,
      ),
  ];

  return PsbtSummary(
    inputSats: inputSats,
    outputs: outputs,
    totalInputs: inputs.length,
    signableInputs: signable,
  );
}

/// Pubkey hex dell'input, scelta tra le derivazioni BIP32 dichiarate.
///
/// // PERCHÉ: un input può dichiarare più derivazioni (multisig); qui si prende
/// la prima di cui il firmatario possiede la chiave, altrimenti si fallisce
/// con un messaggio che dice esattamente quale input è il problema.
String _publicKeyForSigning(
  PsbtTransactionInput input,
  Map<String, ECPrivate> privateKeysByPublicKey, {
  required int index,
}) {
  // 1) Strada standard: la derivazione BIP32 scritta nella PSBT.
  final derivations =
      input.bip32derivationPath ?? const <PsbtInputBip32DerivationPath>[];
  for (final derivation in derivations) {
    final hex = BytesUtils.toHexString(derivation.publicKey);
    if (privateKeysByPublicKey.containsKey(hex)) return hex;
  }

  // 2) Fallback: uno script P2WPKH (0014<hash160>) contiene l'impronta della
  // chiave — si riconosce la nostra senza bisogno di metadati di derivazione.
  // // PERCHÉ: una PSBT può arrivare da un altro strumento (o da una versione
  // precedente) senza bip32Derivation: rifiutarla sarebbe una limitazione
  // gratuita quando l'informazione è già nello script.
  final scriptHex = input.witnessUtxo?.scriptPubKey.toHex() ?? '';
  if (scriptHex.length == 44 && scriptHex.startsWith('0014')) {
    final expectedHash = scriptHex.substring(4);
    for (final entry in privateKeysByPublicKey.entries) {
      if (_pubKeyHash160Hex(entry.value.getPublic()) == expectedHash) {
        return entry.key;
      }
    }
  }

  throw StateError(
    'PSBT: input $index — nessuna chiave nota al firmatario '
    '(derivazioni dichiarate: ${derivations.length}).',
  );
}

/// HASH160 (sha256→ripemd160) esadecimale di una chiave pubblica compressa.
/// // PERCHÉ: identico a `_pubKeyHash160Hex` di `bitcoin_service.dart` — se i
/// due calcoli divergessero, un wallet non riconoscerebbe i propri input.
String _pubKeyHash160Hex(ECPublic publicKey) {
  final sha =
      crypto.sha256.convert(BytesUtils.fromHexString(publicKey.toHex())).bytes;
  final ripemd = RIPEMD160Digest();
  final hash = ripemd.process(Uint8List.fromList(sha));
  return hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// ScriptPubKey REALE dell'output speso (0014… per P2WPKH).
///
/// // PERCHÉ: `sha_scripts` del digest UNIFIED committa gli scriptPubKey
/// on-chain, NON lo scriptCode P2PKH derivato dalla chiave (vedi
/// `unified_sighash.dart` `_spentScriptFor`). Duplicazione minima e
/// intenzionale per non toccare il file validato dai vettori ufficiali.
Script spentScriptFor(UtxoWithAddress utxo) {
  if (utxo.utxo.scriptType == P2shAddressType.p2wpkhInP2sh) {
    final segwit = utxo.public().toSegwitAddress().toScriptPubKey();
    return P2shAddress.fromScript(
      script: segwit,
      type: P2shAddressType.p2wpkhInP2sh,
    ).toScriptPubKey();
  }
  return utxo.public().toSegwitAddress().toScriptPubKey();
}
