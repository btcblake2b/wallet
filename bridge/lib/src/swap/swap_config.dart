import 'dart:convert';
import 'dart:io';

/// Configurazione del servizio swap (file JSON).
///
/// Esempio (`swap-config.json`):
/// ```json
/// {
///   "relays": ["wss://relay.primal.net"],
///   "clnUrl": "https://127.0.0.1:3001",
///   "runeFile": "/home/filippo/.lightning/swap-rune",
///   "providerKeyFile": "/home/filippo/swap/provider.key",
///   "storeFile": "/home/filippo/swap/swap-store.json",
///   "chain": {"esploraUrl": "https://mempool.guide/api"},
///   "limits": {"minSats": 5000, "maxSats": 250000},
///   "logLevel": "info"
/// }
/// ```
/// I blocchi `limits`/`htlc`/`fees`/`timeouts` sono opzionali: i default sono
/// quelli del piano v2 (Blueprint §2.8).
class SwapConfig {
  SwapConfig({
    required this.relays,
    required this.clnUrl,
    required this.providerKeyFile,
    required this.storeFile,
    required this.chain,
    this.runeFile,
    this.runeHex,
    this.clnCliPath,
    this.clnLightningDir,
    this.clnLdLibraryPath,
    this.limits = const SwapLimitsConfig(),
    this.htlc = const SwapHtlcConfig(),
    this.fees = const SwapFeesConfig(),
    this.timeouts = const SwapTimeoutsConfig(),
    this.allowedClientPubkeys = const [],
    this.alias = 'blake2b-swap',
    this.logLevel = 'info',
  });

  /// Relay Nostr su cui il provider ascolta (lista: niente SPOF).
  final List<String> relays;
  final String clnUrl;
  final String? runeFile;
  final String? runeHex;

  /// Accesso ALTERNATIVO al nodo via `lightning-cli` locale (socket UNIX).
  ///
  /// // PERCHÉ (18/09/2026): il fork blake2b `.4` espone il plugin commando
  /// // come `active` ma SENZA metodi (`commando-rune` → "Unknown command"):
  /// // non si possono creare runi nuove. Un provider co-locato col nodo usa
  /// // il socket locale: nessun segreto su disco, permessi dal filesystem.
  final String? clnCliPath;
  final String? clnLightningDir;
  final String? clnLdLibraryPath;

  /// File con la chiave di claim (hex 64, permessi 600) — MAI nel repo.
  final String providerKeyFile;

  /// File dello store delle sessioni (JSON, scrittura atomica).
  final String storeFile;

  final SwapChainConfig chain;
  final SwapLimitsConfig limits;
  final SwapHtlcConfig htlc;
  final SwapFeesConfig fees;
  final SwapTimeoutsConfig timeouts;

  /// Pubkey dei client autorizzati (vuoto = tutti, come la bridge).
  final List<String> allowedClientPubkeys;
  final String alias;
  final String logLevel;

  static final RegExp _hex64 = RegExp(r'^[0-9a-fA-F]{64}$');

  /// True se il relay punta a un host locale (test/dev) — vedi audit SEC-07.
  static bool _isLocalRelay(String relay) {
    final host = Uri.tryParse(relay)?.host ?? '';
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '[::1]';
  }

  static SwapConfig fromJsonFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FormatException('Config swap non trovata: $path');
    }
    final json =
        (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

    final relays = ((json['relays'] as List?) ?? const [])
        .map((e) => '$e')
        .where((e) => e.isNotEmpty)
        .toList();
    // Compat: accetta anche `relay` singolare.
    final singleRelay = '${json['relay'] ?? ''}';
    if (relays.isEmpty && singleRelay.isNotEmpty) {
      relays.add(singleRelay);
    }
    if (relays.isEmpty) {
      throw const FormatException('relays mancante');
    }
    for (final relay in relays) {
      final local = _isLocalRelay(relay);
      if (!relay.startsWith('wss://') &&
          !(relay.startsWith('ws://') && local)) {
        throw const FormatException(
          'relay non sicuro: usare wss:// (ws:// solo su localhost)',
        );
      }
    }

    final clnCliPath = json['clnCliPath']?.toString();
    final clnUrl = '${json['clnUrl'] ?? ''}';
    // PERCHÉ: due modalità di accesso al nodo — clnrest+rune (remoto) oppure
    // lightning-cli locale (co-locato): almeno una deve essere configurata.
    if (clnUrl.isEmpty && (clnCliPath == null || clnCliPath.isEmpty)) {
      throw const FormatException('serve clnUrl oppure clnCliPath');
    }

    final chainJson =
        (json['chain'] as Map?)?.cast<String, dynamic>() ?? const {};
    final esploraUrl = '${chainJson['esploraUrl'] ?? ''}';
    if (esploraUrl.isEmpty || !esploraUrl.startsWith('http')) {
      throw const FormatException('chain.esploraUrl mancante o non valido');
    }

    final limitsJson =
        (json['limits'] as Map?)?.cast<String, dynamic>() ?? const {};
    final limits = SwapLimitsConfig(
      minSats: (limitsJson['minSats'] as num?)?.toInt() ?? 5000,
      maxSats: (limitsJson['maxSats'] as num?)?.toInt() ?? 250000,
      maxFeeRatio: (limitsJson['maxFeeRatio'] as num?)?.toDouble() ?? 0.10,
      maxConcurrent: (limitsJson['maxConcurrent'] as num?)?.toInt() ?? 20,
      maxPerPubkey: (limitsJson['maxPerPubkey'] as num?)?.toInt() ?? 2,
    );
    if (limits.minSats < 546) {
      throw const FormatException('limits.minSats < 546 (dust)');
    }
    if (limits.maxSats <= limits.minSats) {
      throw const FormatException('limits.maxSats <= limits.minSats');
    }
    if (limits.maxFeeRatio <= 0 || limits.maxFeeRatio >= 1) {
      throw const FormatException('limits.maxFeeRatio fuori da (0,1)');
    }
    if (limits.maxConcurrent < 1 || limits.maxPerPubkey < 1) {
      throw const FormatException('limits.max* deve essere ≥ 1');
    }

    final htlcJson =
        (json['htlc'] as Map?)?.cast<String, dynamic>() ?? const {};
    final htlc = SwapHtlcConfig(
      confirmations: (htlcJson['confirmations'] as num?)?.toInt() ?? 1,
      cltvDelta: (htlcJson['cltvDelta'] as num?)?.toInt() ?? 144,
      claimMargin: (htlcJson['claimMargin'] as num?)?.toInt() ?? 2,
      refundMargin: (htlcJson['refundMargin'] as num?)?.toInt() ?? 2,
      fundingBuffer: (htlcJson['fundingBuffer'] as num?)?.toInt() ?? 6,
    );
    if (htlc.cltvDelta < 18) {
      // PERCHÉ: con delta < 18 verrebbero CLTV troppo vicini al tip — il
      // refund dell'utente non avrebbe margine operativo.
      throw const FormatException('htlc.cltvDelta < 18');
    }
    if (htlc.claimMargin < 1 || htlc.fundingBuffer < 1) {
      throw const FormatException('htlc.claimMargin/fundingBuffer < 1');
    }

    final feesJson =
        (json['fees'] as Map?)?.cast<String, dynamic>() ?? const {};
    final fees = SwapFeesConfig(
      serviceFeeSats: (feesJson['serviceFeeSats'] as num?)?.toInt() ?? 0,
      claimFeeSats: (feesJson['claimFeeSats'] as num?)?.toInt() ?? 250,
      claimFeeRateSatVb: (feesJson['claimFeeRateSatVb'] as num?)?.toInt() ?? 2,
      maxRoutingFeePpm: (feesJson['maxRoutingFeePpm'] as num?)?.toInt() ?? 5000,
      maxRoutingFeeBaseSats:
          (feesJson['maxRoutingFeeBaseSats'] as num?)?.toInt() ?? 100,
    );
    if (fees.serviceFeeSats < 0 || fees.claimFeeSats < 0) {
      throw const FormatException('fees negative');
    }

    final timeoutsJson =
        (json['timeouts'] as Map?)?.cast<String, dynamic>() ?? const {};
    final timeouts = SwapTimeoutsConfig(
      quoteTtlSec: (timeoutsJson['quoteTtlSec'] as num?)?.toInt() ?? 600,
      tickSec: (timeoutsJson['tickSec'] as num?)?.toInt() ?? 20,
      payRetryMax: (timeoutsJson['payRetryMax'] as num?)?.toInt() ?? 2,
    );
    if (timeouts.quoteTtlSec < 60 || timeouts.tickSec < 5) {
      throw const FormatException('timeouts troppo bassi');
    }

    final keyFile = '${json['providerKeyFile'] ?? ''}';
    if (keyFile.isEmpty) {
      throw const FormatException('providerKeyFile mancante');
    }
    final storeFile = '${json['storeFile'] ?? ''}';
    if (storeFile.isEmpty) {
      throw const FormatException('storeFile mancante');
    }

    return SwapConfig(
      relays: relays,
      clnUrl: clnUrl,
      runeFile: json['runeFile']?.toString(),
      runeHex: json['runeHex']?.toString(),
      clnCliPath: clnCliPath,
      clnLightningDir: json['clnLightningDir']?.toString(),
      clnLdLibraryPath: json['clnLdLibraryPath']?.toString(),
      providerKeyFile: keyFile,
      storeFile: storeFile,
      chain: SwapChainConfig(
        esploraUrl: esploraUrl,
        bitcoindUrl: chainJson['bitcoindUrl']?.toString(),
      ),
      limits: limits,
      htlc: htlc,
      fees: fees,
      timeouts: timeouts,
      allowedClientPubkeys:
          ((json['allowedClientPubkeys'] as List?) ?? const [])
              .map((e) => '$e'.toLowerCase())
              .toList(),
      alias: '${json['alias'] ?? 'blake2b-swap'}',
      logLevel: '${json['logLevel'] ?? 'info'}',
    );
  }

  /// Legge la chiave di claim dal file (hex 64); la crea non è compito di
  /// questa classe (vedi `swapd --genkey`).
  String loadProviderKeyHex() {
    final raw = File(providerKeyFile).readAsStringSync().trim().toLowerCase();
    if (!_hex64.hasMatch(raw)) {
      throw const FormatException(
        'providerKeyFile non valido: attesa chiave hex 64',
      );
    }
    return raw;
  }

  /// Legge la rune dal file (formato RTL `LIGHTNING_RUNE="…"` o valore raw).
  String loadRune() {
    final hex = runeHex;
    if (hex != null && hex.isNotEmpty) {
      return hex;
    }
    final path = runeFile;
    if (path == null || path.isEmpty) {
      throw const FormatException('Nessuna rune configurata (runeFile/runeHex)');
    }
    final raw = File(path).readAsStringSync().trim();
    final match = RegExp('LIGHTNING_RUNE="([^"]+)"').firstMatch(raw);
    if (match != null) {
      return match.group(1)!;
    }
    return raw;
  }
}

class SwapChainConfig {
  const SwapChainConfig({required this.esploraUrl, this.bitcoindUrl});

  final String esploraUrl;
  final String? bitcoindUrl;
}

class SwapLimitsConfig {
  const SwapLimitsConfig({
    this.minSats = 5000,
    this.maxSats = 250000,
    this.maxFeeRatio = 0.10,
    this.maxConcurrent = 20,
    this.maxPerPubkey = 2,
  });

  final int minSats;
  final int maxSats;

  /// Soglia massima del costo tecnico (claim+routing stimati) sull'importo.
  final double maxFeeRatio;
  final int maxConcurrent;
  final int maxPerPubkey;
}

class SwapHtlcConfig {
  const SwapHtlcConfig({
    this.confirmations = 1,
    this.cltvDelta = 144,
    this.claimMargin = 2,
    this.refundMargin = 2,
    this.fundingBuffer = 6,
  });

  final int confirmations;
  final int cltvDelta;
  final int claimMargin;
  final int refundMargin;
  final int fundingBuffer;
}

class SwapFeesConfig {
  const SwapFeesConfig({
    this.serviceFeeSats = 0,
    this.claimFeeSats = 250,
    this.claimFeeRateSatVb = 2,
    this.maxRoutingFeePpm = 5000,
    this.maxRoutingFeeBaseSats = 100,
  });

  final int serviceFeeSats;
  final int claimFeeSats;
  final int claimFeeRateSatVb;
  final int maxRoutingFeePpm;
  final int maxRoutingFeeBaseSats;
}

class SwapTimeoutsConfig {
  const SwapTimeoutsConfig({
    this.quoteTtlSec = 600,
    this.tickSec = 20,
    this.payRetryMax = 2,
  });

  final int quoteTtlSec;
  final int tickSec;
  final int payRetryMax;
}
