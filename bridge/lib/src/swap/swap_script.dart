import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

/// Parametri dell'HTLC — tutte le stringhe sono hex SENZA prefisso '0x'.
class SwapScriptParams {
  const SwapScriptParams({
    required this.paymentHashHex, // 32B: SHA256(preimage) della invoice
    required this.claimPubkeyHex, // 33B: chiave del provider (compressa)
    required this.refundPubkeyHex, // 33B: chiave utente (m/84'/0'/2'/0/x)
    required this.cltvHeight, // CLTV in blocchi (> 16)
  });

  final String paymentHashHex;
  final String claimPubkeyHex;
  final String refundPubkeyHex;
  final int cltvHeight;
}

/// Costruzione del witnessScript HTLC e dei witness di claim/refund.
///
/// PERCHÉ (P9): copia speculare in `mobile/lib/core/services/swap/swap_script.dart`
/// — i due lati devono produrre BYTE IDENTICI; i vettori in
/// `bridge/test/swap_script_test.dart` e nel test dell'app fanno da guardia.
class SwapScripts {
  /// WitnessScript HTLC (template stile Boltz, versione blake2b):
  ///
  ///     OP_IF
  ///         OP_SHA256 <payment_hash> OP_EQUALVERIFY
  ///         <claim_pubkey>
  ///     OP_ELSE
  ///         <cltv> OP_CHECKLOCKTIMEVERIFY OP_DROP
  ///         <refund_pubkey>
  ///     OP_ENDIF
  ///     OP_CHECKSIG
  ///
  /// Byte attesi (hash 32B + pubkey 33B + cltv 3B): 113 byte.
  static Script witnessScript(SwapScriptParams p) {
    // PERCHÉ: bitcoin_base emette gli int ≤16 come OP_N e gli int >16 come
    // numero CScriptNum minimale: l'altezza CLTV reale è sempre >16, ma la
    // guardia rende esplicito il vincolo (uno script sbagliato qui = fondi
    // bloccati fino al timeout).
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
  static String address(SwapScriptParams p, BasedUtxoNetwork network) =>
      P2wshAddress.fromScript(script: witnessScript(p)).toAddress(network);

  /// ScriptPubKey (hex, '0020…') del witnessScript.
  static String scriptPubKeyHex(SwapScriptParams p) => P2wshAddress.fromScript(
        script: witnessScript(p),
      ).toScriptPubKey().toHex();

  /// Witness di CLAIM: [firma, preimage, 0x01 (selettore OP_IF), witnessScript].
  static TxWitnessInput claimWitness({
    required String sigHex,
    required String preimageHex,
    required String witnessScriptHex,
  }) =>
      TxWitnessInput(stack: [sigHex, preimageHex, '01', witnessScriptHex]);

  /// Witness di REFUND: [firma, item VUOTO (seleziona OP_ELSE), witnessScript].
  ///
  /// PERCHÉ: l'item vuoto serializza come 0x00 e spinge un array vuoto che
  /// OP_IF valuta falso → ramo temporale (CLTV), senza alcun check sull'hash.
  static TxWitnessInput refundWitness({
    required String sigHex,
    required String witnessScriptHex,
  }) =>
      TxWitnessInput(stack: [sigHex, '', witnessScriptHex]);

  /// Confronta il witnessScript derivato dai parametri con quello dichiarato.
  ///
  /// PERCHÉ: usato dall'app PRIMA di firmare il funding e dal provider PRIMA
  /// di pagare: una quote manomessa (script ≠ parametri) si blocca qui.
  static bool matchesWitnessScriptHex(
    SwapScriptParams p,
    String witnessScriptHex,
  ) =>
      witnessScript(p).toHex().toLowerCase() == witnessScriptHex.toLowerCase();
}
