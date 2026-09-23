import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../unified_sighash.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FIRMA UNIFIED di un input PSBT (P4 — M0)
// ─────────────────────────────────────────────────────────────────────────────
// PERCHÉ: il percorso di firma della libreria (`PsbtBuilder.signInput`) calcola
// un digest BIP-143/BIP-341 e VERIFICA la firma prodotta. Sulla chain
// bitcoin-blake2b il digest è SIGHASH_UNIFIED (SHA-256 taggato, non
// double-SHA256): una firma UNIFIED non supera quella verifica, quindi il
// signer della libreria non è utilizzabile. Qui il digest lo calcola
// `unified_sighash.dart` — lo STESSO codice validato dai vettori ufficiali
// SIGHASH_UNIFIED — e le entry PSBT si scrivono a mano in `psbt_service.dart`.

/// Digest UNIFIED per l'input [index] di una transazione segwit v0.
///
/// // PERCHÉ `scriptType` fisso a 1 (WITNESS_V0): in M0 sono supportati solo
/// input P2WPKH. Gli input legacy richiedono `PSBT_IN_NON_WITNESS_UTXO` (la
/// transazione precedente COMPLETA, non solo l'output): fuori scope M0 e
/// rifiutati esplicitamente in `psbt_service.dart`.
List<int> unifiedPsbtDigest({
  required BtcTransaction tx,
  required int index,
  required Script scriptCode,
  required List<BigInt> spentAmounts,
  required List<Script> spentScripts,
}) {
  return computeUnifiedSighash(
    tx: tx,
    txInIndex: index,
    scriptCode: scriptCode,
    spentAmounts: spentAmounts,
    spentScripts: spentScripts,
    scriptType: 1,
  );
}

/// ScriptCode BIP-143 per un input segwit v0: il P2PKH derivato dalla chiave.
///
/// // PERCHÉ: deve restare identico a `_lockingScriptFor` di
/// `unified_sighash.dart` (`utxo.public().toAddress().toScriptPubKey()`). Se i
/// due percorsi divergessero, la firma PSBT sarebbe "valida" in locale ma
/// rifiutata dal nodo — l'errore più costoso possibile su questo file.
Script unifiedScriptCodeForPubkey(ECPublic publicKey) =>
    publicKey.toAddress().toScriptPubKey();

/// Firma [digest] con SIGHASH_ALL|UNIFIED (0x21).
///
/// // PERCHÉ: `signECDSA` appende il byte sighash alla firma DER (verificato:
/// `ec_private.dart` `if (sighash != null) signature = [...signature, sighash]`).
/// È deterministico (RFC 6979, nessuna entropia extra): lo stesso input
/// produce la stessa firma, quindi lo stesso txid.
String unifiedSignDigest(ECPrivate key, List<int> digest) =>
    key.signECDSA(digest, sighash: kSighashAllUnified);

/// Signer UNIFIED per l'hook `PsbtBuilder.signInput`.
///
/// // PERCHÉ questo percorso: `signInput` è l'UNICO modo pubblico per scrivere
/// davvero una firma dentro la PSBT. In bitcoin_base 7.0.0:
/// - `PsbtTransactionInput.toPsbtInputs()` NON include `partialSigs` (quindi
///   ricostruire l'input con `addInput` perde la firma);
/// - `updateInput()` sostituisce solo il TxInput, senza entry.
/// `signInput` invece chiama la scrittura interna corretta.
/// Il digest BIP-143 che la libreria passa qui è IGNORATO: si firma
/// `unifiedDigest` (SIGHASH_UNIFIED della chain blake2b).
class UnifiedPsbtSigner
    implements PsbtBtcSigner<SignInputResponse, PsbtSigningInputDigest> {
  UnifiedPsbtSigner({required this.privateKey, required this.unifiedDigest});

  final ECPrivate privateKey;

  /// Digest SIGHASH_UNIFIED dell'input (da [unifiedPsbtDigest]).
  final List<int> unifiedDigest;

  @override
  late final ECPublic signerPublicKey = privateKey.getPublic();

  @override
  SignInputResponse btcSignInput(PsbtSigningInputDigest digest) {
    return SignInputResponse(
      signature: BytesUtils.fromHexString(
        unifiedSignDigest(privateKey, unifiedDigest),
      ),
      signerPublicKey: signerPublicKey,
    );
  }

  @override
  Future<SignInputResponse> btcSignInputAsync(
    PsbtSigningInputDigest digest,
  ) async =>
      btcSignInput(digest);
}
