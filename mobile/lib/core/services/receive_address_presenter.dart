import '../models/wallet_record.dart';
import 'wallet_index_policy.dart';

/// Cosa la UI deve mostrare sul percorso di ricezione.
///
/// // PERCHÉ un tipo dedicato (ADR 31/10-21): la tabella flag × stato e le
/// // eccezioni del repository sono la verità, ma ogni schermata aveva bisogno
/// // di ri-tradurle in messaggi diversi (`corrupt` → tre vie, `anomalous` →
/// // restore/supporto, `needsAdoption` → conferma). Un solo punto di traduzione
/// // evita che metà delle schermate mostri il messaggio generico.
enum ReceiveAddressView {
  /// Indirizzo pronto e **nuovo** (indice consumato in questa richiesta).
  fresh,

  /// Indirizzo valido ma già assegnato (doppio tap): non è «nuovo».
  alreadyAssigned,

  /// Wallet legacy con rotazione attiva: serve la conferma dell'utente.
  adoptionRequired,

  /// Indici corrotti: ricezione e invio bloccati, uscite dedicate.
  corruptBlocked,

  /// Indice anomalo (oltre il tetto di derivazione): solo restore/supporto.
  anomalousBlocked,

  /// Il wallet non ha `accountXpub` e serve il seed per derivare.
  ///
  /// // PERCHÉ distinta (ADR 02/11-28 §1): l'azione è «sblocca il vault e salva
  /// // l'xpub», non «verifica il backup» né «riprova». Prima era uno
  /// // `StateError` generico.
  seedRequired,

  /// La seed del vault **non corrisponde** al wallet (`/0/0` derivato ≠
  /// `publicAddress`).
  ///
  /// // PERCHÉ distinta da [seedRequired] (ADR 02/11-33 §1): sbloccare non
  /// // serve — la seed è quella sbagliata. Le uscite sono «verifica il
  /// // backup» e «supporto», e il fail-closed evita di persistere un xpub che
  /// // produrrebbe indirizzi diversi da quelli con storia on-chain.
  seedMismatch,
}

/// Traduzione pura (nessun I/O) di stato + esito in [ReceiveAddressView].
class ReceiveAddressPresenter {
  const ReceiveAddressPresenter._();

  /// Da un risultato di lettura riuscita.
  static ReceiveAddressView fromResult({required bool isFresh}) {
    return isFresh
        ? ReceiveAddressView.fresh
        : ReceiveAddressView.alreadyAssigned;
  }

  /// Da uno stato del record, quando non c'è ancora un risultato.
  static ReceiveAddressView fromState({
    required IndicesState state,
    required bool rotationEnabled,
  }) {
    final mode = WalletIndexPolicy.resolve(
      rotationEnabled: rotationEnabled,
      state: state,
    );
    switch (mode) {
      case ReceiveAddressMode.blocked:
        // Il tipo di blocco cambia le uscite: per questo si rilegge lo stato.
        return WalletIndexPolicy.blockedState(state) == IndicesState.anomalous
            ? ReceiveAddressView.anomalousBlocked
            : ReceiveAddressView.corruptBlocked;
      case ReceiveAddressMode.needsAdoption:
        return ReceiveAddressView.adoptionRequired;
      case ReceiveAddressMode.rotate:
      case ReceiveAddressMode.readOnlyIndex:
      case ReceiveAddressMode.legacyPublicAddress:
        return ReceiveAddressView.alreadyAssigned;
    }
  }

  /// True se la ricezione è possibile in questo stato.
  ///
  /// // PERCHÉ (ADR 30/10-6 §4): con indici corrotti/anomali la ricezione è
  /// // **disabilitata** — mostrare `publicAddress` sarebbe riuso.
  static bool canReceive(ReceiveAddressView view) =>
      view == ReceiveAddressView.fresh ||
      view == ReceiveAddressView.alreadyAssigned;

  /// True se l'invio va bloccato (stesso fail-closed della ricezione: il record
  /// è un'unità e il resto potrebbe riusare `/1/N`).
  ///
  /// // PERCHÉ `seedRequired` NON blocca l'invio (ADR 02/11-29 §1): quel caso
  /// // significa «manca l'xpub per derivare l'INDIRIZZO DI RICEZIONE». Il
  /// // flusso di invio ha già il proprio sblocco (chiede la password e usa la
  /// // seed), quindi bloccarlo impedirebbe di spendere fondi che l'utente ha.
  /// // È una decisione, non un default: l'assert è nel test.
  ///
  /// // PERCHÉ `seedMismatch` INVECE blocca (ADR 02/11-33 §1): la seed del vault
  /// // non è quella del wallet, quindi nessuna derivazione è affidabile — né
  /// // per ricevere né per costruire il resto di un invio. Bloccare è più
  /// // onesto che produrre un PSBT con indirizzi incoerenti.
  static bool blocksSpending(ReceiveAddressView view) =>
      view == ReceiveAddressView.corruptBlocked ||
      view == ReceiveAddressView.anomalousBlocked ||
      view == ReceiveAddressView.seedMismatch;
}
