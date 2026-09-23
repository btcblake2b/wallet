/// Ramo BIP44 di un indirizzo del wallet.
///
/// // PERCHÉ (P7): la distinzione fra `/0` (ricezione) e `/1` (resto) è
/// informazione per l'utente, non un dettaglio tecnico — chi guarda i propri
/// indirizzi deve capire perché alcuni nascono come resto delle proprie spese.
enum WalletAddressBranch { external, change }

/// Stato di utilizzo di un indirizzo, derivato dall'attività on-chain.
enum WalletAddressStatus {
  /// Mai comparso in nessuna transazione.
  unused,

  /// Usato ma senza saldo: fondi ricevuti e poi spesi.
  usedEmpty,

  /// Con saldo disponibile.
  hasFunds,
}

/// Indirizzo derivato del wallet con il suo stato on-chain.
///
/// Stile del progetto: classe manuale (niente Freezed/JsonSerializable), const
/// constructor, campi `final`; come [UtxoInfo] NON è serializzabile perché non
/// viene mai persistita (si ricava a ogni apertura della schermata).
class WalletAddress {
  const WalletAddress({
    required this.address,
    required this.branch,
    required this.index,
    required this.derivationPath,
    required this.balanceSats,
    required this.txCount,
  });

  final String address;

  /// Ramo di derivazione (`/0` ricezione, `/1` resto).
  final WalletAddressBranch branch;

  /// Indice nel ramo (0-based, come nel path BIP44).
  final int index;

  /// Path completo di derivazione (es. `m/84'/0'/0'/0/5`).
  final String derivationPath;

  /// Saldo in satoshi (catena confermata + mempool).
  final int balanceSats;

  /// Transazioni che toccano l'indirizzo (catena + mempool).
  final int txCount;

  /// Stato dell'indirizzo, DERIVATO da [txCount] e [balanceSats].
  ///
  /// // PERCHÉ (P7): un campo `status` separato sarebbe una seconda verità
  /// desincronizzabile; con questa regola un indirizzo usato e poi speso
  /// (`txCount > 0`, saldo 0) NON viene presentato come "mai usato".
  WalletAddressStatus get status {
    if (txCount == 0) return WalletAddressStatus.unused;
    return balanceSats > 0
        ? WalletAddressStatus.hasFunds
        : WalletAddressStatus.usedEmpty;
  }

  /// True se l'indirizzo è già comparso sulla chain (almeno una transazione).
  bool get hasActivity => txCount > 0;

  WalletAddress copyWith({int? balanceSats, int? txCount}) {
    return WalletAddress(
      address: address,
      branch: branch,
      index: index,
      derivationPath: derivationPath,
      balanceSats: balanceSats ?? this.balanceSats,
      txCount: txCount ?? this.txCount,
    );
  }
}
