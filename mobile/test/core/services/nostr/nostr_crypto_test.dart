import 'dart:convert';

import 'package:btc_blake2b_wallet/core/services/nostr/nostr_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vettori ufficiali BIP340: github.com/bitcoin/bips/blob/master/bip-0340/test-vectors.csv
/// (usate le righe 0-3 per la firma con aux esplicito e la riga 6 come caso negativo).
void main() {
  group('BIP340 — sign (vettori ufficiali)', () {
    test('vettore 0: zero aux, zero message', () {
      final sig = NostrCrypto.schnorrSign(
        privkeyHex:
            '0000000000000000000000000000000000000000000000000000000000000003',
        messageHex:
            '0000000000000000000000000000000000000000000000000000000000000000',
        auxHex:
            '0000000000000000000000000000000000000000000000000000000000000000',
      );
      expect(
        sig.toLowerCase(),
        'e907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca8215'
        '25f66a4a85ea8b71e482a74f382d2ce5ebeee8fdb2172f477df4900d310536c0',
      );
    });

    test('vettore 1', () {
      final sig = NostrCrypto.schnorrSign(
        privkeyHex:
            'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
        messageHex:
            '243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c89',
        auxHex:
            '0000000000000000000000000000000000000000000000000000000000000001',
      );
      expect(
        sig.toLowerCase(),
        '6896bd60eeae296db48a229ff71dfe071bde413e6d43f917dc8dcf8c78de3341'
        '8906d11ac976abccb20b091292bff4ea897efcb639ea871cfa95f6de339e4b0a',
      );
    });

    test('vettore 2', () {
      final sig = NostrCrypto.schnorrSign(
        privkeyHex:
            'c90fdaa22168c234c4c6628b80dc1cd129024e088a67cc74020bbea63b14e5c9',
        messageHex:
            '7e2d58d8b3bcdf1abadec7829054f90dda9805aab56c77333024b9d0a508b75c',
        auxHex:
            'c87aa53824b4d7ae2eb035a2b5bbbccc080e76cdc6d1692c4b0b62d798e6d906',
      );
      expect(
        sig.toLowerCase(),
        '5831aaeed7b44bb74e5eab94ba9d4294c49bcf2a60728d8b4c200f50dd313c1b'
        'ab745879a5ad954a72c45a91c3a51d3c7adea98d82f8481e0e1e03674a6f3fb7',
      );
    });

    test('vettore 3: aux e message tutti 0xFF (caso modulo)', () {
      final sig = NostrCrypto.schnorrSign(
        privkeyHex:
            '0b432b2677937381aef05bb02a66ecd012773062cf3fa2549e44f58ed2401710',
        messageHex:
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
        auxHex:
            'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      );
      expect(
        sig.toLowerCase(),
        '7eb0509757e246f19449885651611cb965ecc1a187dd51b64fda1edc9637d5ec9'
        '7582b9cb13db3933705b32ba982af5af25fd78881ebb32771fc5922efc66ea3',
      );
    });
  });

  group('BIP340 — verify', () {
    test('accetta le firme dei vettori ufficiali', () {
      expect(
        NostrCrypto.schnorrVerify(
          pubkeyHex:
              'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
          messageHex:
              '0000000000000000000000000000000000000000000000000000000000000000',
          signatureHex:
              'e907831f80848d1069a5371b402410364bdf1c5f8307b0084c55f1ce2dca8215'
              '25f66a4a85ea8b71e482a74f382d2ce5ebeee8fdb2172f477df4900d310536c0',
        ),
        isTrue,
      );
    });

    test('rifiuta la firma del vettore negativo 6', () {
      expect(
        NostrCrypto.schnorrVerify(
          pubkeyHex:
              'dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659',
          messageHex:
              '243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c89',
          signatureHex:
              'fff97bd5755eeea420453a14355235d382f6472f8568a18b2f057a1460297556'
              '3cc27944640ac607cd107ae10923d9ef7a73c643e166be5ebea34b1ac553e2',
        ),
        isFalse,
      );
    });

    test('input malformato → false (nessuna eccezione)', () {
      expect(
        NostrCrypto.schnorrVerify(
          pubkeyHex: 'zz',
          messageHex: 'zz',
          signatureHex: 'zz',
        ),
        isFalse,
      );
    });
  });

  group('derivePublicKey', () {
    test('coincide con la pubkey dei vettori ufficiali', () {
      expect(
        NostrCrypto.derivePublicKey(
          'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef',
        ),
        'dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659',
      );
    });
  });

  group('NIP-04', () {
    // Coppia di chiavi dai vettori BIP340 (valori pubblici di test).
    const skA =
        '0000000000000000000000000000000000000000000000000000000000000003';
    const skB =
        'b7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef';
    const pkA =
        'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9';
    const pkB =
        'dff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659';

    test('round-trip A→B', () {
      final payload = NostrCrypto.nip04Encrypt(
          privkeyHex: skA, pubkeyHex: pkB, plaintext: 'ciao da A',);
      expect(
        NostrCrypto.nip04Decrypt(
            privkeyHex: skB, pubkeyHex: pkA, payload: payload,),
        'ciao da A',
      );
    });

    test('round-trip B→A (parità opposta)', () {
      final payload = NostrCrypto.nip04Encrypt(
        privkeyHex: skB,
        pubkeyHex: pkA,
        plaintext: 'risposta di B',
      );
      expect(
        NostrCrypto.nip04Decrypt(
            privkeyHex: skA, pubkeyHex: pkB, payload: payload,),
        'risposta di B',
      );
    });

    test('formato: base64?iv=base64 con IV di 16 byte', () {
      final payload = NostrCrypto.nip04Encrypt(
          privkeyHex: skA, pubkeyHex: pkB, plaintext: 'x',);
      expect(payload.contains('?iv='), isTrue);
      final ivB64 = payload.substring(payload.lastIndexOf('?iv=') + 4);
      expect(base64.decode(ivB64).length, 16);
    });

    test('payload senza ?iv= → FormatException', () {
      expect(
        () => NostrCrypto.nip04Decrypt(
          privkeyHex: skA,
          pubkeyHex: pkB,
          payload: 'non-valido',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('decrypt con chiave sbagliata NON restituisce il plaintext', () {
      final payload = NostrCrypto.nip04Encrypt(
        privkeyHex: skA,
        pubkeyHex: pkB,
        plaintext: 'segretissimo',
      );
      String? decrypted;
      try {
        // pkA al posto di pkB: shared secret diverso.
        decrypted = NostrCrypto.nip04Decrypt(
          privkeyHex: skA,
          pubkeyHex: pkA,
          payload: payload,
        );
      } catch (_) {
        decrypted = null; // padding PKCS7 non valido → eccezione attesa
      }
      expect(decrypted, isNot('segretissimo'));
    });
  });

  group('randomHex32', () {
    test('64 char hex, lowercase, chiamate indipendenti', () {
      final a = NostrCrypto.randomHex32();
      final b = NostrCrypto.randomHex32();
      expect(a.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(a), isTrue);
      expect(a == b, isFalse);
    });
  });
}
