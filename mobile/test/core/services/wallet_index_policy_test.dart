import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/wallet_index_policy.dart';

void main() {
  group('WalletIndexPolicy — tabella flag × stato (ADR 30/10-7 §2)', () {
    test('flag spento + legacy → publicAddress', () {
      expect(
        WalletIndexPolicy.resolve(
          rotationEnabled: false,
          state: IndicesState.legacyUninitialized,
        ),
        ReceiveAddressMode.legacyPublicAddress,
      );
    });

    test('flag spento + valid → legge /0/N senza avanzare', () {
      expect(
        WalletIndexPolicy.resolve(
          rotationEnabled: false,
          state: IndicesState.valid,
        ),
        ReceiveAddressMode.readOnlyIndex,
      );
    });

    test('flag spento + corrotto → FAIL-CLOSED (il flag non è un bypass)', () {
      // PERCHÉ: se il kill switch potesse ignorare la corruzione, sarebbe un
      // fail-open con un nome nuovo — esattamente ciò che ADR 30/10-7 vieta.
      expect(
        WalletIndexPolicy.resolve(
          rotationEnabled: false,
          state: IndicesState.corrupt,
        ),
        ReceiveAddressMode.blocked,
      );
      expect(
        WalletIndexPolicy.resolve(
          rotationEnabled: false,
          state: IndicesState.anomalous,
        ),
        ReceiveAddressMode.blocked,
      );
    });

    test('flag acceso + legacy → serve adozione esplicita', () {
      expect(
        WalletIndexPolicy.resolve(
          rotationEnabled: true,
          state: IndicesState.legacyUninitialized,
        ),
        ReceiveAddressMode.needsAdoption,
      );
    });

    test('flag acceso + valid → write-ahead CAS', () {
      expect(
        WalletIndexPolicy.resolve(
          rotationEnabled: true,
          state: IndicesState.valid,
        ),
        ReceiveAddressMode.rotate,
      );
    });

    test('flag acceso + corrotto/anomalo → fail-closed', () {
      for (final state in [IndicesState.corrupt, IndicesState.anomalous]) {
        expect(
          WalletIndexPolicy.resolve(rotationEnabled: true, state: state),
          ReceiveAddressMode.blocked,
          reason: 'stato $state deve bloccare con flag acceso',
        );
      }
    });

    test('tutte le 8 combinazioni sono coperte e deterministiche', () {
      // PERCHÉ: la tabella è chiusa — nessuna combinazione deve restare
      // ambigua quando un domani si aggiunge uno stato all'enum.
      for (final rotation in [true, false]) {
        for (final state in IndicesState.values) {
          final mode = WalletIndexPolicy.resolve(
            rotationEnabled: rotation,
            state: state,
          );
          expect(
            mode,
            isNotNull,
            reason: 'rotazione=$rotation stato=$state',
          );
        }
      }
    });

    test('blockedState distingue corrotto da anomalo (uscite diverse)', () {
      // PERCHÉ: `blocked` è uguale per entrambi, ma la UX no — il corrotto ha
      // anche «riparti da 0», l'anomalo no. La UI legge questo, non lo stato
      // re-interpretato in ogni schermata.
      expect(
        WalletIndexPolicy.blockedState(IndicesState.corrupt),
        IndicesState.corrupt,
      );
      expect(
        WalletIndexPolicy.blockedState(IndicesState.anomalous),
        IndicesState.anomalous,
      );
      expect(WalletIndexPolicy.blockedState(IndicesState.valid), isNull);
      expect(
        WalletIndexPolicy.blockedState(IndicesState.legacyUninitialized),
        isNull,
      );
    });

    test('restore: indice autoritativo = max(persistito, scansione)', () {
      // PERCHÉ (ADR 30/10-12 §3): il persistito è un floor anche per la
      // ricezione — il record non scende mai, altrimenti si riusa un indirizzo.
      expect(
        WalletIndexPolicy.resolveRestoredReceiveIndex(
          persisted: 6,
          scanned: 6,
        ),
        6,
      );
      // Gap-scan trova meno usage del record: vince il record.
      expect(
        WalletIndexPolicy.resolveRestoredReceiveIndex(
          persisted: 6,
          scanned: 3,
        ),
        6,
      );
      // Gap-scan trova più usage del record: vince la scansione.
      expect(
        WalletIndexPolicy.resolveRestoredReceiveIndex(
          persisted: 2,
          scanned: 9,
        ),
        9,
      );
      // Valori negativi (difensivo) degradano a 0, non a un indice impossibile.
      expect(
        WalletIndexPolicy.resolveRestoredReceiveIndex(
          persisted: -5,
          scanned: -1,
        ),
        0,
      );
    });

    test('restore su record corrotto/anomalo: fail-closed, non si risolve', () {
      // PERCHÉ (ADR 30/10-13): il restore è il percorso di recupero — fissare
      // come autoritativo l'indice di un record non valido sarebbe inventarlo.
      final corrupt = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'w1',
        'encrypted_seed': 'enc',
        'public_address': 'bc1q',
        'device_id': 'dev',
        'created_at': '2026-10-30T00:00:00.000Z',
        'schema_version': 2,
        'next_receive_index': -2,
        'next_change_index': 0,
      });
      final anomalous = WalletRecord.fromMap(<String, dynamic>{
        'wallet_id': 'w1',
        'encrypted_seed': 'enc',
        'public_address': 'bc1q',
        'device_id': 'dev',
        'created_at': '2026-10-30T00:00:00.000Z',
        'schema_version': 2,
        'next_receive_index': WalletRecord.maxDerivationIndex + 5,
        'next_change_index': 0,
      });

      expect(
        () => WalletIndexPolicy.resolveRestoredReceiveIndexFor(
          record: corrupt,
          scanned: 4,
        ),
        throwsA(isA<CorruptWalletIndicesException>()),
      );
      expect(
        () => WalletIndexPolicy.resolveRestoredReceiveIndexFor(
          record: anomalous,
          scanned: 4,
        ),
        throwsA(isA<AnomalousWalletIndexException>()),
      );
    });

    test('blockedState non può divergere da resolve (una sola fonte)', () {
      // PERCHÉ: due mappature dello stesso stato divergerebbero il giorno in cui
      // qualcuno ne cambia una. Il legame è asserito qui.
      for (final rotation in [true, false]) {
        for (final state in IndicesState.values) {
          final isBlocked = WalletIndexPolicy.resolve(
                rotationEnabled: rotation,
                state: state,
              ) ==
              ReceiveAddressMode.blocked;
          final hasBlockedState = WalletIndexPolicy.blockedState(state) != null;
          expect(
            hasBlockedState,
            isBlocked,
            reason: 'stato $state con rotazione=$rotation',
          );
        }
      }
    });
  });
}
