import 'package:bip32/bip32.dart' as bip32;

import '../config/bitcoin_network_config.dart';
import 'crypto_utils.dart';

/// Dati per derivare gli indirizzi di un wallet watch-only da una chiave
/// pubblica estesa (xpub) di account (profondità 3: m/purpose'/coin'/account').
///
/// PERCHÉ: il wallet watch-only non ha MAI il seed: solo l'xpub (chiavi
/// pubbliche). La derivazione è identica a quella hot (external /0/N e change
/// /1/N) ma parte dalla chiave pubblica, quindi non può firmare.
class WatchOnlyDerivationData {
  const WatchOnlyDerivationData({
    required this.accountXpub,
    this.scriptType = WalletScriptType.p2wpkh,
    this.addressCount = 100,
  });

  /// Chiave pubblica estesa di account (es. `xpub…` mainnet).
  final String accountXpub;

  /// Tipo di indirizzo da derivare (BIP84 native / BIP49 nested / BIP44 legacy).
  /// PERCHÉ: lo stesso xpub può essere rappresentato con encoding diversi —
  /// l'utente sceglie il tipo dell'account che vuole monitorare.
  final WalletScriptType scriptType;

  /// Numero di indirizzi da derivare per catena (external + change).
  final int addressCount;
}

/// Risultato della derivazione watch-only (solo chiavi pubbliche).
class WatchOnlyDerivationResult {
  const WatchOnlyDerivationResult({
    required this.publicAddress,
    required this.fingerprint,
    required this.accountXpub,
    required this.externalAddresses,
    required this.changeAddresses,
  });

  /// Primo indirizzo external (m/purpose'/coin'/account'/0/0) — usato come
  /// `publicAddress` del WalletRecord e chiave della BalanceCache.
  final String publicAddress;

  /// Fingerprint (4 byte HASH160) della chiave pubblica dell'account.
  final String fingerprint;

  /// L'xpub validato (normalizzato).
  final String accountXpub;

  /// Indirizzi external (ricezione): account'/0/0..N-1.
  final List<String> externalAddresses;

  /// Indirizzi change (resto): account'/1/0..N-1.
  final List<String> changeAddresses;
}

/// Deriva gli indirizzi (external e change) da un xpub di account.
///
/// Funzione top-level per essere eseguita in `compute` (derivazione
/// CPU-bound), stesso pattern di `deriveWalletData` in `crypto_utils.dart`.
///
/// Validazioni:
/// - l'xpub deve parsare con i prefissi della rete corrente (mainnet blake2b
///   = `xpub`/`0x0488b21e`; un `tpub` testnet viene rifiutato);
/// - viene rifiutata una chiave PRIVATA estesa (`xprv`): un wallet watch-only
///   non deve mai contenere chiavi private.
WatchOnlyDerivationResult deriveWatchOnlyAddresses(
  WatchOnlyDerivationData data,
) {
  final network = BitcoinNetworkConfig.bip32NetworkType;
  final bip32.BIP32 node;
  try {
    node = bip32.BIP32.fromBase58(data.accountXpub, network);
  } catch (_) {
    throw const FormatException(
      'Xpub non valido per la rete corrente (mainnet blake2b).',
    );
  }

  // PERCHÉ: se l'utente incolla un xprv, il vault conterrebbe una chiave
  // privata in un wallet che si dichiara "sola lettura" — contraddice la
  // promessa watch-only (nessun segreto). Rifiuto esplicito.
  if (node.privateKey != null) {
    throw StateError(
      'Inserisci una chiave pubblica estesa (xpub), non una privata (xprv).',
    );
  }

  final type = data.scriptType;
  final externalChain = node.derive(0);
  final changeChain = node.derive(1);

  final externalAddresses = <String>[];
  final changeAddresses = <String>[];
  for (var i = 0; i < data.addressCount; i++) {
    externalAddresses.add(
      pubKeyToAddressForType(
        externalChain.derive(i).publicKey,
        type: type,
      ),
    );
    changeAddresses.add(
      pubKeyToAddressForType(
        changeChain.derive(i).publicKey,
        type: type,
      ),
    );
  }

  // PERCHÉ: stesso formato di masterFingerprint in deriveWalletData
  // (4 byte HASH160 in hex maiuscolo).
  final fingerprint = node.fingerprint
      .map((e) => e.toRadixString(16).padLeft(2, '0'))
      .join('')
      .toUpperCase();

  return WatchOnlyDerivationResult(
    publicAddress: externalAddresses.first,
    fingerprint: fingerprint,
    accountXpub: data.accountXpub,
    externalAddresses: externalAddresses,
    changeAddresses: changeAddresses,
  );
}
