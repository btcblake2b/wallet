import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/digests/ripemd160.dart';

import 'package:btc_blake2b_wallet/core/services/psbt/psbt_service.dart';
import 'package:btc_blake2b_wallet/core/services/unified_sighash.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PSBT (P4 — M0)
// ─────────────────────────────────────────────────────────────────────────────
// PERCHÉ questi test sono critici: il percorso PSBT muove fondi reali. La prova
// che conta non è "il codice gira" ma che **la firma prodotta coincida** con
// quella del builder già in produzione (`buildAndSignUnifiedTx`): stessa
// costruzione + stesso digest + stessa firma ⇒ stesso rischio, zero regressioni.

/// Chiave deterministica di test (scalar 42, come nei test dei vettori).
final ECPrivate _key = ECPrivate.fromBytes(
  BigintUtils.toBytes(BigInt.from(42), length: 32, order: Endian.big),
);
final String _pubHex = _key.getPublic().toHex();

UtxoWithAddress _utxo({
  String? txHash,
  int vout = 0,
  int value = 100000,
  ECPrivate? key,
}) {
  final owner = key ?? _key;
  return UtxoWithAddress(
    utxo: BitcoinUtxo(
      txHash: txHash ?? 'a' * 64,
      value: BigInt.from(value),
      vout: vout,
      scriptType: SegwitAddressType.p2wpkh,
    ),
    ownerDetails: UtxoAddressDetails(
      publicKey: owner.getPublic().toHex(),
      address: owner.getPublic().toSegwitAddress(),
    ),
  );
}

BitcoinOutput _output({int value = 90000, ECPrivate? to}) {
  final recipient = to ?? _key;
  return BitcoinOutput(
    address: recipient.getPublic().toSegwitAddress(),
    value: BigInt.from(value),
  );
}

PsbtInputBip32DerivationPath _derivation() {
  return PsbtInputBip32DerivationPath(
    fingerprint: const <int>[1, 2, 3, 4],
    indexes: Bip32PathParser.parse("m/84'/0'/0'/0/0").elems,
    publicKey: BytesUtils.fromHexString(_pubHex),
  );
}

String _createPsbt({
  List<UtxoWithAddress>? utxos,
  List<BitcoinOutput>? outputs,
  int fee = 10000,
  Map<String, PsbtInputBip32DerivationPath>? derivations,
}) {
  return createPsbtBase64(
    utxoWithAddresses: utxos ?? <UtxoWithAddress>[_utxo()],
    outputs: outputs ?? <BitcoinOutput>[_output()],
    fee: BigInt.from(fee),
    bip32DerivationByPublicKey: derivations,
  );
}

List<int> _partialSignatureBytes(String psbtBase64) {
  final signed = signPsbtBase64(
    psbtBase64: psbtBase64,
    privateKeysByPublicKey: <String, ECPrivate>{_pubHex: _key},
  );
  final builder = PsbtBuilder.fromBase64<PsbtBuilderV0>(signed);
  return builder.psbtInputs().first.partialSigs!.first.signature;
}

void main() {
  group('createPsbtBase64', () {
    test('riepilogo coerente: input, output e fee', () {
      final summary = summarizePsbt(_createPsbt());

      expect(summary.totalInputs, 1);
      expect(summary.outputs.length, 1);
      expect(summary.inputSats, BigInt.from(100000));
      expect(summary.outputSats, BigInt.from(90000));
      expect(summary.feeSats, BigInt.from(10000));
      // Senza derivazioni dichiarate la PSBT resta firmabile solo da chi
      // conosce già i path (nostro caso M0).
      expect(summary.signableInputs, 0);
    });

    test('con derivazione BIP32 l input è marcato firmabile', () {
      final summary = summarizePsbt(
        _createPsbt(
          derivations: <String, PsbtInputBip32DerivationPath>{
            _pubHex: _derivation(),
          },
        ),
      );

      expect(summary.signableInputs, 1);
    });

    test('input legacy → StateError (scope M0 dichiarato)', () {
      final legacy = UtxoWithAddress(
        utxo: BitcoinUtxo(
          txHash: 'a' * 64,
          value: BigInt.from(1000),
          vout: 0,
          scriptType: P2pkhAddressType.p2pkh,
        ),
        ownerDetails: UtxoAddressDetails(
          publicKey: _pubHex,
          address: _key.getPublic().toAddress(),
        ),
      );

      expect(
        () => createPsbtBase64(
          utxoWithAddresses: <UtxoWithAddress>[legacy],
          outputs: <BitcoinOutput>[_output()],
          fee: BigInt.from(1000),
        ),
        throwsStateError,
      );
    });

    test('fee incoerente con input/output → StateError', () {
      // 100000 in, 90000 out, fee dichiarata 5000 → 5000 sat non giustificati.
      expect(() => _createPsbt(fee: 5000), throwsStateError);
    });

    test('nessun input o nessun output → StateError', () {
      expect(
        () => createPsbtBase64(
          utxoWithAddresses: const <UtxoWithAddress>[],
          outputs: <BitcoinOutput>[_output()],
          fee: BigInt.from(10000),
        ),
        throwsStateError,
      );
      expect(
        () => createPsbtBase64(
          utxoWithAddresses: <UtxoWithAddress>[_utxo()],
          outputs: const <BitcoinOutput>[],
          fee: BigInt.from(10000),
        ),
        throwsStateError,
      );
    });
  });

  group('signPsbtBase64 / finalizePsbtToTxHex', () {
    test('EQUIVALENZA col builder diretto (stessa firma, stessa tx)', () {
      final utxo = _utxo();
      final output = _output();
      final fee = BigInt.from(10000);

      // (a) percorso PSBT: crea → firma → finalizza
      final psbtHex = finalizePsbtToTxHex(
        signPsbtBase64(
          psbtBase64: createPsbtBase64(
            utxoWithAddresses: <UtxoWithAddress>[utxo],
            outputs: <BitcoinOutput>[output],
            fee: fee,
          ),
          privateKeysByPublicKey: <String, ECPrivate>{_pubHex: _key},
        ),
      );

      // (b) percorso diretto già in produzione
      final directHex = buildAndSignUnifiedTx(
        utxoWithAddresses: <UtxoWithAddress>[utxo],
        outputs: <BitcoinOutput>[output],
        privateKeysByPublicKey: <String, ECPrivate>{_pubHex: _key},
        fee: fee,
        enableRBF: true,
      );

      final psbtTx = BtcTransaction.deserialize(
        BytesUtils.fromHexString(psbtHex),
      );
      final directTx = BtcTransaction.deserialize(
        BytesUtils.fromHexString(directHex),
      );

      // PROVA: se ordine input, sequence o scriptCode divergessero, i digest
      // differirebbero e quindi anche le firme. Firma uguale ⇒ costruzione
      // uguale ⇒ nessuna regressione sul percorso che già funziona.
      expect(
        psbtTx.witnesses.first.stack.first,
        directTx.witnesses.first.stack.first,
      );
      expect(
        psbtTx.witnesses.first.stack[1],
        directTx.witnesses.first.stack[1],
      );
      expect(
        psbtTx.outputs.map((o) => o.amount).toList(),
        directTx.outputs.map((o) => o.amount).toList(),
      );
      // Firma deterministica (RFC 6979) + stessa costruzione ⇒ stesso hex.
      expect(psbtHex, directHex);
    });

    test('la partial sig termina col byte sighash UNIFIED 0x21', () {
      final signature = _partialSignatureBytes(
        _createPsbt(
          derivations: <String, PsbtInputBip32DerivationPath>{
            _pubHex: _derivation(),
          },
        ),
      );

      expect(signature.last, 0x21);
    });

    test('la firma è legata agli output: PSBT manomessa → firma diversa', () {
      final signatureA = _partialSignatureBytes(
        _createPsbt(
          outputs: <BitcoinOutput>[_output(value: 90000)],
          fee: 10000,
        ),
      );
      final signatureB = _partialSignatureBytes(
        _createPsbt(
          outputs: <BitcoinOutput>[_output(value: 80000)],
          fee: 20000,
        ),
      );

      expect(signatureA, isNot(signatureB));
    });

    test('input senza chiave privata nota → StateError', () {
      final psbt = _createPsbt(
        derivations: <String, PsbtInputBip32DerivationPath>{
          _pubHex: _derivation(),
        },
      );

      expect(
        () => signPsbtBase64(
          psbtBase64: psbt,
          privateKeysByPublicKey: const <String, ECPrivate>{},
        ),
        throwsStateError,
      );
    });

    test('senza derivazione BIP32 la chiave si riconosce dal witnessUtxo', () {
      // // PERCHÉ: lo script P2WPKH (0014<hash160>) contiene l'impronta della
      // chiave: una PSBT senza metadati di derivazione deve restare firmabile
      // (è il caso di una PSBT prodotta da un altro strumento).
      final signed = signPsbtBase64(
        psbtBase64: _createPsbt(),
        privateKeysByPublicKey: <String, ECPrivate>{_pubHex: _key},
      );

      final builder = PsbtBuilder.fromBase64<PsbtBuilderV0>(signed);
      expect(builder.psbtInputs().first.partialSigs, hasLength(1));
    });

    test('chiave estranea → StateError (nessun input firmabile)', () {
      final otherKey = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(7), length: 32, order: Endian.big),
      );

      expect(
        () => signPsbtBase64(
          psbtBase64: _createPsbt(),
          privateKeysByPublicKey: <String, ECPrivate>{
            otherKey.getPublic().toHex(): otherKey,
          },
        ),
        throwsStateError,
      );
    });

    test('finalize di una PSBT non firmata → errore (mai tx parziale)', () {
      expect(
        () => finalizePsbtToTxHex(_createPsbt()),
        throwsA(anything),
      );
    });
  });

  group('createPsbtFromInputs (percorso senza chiavi: watch-only)', () {
    // ScriptPubKey reale dell'output speso, calcolato con la stessa ricetta
    // dell'app (`_pubKeyHash160Hex` in bitcoin_service): `0014` + hash160.
    // // PERCHÉ non si usa `Script.toHex()` della libreria: verificato che NON
    // round-trippa per script appena costruiti (produce hex corrotto), quindi
    // come sorgente di verità si usa la ricetta, non il serializer.
    String p2wpkhScriptHex(String publicKeyHex) {
      final sha =
          crypto.sha256.convert(BytesUtils.fromHexString(publicKeyHex)).bytes;
      final hash = RIPEMD160Digest().process(Uint8List.fromList(sha));
      final hashHex =
          hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      return '0014$hashHex';
    }

    final String spentScriptHex = p2wpkhScriptHex(_pubHex);

    PsbtInputSpec spec({int valueSats = 100000}) => PsbtInputSpec(
          txid: 'a' * 64,
          vout: 0,
          valueSats: valueSats,
          scriptPubKeyHex: spentScriptHex,
          derivationPath: "m/84'/0'/0'/0/0",
          publicKeyHex: _pubHex,
        );

    test(
        'PSBT creata SENZA chiavi → firmata dal dispositivo con seed produce '
        'la stessa transazione del percorso diretto', () {
      const int fee = 10000;
      final psbt = createPsbtFromInputs(
        inputs: <PsbtInputSpec>[spec()],
        outputs: <BitcoinOutput>[_output()],
        fee: BigInt.from(fee),
      );

      // Il dispositivo watch-only non ha chiavi: la PSBT si crea comunque.
      final summary = summarizePsbt(psbt);
      expect(summary.inputSats, BigInt.from(100000));
      expect(summary.feeSats, BigInt.from(fee));

      // Il dispositivo con il seed la firma e la finalizza.
      final psbtHex = finalizePsbtToTxHex(
        signPsbtBase64(
          psbtBase64: psbt,
          privateKeysByPublicKey: <String, ECPrivate>{_pubHex: _key},
        ),
      );

      final directHex = buildAndSignUnifiedTx(
        utxoWithAddresses: <UtxoWithAddress>[_utxo()],
        outputs: <BitcoinOutput>[_output()],
        privateKeysByPublicKey: <String, ECPrivate>{_pubHex: _key},
        fee: BigInt.from(fee),
        enableRBF: true,
      );

      // PROVA: stessa firma ⇒ stesso digest ⇒ stessa transazione. Il percorso
      // "crea su un dispositivo, firma su un altro" è equivalente al percorso
      // diretto già in produzione.
      final psbtTx = BtcTransaction.deserialize(
        BytesUtils.fromHexString(psbtHex),
      );
      final directTx = BtcTransaction.deserialize(
        BytesUtils.fromHexString(directHex),
      );
      expect(
        psbtTx.witnesses.first.stack.first,
        directTx.witnesses.first.stack.first,
      );
      expect(psbtHex, directHex);
    });

    test('script non P2WPKH → StateError (scope M0)', () {
      expect(
        () => createPsbtFromInputs(
          inputs: <PsbtInputSpec>[
            PsbtInputSpec(
              txid: 'a' * 64,
              vout: 0,
              valueSats: 100000,
              scriptPubKeyHex: 'a914${'b' * 40}87',
              publicKeyHex: _pubHex,
            ),
          ],
          outputs: <BitcoinOutput>[_output()],
          fee: BigInt.from(10000),
        ),
        throwsStateError,
      );
    });

    test('script on-chain di un ALTRA chiave → StateError (proprietà)', () {
      // PERCHÉ: uno script P2WPKH formalmente valido ma di un altra chiave non
      // è spendibile da questa: la PSBT non deve nemmeno essere costruita.
      final otherKey = ECPrivate.fromBytes(
        BigintUtils.toBytes(BigInt.from(9), length: 32, order: Endian.big),
      );
      final otherScriptHex = p2wpkhScriptHex(otherKey.getPublic().toHex());

      expect(
        () => createPsbtFromInputs(
          inputs: <PsbtInputSpec>[
            PsbtInputSpec(
              txid: 'a' * 64,
              vout: 0,
              valueSats: 100000,
              scriptPubKeyHex: otherScriptHex,
              publicKeyHex: _pubHex,
            ),
          ],
          outputs: <BitcoinOutput>[_output()],
          fee: BigInt.from(10000),
        ),
        throwsStateError,
      );
    });

    test('fee incoerente → StateError', () {
      expect(
        () => createPsbtFromInputs(
          inputs: <PsbtInputSpec>[spec()],
          outputs: <BitcoinOutput>[_output()],
          fee: BigInt.from(5000),
        ),
        throwsStateError,
      );
    });

    test('metadato BIP32 presente solo con fingerprint del master', () {
      final withFingerprint = PsbtBuilder.fromBase64<PsbtBuilderV0>(
        createPsbtFromInputs(
          inputs: <PsbtInputSpec>[spec()],
          outputs: <BitcoinOutput>[_output()],
          fee: BigInt.from(10000),
          masterFingerprint: const <int>[1, 2, 3, 4],
        ),
      );
      expect(
        withFingerprint.psbtInputs().first.bip32derivationPath,
        isNotNull,
      );

      final withoutFingerprint = PsbtBuilder.fromBase64<PsbtBuilderV0>(
        createPsbtFromInputs(
          inputs: <PsbtInputSpec>[spec()],
          outputs: <BitcoinOutput>[_output()],
          fee: BigInt.from(10000),
        ),
      );
      // // PERCHÉ: senza fingerprint la derivazione non è verificabile dal
      // firmatario → meglio nessun metadato che un metadato incompleto.
      expect(
        withoutFingerprint.psbtInputs().first.bip32derivationPath,
        isNull,
      );
    });
  });
}
