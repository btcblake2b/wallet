import 'package:bip32/bip32.dart' as bip32;
import 'package:bitcoin_base/bitcoin_base.dart' as bitcoin_base;

/// Rete Bitcoin supportate.
enum BtcNetwork {
  testnet,
  mainnet,
}

/// Configurazione centralizzata per la rete Bitcoin.
///
/// Per passare da testnet a mainnet (o viceversa), modificare [current].
/// Tutti i parametri (BIP32, Bech32, derivation path, API, fee) derivano
/// automaticamente da questa scelta.
class BitcoinNetworkConfig {
  BitcoinNetworkConfig._();

  // ============================================================
  // ⚠️  CAMBIA QUI per passare da testnet a mainnet
  // ============================================================
  // PERCHÉ: rete bitcoin-blake2b MAINNET — indirizzi/chiavi/firme invariati
  // rispetto a Bitcoin (bc1, xpub/xprv, coin_type 0'). Endpoint verificato il
  // 2026-08-31: mempool.guide/api serve la mainnet blake2b (chain=main).
  // Dal 2026-09-08 è l'UNICA fonte per le letture on-chain (il backend
  // personale watch-only è stato rimosso dall'app). La firma usa
  // SIGHASH_UNIFIED (0x20) per la replay protection (vedi unified_sighash.dart).
  static const BtcNetwork current = BtcNetwork.mainnet;

  // ============================================================
  // BIP32 – prefissi extended key (xpub/xprv per mainnet, tpub/tprv per testnet)
  // ============================================================
  static bip32.NetworkType get bip32NetworkType {
    switch (current) {
      case BtcNetwork.testnet:
        return bip32.NetworkType(
          wif: 0xef,
          bip32: bip32.Bip32Type(public: 0x043587cf, private: 0x04358394),
        );
      case BtcNetwork.mainnet:
        return bip32.NetworkType(
          wif: 0x80,
          bip32: bip32.Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
        );
    }
  }

  // ============================================================
  // Bech32 – human-readable part (bc1 per mainnet, tb1 per testnet)
  // ============================================================
  static String get bech32Hrp {
    switch (current) {
      case BtcNetwork.testnet:
        return 'tb';
      case BtcNetwork.mainnet:
        return 'bc';
    }
  }

  // ============================================================
  // BIP84 coin_type (0' = mainnet, 1' = testnet)
  // ============================================================
  static int get coinType {
    switch (current) {
      case BtcNetwork.testnet:
        return 1;
      case BtcNetwork.mainnet:
        return 0;
    }
  }

  /// Derivation path predefinito: m/84'/{coinType}'/0'
  static String get defaultDerivationPath => "m/84'/$coinType'/0'";

  // ============================================================
  // API Esplora-compatibile (esploratore) — rete bitcoin-blake2b
  // ============================================================
  // PERCHÉ: la rete blake2b non usa Blockstream; mempool.guide espone l'API
  // Esplora-compatibile (formato: /address, /utxo, /tx, POST /tx).
  // Dal 2026-09-08 è l'UNICA fonte per saldo, storico, info e tx status.
  static String get blockstreamApiBaseUrl {
    switch (current) {
      case BtcNetwork.testnet:
        return 'https://mempool.guide/testnet4/api';
      case BtcNetwork.mainnet:
        return 'https://mempool.guide/api';
    }
  }

  // ============================================================
  // API Mempool (fee estimates) — rete bitcoin-blake2b
  // ============================================================
  static String get mempoolApiBaseUrl {
    switch (current) {
      case BtcNetwork.testnet:
        return 'https://mempool.guide/testnet4/api';
      case BtcNetwork.mainnet:
        return 'https://mempool.guide/api';
    }
  }

  // ============================================================
  // bitcoin_base library network
  // ============================================================
  static bitcoin_base.BitcoinNetwork get bitcoinBaseNetwork {
    switch (current) {
      case BtcNetwork.testnet:
        return bitcoin_base.BitcoinNetwork.testnet;
      case BtcNetwork.mainnet:
        return bitcoin_base.BitcoinNetwork.mainnet;
    }
  }

  // ============================================================
  // UI helpers
  // ============================================================
  static String get ticker {
    switch (current) {
      case BtcNetwork.testnet:
        return 'tBTC';
      case BtcNetwork.mainnet:
        return 'BTC';
    }
  }

  static String get networkName {
    switch (current) {
      case BtcNetwork.testnet:
        return 'Testnet';
      case BtcNetwork.mainnet:
        return 'Mainnet';
    }
  }

  /// Restituisce `true` se l'indirizzo ha un prefisso valido per la rete corrente.
  static bool isValidAddressPrefix(String address) {
    switch (current) {
      case BtcNetwork.testnet:
        return address.startsWith('tb1') ||
            address.startsWith('m') ||
            address.startsWith('n') ||
            address.startsWith('2');
      case BtcNetwork.mainnet:
        return address.startsWith('bc1') ||
            address.startsWith('1') ||
            address.startsWith('3');
    }
  }

  /// Verifica completa dell'indirizzo Bitcoin: prefisso, checksum Bech32m/Bech32/Base58.
  /// PERCHÉ (UX-002): Previene l'invio di fondi a indirizzi con typo o checksum invalido.
  /// Usa `bitcoin_base` per la validazione crittografica nativa.
  static bool isValidAddress(String address) {
    try {
      return bitcoin_base.BitcoinNetworkAddress.tryParse<
              bitcoin_base.BitcoinAddress>(
            address: address,
            network: bitcoinBaseNetwork,
          ) !=
          null;
    } catch (_) {
      return false;
    }
  }

  static String get addressPrefixHint {
    switch (current) {
      case BtcNetwork.testnet:
        return 'tb1q...';
      case BtcNetwork.mainnet:
        return 'bc1q...';
    }
  }

  /// Messaggio descrittivo per i prefissi accettati.
  static String get addressPrefixDescription {
    switch (current) {
      case BtcNetwork.testnet:
        return 'tb1..., m..., n..., 2...';
      case BtcNetwork.mainnet:
        return 'bc1..., 1..., 3...';
    }
  }

  /// Fallback fee estimates quando l'API non risponde.
  static ({int low, int normal, int high}) get fallbackFeeEstimates {
    switch (current) {
      case BtcNetwork.testnet:
        return (low: 1, normal: 3, high: 10);
      case BtcNetwork.mainnet:
        // PERCHÉ (rete bitcoin-blake2b, verificato in domain/bitcoin.md):
        // mempool reale {economy:1, hour:1, fastest:2, minimum:1} sat/vB — i
        // valori Bitcoin SHA256 (3/12/30) sovrastimerebbero 10-30x le fee.
        return (low: 1, normal: 2, high: 3);
    }
  }

  /// Avviso legale mostrato nella schermata di invio.
  static String get networkDisclaimer {
    switch (current) {
      case BtcNetwork.testnet:
        return 'Rete: Bitcoin Testnet. Le transazioni sono su testnet e non hanno valore reale.\n'
            'La firma avviene localmente sul tuo dispositivo, la seed non viene mai inviata.';
      case BtcNetwork.mainnet:
        return 'Rete: Bitcoin Mainnet. Le transazioni sono reali e hanno valore economico.\n'
            'La firma avviene localmente sul tuo dispositivo, la seed non viene mai inviata.';
    }
  }

  /// Conferma broadcast avvenuto.
  static String get broadcastConfirmationMessage {
    switch (current) {
      case BtcNetwork.testnet:
        return 'La transazione è stata trasmessa alla rete Bitcoin Testnet.';
      case BtcNetwork.mainnet:
        return 'La transazione è stata trasmessa alla rete Bitcoin Mainnet.';
    }
  }

  /// Placeholder per il form importo.
  static String get amountHint => '0.00001000';

  /// Label per il campo importo.
  static String get amountSuffix => ticker;
}

/// Tipo di account HD del wallet (script di locking e path di derivazione).
///
/// PERCHÉ (BIP49): la creazione resta BIP84 native; l'import può scegliere
/// anche BIP49 (nested segwit) per recuperare fondi da seed usati altrove.
/// Il tipo si deduce dal `derivationPath` già salvato in `WalletRecord`
/// (nessun nuovo campo, nessuna migrazione).
enum WalletScriptType {
  /// BIP84 Native SegWit (P2WPKH, Bech32 `bc1q…`) — default di creazione.
  p2wpkh,

  /// BIP49 Nested SegWit (P2SH-P2WPKH, base58 `3…` mainnet / `2…` testnet).
  p2shP2wpkh,

  /// BIP44 Legacy P2PKH (base58 `1…` mainnet / `m|n…` testnet).
  p2pkh;

  /// Purpose BIP del path account (84 = native, 49 = nested, 44 = legacy).
  int get purpose {
    switch (this) {
      case WalletScriptType.p2wpkh:
        return 84;
      case WalletScriptType.p2shP2wpkh:
        return 49;
      case WalletScriptType.p2pkh:
        return 44;
    }
  }

  bool get isNested => this == WalletScriptType.p2shP2wpkh;

  bool get isLegacy => this == WalletScriptType.p2pkh;

  /// Path account completo: `m/{purpose}'/{coinType}'/0'`.
  String accountPath({int? coinType}) {
    final ct = coinType ?? BitcoinNetworkConfig.coinType;
    return "m/$purpose'/$ct'/0'";
  }

  /// Prefisso tipico degli indirizzi per la rete corrente (hint UI).
  /// PERCHÉ: su testnet legacy = `m/n…`, nested = `2…`, native = `tb1q…`.
  String get addressPrefix {
    const isTestnet = BitcoinNetworkConfig.current == BtcNetwork.testnet;
    switch (this) {
      case WalletScriptType.p2pkh:
        return isTestnet ? 'm/n…' : '1…';
      case WalletScriptType.p2shP2wpkh:
        return isTestnet ? '2…' : '3…';
      case WalletScriptType.p2wpkh:
        return isTestnet ? 'tb1q…' : 'bc1q…';
    }
  }

  /// Inferisce il tipo dal derivation path. Fallback: native segwit
  /// (comportamento storico per path null o non standard).
  static WalletScriptType fromDerivationPath(String? path) {
    if (path == null) return WalletScriptType.p2wpkh;
    final match = RegExp(r"^m/(\d+)'").firstMatch(path);
    if (match == null) return WalletScriptType.p2wpkh;
    switch (int.parse(match.group(1)!)) {
      case 49:
        return WalletScriptType.p2shP2wpkh;
      case 44:
        return WalletScriptType.p2pkh;
      default:
        return WalletScriptType.p2wpkh;
    }
  }
}
