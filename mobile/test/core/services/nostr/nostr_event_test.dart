import 'dart:convert';

import 'package:btc_blake2b_wallet/core/services/nostr/nostr_event.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Vettori di test Nostr: keypair dal file BIP340 ufficiale.
void main() {
  const priv =
      '0000000000000000000000000000000000000000000000000000000000000003';
  const pub =
      'f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9';

  group('computeId (NIP-01)', () {
    test('serializzazione canonica: sha256 della stringa attesa', () {
      // // PERCHÉ: stringa costruita a mano — se cambiasse la serializzazione
      // (spazi, escaping, ordine) questo test fallirebbe.
      const expectedSerialized =
          '[0,"$pub",1700000000,23194,[["p","abc"]],"hello"]';
      final id = NostrEvent.computeId(
        pubkey: pub,
        createdAt: 1700000000,
        kind: 23194,
        tags: [
          ['p', 'abc'],
        ],
        content: 'hello',
      );
      expect(id, sha256.convert(utf8.encode(expectedSerialized)).toString());
    });

    test('deterministico: chiamate ripetute → stesso id', () {
      String compute() => NostrEvent.computeId(
            pubkey: pub,
            createdAt: 1700000000,
            kind: 23198,
            tags: const [],
            content: '{"method":"list_channels","params":{}}',
          );
      expect(compute(), compute());
    });

    test('content diverso → id diverso', () {
      final a = NostrEvent.computeId(
        pubkey: pub,
        createdAt: 1700000000,
        kind: 23198,
        tags: const [],
        content: 'a',
      );
      final b = NostrEvent.computeId(
        pubkey: pub,
        createdAt: 1700000000,
        kind: 23198,
        tags: const [],
        content: 'b',
      );
      expect(a, isNot(b));
    });

    test('id è 64 char hex lowercase', () {
      final id = NostrEvent.computeId(
        pubkey: pub,
        createdAt: 1,
        kind: 1,
        tags: const [],
        content: '',
      );
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(id), isTrue);
    });
  });

  group('unsigned / sign / verify', () {
    test('unsigned: sig vuota, id presente, isSigned false', () {
      final event = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23194,
        createdAt: 1700000000,
      );
      expect(event.sig, isEmpty);
      expect(event.id.length, 64);
      expect(event.isSigned, isFalse);
    });

    test('sign produce una firma valida (verify true)', () {
      final event = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23194,
        tags: [
          ['p', 'deadbeef'],
        ],
        content: 'test',
        createdAt: 1700000000,
      ).sign(priv);

      expect(event.sig.length, 128);
      expect(event.isSigned, isTrue);
      expect(event.verify(), isTrue);
    });

    test('due firme dello stesso evento sono entrambe valide (aux random)', () {
      final base = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23194,
        content: 'stesso contenuto',
        createdAt: 1700000000,
      );
      final first = base.sign(priv);
      final second = base.sign(priv);
      expect(first.sig == second.sig, isFalse);
      expect(first.verify(), isTrue);
      expect(second.verify(), isTrue);
    });

    test('evento manomesso (firma di un altro payload) → verify false', () {
      final original = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23194,
        content: 'contenuto originale',
        createdAt: 1700000000,
      ).sign(priv);

      final forged = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23194,
        content: 'contenuto manomesso',
        createdAt: 1700000000,
      ).copyWith(sig: original.sig);

      expect(forged.verify(), isFalse);
    });

    test('tag alterato con id+firma originali -> verify false (SEC-01)', () {
      final original = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23194,
        tags: [
          ['p', 'node_pubkey'],
        ],
        content: 'contenuto',
        createdAt: 1700000000,
      ).sign(priv);

      // Attacco relay: stesso id/firma ma tag sostituito (redirezione `e`).
      final tampered = NostrEvent(
        id: original.id,
        pubkey: original.pubkey,
        createdAt: original.createdAt,
        kind: original.kind,
        tags: [
          ['p', 'attacker_pubkey'],
        ],
        content: original.content,
        sig: original.sig,
      );

      expect(tampered.verify(), isFalse);
    });
  });

  group('serializzazione', () {
    test('toJson/fromJson round-trip completo', () {
      final event = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23198,
        tags: [
          ['p', 'node_pubkey'],
          ['e', 'request_id'],
        ],
        content: 'cifrato?iv=abc',
        createdAt: 1700000000,
      ).sign(priv);

      final restored = NostrEvent.fromJson(event.toJson());
      expect(restored.id, event.id);
      expect(restored.pubkey, event.pubkey);
      expect(restored.createdAt, event.createdAt);
      expect(restored.kind, event.kind);
      expect(restored.tags, event.tags);
      expect(restored.content, event.content);
      expect(restored.sig, event.sig);
      expect(restored.verify(), isTrue);
    });

    test('fromJson difensivo su campi mancanti', () {
      final restored = NostrEvent.fromJson(const {});
      expect(restored.id, isEmpty);
      expect(restored.createdAt, 0);
      expect(restored.tags, isEmpty);
      expect(restored.isSigned, isFalse);
    });

    test('tag `e` e `p` per la correlazione delle risposte', () {
      final event = NostrEvent.unsigned(
        pubkey: pub,
        kind: 23195,
        tags: [
          ['p', 'client_pubkey'],
          ['e', 'request_event_id'],
        ],
        content: 'x',
        createdAt: 1700000000,
      );
      expect(event.firstTagValue('p'), 'client_pubkey');
      expect(event.firstTagValue('e'), 'request_event_id');
      expect(event.firstTagValue('x'), isNull);
    });
  });
}
