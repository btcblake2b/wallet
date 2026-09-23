import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:nwc_cln_bridge/src/bitcoin/unified_sighash.dart';
import 'package:nwc_cln_bridge/src/swap/swap_script.dart';
import 'package:nwc_cln_bridge/src/swap/swap_signer.dart';
import 'package:test/test.dart';

import 'swap_fixtures.dart';

/// Signer del claim: struttura tx, firma UNIFIED, guardie.
void main() {
  // Chiave provider di test (scalar piccolo) e parametri HTLC coerenti.
  final privkeyHex = BytesUtils.toHexString(
    BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
  );
  final signer = SwapSigner(privkeyHex);
  final params = SwapScriptParams(
    paymentHashHex: SwapFixtures.paymentHashHex,
    claimPubkeyHex: signer.pubkeyHex,
    refundPubkeyHex: SwapFixtures.refundPubkeyHex,
    cltvHeight: 972144,
  );

  const fundingTxid = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const fundingAmountSats = 5250;
  const claimFeeSats = 280;

  String buildRaw() => signer.buildClaimTx(
        fundingTxid: fundingTxid,
        fundingVout: 0,
        fundingAmountSats: fundingAmountSats,
        scriptParams: params,
        preimageHex: SwapFixtures.preimageHex,
        destinationAddress: SwapFixtures.destinationAddress,
        feeSats: claimFeeSats,
      );

  test('struttura: input, importo netto, sequence RBF, witness di claim', () {
    final tx = BtcTransaction.deserialize(
      BytesUtils.fromHexString(buildRaw()),
    );
    expect(tx.inputs.length, 1);
    expect(tx.inputs.first.txId, fundingTxid);
    expect(tx.inputs.first.txIndex, 0);
    expect(tx.inputs.first.sequence, kReplaceByFeeSequence);
    expect(tx.outputs.length, 1);
    expect(
      tx.outputs.first.amount,
      BigInt.from(fundingAmountSats - claimFeeSats),
    );
    expect(tx.witnesses.length, 1);
    final stack = tx.witnesses.first.stack;
    expect(stack.length, 4);
    // PERCHÉ: signECDSA appende il byte nHashType; UNIFIED ALL = 0x21.
    expect(stack[0].toLowerCase(), endsWith('21'));
    expect(stack[1], SwapFixtures.preimageHex);
    expect(stack[2], '01');
    expect(stack[3], SwapScripts.witnessScript(params).toHex());
  });

  test('la firma verifica sul digest UNIFIED con gli scriptPubKey reali', () {
    final tx = BtcTransaction.deserialize(
      BytesUtils.fromHexString(buildRaw()),
    );
    final script = SwapScripts.witnessScript(params);
    final scriptPubKey = P2wshAddress.fromScript(
      script: script,
    ).toScriptPubKey();
    final digest = computeUnifiedSighash(
      tx: tx,
      txInIndex: 0,
      scriptCode: script,
      spentAmounts: [BigInt.from(fundingAmountSats)],
      spentScripts: [scriptPubKey],
      scriptType: 1,
    );
    final sigWithType = BytesUtils.fromHexString(
      tx.witnesses.first.stack.first,
    );
    final derSig = sigWithType.sublist(0, sigWithType.length - 1);
    final verifier = BitcoinSignatureVerifier.fromKeyBytes(
      BytesUtils.fromHexString(signer.pubkeyHex),
    );
    expect(
      verifier.verifyECDSADerSignature(digest: digest, signature: derSig),
      isTrue,
    );
  });

  test('guardie: fee non valida, preimage non valida, destinazione non valida',
      () {
    expect(
      () => signer.buildClaimTx(
        fundingTxid: fundingTxid,
        fundingVout: 0,
        fundingAmountSats: fundingAmountSats,
        scriptParams: params,
        preimageHex: SwapFixtures.preimageHex,
        destinationAddress: SwapFixtures.destinationAddress,
        feeSats: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => signer.buildClaimTx(
        fundingTxid: fundingTxid,
        fundingVout: 0,
        fundingAmountSats: fundingAmountSats,
        scriptParams: params,
        preimageHex: 'ab',
        destinationAddress: SwapFixtures.destinationAddress,
        feeSats: claimFeeSats,
      ),
      throwsArgumentError,
    );
    expect(
      () => signer.buildClaimTx(
        fundingTxid: fundingTxid,
        fundingVout: 0,
        fundingAmountSats: fundingAmountSats,
        scriptParams: params,
        preimageHex: SwapFixtures.preimageHex,
        destinationAddress: 'non-un-indirizzo',
        feeSats: claimFeeSats,
      ),
      throwsA(anything),
    );
  });
}
