import 'dart:math';
import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:nwc_cln_bridge/src/bitcoin/unified_sighash.dart';
import 'package:nwc_cln_bridge/src/swap/swap_script.dart';
import 'package:test/test.dart';

/// Vettori dello script HTLC (P9) — l'app ha la copia speculare in
/// `mobile/test/core/services/swap/swap_script_test.dart`: i byte attesi
/// devono coincidere su entrambi i lati.
void main() {
  // Vettore fisso, verificato a mano byte per byte:
  // - payment_hash: 32 byte 0x11 (SHA256 della preimage, fittizio ma valido)
  // - claim pubkey: G compressa | refund pubkey: 2G compressa
  // - cltv: 972000 = 0x0ED4E0 → CScriptNum minimale LE [e0 d4 0e] (3 byte)
  const paymentHashHex =
      '1111111111111111111111111111111111111111111111111111111111111111';
  const claimPubkeyHex =
      '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798';
  const refundPubkeyHex =
      '02c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5';
  const cltvHeight = 972000;

  const params = SwapScriptParams(
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
        // Script manomesso (primo byte rimosso → hex diverso) → false.
        SwapScripts.matchesWitnessScriptHex(
          params,
          BytesUtils.toHexString(expected.sublist(1)),
        ),
        isFalse,
      );
    });

    test('rifiuta cltv ≤ 16 (evita OP_N al posto del numero)', () {
      expect(
        () => SwapScripts.witnessScript(
          const SwapScriptParams(
            paymentHashHex: paymentHashHex,
            claimPubkeyHex: claimPubkeyHex,
            refundPubkeyHex: refundPubkeyHex,
            cltvHeight: 16,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('rifiuta payment_hash o pubkey di lunghezza sbagliata', () {
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
          const SwapScriptParams(
            paymentHashHex: paymentHashHex,
            claimPubkeyHex: '02',
            refundPubkeyHex: refundPubkeyHex,
            cltvHeight: cltvHeight,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('fuzz leggero: hash randomici → script coerente, nessuna eccezione',
        () {
      final rnd = Random(20260917);
      for (var i = 0; i < 200; i++) {
        final hashBytes = List<int>.generate(32, (_) => rnd.nextInt(256));
        final cltv = 17 + rnd.nextInt(900000);
        final p = SwapScriptParams(
          paymentHashHex: BytesUtils.toHexString(hashBytes),
          claimPubkeyHex: claimPubkeyHex,
          refundPubkeyHex: refundPubkeyHex,
          cltvHeight: cltv,
        );
        final bytes = SwapScripts.witnessScript(p).toBytes();
        expect(bytes.first, 0x63); // OP_IF
        expect(bytes.last, 0xac); // OP_CHECKSIG
        expect(bytes.contains(0x88), isTrue); // OP_EQUALVERIFY
        expect(
          SwapScripts.matchesWitnessScriptHex(
            p,
            SwapScripts.witnessScript(p).toHex(),
          ),
          isTrue,
        );
      }
    });
  });

  group('SwapScripts indirizzo P2WSH', () {
    test('indirizzo bech32 + round-trip scriptPubKey 0020+sha256', () {
      final ws = SwapScripts.witnessScript(params);
      final addr = P2wshAddress.fromScript(script: ws).toAddress(
        BitcoinNetwork.mainnet,
      );
      expect(addr.startsWith('bc1q'), isTrue);

      final parsed = P2wshAddress.fromAddress(
        address: addr,
        network: BitcoinNetwork.mainnet,
      );
      final program = QuickCrypto.sha256Hash(ws.toBytes());
      expect(
        parsed.toScriptPubKey().toHex(),
        BytesUtils.toHexString([0x00, 0x20, ...program]),
      );
      expect(
        SwapScripts.scriptPubKeyHex(params),
        parsed.toScriptPubKey().toHex(),
      );
      // Il percorso di funding dell'app usa BitcoinAddress(...): deve parsare
      // anche un indirizzo P2WSH (0020…).
      final viaLib = BitcoinAddress(addr, network: BitcoinNetwork.mainnet);
      expect(
        viaLib.baseAddress.toScriptPubKey().toHex(),
        parsed.toScriptPubKey().toHex(),
      );
    });
  });

  group('SwapScripts witness', () {
    final wsHex = SwapScripts.witnessScript(params).toHex();

    test('claim: [sig, preimage, 01, script] round-trip', () {
      final wit = SwapScripts.claimWitness(
        sigHex: 'aa' * 71,
        preimageHex: 'bb' * 32,
        witnessScriptHex: wsHex,
      );
      final decoded = TxWitnessInput.deserialize(wit.toBytes());
      expect(decoded.stack, ['aa' * 71, 'bb' * 32, '01', wsHex]);
    });

    test('refund: item vuoto serializzato 0x00 e round-trip', () {
      final wit = SwapScripts.refundWitness(
        sigHex: 'cc' * 71,
        witnessScriptHex: wsHex,
      );
      final bytes = wit.toBytes();
      expect(bytes[0], 3); // tre item nello stack
      expect(bytes[1], 71); // lunghezza firma
      final emptyItemPos = 2 + 71;
      expect(bytes[emptyItemPos], 0x00); // item vuoto = selettore OP_ELSE
      expect(bytes[emptyItemPos + 1], 113); // lunghezza witnessScript
      final decoded = TxWitnessInput.deserialize(bytes);
      expect(decoded.stack, ['cc' * 71, '', wsHex]);
    });

    test('probe: item vuoto in uno stack qualsiasi serializza 0x00', () {
      expect(
        TxWitnessInput(stack: ['', 'ab']).toBytes(),
        [0x02, 0x00, 0x01, 0xab],
      );
    });
  });

  group('probe tx primitives (M0.1)', () {
    test('locktime e sequence serializzati come atteso', () {
      final tx = BtcTransaction(
        inputs: [
          TxInput(txId: 'aa' * 32, txIndex: 0, sequance: kReplaceByFeeSequence),
        ],
        outputs: [
          TxOutput(amount: BigInt.from(1000), scriptPubKey: Script(script: [])),
        ],
        locktime: IntUtils.toBytes(144, length: 4, byteOrder: Endian.little),
      );
      final hex = tx.toHex();
      expect(hex.endsWith('90000000'), isTrue); // nLockTime 144 LE in coda
      expect(hex.contains('fdffffff'), isTrue); // sequence 0xfffffffd LE
    });
  });
}
