import '../config/feature_flags.dart';
import '../models/wallet_record.dart';
import 'receive_address_presenter.dart';
import 'wallet_repository.dart';

/// Esito della risoluzione dell'indirizzo di ricezione per la UI.
class ReceiveAddressResolution {
  const ReceiveAddressResolution({
    required this.view,
    this.address,
    this.index,
    this.derivationPath,
    this.record,
  });

  final ReceiveAddressView view;

  /// Presente solo per [ReceiveAddressView.fresh] e
  /// [ReceiveAddressView.alreadyAssigned].
  final String? address;
  final int? index;
  final String? derivationPath;

  /// Record **persistito** dopo l'operazione (l'indice può essere avanzato e,
  /// per un wallet legacy, il backfill può aver aggiunto `accountXpub`).
  ///
  /// // PERCHÉ esposto (ADR 02/11-32 §1): la schermata tiene una copia in
  /// // memoria del wallet. Se non la aggiorna, `hasAccountXpub` resta falso e
  /// // il tap successivo su Ricevi decifra di nuovo la seed — l'invariante
  /// // «una volta sola» sarebbe vera nel repository e falsa nell'app.
  final WalletRecord? record;

  bool get hasAddress => address != null;
}

/// Unico punto in cui la UI chiede **quale indirizzo mostrare**.
///
/// // PERCHÉ un servizio e non chiamate sparse (ADR 31/10-23): la schermata
/// // Cassa e quella Ricevi devono comportarsi allo stesso modo davanti agli
/// // stessi quattro casi (`fresh`, `alreadyAssigned`, `adoptionRequired`,
/// // `corrupt`/`anomalous`). Traducendo le eccezioni del repository in viste
/// // qui, una schermata non può dimenticarsi un caso.
class ReceiveAddressService {
  const ReceiveAddressService({
    required WalletRepository repository,
    required FeatureFlags flags,
  })  : _repository = repository,
        _flags = flags;

  final WalletRepository _repository;
  final FeatureFlags _flags;

  /// Risolve l'indirizzo. [mnemonic] serve solo ai wallet **senza**
  /// `accountXpub` (record precedenti al 26/10): con l'xpub si deriva senza
  /// decifrare la seed.
  Future<ReceiveAddressResolution> next(
    WalletRecord wallet, {
    String? mnemonic,
    bool adoptLegacy = false,
  }) async {
    // Controllo rapido sullo stato in memoria: evita una chiamata inutile.
    // La decisione vera la prende il repository sul record persistito.
    final pre = ReceiveAddressPresenter.fromState(
      state: wallet.indicesState,
      rotationEnabled: _flags.walletIndexRotation,
    );
    if (!ReceiveAddressPresenter.canReceive(pre)) {
      return ReceiveAddressResolution(view: pre);
    }

    try {
      final result = await _repository.nextReceiveAddress(
        wallet,
        rotationEnabled: _flags.walletIndexRotation,
        adoptLegacy: adoptLegacy,
        mnemonic: mnemonic,
      );
      return ReceiveAddressResolution(
        view: ReceiveAddressPresenter.fromResult(isFresh: result.isFresh),
        address: result.address,
        index: result.index,
        derivationPath: result.derivationPath,
        record: result.record,
      );
    } on WalletIndicesAdoptionRequiredException {
      return const ReceiveAddressResolution(
        view: ReceiveAddressView.adoptionRequired,
      );
    } on CorruptWalletIndicesException {
      return const ReceiveAddressResolution(
        view: ReceiveAddressView.corruptBlocked,
      );
    } on AnomalousWalletIndexException {
      return const ReceiveAddressResolution(
        view: ReceiveAddressView.anomalousBlocked,
      );
    } on SeedUnavailableException {
      // Caso noto e azionabile: sblocca il vault per derivare e salvare l'xpub.
      return const ReceiveAddressResolution(
        view: ReceiveAddressView.seedRequired,
      );
    } on SeedWalletMismatchException {
      // // PERCHÉ (ADR 02/11-33 §1): la seed del vault non è quella del wallet.
      // Sbloccare non serve; le uscite sono «verifica il backup» e «supporto».
      return const ReceiveAddressResolution(
        view: ReceiveAddressView.seedMismatch,
      );
    }
  }
}
