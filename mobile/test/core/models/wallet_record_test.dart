import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';

void main() {
  group('WalletRecord', () {
    test('should instantiate', () {
      final sut = WalletRecord(
        walletId: 'test_wallet_id',
        encryptedSeed: 'test_encrypted_seed',
        publicAddress: 'test_public_address',
        deviceId: 'test_device_id',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(sut, isNotNull);
      expect(sut.walletId, 'test_wallet_id');
    });

    test('fromMap migra i record legacy ignorando il campo state', () {
      // PERCHÉ: i record salvati prima della rimozione di locked/unlocked
      // contengono 'state' — fromMap deve ignorarlo senza errori.
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'legacy_id',
        'encrypted_seed': 'enc',
        'public_address': 'tb1qlegacy',
        'state': 'locked',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(sut.walletId, 'legacy_id');
      expect(sut.publicAddress, 'tb1qlegacy');
    });

    test('default kind hot e accountXpub null per i wallet seed', () {
      final sut = WalletRecord(
        walletId: 'id',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qaddr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
      );

      // PERCHÉ: default hot = zero breaking su tutti i wallet esistenti.
      expect(sut.kind, WalletKind.hot);
      expect(sut.accountXpub, isNull);
    });

    test('fromMap senza kind migra a hot (record pre-watch-only)', () {
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'legacy_id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(sut.kind, WalletKind.hot);
      expect(sut.accountXpub, isNull);
    });

    test('round-trip toMap/fromMap preserva kind watchOnly e accountXpub', () {
      final sut = WalletRecord(
        walletId: 'wo_id',
        encryptedSeed: '',
        publicAddress: 'bc1qwatch',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
        kind: WalletKind.watchOnly,
        accountXpub:
            'xpub6CUGRUonZSQ4TWtTMmzXdrXDtypWKiKrhko4egpiMZbpiaQL2jkwSB1icqYh2cfDfVxdx4df189oLKnC5fSwqPfgyP3hooxujYzAu3fDVmz',
      );

      final restored = WalletRecord.fromMap(sut.toMap());

      expect(restored.kind, WalletKind.watchOnly);
      expect(restored.accountXpub, sut.accountXpub);
      expect(restored.encryptedSeed, '');
    });

    test('copyWith cambia kind/accountXpub e clearAccountXpub azzera', () {
      final sut = WalletRecord(
        walletId: 'id',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qaddr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
      );

      final asWatch = sut.copyWith(
        kind: WalletKind.watchOnly,
        accountXpub:
            'xpub6CUGRUonZSQ4TWtTMmzXdrXDtypWKiKrhko4egpiMZbpiaQL2jkwSB1icqYh2cfDfVxdx4df189oLKnC5fSwqPfgyP3hooxujYzAu3fDVmz',
      );
      expect(asWatch.kind, WalletKind.watchOnly);
      expect(asWatch.accountXpub, isNotNull);

      final cleared = asWatch.copyWith(clearAccountXpub: true);
      expect(cleared.kind, WalletKind.watchOnly);
      expect(cleared.accountXpub, isNull);
    });

    test('txNotes: round-trip toMap/fromMap preserva le note', () {
      final sut = WalletRecord(
        walletId: 'id',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qaddr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
        txNotes: const {'tx1': 'colazione', 'tx2': 'affitto'},
      );

      final restored = WalletRecord.fromMap(sut.toMap());

      expect(restored.txNotes, {'tx1': 'colazione', 'tx2': 'affitto'});
      expect(restored.noteFor('tx1'), 'colazione');
    });

    test('fromMap senza tx_notes → mappa vuota (record pre-note)', () {
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'legacy_id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(sut.txNotes, isEmpty);
      expect(sut.noteFor('qualsiasi'), isNull);
    });

    test('fromMap con tx_notes di tipo inatteso → mappa vuota, nessun crash',
        () {
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
        'tx_notes': 'non-una-mappa',
      });

      expect(sut.txNotes, isEmpty);
    });

    test('noteFor ignora note vuote o di soli spazi', () {
      final sut = WalletRecord(
        walletId: 'id',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qaddr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
        txNotes: const {'tx1': '   ', 'tx2': ' ok '},
      );

      expect(sut.noteFor('tx1'), isNull);
      expect(sut.noteFor('tx2'), 'ok');
      expect(sut.noteFor('assente'), isNull);
    });

    test('copyWith aggiorna txNotes senza toccare utxoLabels', () {
      final sut = WalletRecord(
        walletId: 'id',
        encryptedSeed: 'enc',
        publicAddress: 'bc1qaddr',
        deviceId: 'dev',
        createdAt: DateTime(2024, 1, 1),
        utxoLabels: const {'txid:0': 'utxo'},
      );

      final updated = sut.copyWith(txNotes: const {'tx1': 'nota'});

      expect(updated.txNotes, {'tx1': 'nota'});
      expect(updated.utxoLabels, {'txid:0': 'utxo'});
      // PERCHÉ: i record sono immutabili — l'istanza di partenza non cambia.
      expect(sut.txNotes, isEmpty);
    });
  });

  group('WalletRecord — indici persistiti (ADR 30/10)', () {
    WalletRecord buildRecord() => WalletRecord(
          walletId: 'id',
          encryptedSeed: 'enc',
          publicAddress: 'bc1qaddr',
          deviceId: 'dev',
          createdAt: DateTime(2024, 1, 1),
        );

    test('default: schemaVersion corrente e indici a zero', () {
      final sut = buildRecord();

      expect(sut.schemaVersion, WalletRecord.currentSchemaVersion);
      expect(sut.requireNextReceiveIndex(), 0);
      expect(sut.requireNextChangeIndex(), 0);
      expect(sut.hasPersistedIndices, isTrue);
    });

    test('roundtrip toMap/fromMap conserva gli indici', () {
      final sut = buildRecord().copyWith(
        nextReceiveIndex: 7,
        nextChangeIndex: 3,
      );

      final restored = WalletRecord.fromMap(sut.toMap());

      expect(restored.schemaVersion, WalletRecord.currentSchemaVersion);
      expect(restored.requireNextReceiveIndex(), 7);
      expect(restored.requireNextChangeIndex(), 3);
    });

    test('record legacy senza i nuovi campi: schema v1, indici a zero', () {
      // PERCHÉ: il record salvato da una build precedente non ha né
      // `schema_version` né gli indici — deve restare leggibile e
      // riconoscibile come legacy (base della migrazione dry-run).
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'legacy_id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qlegacy',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(sut.schemaVersion, WalletRecord.legacySchemaVersion);
      expect(sut.hasPersistedIndices, isFalse);
      expect(sut.indicesState, IndicesState.legacyUninitialized);
      expect(sut.requireNextReceiveIndex(), 0);
      expect(sut.requireNextChangeIndex(), 0);
    });

    test('v2 corrotto: fail closed, nessun indice restituito', () {
      // PERCHÉ (ADR 30/10-5): un v2 con indici illeggibili NON si resetta a 0 —
      // `/0/0` è `publicAddress`, già usato: sarebbe address reuse silenzioso.
      final sut = WalletRecord.fromMap(
        _v2Map(receive: -4, change: 'non-un-numero'),
      );

      expect(sut.schemaVersion, WalletRecord.currentSchemaVersion);
      expect(sut.indicesState, IndicesState.corrupt);
      expect(
        sut.requireNextReceiveIndex,
        throwsA(isA<CorruptWalletIndicesException>()),
      );
      expect(
        sut.requireNextChangeIndex,
        throwsA(isA<CorruptWalletIndicesException>()),
      );
    });

    test('v2 senza i campi indice: corrotto, non zero', () {
      // PERCHÉ: un record dichiarato v2 deve avere gli indici. Se mancano, il
      // dato è incompleto — non «legacy», quindi non si parte da 0.
      final sut = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
        'schema_version': 2,
      });

      expect(sut.indicesState, IndicesState.corrupt);
      expect(
        sut.requireNextReceiveIndex,
        throwsA(isA<CorruptWalletIndicesException>()),
      );
    });

    test('negativo, overflow, stringa e null esplicito sono corruzione', () {
      for (final bad in <Object?>[
        -1,
        -99999,
        WalletRecord.maxSaneIndex + 1,
        'x',
        null,
      ]) {
        final sut = WalletRecord.fromMap(_v2Map(receive: bad, change: 0));

        expect(
          sut.indicesState,
          IndicesState.corrupt,
          reason: 'valore $bad deve essere trattato come corrotto',
        );
      }
    });

    test('la corruzione sopravvive al roundtrip (non viene «lavata»)', () {
      // PERCHÉ: senza `indices_state` nel JSON, un toMap/fromMap rileggerebbe
      // 0 come dato valido e il riuso comincerebbe al riavvio successivo.
      final corrupt = WalletRecord.fromMap(_v2Map(receive: -4, change: 0));
      final restored = WalletRecord.fromMap(corrupt.toMap());

      expect(restored.indicesState, IndicesState.corrupt);
      expect(restored.toMap()['indices_state'], 'corrupt');
    });

    test('copyWith preserva schemaVersion e hasPersistedIndices', () {
      final sut = buildRecord().copyWith(nextReceiveIndex: 3);

      final renamed = sut.copyWith(name: 'Spese');

      expect(renamed.schemaVersion, WalletRecord.currentSchemaVersion);
      expect(renamed.hasPersistedIndices, isTrue);
    });

    test('nessun percorso pubblico da corrotto a valido tranne confirmReset',
        () {
      // PERCHÉ (ADR 30/10-6): lo stato non è un parametro di copyWith — un
      // chiamante distratto non può «aggiustare» il record.
      final corrupt = WalletRecord.fromMap(_v2Map(receive: -4, change: -1));

      final touched = corrupt.copyWith(nextReceiveIndex: 0);
      expect(touched.indicesState, IndicesState.corrupt);
      expect(
        touched.requireNextReceiveIndex,
        throwsA(isA<CorruptWalletIndicesException>()),
      );

      final confirmed =
          corrupt.confirmResetIndices(newReceive: 0, newChange: 0);
      expect(confirmed.indicesState, IndicesState.valid);
      expect(confirmed.requireNextReceiveIndex(), 0);
      expect(confirmed.requireNextChangeIndex(), 0);
      // La versione di schema non cambia: si adottano indici, non un formato.
      expect(confirmed.schemaVersion, WalletRecord.currentSchemaVersion);
    });

    test('confirmResetIndices valida i valori proposti', () {
      final corrupt = WalletRecord.fromMap(_v2Map(receive: -4, change: -1));

      expect(
        () => corrupt.confirmResetIndices(newReceive: -1, newChange: 0),
        throwsA(isA<InvalidWalletIndexException>()),
      );
      expect(
        () => corrupt.confirmResetIndices(
          newReceive: 0,
          newChange: WalletRecord.maxSaneIndex + 1,
        ),
        throwsA(isA<InvalidWalletIndexException>()),
      );
      // Il record di partenza resta corrotto: nessun effetto collaterale.
      expect(corrupt.indicesState, IndicesState.corrupt);
    });

    test('advanceReceiveIndex: write-ahead con compare-and-set', () {
      // PERCHÉ (ADR 30/10-7): il chiamante persiste N+1 prima di mostrare
      // /0/N. La primitiva è un CAS: se il record è già avanzato, non avanza
      // una seconda volta (doppio tap non deve consumare due indirizzi).
      final sut = buildRecord();
      final advanced = sut.advanceReceiveIndex(expected: 0);

      expect(advanced.requireNextReceiveIndex(), 1);
      // Il record di partenza non cambia (immutabilità).
      expect(sut.requireNextReceiveIndex(), 0);

      expect(
        () => advanced.advanceReceiveIndex(expected: 0),
        throwsA(
          isA<IndexConflictException>()
              .having((e) => e.expected, 'expected', 0)
              .having((e) => e.actual, 'actual', 1),
        ),
      );
      // …e non ha consumato un secondo indirizzo.
      expect(advanced.requireNextReceiveIndex(), 1);
    });

    test('advanceReceiveIndex: rifiuta stati non valid', () {
      final legacy = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      final corrupt = WalletRecord.fromMap(_v2Map(receive: -4, change: 0));

      expect(
        () => legacy.advanceReceiveIndex(expected: 0),
        throwsA(isA<InvalidWalletIndexException>()),
      );
      expect(
        () => corrupt.advanceReceiveIndex(expected: 0),
        throwsA(isA<InvalidWalletIndexException>()),
      );
    });

    test('dry-run: fromMap su record legacy non scrive nulla', () {
      // PERCHÉ (ADR e): il dry-run è «leggi il record esistente e guarda cosa
      // diventerebbe» — la mappa di partenza non deve essere mutata e nessuna
      // scrittura deve avvenire in questo percorso.
      final legacy = <String, dynamic>{
        'wallet_id': 'legacy_id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qlegacy',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
      };
      final snapshot = Map<String, dynamic>.from(legacy);

      final dryRun = WalletRecord.fromMap(legacy);

      // La mappa originale resta identica (nessuna migrazione in-place)…
      expect(legacy, snapshot);
      // …e il record dice cosa diventerebbe, senza persisterlo.
      expect(dryRun.indicesState, IndicesState.legacyUninitialized);
      expect(dryRun.schemaVersion, WalletRecord.legacySchemaVersion);
      expect(dryRun.hasPersistedIndices, isFalse);
      // Cosa diventerebbe: adozione esplicita degli indici iniziali.
      final migrated = dryRun.confirmResetIndices(
        newReceive: 0,
        newChange: 0,
      );
      expect(migrated.indicesState, IndicesState.valid);
      expect(migrated.requireNextReceiveIndex(), 0);
      // …e il record di partenza non è stato toccato.
      expect(dryRun.indicesState, IndicesState.legacyUninitialized);
    });

    test('nessuno stato illegale: etichetta valid senza dati = corrotto', () {
      // PERCHÉ (ADR 30/10-6): un'etichetta «valid» senza indici leggibili non
      // si crede (fail closed); legacy + indici scritti = record già migrato.
      final labelledValid = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
        'schema_version': 2,
        'indices_state': 'valid',
      });
      expect(labelledValid.indicesState, IndicesState.corrupt);

      final legacyWithKeys = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'id',
        'encrypted_seed': 'enc',
        'public_address': 'bc1qaddr',
        'device_id': 'dev',
        'created_at': '2024-01-01T00:00:00.000Z',
        'indices_state': 'legacyUninitialized',
        'next_receive_index': 3,
        'next_change_index': 1,
      });
      expect(legacyWithKeys.indicesState, IndicesState.valid);
      expect(legacyWithKeys.requireNextReceiveIndex(), 3);
    });

    test('indice anomalo: fail-closed con eccezione dedicata, non corrotto',
        () {
      // PERCHÉ (ADR 30/10-8): oltre maxDerivationIndex il valore è leggibile ma
      // fuori scala — messaggio diverso dal corrotto, stessa chiusura.
      final anomalous = WalletRecord.fromMap(
        _v2Map(
          receive: WalletRecord.maxDerivationIndex + 1,
          change: 0,
        ),
      );

      expect(anomalous.indicesState, IndicesState.anomalous);
      expect(anomalous.isAnomalous, isTrue);
      expect(
        anomalous.requireNextReceiveIndex,
        throwsA(isA<AnomalousWalletIndexException>()),
      );
      // Roundtrip: la classificazione non si perde.
      expect(
        WalletRecord.fromMap(anomalous.toMap()).indicesState,
        IndicesState.anomalous,
      );
      // Al confine: maxDerivationIndex è ancora valido.
      final boundary = WalletRecord.fromMap(
        _v2Map(receive: WalletRecord.maxDerivationIndex, change: 0),
      );
      expect(boundary.indicesState, IndicesState.valid);
      expect(
        boundary.requireNextReceiveIndex(),
        WalletRecord.maxDerivationIndex,
      );
    });

    test('confirmResetIndices non accetta un indice anomalo', () {
      final corrupt = WalletRecord.fromMap(_v2Map(receive: -4, change: -1));

      expect(
        () => corrupt.confirmResetIndices(
          newReceive: WalletRecord.maxDerivationIndex + 1,
          newChange: 0,
        ),
        throwsA(isA<InvalidWalletIndexException>()),
      );
    });

    test('reset VIETATO da indice anomalo: sarebbe reuse informato', () {
      // PERCHÉ (ADR 30/10-9): l'indice anomalo è NOTO (es. 15.000 incassi
      // reali). Ripartire da 0 non recupera nulla: riusa 15.000 indirizzi.
      final anomalous = WalletRecord.fromMap(
        _v2Map(receive: 15000, change: 0),
      );

      expect(
        () => anomalous.confirmResetIndices(newReceive: 0, newChange: 0),
        throwsA(isA<AnomalousWalletIndexException>()),
      );
      expect(anomalous.requireNextReceiveIndex, throwsA(isA<Exception>()));
    });

    test('reset rifiutato anche su record già valido', () {
      final valid = buildRecord().copyWith(nextReceiveIndex: 4);

      expect(
        () => valid.confirmResetIndices(newReceive: 0, newChange: 0),
        throwsA(isA<InvalidWalletIndexException>()),
      );
      expect(valid.requireNextReceiveIndex(), 4);
    });

    test('advanceChangeIndex: floor che vince sul derivato (drift sicuro)', () {
      // PERCHÉ (ADR 30/10-9 §3): write-ahead + broadcast fallito ⇒ il floor
      // avanza e l'indirizzo non è usato. In lettura vince il floor: il test
      // confronta il floor con un derivato più basso, non l'uguaglianza.
      final before = buildRecord().copyWith(nextChangeIndex: 2);
      final afterBroadcastAttempt = before.advanceChangeIndex(expected: 2);

      expect(afterBroadcastAttempt.requireNextChangeIndex(), 3);
      // Broadcast fallito: nessun UTXO nuovo → il derivato resta 1.
      const derivedFromUtxos = 1;
      final effective = [
        derivedFromUtxos,
        afterBroadcastAttempt.requireNextChangeIndex(),
      ].reduce((a, b) => a > b ? a : b);
      expect(effective, 3);
      // …e un secondo tentativo con lo stesso expected non avanza di nuovo.
      expect(
        () => afterBroadcastAttempt.advanceChangeIndex(expected: 2),
        throwsA(isA<IndexConflictException>()),
      );
    });

    test('advanceChangeIndex: rifiuta stati non valid', () {
      final corrupt = WalletRecord.fromMap(_v2Map(receive: -4, change: 0));

      expect(
        () => corrupt.advanceChangeIndex(expected: 0),
        throwsA(isA<InvalidWalletIndexException>()),
      );
    });

    test('consumer A4: legge, incrementa e riserializza senza perdite', () {
      // Simula A4 (scanner/incasso): chiede un indirizzo nuovo e lo consuma.
      final consumer = FakeA4Consumer(buildRecord());

      final first = consumer.nextReceiveAddress();
      final second = consumer.nextReceiveAddress();
      final third = consumer.nextReceiveAddress();

      expect(<String>{first, second, third}, hasLength(3));
      expect(consumer.record.requireNextReceiveIndex(), 3);
      // Il contratto regge anche dopo un salvataggio/rilettura.
      final reloaded = WalletRecord.fromMap(consumer.record.toMap());
      expect(reloaded.requireNextReceiveIndex(), 3);
      expect(reloaded.indicesState, IndicesState.valid);
    });

    test('consumer B2: legge indirizzo e label per la ricevuta', () {
      // Simula B2 (Cassa): ricevuta con indirizzo, indice e label.
      final record = buildRecord().copyWith(nextReceiveIndex: 4);
      final receipt = const FakeB2Consumer().receiptFor(
        record: record,
        label: 'Caffè',
      );

      expect(receipt, contains('bc1qaddr'));
      expect(receipt, contains('/0/4'));
      expect(receipt, contains('Caffè'));
    });

    test('consumer B2: su record corrotto fallisce, non inventa un indirizzo',
        () {
      final corrupt = WalletRecord.fromMap(_v2Map(receive: -1, change: 0));

      expect(
        () => const FakeB2Consumer().receiptFor(
          record: corrupt,
          label: 'Caffè',
        ),
        throwsA(isA<CorruptWalletIndicesException>()),
      );
    });
  });
}

/// Mappa di un record v2 con indici parametrici (anche non validi).
Map<String, dynamic> _v2Map({Object? receive, Object? change}) {
  return <String, dynamic>{
    'wallet_id': 'id',
    'encrypted_seed': 'enc',
    'public_address': 'bc1qaddr',
    'device_id': 'dev',
    'created_at': '2024-01-01T00:00:00.000Z',
    'schema_version': 2,
    'next_receive_index': receive,
    'next_change_index': change,
  };
}

/// Consumatore finto che si comporta come A4: chiede un indirizzo nuovo,
/// consuma l'indice e riserializza il record.
class FakeA4Consumer {
  FakeA4Consumer(this.record);

  WalletRecord record;

  String nextReceiveAddress() {
    final index = record.requireNextReceiveIndex();
    // Write-ahead con CAS: il repository persisterebbe `record` subito dopo.
    record = record.advanceReceiveIndex(expected: index);
    return '${record.publicAddress}#/0/$index';
  }
}

/// Consumatore finto che si comporta come B2: compone una ricevuta leggendo
/// indirizzo e indice dal record (fail closed se il record è corrotto).
class FakeB2Consumer {
  const FakeB2Consumer();

  String receiptFor({required WalletRecord record, required String label}) {
    final index = record.requireNextReceiveIndex();
    return 'receipt;${record.publicAddress};/0/$index;$label';
  }
}
