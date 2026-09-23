import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../../config/bitcoin_network_config.dart';
import '../unified_sighash.dart';

/// Parametri dell'HTLC — tutte le stringhe sono hex SENZA prefisso '0x'.
class SwapScriptParams {
  const SwapScriptParams({
    required this.paymentHashHex, // 32B: SHA256(preimage) della invoice
    required this.claimPubkeyHex, // 33B: chiave del provider (compressa)
    required this.refundPubkeyHex, // 33B: chiave utente (m/84'/coin'/2'/0/x)
    required this.cltvHeight, // CLTV in blocchi (> 16)
  });

  final String paymentHashHex;
  final String claimPubkeyHex;
  final String refundPubkeyHex;
  final int cltvHeight;
}

/// Costruzione del witnessScript HTLC e del witness di refund (lato APP).
///
/// // PERCHÉ (P9): copia SPECULARE di `bridge/lib/src/swap/swap_script.dart`:
/// // i due lati devono produrre BYTE IDENTICI, altrimenti l'HTLC finanziato
/// // dall'app non sarebbe claimabile dal provider (o viceversa). I vettori di
/// // test (113 byte, cltv 972000 → `03 e0 d4 0e`) sono la guardia.
///
/// Template (stile Boltz, versione blake2b):
///
///     OP_IF
///         OP_SHA256 <payment_hash> OP_EQUALVERIFY
///         <claim_pubkey>
///     OP_ELSE
///         <cltv> OP_CHECKLOCKTIMEVERIFY OP_DROP
///         <refund_pubkey>
///     OP_ENDIF
///     OP_CHECKSIG
class SwapScripts {
  /// WitnessScript HTLC (byte attesi: 113).
  static Script witnessScript(SwapScriptParams p) {
    // PERCHÉ: bitcoin_base emette gli int ≤16 come OP_N e gli int >16 come
    // numero CScriptNum minimale: l'altezza CLTV reale è sempre >16, ma la
    // guardia rende esplicito il vincolo (script sbagliato = fondi bloccati).
    if (p.cltvHeight <= 16) {
      throw ArgumentError(
        'cltvHeight ≤ 16: bitcoin_base lo emette come OP_N, non come numero.',
      );
    }
    final paymentHash = BytesUtils.fromHexString(p.paymentHashHex);
    if (paymentHash.length != 32) {
      throw ArgumentError(
        'payment_hash: attesi 32 byte, trovati ${paymentHash.length}.',
      );
    }
    final claim = BytesUtils.fromHexString(p.claimPubkeyHex);
    final refund = BytesUtils.fromHexString(p.refundPubkeyHex);
    if (claim.length != 33 || refund.length != 33) {
      throw ArgumentError('pubkey: attese 33 byte (compresse).');
    }
    return Script(
      script: [
        BitcoinOpcode.opIf,
        BitcoinOpcode.opSha256,
        p.paymentHashHex,
        BitcoinOpcode.opEqualVerify,
        p.claimPubkeyHex,
        BitcoinOpcode.opElse,
        p.cltvHeight,
        BitcoinOpcode.opCheckLockTimeVerify,
        BitcoinOpcode.opDrop,
        p.refundPubkeyHex,
        BitcoinOpcode.opEndIf,
        BitcoinOpcode.opCheckSig,
      ],
    );
  }

  /// Indirizzo P2WSH (bech32 'bc1q…') del witnessScript.
  static String address(SwapScriptParams p) =>
      P2wshAddress.fromScript(script: witnessScript(p)).toAddress(
        BitcoinNetworkConfig.bitcoinBaseNetwork,
      );

  /// ScriptPubKey (hex, '0020…') del witnessScript.
  static String scriptPubKeyHex(SwapScriptParams p) => P2wshAddress.fromScript(
        script: witnessScript(p),
      ).toScriptPubKey().toHex();

  /// Witness di REFUND: [firma, item VUOTO (seleziona OP_ELSE), witnessScript].
  ///
  /// // PERCHÉ: l'item vuoto serializza come 0x00 e spinge un array vuoto che
  /// // OP_IF valuta falso → ramo temporale (CLTV), senza check sull'hash.
  static TxWitnessInput refundWitness({
    required String sigHex,
    required String witnessScriptHex,
  }) =>
      TxWitnessInput(stack: [sigHex, '', witnessScriptHex]);

  /// Confronta il witnessScript derivato dai parametri con quello dichiarato
  /// dal provider.
  ///
  /// // PERCHÉ: guardia PRIMA di firmare il funding — una quote manomessa
  /// // (script ≠ parametri) significa fondi potenzialmente irrecuperabili:
  /// // meglio fallire che finanziare un HTLC diverso da quello atteso.
  static bool matchesWitnessScriptHex(
    SwapScriptParams p,
    String witnessScriptHex,
  ) =>
      witnessScript(p).toHex().toLowerCase() == witnessScriptHex.toLowerCase();
}

/// vB stimati della tx di refund (1 input P2WSH + 1 output P2WPKH).
///
/// // PERCHÉ: costante usata per il fee; i test la verificano sul peso reale
/// // della tx costruita (stesso ordine di grandezza del claim provider).
const int kSwapRefundTxVbytes = 140;

/// Costruisce e firma la tx di REFUND (raw hex, NON trasmessa).
///
/// // FLOW: Pagamento LN via swap (P9) — app
/// // STEP: 5 (percorso di recupero) — dopo il CLTV, se il provider non ha
/// // claimato, l'utente spende l'HTLC col ramo OP_ELSE.
///
/// - input: outpoint del funding, sequence RBF (0xfffffffd, non-final);
/// - locktime: [SwapScriptParams.cltvHeight] (il nodo rifiuta la tx se
///   nLockTime < CLTV dello script);
/// - output: [destinationAddress] con importo − [feeSats];
/// - firma: SIGHASH_UNIFIED (0x21) sul digest del fork blake2b.
String buildSignedRefundTxHex({
  required ECPrivate refundKey,
  required SwapScriptParams scriptParams,
  required String witnessScriptHex,
  required String fundingTxid,
  required int fundingVout,
  required int fundingAmountSats,
  required String destinationAddress,
  required int feeSats,
}) {
  if (feeSats <= 0 || feeSats >= fundingAmountSats) {
    throw ArgumentError(
      'fee refund non valida: $feeSats su $fundingAmountSats',
    );
  }
  final script = SwapScripts.witnessScript(scriptParams);
  final derivedHex = script.toHex().toLowerCase();
  if (derivedHex != witnessScriptHex.toLowerCase()) {
    throw ArgumentError(
      'witnessScript dichiarato diverso da quello dei parametri '
      '(possibile quote manomessa).',
    );
  }
  final scriptPubKey = P2wshAddress.fromScript(
    script: script,
  ).toScriptPubKey();

  final tx = BtcTransaction(
    inputs: [
      TxInput(
        txId: fundingTxid,
        txIndex: fundingVout,
        sequance: kReplaceByFeeSequence,
      ),
    ],
    outputs: [
      BitcoinOutput(
        address: BitcoinAddress(
          destinationAddress,
          network: BitcoinNetworkConfig.bitcoinBaseNetwork,
        ).baseAddress,
        value: BigInt.from(fundingAmountSats - feeSats),
      ).toOutput,
    ],
    locktime: IntUtils.toBytes(
      scriptParams.cltvHeight,
      length: 4,
      byteOrder: Endian.little,
    ),
  );

  // PERCHÉ: il digest UNIFIED committa locktime e hashSequences — la firma
  // vale SOLO per questa tx (scriptCode = witnessScript, spentScript = la
  // P2WSH reale dell'HTLC).
  final digest = computeUnifiedSighash(
    tx: tx,
    txInIndex: 0,
    scriptCode: script,
    spentAmounts: [BigInt.from(fundingAmountSats)],
    spentScripts: [scriptPubKey],
    scriptType: 1,
  );
  final sigHex = refundKey.signECDSA(digest, sighash: kSighashAllUnified);

  final signed = tx.copyWith(
    witnesses: [
      SwapScripts.refundWitness(
        sigHex: sigHex,
        witnessScriptHex: derivedHex,
      ),
    ],
  );
  return signed.toHex();
}
