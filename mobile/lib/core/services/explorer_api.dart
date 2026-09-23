import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../models/wallet_balance.dart';
import 'explorer_mirrors.dart';

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
    List<String>? baseUrls,
    this.fallbackTimeout = const Duration(seconds: 8),
  })  : _client = client ?? http.Client(),
        _explicitBaseUrls = _explicitHosts(baseUrls) {
    // PERCHÉ: host "sticky" — parte dal primario, si sposta su un mirror solo
    // dopo un failover riuscito: evita di ripagare il timeout del primario a
    // ogni richiesta dello scan gap-limit (20+ richieste per catena).
    _activeBaseUrl = this.baseUrls.first;
  }

  // PERCHÉ: client HTTP iniettabile (pattern P1.2 già usato in BitcoinService)
  // per testare con MockClient senza colpire la rete reale.
  final http.Client _client;

  /// Host passati esplicitamente (test). null = si usa la politica di processo
  /// ([ExplorerMirrors]), letta a OGNI richiesta: così l'interruttore delle
  /// Impostazioni ha effetto anche su istanze già create.
  final List<String>? _explicitBaseUrls;

  /// Host Esplora in ordine di priorità (lista di 1 = single-host storico).
  List<String> get baseUrls =>
      _explicitBaseUrls ?? ExplorerMirrors.instance.readHosts;

  /// Timeout di un tentativo su un host di fallback. Si usa comunque il
  /// minore fra questo e [timeout]: un mirror non aspetta mai più del primario.
  final Duration fallbackTimeout;

  /// Host corrente delle richieste (sticky sul primario finché risponde).
  late String _activeBaseUrl;

  static const Map<String, String> _headers = <String, String>{
    'User-Agent': kExplorerUserAgent,
  };

  /// Host espliciti (test) o null → la lista arriva dalla politica di processo.
  static List<String>? _explicitHosts(List<String>? explicit) =>
      (explicit == null || explicit.isEmpty)
          ? null
          : List<String>.unmodifiable(explicit);

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

  /// GET su [path] con failover fra gli host Esplora configurati.
  ///
  /// Si parte dall'host sticky ([_activeBaseUrl]) e si prosegue con gli altri
  /// SOLO se l'errore è di disponibilità ([_isFailoverWorthy]). Il retry con
  /// backoff resta sull'host primario ([maxAttempts]); i mirror tentano una
  /// volta sola, con timeout ridotto.
  Future<String> _getString(String path) async {
    // FLOW: Lettura on-chain con failover Esplora
    // PERCHÉ: se l'utente ha disattivato i mirror dopo un failover, l'host
    // sticky non è più permesso → si torna al primario da questa richiesta.
    if (!baseUrls.contains(_activeBaseUrl)) {
      _activeBaseUrl = baseUrls.first;
    }
    // STEP: 1 — ordine host: sticky per primo, poi gli altri della lista.
    final ordered = <String>[
      _activeBaseUrl,
      ...baseUrls.where((h) => h != _activeBaseUrl),
    ];
    ApiException? reportedError;

    for (var hostIndex = 0; hostIndex < ordered.length; hostIndex++) {
      final host = ordered[hostIndex];
      final isCurrentHost = hostIndex == 0;
      // PERCHÉ: 3 host x 3 tentativi x 15s = 45s per richiesta bloccherebbero
      // lo scan gap-limit (20+ richieste per catena).
      final attempts = isCurrentHost ? maxAttempts : 1;
      final hostTimeout = fallbackTimeout < timeout ? fallbackTimeout : timeout;

      // STEP: 2 — tentativi sull'host corrente (retry/backoff come prima).
      for (var attempt = 1; attempt <= attempts; attempt++) {
        final isLast = attempt == attempts;
        http.Response response;
        try {
          response = await _client
              .get(Uri.parse('$host/$path'), headers: _headers)
              .timeout(isCurrentHost ? timeout : hostTimeout);
        } on TimeoutException {
          reportedError ??= const ApiException(
            'timeout',
            'Timeout della richiesta',
          );
          if (!isLast) {
            await _waitBeforeRetry(attempt);
            continue;
          }
          break; // host esaurito → failover
        } on http.ClientException {
          // PERCHÉ: copre SocketException/network su tutte le piattaforme
          // (incluso web, dove dart:io non è disponibile).
          reportedError ??= const ApiException(
            'network',
            'Rete non disponibile',
          );
          if (!isLast) {
            await _waitBeforeRetry(attempt);
            continue;
          }
          break; // host esaurito → failover
        }

        if (response.statusCode == 200) {
          // STEP: 3 — host sticky: le richieste successive restano qui.
          if (!isCurrentHost) {
            debugPrint('[ExplorerApi] failover attivo su $host');
            _activeBaseUrl = host;
          }
          return response.body;
        }

        final error = _mapHttpError(response.statusCode);
        reportedError ??= error;
        // PERCHÉ: 404 e bad_response sono RISPOSTE VALIDE (es. tx sconosciuta):
        // si propagano subito, senza failover, per non mascherarne l'esito.
        if (!_isFailoverWorthy(error)) throw error;
        if (!isLast && _isRetryable(response.statusCode)) {
          // PERCHÉ: Retry-After (429) ha priorità quando il servizio lo indica.
          await _waitBeforeRetry(
            attempt,
            retryAfter: response.headers['retry-after'],
          );
          continue;
        }
        break; // host esaurito → failover
      }
    }

    // PERCHÉ: si rilancia l'errore del PRIMO host tentato (di norma il
    // primario): codici e messaggi mappati dalla UI restano quelli storici.
    throw reportedError ??
        const ApiException('internal_error', 'Tentativi di lettura esauriti');
  }

  /// True se l'errore giustifica il passaggio a un altro host Esplora.
  /// PERCHÉ: solo indisponibilità — `not_found` e `bad_response` sono esiti
  /// legittimi della richiesta e non vanno ritentati altrove.
  static bool _isFailoverWorthy(ApiException e) =>
      e.isNetworkError || e.isRateLimited || e.isServiceUnavailable;

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
