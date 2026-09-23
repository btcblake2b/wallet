import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:btc_blake2b_wallet/core/services/unified_sighash.dart';

/// Test delle proprietà crittografiche del digest SIGHASH_UNIFIED
/// (Bitcoin Knots PR #357 — la chain blake2b attiva il fork con
/// DEPLOYMENT_BLAKE2B). Spec di riferimento: `doc/unified-sighash.md` di Knots,
/// tag `v29.4.1.knots20260508`, con 166 vettori (indicata dal meeting community
/// del 16/09/2026). Il gruppo "Vettori ufficiali" in fondo usa
/// `unified_sighash.json` del PR #357; le proprietà sotto pinnano il resto:
///   - replay protection (digest ≠ BIP-143 legacy)
///   - determinismo
///   - commitment a tutti gli output spesi (CVE-2020-14199)
///   - domain separation per script_type e per input
void main() {
  // Script P2PKH standard (OP_DUP OP_HASH160 <20B> OP_EQUALVERIFY OP_CHECKSIG)
  final scriptCode = Script(script: ['76', 'a9', '14', '11' * 20, '88', 'ac']);
  // ScriptPubKey P2WPKH (0014 + hash160 di 20 byte)
  final spentScript = Script(script: ['0014', '22' * 20]);

  BtcTransaction buildTx() {
    return BtcTransaction(
      version: [1, 0, 0, 0],
      locktime: [0, 0, 0, 0],
      inputs: [
        TxInput(txId: 'a' * 64, txIndex: 0),
        TxInput(txId: 'b' * 64, txIndex: 1),
      ],
      outputs: [
        TxOutput(amount: BigInt.from(90000), scriptPubKey: spentScript),
        TxOutput(amount: BigInt.from(10000), scriptPubKey: spentScript),
      ],
    );
  }

  List<int> digestFor({
    required BtcTransaction tx,
    int txInIndex = 0,
    List<BigInt>? amounts,
    List<Script>? scripts,
  }) {
    return computeUnifiedSighash(
      tx: tx,
      txInIndex: txInIndex,
      scriptCode: scriptCode,
      spentAmounts: amounts ?? [BigInt.from(100000), BigInt.from(200000)],
      spentScripts: scripts ?? [spentScript, spentScript],
    );
  }

  group('computeUnifiedSighash', () {
    test('digest is deterministic (32 bytes)', () {
      final tx = buildTx();
      final d1 = digestFor(tx: tx);
      final d2 = digestFor(tx: tx);
      expect(d1, equals(d2));
      expect(d1.length, 32);
    });

    test('digest differs from legacy BIP-143 (replay protection)', () {
      final tx = buildTx();
      final unified = digestFor(tx: tx);
      // Digest BIP-143 (getTransactionSegwitDigit) per lo stesso input
      final legacy = tx.getTransactionSegwitDigit(
        txInIndex: 0,
        script: scriptCode,
        amount: BigInt.from(100000),
      );
      // PERCHÉ: il tagged hash rende il messaggio disgiunto da ogni sighash
      // esistente → la firma UNIFIED non verifica sotto BIP-143 e viceversa.
      expect(unified, isNot(equals(legacy)));
    });

    test('digest changes when a spent amount changes (CVE-2020-14199)', () {
      final tx = buildTx();
      final base = digestFor(tx: tx);
      final mutated = digestFor(
        tx: tx,
        amounts: [BigInt.from(99999), BigInt.from(200000)],
      );
      // PERCHÉ: il digest committa a TUTTI gli output spesi (amount+script),
      // chiudendo CVE-2020-14199 (spendere input con script falsi).
      expect(mutated, isNot(equals(base)));
    });

    test('digest changes when a spent script changes', () {
      final tx = buildTx();
      final base = digestFor(tx: tx);
      final otherScript = Script(script: ['0014', '33' * 20]);
      final mutated = digestFor(tx: tx, scripts: [otherScript, spentScript]);
      expect(mutated, isNot(equals(base)));
    });

    test('digest differs per input index (nIn entra nel messaggio)', () {
      final tx = buildTx();
      final d0 = digestFor(tx: tx, txInIndex: 0);
      final d1 = digestFor(tx: tx, txInIndex: 1);
      expect(d1, isNot(equals(d0)));
    });

    test('script_type separa i messaggi (0 legacy ≠ 1 segwit v0)', () {
      final tx = buildTx();
      final amounts = [BigInt.from(100000), BigInt.from(200000)];
      final scripts = [spentScript, spentScript];
      final legacy = computeUnifiedSighash(
        tx: tx,
        txInIndex: 0,
        scriptCode: scriptCode,
        spentAmounts: amounts,
        spentScripts: scripts,
        scriptType: 0,
      );
      final segwit = computeUnifiedSighash(
        tx: tx,
        txInIndex: 0,
        scriptCode: scriptCode,
        spentAmounts: amounts,
        spentScripts: scripts,
        scriptType: 1,
      );
      // PERCHÉ (BIP44): il byte di script type separa i domini — una firma
      // fatta per un tipo non può valere per un altro.
      expect(legacy, isNot(equals(segwit)));
    });

    test('script_type 0 differisce dal digest legacy classico (replay)', () {
      final tx = buildTx();
      final d0 = computeUnifiedSighash(
        tx: tx,
        txInIndex: 0,
        scriptCode: scriptCode,
        spentAmounts: [BigInt.from(100000), BigInt.from(200000)],
        spentScripts: [spentScript, spentScript],
        scriptType: 0,
      );
      // Digest legacy classico (non unificato) per lo stesso input.
      final legacyDigest =
          tx.getTransactionDigest(txInIndex: 0, script: scriptCode);
      // PERCHÉ: il bit 0x20 opt-in rende il messaggio disgiunto → la firma
      // UNIFIED type 0 non è replayabile su chain senza il fork.
      expect(d0, isNot(equals(legacyDigest)));
    });

    test('digest changes when an output changes (hashOutputs committa tutto)',
        () {
      final tx = buildTx();
      final base = digestFor(tx: tx);
      final mutatedTx = tx.copyWith(
        outputs: [
          TxOutput(amount: BigInt.from(90001), scriptPubKey: spentScript),
          TxOutput(amount: BigInt.from(10000), scriptPubKey: spentScript),
        ],
      );
      final mutated = digestFor(tx: mutatedTx);
      expect(mutated, isNot(equals(base)));
    });
  });

  group('buildAndSignUnifiedTx', () {
    test('produces a signed tx whose signature ends with byte 0x21', () {
      // Chiave di test valida (scalar piccolo)
      final key = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
      );
      final pub = key.getPublic();
      final pubHex = pub.toHex();

      final utxo = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'a' * 64,
          value: BigInt.from(100000),
          vout: 0,
          scriptType: SegwitAddressType.p2wpkh,
        ),
        ownerDetails: UtxoAddressDetails(
          publicKey: pubHex,
          address: pub.toSegwitAddress(),
        ),
      );

      final output = BitcoinOutput(
        address: pub.toSegwitAddress(),
        value: BigInt.from(90000),
      );

      final hex = buildAndSignUnifiedTx(
        utxoWithAddresses: [utxo],
        outputs: [output],
        privateKeysByPublicKey: {pubHex: key},
        fee: BigInt.from(10000),
      );

      final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(hex));

      expect(tx.witnesses.length, 1);
      final wit = tx.witnesses.first.stack;
      expect(wit.length, 2, reason: 'witness P2WPKH = [signature, pubkey]');
      // PERCHÉ: signECDSA appende il byte nHashType; UNIFIED ALL = 0x21
      expect(wit.first.toLowerCase(), endsWith('21'));
      expect(wit[1].toLowerCase(), equals(pubHex.toLowerCase()));
      // La pubkey del witness deve corrispondere a quella dell'owner
      expect(wit[1].toLowerCase(), equals(pubHex.toLowerCase()));
    });

    test(
        'enableRBF: ogni input ha sequence non-final (0xfffffffd); '
        'default sequence finale', () {
      final key = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
      );
      final pub = key.getPublic();
      final pubHex = pub.toHex();

      final utxo = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'b' * 64,
          value: BigInt.from(100000),
          vout: 0,
          scriptType: SegwitAddressType.p2wpkh,
        ),
        ownerDetails: UtxoAddressDetails(
          publicKey: pubHex,
          address: pub.toSegwitAddress(),
        ),
      );
      final output = BitcoinOutput(
        address: pub.toSegwitAddress(),
        value: BigInt.from(90000),
      );

      // RBF attivo: sequence 0xfffffffd LE su ogni input, firma UNIFIED 0x21.
      final hexRbf = buildAndSignUnifiedTx(
        utxoWithAddresses: [utxo],
        outputs: [output],
        privateKeysByPublicKey: {pubHex: key},
        fee: BigInt.from(10000),
        enableRBF: true,
      );
      final txRbf =
          BtcTransaction.deserialize(BytesUtils.fromHexString(hexRbf));
      expect(txRbf.inputs.first.sequence, kReplaceByFeeSequence);
      expect(
        txRbf.witnesses.first.stack.first.toLowerCase(),
        endsWith('21'),
      );

      // Default: sequence finale 0xffffffff.
      final hexDefault = buildAndSignUnifiedTx(
        utxoWithAddresses: [utxo],
        outputs: [output],
        privateKeysByPublicKey: {pubHex: key},
        fee: BigInt.from(10000),
      );
      final txDefault =
          BtcTransaction.deserialize(BytesUtils.fromHexString(hexDefault));
      expect(txDefault.inputs.first.sequence, [0xff, 0xff, 0xff, 0xff]);
      expect(txDefault.inputs.first.sequence, isNot(kReplaceByFeeSequence));
    });

    test('sorts inputs by BIP-69', () {
      final key = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
      );
      final pub = key.getPublic();
      final pubHex = pub.toHex();
      final addr = pub.toSegwitAddress();

      // due utxo con txid in ordine inverso: 'b...' prima di 'a...'
      final utxoB = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'b' * 64,
          value: BigInt.from(100000),
          vout: 0,
          scriptType: SegwitAddressType.p2wpkh,
        ),
        ownerDetails: UtxoAddressDetails(publicKey: pubHex, address: addr),
      );
      final utxoA = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'a' * 64,
          value: BigInt.from(200000),
          vout: 0,
          scriptType: SegwitAddressType.p2wpkh,
        ),
        ownerDetails: UtxoAddressDetails(publicKey: pubHex, address: addr),
      );

      final hex = buildAndSignUnifiedTx(
        utxoWithAddresses: [utxoB, utxoA],
        outputs: [BitcoinOutput(address: addr, value: BigInt.from(290000))],
        privateKeysByPublicKey: {pubHex: key},
        fee: BigInt.from(10000),
      );

      final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(hex));
      expect(tx.inputs.length, 2);
      // BIP-69: l'input con txid 'a...' (lessicograficamente minore) viene prima
      expect(tx.inputs.first.txId, 'a' * 64);
      expect(tx.inputs[1].txId, 'b' * 64);
    });

    test(
        'la firma prodotta verifica contro il digest con gli scriptPubKey reali',
        () {
      // PERCHÉ: riproduce il caso d'uso reale — un UTXO P2WPKH con scriptPubKey
      // on-chain 0014{hash160(pub)}. La firma deve verificare contro il digest
      // calcolato con sha_scripts = scriptPubKey REALE (0014...), non P2PKH.
      // Questo test avrebbe catturato il bug sha_scripts (firma sempre invalida).
      final key = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
      );
      final pub = key.getPublic();
      final pubHex = pub.toHex();
      final segwitAddr = pub.toSegwitAddress();

      final utxo = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'a' * 64,
          value: BigInt.from(100000),
          vout: 0,
          scriptType: SegwitAddressType.p2wpkh,
        ),
        ownerDetails:
            UtxoAddressDetails(publicKey: pubHex, address: segwitAddr),
      );

      final hex = buildAndSignUnifiedTx(
        utxoWithAddresses: [utxo],
        outputs: [
          BitcoinOutput(address: segwitAddr, value: BigInt.from(90000)),
        ],
        privateKeysByPublicKey: {pubHex: key},
        fee: BigInt.from(10000),
      );

      final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(hex));
      expect(tx.witnesses.length, 1);
      final wit = tx.witnesses.first.stack;
      expect(wit.length, 2);
      final sigHex = wit.first;
      final pubkeyHex = wit[1];
      // togli il byte sighash (0x21) dalla firma per la verifica ECDSA
      final derSig =
          BytesUtils.fromHexString(sigHex).sublist(0, sigHex.length ~/ 2 - 1);
      final pubkeyBytes = BytesUtils.fromHexString(pubkeyHex);

      // Ricomputa il digest come fa il nodo: scriptCode = P2PKH, sha_scripts =
      // scriptPubKey reale (0014...), amount 100000.
      final digest = computeUnifiedSighash(
        tx: tx,
        txInIndex: 0,
        scriptCode: pub.toAddress().toScriptPubKey(),
        spentAmounts: [BigInt.from(100000)],
        spentScripts: [segwitAddr.toScriptPubKey()],
      );

      final verifier = BitcoinSignatureVerifier.fromKeyBytes(pubkeyBytes);
      expect(
        verifier.verifyECDSADerSignature(
          digest: digest,
          signature: derSig,
        ),
        isTrue,
        reason: 'la firma deve verificare contro il digest UNIFIED',
      );
    });

    test('input legacy P2PKH: firma in scriptSig (type 0), nessun witness', () {
      // PERCHÉ (BIP44): script type 0 → la firma (DER+0x21) e la pubkey vanno
      // nello scriptSig; una tx tutta legacy non ha marker witness.
      final key = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
      );
      final pub = key.getPublic();
      final pubHex = pub.toHex();
      final legacyAddr = pub.toAddress();

      final utxo = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'a' * 64,
          value: BigInt.from(100000),
          vout: 0,
          scriptType: P2pkhAddressType.p2pkh,
        ),
        ownerDetails:
            UtxoAddressDetails(publicKey: pubHex, address: legacyAddr),
      );

      final hex = buildAndSignUnifiedTx(
        utxoWithAddresses: [utxo],
        outputs: [
          BitcoinOutput(address: legacyAddr, value: BigInt.from(90000)),
        ],
        privateKeysByPublicKey: {pubHex: key},
        fee: BigInt.from(10000),
      );

      final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(hex));
      // Tx tutta legacy → nessun witness.
      expect(tx.witnesses, isEmpty);
      final scriptSigHex = tx.inputs.first.scriptSig.toHex().toLowerCase();
      // scriptSig = <push sig> <push pub> → termina con la push della pubkey.
      expect(
        scriptSigHex.endsWith(pubHex.toLowerCase()),
        isTrue,
        reason: 'la pubkey deve chiudere lo scriptSig P2PKH',
      );

      // Verifica crittografica della firma nello scriptSig sul digest type 0.
      final digest = computeUnifiedSighash(
        tx: tx,
        txInIndex: 0,
        scriptCode: legacyAddr.toScriptPubKey(),
        spentAmounts: [BigInt.from(100000)],
        spentScripts: [legacyAddr.toScriptPubKey()],
        scriptType: 0,
      );
      final scriptSigBytes =
          BytesUtils.fromHexString(tx.inputs.first.scriptSig.toHex());
      final sigLen = scriptSigBytes.first;
      final sigWithType = scriptSigBytes.sublist(1, 1 + sigLen);
      final derSig = sigWithType.sublist(0, sigWithType.length - 1);
      final verifier = BitcoinSignatureVerifier.fromKeyBytes(
          BytesUtils.fromHexString(pubHex),);
      expect(
        verifier.verifyECDSADerSignature(digest: digest, signature: derSig),
        isTrue,
        reason: 'la firma legacy deve verificare sul digest UNIFIED type 0',
      );
    });

    test('input misti legacy+segwit: script_type per-input e witness allineate',
        () {
      // PERCHÉ (BIP44): copre il caso reale di un wallet con UTXO di tipi
      // diversi: stesso digest unificato ma script_type diverso per input,
      // witness vuota per l'input legacy (tx segwit).
      final key = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
      );
      final pub = key.getPublic();
      final pubHex = pub.toHex();
      final legacyAddr = pub.toAddress();
      final segwitAddr = pub.toSegwitAddress();

      // BIP-69: 'a…' (legacy) prima di 'b…' (segwit).
      final utxoLegacy = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'a' * 64,
          value: BigInt.from(100000),
          vout: 0,
          scriptType: P2pkhAddressType.p2pkh,
        ),
        ownerDetails:
            UtxoAddressDetails(publicKey: pubHex, address: legacyAddr),
      );
      final utxoSegwit = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'b' * 64,
          value: BigInt.from(200000),
          vout: 0,
          scriptType: SegwitAddressType.p2wpkh,
        ),
        ownerDetails:
            UtxoAddressDetails(publicKey: pubHex, address: segwitAddr),
      );

      final hex = buildAndSignUnifiedTx(
        utxoWithAddresses: [utxoLegacy, utxoSegwit],
        outputs: [
          BitcoinOutput(address: segwitAddr, value: BigInt.from(290000)),
        ],
        privateKeysByPublicKey: {pubHex: key},
        fee: BigInt.from(10000),
      );

      final tx = BtcTransaction.deserialize(BytesUtils.fromHexString(hex));
      expect(tx.inputs.length, 2);
      // Tx con witness marker → 2 witness: legacy vuota, segwit [sig, pub].
      expect(tx.witnesses.length, 2);
      expect(
        tx.witnesses[0].stack,
        isEmpty,
        reason: 'input legacy in tx segwit → witness vuota',
      );
      expect(tx.witnesses[1].stack.length, 2);
      // scriptSig presente solo sull'input legacy.
      expect(tx.inputs[0].scriptSig.toHex().isNotEmpty, isTrue);
      expect(
        tx.inputs[1].scriptSig.toHex(),
        isEmpty,
        reason: 'P2WPKH native non ha scriptSig',
      );

      final spentScripts = [
        legacyAddr.toScriptPubKey(),
        segwitAddr.toScriptPubKey(),
      ];
      final amounts = [BigInt.from(100000), BigInt.from(200000)];

      // Firma legacy → digest type 0.
      final legacyDigest = computeUnifiedSighash(
        tx: tx,
        txInIndex: 0,
        scriptCode: legacyAddr.toScriptPubKey(),
        spentAmounts: amounts,
        spentScripts: spentScripts,
        scriptType: 0,
      );
      final scriptSigBytes =
          BytesUtils.fromHexString(tx.inputs[0].scriptSig.toHex());
      final sigLen = scriptSigBytes.first;
      final legacySig = scriptSigBytes.sublist(1, 1 + sigLen);
      final verifier = BitcoinSignatureVerifier.fromKeyBytes(
          BytesUtils.fromHexString(pubHex),);
      expect(
        verifier.verifyECDSADerSignature(
          digest: legacyDigest,
          signature: legacySig.sublist(0, legacySig.length - 1),
        ),
        isTrue,
        reason: 'la firma dell\'input legacy deve verificare sul type 0',
      );

      // Firma segwit → digest type 1 (scriptCode BIP143 = P2PKH).
      final segwitDigest = computeUnifiedSighash(
        tx: tx,
        txInIndex: 1,
        scriptCode: pub.toAddress().toScriptPubKey(),
        spentAmounts: amounts,
        spentScripts: spentScripts,
        scriptType: 1,
      );
      final segwitSig = tx.witnesses[1].stack.first;
      final segwitSigBytes = BytesUtils.fromHexString(segwitSig);
      expect(
        verifier.verifyECDSADerSignature(
          digest: segwitDigest,
          signature: segwitSigBytes.sublist(0, segwitSigBytes.length - 1),
        ),
        isTrue,
        reason: 'la firma dell\'input segwit deve verificare sul type 1',
      );
    });
  });

  group(
      'Vettori ufficiali (unified_sighash.json, script_type=1, hashType=0x21)',
      () {
    // Vettori estratti da src/test/data/unified_sighash.json del PR #357
    // (privkeyio/hf-sighash-opt-in). Sono 8 casi segwit v0 con SIGHASH_ALL|UNIFIED
    // (0x21) — lo stesso caso d'uso dell'app. Hashes raw, non reversed.
    // Gli stessi casi sono nella spec normativa Knots `doc/unified-sighash.md`
    // @ `v29.4.1.knots20260508` (166 vettori totali): qui ne pinniamo 8.
    final vectors = <Map<String, Object>>[
      {
        'scriptCode': '515151515151',
        'rawTx':
            '8e197b4c0194140e3f6cb8a9d6ca4088e0a815b50735368cf53764d84558499518643b09740d6dea19002155ac0602c372fe59aa0e010007565656565656563f9c44ce1e3c0600055555555555419088c0',
        'inIdx': 0,
        'spent': [
          {'value': BigInt.from(163728673632716), 'script': '51515151515151'},
        ],
        'sighash':
            'f2c5bab31e7924172309e841f22885a287927cecb6e06fec9abc8902882fe659',
      },
      {
        'scriptCode': '5252',
        'rawTx':
            'cc2a0f220184cfa91629b696f8bda445973bcd0746a284a4b0f4c78ef37cc84f231a6b68829a7bdcc6009acc032d01f6901c4527e501000155da835819',
        'inIdx': 0,
        'spent': [
          {'value': BigInt.from(438341308167044), 'script': '5656565656565656'},
        ],
        'sighash':
            'e436aba06dbac2f6acbf0f23ba96b198f6678cd104f6bc2204c50104f7fc8cba',
      },
      {
        'scriptCode': '535353535353',
        'rawTx':
            'ebd42a0a02b75a1c5e66cf6e7dde20b612bb00772bd3573fe5eb2275111ea8651d69f1d4b494e8ce5100c890b4d7097e2e06779f9c420ea2a7e3c78496b4650e62dd391161faa604a3c733d9e72e2b40e66600d9546aac01e8740d50967500000355555526e0a6d5',
        'inIdx': 1,
        'spent': [
          {'value': BigInt.from(1597090254845911), 'script': '5454545454'},
          {'value': BigInt.from(1849715362702527), 'script': '525252525252'},
        ],
        'sighash':
            '28911b0ff2abfa96f62027f4e3a334635666014da3a8accd854c2660b7e3f13c',
      },
      {
        'scriptCode': '55555555',
        'rawTx':
            'bece061c0214507277902331b38e2a94953a6ea54b1e91936980b1e51349b35e46aa0626913aceda41001c61c866f8a0ae01e0aff0ee2786b4b6dbbac4537349cfc0a18f3da2ab29a61b068459e42891eedc0073b8730d02ec7dfe5699e600000352525271bdf5b4e3ca010004555555551b4b2051',
        'inIdx': 1,
        'spent': [
          {'value': BigInt.from(1166767615501852), 'script': '545454545454'},
          {'value': BigInt.from(1230938136281501), 'script': '545454545454'},
        ],
        'sighash':
            '4f522185c73a538bbcbc326f6a0187a6f073d672db27a1d52bc08fffe792be4b',
      },
      {
        'scriptCode': '565656565656',
        'rawTx':
            'e78d1f28015723313c0c7b198fe0304fb45e6b638fa0669f69659970efa4973eed6368540bab6fd84400937572e7030f43c1f1eeb60200045555555574bdced0bd2c03000353535363e81864da2c03000851515151515151515b17b177',
        'inIdx': 0,
        'spent': [
          {'value': BigInt.from(605598600082670), 'script': '56565656565656'},
        ],
        'sighash':
            '885cf61f29077eb60ebb8ed4c019e4ea79410b1ea1c82e04b08fa3f6b8c152cc',
      },
      {
        'scriptCode': '525252',
        'rawTx':
            'ea62133801f7aa40f6ece16904ff89582b3dedc7ab0125aa57129311bd27855d828238c244377357ba0056b3a2b102964be46f5fe80500055454545454db895ad0498f0600025555403f1498',
        'inIdx': 0,
        'spent': [
          {'value': BigInt.from(1029877187370002), 'script': '5252'},
        ],
        'sighash':
            'df93da32b5227902a9d3224f1c891bad3bbb78c32f2af5eeccafcd8228e86b69',
      },
      {
        'scriptCode': '5252',
        'rawTx':
            '2556a07e034d0d1d2ece123bc673c95ebe2e0274e7a7de12d7a9b377907bca2e117ebbb31f46963a9700d7ece6da3adde5663ef3d98d153afb11619554b83231b87e206a12300e351095eb2dfb85751a16f300bb070192c1f5e09c3cc90dfad2140cc7edb7b0b18d9f39b013924d8511206c1111d36c99dabbc40800841a1d860132d6f09784f904000853535353535353532f84d0c1',
        'inIdx': 2,
        'spent': [
          {'value': BigInt.from(1066671014058054), 'script': '52525252525252'},
          {
            'value': BigInt.from(1214768938606586),
            'script': '5656565656565656',
          },
          {'value': BigInt.from(1855602602674740), 'script': '53535353'},
        ],
        'sighash':
            '30bd7a3812ace8682f0637e415a44ed092ae173d27160714d276333a6273d532',
      },
      {
        'scriptCode': '53535353535353',
        'rawTx':
            '4d2b3a46010b4a44b840a3a55dfa98b6eebe96077ef13c62723ab6b287df45c810df8d9ceb7735541b00a1094cb10281d09ea91ab10000065656565656566910b1c3967905000456565656e3577348',
        'inIdx': 0,
        'spent': [
          {'value': BigInt.from(32625082010655), 'script': '54545454545454'},
        ],
        'sighash':
            'c8882a3305da5d6df92413f2bedebc4a1258c0ff5375a39bdea3f1b30f56bcfc',
      },
    ];

    for (var vi = 0; vi < vectors.length; vi++) {
      final v = vectors[vi];
      test(
          'vector $vi: scriptCode=${(v['scriptCode'] as String).substring(0, 4)}... inIdx=${v['inIdx']}',
          () {
        final tx = BtcTransaction.deserialize(
          BytesUtils.fromHexString(v['rawTx'] as String),
        );
        final spent = (v['spent'] as List<Map<String, Object>>);
        // PERCHÉ: il digest serializza i BYTE RAW dello script (CompactSize +
        // byte). Script(script: ['hex']) tratterebbe la stringa come data-push
        // aggiungendo un prefisso di lunghezza; Script.deserialize dà i byte esatti.
        final digest = computeUnifiedSighash(
          tx: tx,
          txInIndex: v['inIdx'] as int,
          scriptCode: Script.deserialize(
            bytes: BytesUtils.fromHexString(v['scriptCode'] as String),
          ),
          spentAmounts: spent.map((e) => e['value'] as BigInt).toList(),
          spentScripts: spent
              .map(
                (e) => Script.deserialize(
                  bytes: BytesUtils.fromHexString(e['script'] as String),
                ),
              )
              .toList(),
        );
        expect(
          BytesUtils.toHexString(digest),
          v['sighash'] as String,
          reason: 'vector $vi — digest non corrisponde alla spec',
        );
      });
    }
  });
}
