import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

import '../bitcoin/unified_sighash.dart';
import 'swap_script.dart';

/// Firma del CLAIM dell'HTLC (lato provider) con SIGHASH_UNIFIED.
///
/// PERCHÉ (Blueprint §2.4): il claim spende l'output P2WSH creato dall'utente
/// con witness `[firma, preimage, 0x01, witnessScript]`; la firma DEVE usare
/// il digest del fork (non BIP-143), altrimenti il nodo la rifiuta.
class SwapSigner {
  SwapSigner(String privkeyHex)
      : _key = ECPrivate.fromBytes(BytesUtils.fromHexString(privkeyHex)) {
    if (BytesUtils.fromHexString(privkeyHex).length != 32) {
      throw ArgumentError('chiave provider: attesi 32 byte (hex 64).');
    }
  }

  final ECPrivate _key;
  late final ECPublic _pub = _key.getPublic();

  String get pubkeyHex => _pub.toHex();

  /// vB stimati della tx di claim (1 input P2WSH + 1 output P2WPKH).
  /// PERCHÉ: costante usata per il fee di claim; i test la verificano sul
  /// peso reale della tx costruita.
  static const int claimTxVbytes = 140;

  /// Costruisce e firma la tx di CLAIM (raw hex, NON trasmessa).
  ///
  /// [destinationAddress] è un indirizzo del wallet del provider (newaddr).
  /// L'output del claim vale [fundingAmountSats] − [feeSats].
  String buildClaimTx({
    required String fundingTxid,
    required int fundingVout,
    required int fundingAmountSats,
    required SwapScriptParams scriptParams,
    required String preimageHex,
    required String destinationAddress,
    required int feeSats,
  }) {
    if (feeSats <= 0 || feeSats >= fundingAmountSats) {
      throw ArgumentError(
        'fee claim non valida: $feeSats su $fundingAmountSats',
      );
    }
    final preimage = BytesUtils.fromHexString(preimageHex);
    if (preimage.length != 32) {
      throw ArgumentError('preimage: attesi 32 byte.');
    }
    final script = SwapScripts.witnessScript(scriptParams);
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
            network: BitcoinNetwork.mainnet,
          ).baseAddress,
          value: BigInt.from(fundingAmountSats - feeSats),
        ).toOutput,
      ],
    );

    final digest = computeUnifiedSighash(
      tx: tx,
      txInIndex: 0,
      scriptCode: script,
      spentAmounts: [BigInt.from(fundingAmountSats)],
      spentScripts: [scriptPubKey],
      scriptType: 1,
    );
    final sigHex = _key.signECDSA(digest, sighash: kSighashAllUnified);

    final signed = tx.copyWith(
      witnesses: [
        SwapScripts.claimWitness(
          sigHex: sigHex,
          preimageHex: preimageHex,
          witnessScriptHex: script.toHex(),
        ),
      ],
    );
    return signed.toHex();
  }
}
