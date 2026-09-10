import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/bitcoin_network_config.dart';
import '../models/wallet_balance.dart';

/// User-Agent condiviso per le richieste all'API Esplora-compatibile.
/// PERCHÉ: identificare client e contatto è buona prassi per API pubbliche:
/// riduce i blocchi "da bot" e permette all'operatore di contattarci.
const String kExplorerUserAgent =
    'BtcBlake2bWallet (+https://btcblake2b.org; contact@btcblake2b.org)';

/// Errore tipizzato del servizio API Esplora-compatibile (mempool.guide).
///
/// [code] è un codice macchina stabile (rate_limited, node_unavailable,
/// not_found, internal_error, timeout, network, bad_response, http_XXX);
/// [message] è tecnico (non localizzato): la UI mappa [code] su
/// AppLocalizations.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  bool get isRateLimited => code == 'rate_limited';
  bool get isServiceUnavailable =>
      code == 'node_unavailable' || code == 'internal_error';
  bool get isNotFound => code == 'not_found';
  bool get isNetworkError => code == 'network' || code == 'timeout';

  @override
  String toString() => 'ApiException($code): $message';
}

/// Client per l'API Esplora-compatibile della rete bitcoin-blake2b
/// (mempool.guide, mainnet dal 2026-08-31).
///
/// Formato risposta stile Esplora/Blockstream: `chain_stats` + `mempool_stats`
/// con valori in satoshi. Tutti gli errori (HTTP != 200, timeout, rete, body
/// malformato) lanciano [ApiException] tipizzata, che il chiamante
/// (`BitcoinService.fetchAddressInfo`) propaga come stato "non disponibile"
/// (mai mascherare l'errore su saldo 0).
class ExplorerApi {
  ExplorerApi({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
    this.maxAttempts = 1,
    this.baseRetryDelay = const Duration(milliseconds: 600),
  }) : _client = client ?? http.Client();

  // PERCHÉ: client HTTP iniettabile (pattern P1.2 già usato in BitcoinService)
  // per testare con MockClient senza colpire la rete reale.
  final http.Client _client;

  /// Timeout di rete per ogni richiesta (15s, regola del servizio).
  final Duration timeout;

  /// Tentativi massimi per richiesta (1 = nessun retry).
  /// PERCHÉ: il default 1 mantiene il comportamento storico e i test
  /// deterministici; i punti di produzione (BitcoinService, ExplorerScreen)
  /// abilitano `maxAttempts: 3` per assorbire gli errori transitori
  /// (429/502/503/timeout/rete) con backoff.
  final int maxAttempts;

  /// Ritardo base del backoff esponenziale (raddoppia a ogni tentativo) + jitter.
  final Duration baseRetryDelay;

  // PERCHÉ: unica sorgente per le letture on-chain — mempool.guide
  // (Esplora-compatibile), nessun backend personale.
  String get _baseUrl => BitcoinNetworkConfig.blockstreamApiBaseUrl;

  /// Saldo (catena confermata + mempool) in satoshi e conteggio transazioni.
  ///
  /// GET {base}/address/{address} →
  /// ```
  /// { "chain_stats":  {"funded_txo_sum": int, "spent_txo_sum": int, "tx_count": int},
  ///   "mempool_stats": {...stessa forma...} }
  /// ```
  /// // PERCHÉ: UNA sola richiesta per indirizzo, nessun doppio salto — un
  /// saldo 0 è un saldo reale (indirizzo vuoto) e viene ritornato com'è.
  Future<WalletBalance> addressBalance(String address) async {
    final data = await _getJson('address/$address');
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'bad_response',
        'Risposta non valida dal servizio (oggetto JSON atteso)',
      );
    }
    return WalletBalance.fromChainStats(
      chainStats: _asMap(data['chain_stats']),
      mempoolStats: _asMap(data['mempool_stats']),
    );
  }

  /// Stato di una transazione.
  ///
  /// GET {base}/tx/{txid} →
  /// `{"txid": "...", "status": {"confirmed": bool, "block_height": int,
  /// "block_hash": str}}`. Ritorna `null` se il body non è un oggetto JSON.
  Future<TxStatus?> txStatus(String txid) async {
    final data = await _getJson('tx/$txid');
    if (data is! Map<String, dynamic>) return null;
    return TxStatus.fromMap(data);
  }

  /// Altezza del blocco tip della chain.
  ///
  /// GET {base}/blocks/tip/height → 969878
  /// // PERCHÉ (verificato 2026-09-08): mempool.guide risponde con un int JSON
  /// puro su /blocks/tip/height; lo stile Esplora /blocks/tip-height ritorna
  /// invece una LISTA di blocchi → non compatibile con il parsing int.
  Future<int> tipHeight() async {
    final body = await _getString('blocks/tip/height');
    // PERCHÉ: il servizio risponde con un int JSON puro; se il parsing
    // fallisce è una risposta malformata → ApiException bad_response.
    final parsed = int.tryParse(body.trim());
    if (parsed == null) {
      throw const ApiException(
        'bad_response',
        'Risposta non valida dal servizio (tip-height non intero)',
      );
    }
    return parsed;
  }

  /// Saldo in formato Map (chain+mempool) — compatibilità con
  /// `BitcoinService.fetchAddressInfo` (unica fonte: mempool.guide).
  ///
  /// PERCHÉ: NON cambio il tipo di ritorno: `BitcoinService` e i suoi test
  /// consumano la Map; su errore [ApiException] si propaga al chiamante, che
  /// mostra lo stato "non disponibile" (mai 0 come saldo vero).
  Future<Map<String, dynamic>> fetchAddressInfo(String address) async {
    final balance = await addressBalance(address);
    return {'balance': balance.balanceSats, 'tx_count': balance.txCount};
  }

  // ── Interni ──────────────────────────────────────────────────────────────

  Future<dynamic> _getJson(String path) async {
    final body = await _getString(path);
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ApiException(
        'bad_response',
        'Risposta non valida dal servizio (JSON malformato)',
      );
    }
  }

  Future<String> _getString(String path) async {
    final uri = Uri.parse('$_baseUrl/$path');
    const headers = {'User-Agent': kExplorerUserAgent};
    // PERCHÉ: retry su errori transitori — un 429/502/503 o un timeout di rete
    // possono essere momentanei (il 502 è spesso un blip del servizio):
    // riprovare con backoff evita "saldo non disponibile" per un errore solo.
    // Il circuit breaker (BitcoinService) resta il guardiano degli outage lunghi.
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final isLast = attempt == maxAttempts;
      http.Response response;
      try {
        response = await _client.get(uri, headers: headers).timeout(timeout);
      } on TimeoutException {
        if (isLast) {
          throw const ApiException('timeout', 'Timeout della richiesta');
        }
        await _waitBeforeRetry(attempt);
        continue;
      } on http.ClientException {
        // PERCHÉ: copre SocketException/network su tutte le piattaforme
        // (incluso web, dove dart:io non è disponibile).
        if (isLast) {
          throw const ApiException('network', 'Rete non disponibile');
        }
        await _waitBeforeRetry(attempt);
        continue;
      }
      if (response.statusCode == 200) {
        return response.body;
      }
      if (!isLast && _isRetryable(response.statusCode)) {
        // PERCHÉ: Retry-After (429) ha priorità quando il servizio lo indica.
        await _waitBeforeRetry(
          attempt,
          retryAfter: response.headers['retry-after'],
        );
        continue;
      }
      throw _mapHttpError(response.statusCode);
    }
    // Irraggiungibile: maxAttempts >= 1 per costruzione.
    throw const ApiException('internal_error', 'Tentativi di lettura esauriti');
  }

  /// True se lo status HTTP indica un errore transitorio da ritentare.
  /// PERCHÉ: il 500 è ESCLUSO di proposito — i fallimenti "errore interno"
  /// non generano retry e i test esistenti (MockClient 500) restano a 1 tentativo.
  bool _isRetryable(int statusCode) =>
      statusCode == 429 || statusCode == 502 || statusCode == 503;

  /// Attesa prima del retry: backoff esponenziale (base x2^tentativo) + jitter
  /// casuale, oppure Retry-After del servizio (cap 15s) se presente.
  Future<void> _waitBeforeRetry(int attempt, {String? retryAfter}) async {
    Duration delay;
    final retryAfterSeconds = int.tryParse(retryAfter ?? '');
    if (retryAfterSeconds != null && retryAfterSeconds > 0) {
      delay = Duration(seconds: min(retryAfterSeconds, 15));
    } else {
      // PERCHÉ: jitter evita che più dispositivi riprovino in sincrono e
      // rimbalzino insieme contro il rate limiter.
      final baseMs = baseRetryDelay.inMilliseconds * (1 << (attempt - 1));
      final jitterMs = Random().nextInt(max(baseMs ~/ 3, 1));
      delay = Duration(milliseconds: baseMs + jitterMs);
    }
    await Future<void>.delayed(delay);
  }

  /// Mappa un codice HTTP su un'ApiException con messaggio leggibile.
  ApiException _mapHttpError(int statusCode) {
    switch (statusCode) {
      case 429:
        return const ApiException(
          'rate_limited',
          'Rate limit superato (30 req/min)',
          statusCode: 429,
        );
      case 503:
        return const ApiException(
          'node_unavailable',
          'Nodo temporaneamente non disponibile',
          statusCode: 503,
        );
      case 404:
        return const ApiException(
          'not_found',
          'Risorsa non trovata',
          statusCode: 404,
        );
      case 500:
        return const ApiException(
          'internal_error',
          'Errore interno del servizio',
          statusCode: 500,
        );
      default:
        return ApiException(
          'http_$statusCode',
          'Errore HTTP $statusCode',
          statusCode: statusCode,
        );
    }
  }

  static Map<String, dynamic> _asMap(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
}
