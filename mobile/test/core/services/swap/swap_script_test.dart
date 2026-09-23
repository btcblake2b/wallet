import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:btc_blake2b_wallet/core/services/swap/swap_script.dart';
import 'package:btc_blake2b_wallet/core/services/unified_sighash.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vettori dello script HTLC (P9) — SPECULARI a
/// `bridge/test/swap_script_test.dart`: i byte devono coincidere su entrambi
/// i lati, altrimenti l'HTLC finanziato dall'app non sarebbe claimabile dal
/// provider (o viceversa).
void main() {
  // Vettore fisso, verificato a mano byte per byte:
  // - payment_hash: 32 byte 0x11 (fittizio ma di lunghezza valida)
  // - claim pubkey: G compressa | refund pubkey: 2G compressa
  // - cltv: 972000 = 0x0ED4E0 → CScriptNum minimale LE [e0 d4 0e] (3 byte)
  final paymentHashHex = '11' * 32;
  const claimPubkeyHex =
      '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const refundPubkeyHex =
      '02c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
  const cltvHeight = 972000;

  final params = SwapScriptParams(
    paymentHashHex: paymentHashHex,
    claimPubkeyHex: claimPubkeyHex,
    refundPubkeyHex: refundPubkeyHex,
    cltvHeight: cltvHeight,
  );

  /// Push minimale (BIP62) per dati ≤ 75 byte: prefisso di lunghezza.
  List<int> pushData(List<int> data) => [data.length, ...data];

  group('SwapScripts.witnessScript', () {
    test('produce i byte attesi (vettore indipendente, 113 byte)', () {
      final expected = <int>[
        0x63, // OP_IF
        0xa8, // OP_SHA256
        ...pushData(BytesUtils.fromHexString(paymentHashHex)),
        0x88, // OP_EQUALVERIFY
        ...pushData(BytesUtils.fromHexString(claimPubkeyHex)),
        0x67, // OP_ELSE
        ...pushData([0xe0, 0xd4, 0x0e]), // 972000 CScriptNum minimale
        0xb1, // OP_CHECKLOCKTIMEVERIFY
        0x75, // OP_DROP
        ...pushData(BytesUtils.fromHexString(refundPubkeyHex)),
        0x68, // OP_ENDIF
        0xac, // OP_CHECKSIG
      ];
      final script = SwapScripts.witnessScript(params);
      expect(script.toBytes(), expected);
      expect(script.toBytes().length, 113);
      expect(script.toHex(), BytesUtils.toHexString(expected));
      expect(
        SwapScripts.matchesWitnessScriptHex(params, script.toHex()),
        isTrue,
      );
      expect(
        // Script manomesso (primo byte rimosso) → false.
        SwapScripts.matchesWitnessScriptHex(
          params,
          BytesUtils.toHexString(expected.sublist(1)),
        ),
        isFalse,
      );
    });

    test('rifiuta cltv ≤ 16 e dati di lunghezza sbagliata', () {
      expect(
        () => SwapScripts.witnessScript(
          SwapScriptParams(
            paymentHashHex: paymentHashHex,
            claimPubkeyHex: claimPubkeyHex,
            refundPubkeyHex: refundPubkeyHex,
            cltvHeight: 16,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => SwapScripts.witnessScript(
          const SwapScriptParams(
            paymentHashHex: '11',
            claimPubkeyHex: claimPubkeyHex,
            refundPubkeyHex: refundPubkeyHex,
            cltvHeight: cltvHeight,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => SwapScripts.witnessScript(
          SwapScriptParams(
            paymentHashHex: paymentHashHex,
            claimPubkeyHex: '02abcd',
            refundPubkeyHex: refundPubkeyHex,
            cltvHeight: cltvHeight,
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group('SwapScripts.address / scriptPubKeyHex / refundWitness', () {
    test('P2WSH coerente: spk 0020… e indirizzo bc1q', () {
      final spk = SwapScripts.scriptPubKeyHex(params);
      expect(spk.startsWith('0020'), isTrue);
      // 0x0020 (witness v0) + SHA256(witnessScript) → 68 char hex.
      expect(spk.length, 68);
      expect(SwapScripts.address(params).startsWith('bc1q'), isTrue);
    });

    test('refundWitness: [firma, item vuoto, witnessScript]', () {
      final witness = SwapScripts.refundWitness(
        sigHex: '3045abcd',
        witnessScriptHex: '63a82000',
      );
      expect(witness.stack.length, 3);
      expect(witness.stack[0], '3045abcd');
      expect(witness.stack[1], '');
      expect(witness.stack[2], '63a82000');
    });
  });

  group('buildSignedRefundTxHex', () {
    final refundKey = ECPrivate.fromBytes(
      BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
    );
    final fundingTxid = 'aa' * 32;
    const fundingAmountSats = 5250;
    const feeSats = 280;
    const destinationAddress =
        'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4';

    String buildRaw() => buildSignedRefundTxHex(
          refundKey: refundKey,
          scriptParams: params,
          witnessScriptHex: SwapScripts.witnessScript(params).toHex(),
          fundingTxid: fundingTxid,
          fundingVout: 1,
          fundingAmountSats: fundingAmountSats,
          destinationAddress: destinationAddress,
          feeSats: feeSats,
        );

    test('struttura: input, importo netto, locktime CLTV, witness di refund',
        () {
      final tx = BtcTransaction.deserialize(
        BytesUtils.fromHexString(buildRaw()),
      );
      expect(tx.inputs.length, 1);
      expect(tx.inputs.first.txId, fundingTxid);
      expect(tx.inputs.first.txIndex, 1);
      expect(tx.inputs.first.sequence, kReplaceByFeeSequence);
      // PERCHÉ: in bitcoin_base locktime è una lista di 4 byte LE.
      expect(
        tx.locktime[0] | tx.locktime[1] << 8 | tx.locktime[2] << 16 | tx.locktime[3] << 24,
        cltvHeight,
      );
      expect(tx.outputs.length, 1);
      expect(
        tx.outputs.first.amount,
        BigInt.from(fundingAmountSats - feeSats),
      );
      expect(tx.witnesses.length, 1);
      final stack = tx.witnesses.first.stack;
      expect(stack.length, 3);
      // PERCHÉ: signECDSA appende il byte nHashType; UNIFIED ALL = 0x21.
      expect(stack[0].toLowerCase(), endsWith('21'));
      expect(stack[1], '');
      expect(stack[2], SwapScripts.witnessScript(params).toHex());
    });

    test('la firma verifica sul digest UNIFIED con gli scriptPubKey reali',
        () {
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
        BytesUtils.fromHexString(refundKey.getPublic().toHex()),
      );
      expect(
        verifier.verifyECDSADerSignature(digest: digest, signature: derSig),
        isTrue,
      );
    });

    test('guardie: fee non valida, script manomesso, fee ≥ importo', () {
      expect(
        () => buildSignedRefundTxHex(
          refundKey: refundKey,
          scriptParams: params,
          witnessScriptHex: SwapScripts.witnessScript(params).toHex(),
          fundingTxid: fundingTxid,
          fundingVout: 0,
          fundingAmountSats: fundingAmountSats,
          destinationAddress: destinationAddress,
          feeSats: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => buildSignedRefundTxHex(
          refundKey: refundKey,
          scriptParams: params,
          witnessScriptHex: 'deadbeef',
          fundingTxid: fundingTxid,
          fundingVout: 0,
          fundingAmountSats: fundingAmountSats,
          destinationAddress: destinationAddress,
          feeSats: feeSats,
        ),
        throwsArgumentError,
      );
      expect(
        () => buildSignedRefundTxHex(
          refundKey: refundKey,
          scriptParams: params,
          witnessScriptHex: SwapScripts.witnessScript(params).toHex(),
          fundingTxid: fundingTxid,
          fundingVout: 0,
          fundingAmountSats: fundingAmountSats,
          destinationAddress: destinationAddress,
          feeSats: fundingAmountSats,
        ),
        throwsArgumentError,
      );
    });

    test('cambiare locktime o importo INVALIDA la firma (digest committa)',
        () {
      final raw = buildRaw();
      final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(raw));
      final script = SwapScripts.witnessScript(params);
      final scriptPubKey = P2wshAddress.fromScript(
        script: script,
      ).toScriptPubKey();
      final sigWithType = BytesUtils.fromHexString(
        tx.witnesses.first.stack.first,
      );
      final derSig = sigWithType.sublist(0, sigWithType.length - 1);
      final verifier = BitcoinSignatureVerifier.fromKeyBytes(
        BytesUtils.fromHexString(refundKey.getPublic().toHex()),
      );
      // Digest con un importo DIVERSO da quello firmato → deve fallire.
      final wrongDigest = computeUnifiedSighash(
        tx: tx,
        txInIndex: 0,
        scriptCode: script,
        spentAmounts: [BigInt.from(fundingAmountSats + 1)],
        spentScripts: [scriptPubKey],
        scriptType: 1,
      );
      expect(
        verifier.verifyECDSADerSignature(
          digest: wrongDigest,
          signature: derSig,
        ),
        isFalse,
      );
    });
  });
}
