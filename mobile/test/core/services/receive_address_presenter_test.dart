import 'package:flutter_test/flutter_test.dart';
import 'package:btc_blake2b_wallet/core/config/feature_flags.dart';
import 'package:btc_blake2b_wallet/core/models/wallet_record.dart';
import 'package:btc_blake2b_wallet/core/services/receive_address_presenter.dart';

void main() {
  group('ReceiveAddressPresenter (ADR 31/10-21)', () {
    test('esito fresco vs già assegnato', () {
      expect(
        ReceiveAddressPresenter.fromResult(isFresh: true),
        ReceiveAddressView.fresh,
      );
      expect(
        ReceiveAddressPresenter.fromResult(isFresh: false),
        ReceiveAddressView.alreadyAssigned,
      );
    });

    test('corrotto e anomalo hanno viste DIVERSE (uscite diverse)', () {
      expect(
        ReceiveAddressPresenter.fromState(
          state: IndicesState.corrupt,
          rotationEnabled: true,
        ),
        ReceiveAddressView.corruptBlocked,
      );
      expect(
        ReceiveAddressPresenter.fromState(
          state: IndicesState.anomalous,
          rotationEnabled: true,
        ),
        ReceiveAddressView.anomalousBlocked,
      );
    });

    test('corrotto/anomalo bloccano anche con rotazione spenta', () {
      for (final state in [IndicesState.corrupt, IndicesState.anomalous]) {
        final view = ReceiveAddressPresenter.fromState(
          state: state,
          rotationEnabled: false,
        );
        expect(ReceiveAddressPresenter.canReceive(view), isFalse);
        expect(ReceiveAddressPresenter.blocksSpending(view), isTrue);
      }
    });

    test('legacy + rotazione attiva richiede adozione', () {
      expect(
        ReceiveAddressPresenter.fromState(
          state: IndicesState.legacyUninitialized,
          rotationEnabled: true,
        ),
        ReceiveAddressView.adoptionRequired,
      );
    });

    test('legacy + rotazione spenta: si può ricevere (publicAddress)', () {
      final view = ReceiveAddressPresenter.fromState(
        state: IndicesState.legacyUninitialized,
        rotationEnabled: false,
      );
      expect(view, ReceiveAddressView.alreadyAssigned);
      expect(ReceiveAddressPresenter.canReceive(view), isTrue);
      expect(ReceiveAddressPresenter.blocksSpending(view), isFalse);
    });

    test('valid con rotazione spenta: indirizzo leggibile, invio consentito',
        () {
      final view = ReceiveAddressPresenter.fromState(
        state: IndicesState.valid,
        rotationEnabled: false,
      );
      expect(ReceiveAddressPresenter.canReceive(view), isTrue);
      expect(ReceiveAddressPresenter.blocksSpending(view), isFalse);
    });

    test('seedRequired: non si riceve, ma NON si blocca l\'invio', () {
      // PERCHÉ (ADR 02/11-29 §1): `canReceive`/`blocksSpending` sono `==` su
      // enum, quindi il compilatore non segnala un valore non nominato. Queste
      // due asserzioni sono l'unica difesa: senza, `seedRequired` poteva
      // finire «incluso» o «escluso» per caso.
      expect(
        ReceiveAddressPresenter.canReceive(ReceiveAddressView.seedRequired),
        isFalse,
        reason: 'senza xpub non si può derivare l\'indirizzo di ricezione',
      );
      expect(
        ReceiveAddressPresenter.blocksSpending(
          ReceiveAddressView.seedRequired,
        ),
        isFalse,
        reason: 'l\'invio ha il proprio sblocco (password) e usa la seed: '
            'bloccarlo impedirebbe di spendere',
      );
    });

    test('seedMismatch: né ricezione né invio (ADR 02/11-33 §1)', () {
      // PERCHÉ diverso da seedRequired: la seed c'è, è quella sbagliata.
      // Sbloccare non serve, e nessuna derivazione è affidabile — nemmeno il
      // resto di un invio, quindi qui anche lo spending si blocca.
      expect(
        ReceiveAddressPresenter.canReceive(ReceiveAddressView.seedMismatch),
        isFalse,
      );
      expect(
        ReceiveAddressPresenter.blocksSpending(ReceiveAddressView.seedMismatch),
        isTrue,
        reason: 'seed del vault ≠ seed del wallet: i PSBT avrebbero '
            'indirizzi incoerenti',
      );
    });

    test('FeatureFlags: default conservativo, override da dart-define', () {
      // PERCHÉ: senza `--dart-define` la rotazione è spenta, così una build di
      // rollback non richiede modifiche al codice.
      expect(FeatureFlags.current.walletIndexRotation, isFalse);
    });
  });
}
