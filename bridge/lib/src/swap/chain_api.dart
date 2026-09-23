import 'dart:convert';

import 'package:http/http.dart' as http;

/// Stato di una transazione per il watcher dello swap.
class ChainTxStatus {
  const ChainTxStatus({
    required this.txid,
    required this.confirmed,
    this.blockHeight,
  });

  final String txid;
  final bool confirmed;
  final int? blockHeight;
}

/// Transazione vista su un indirizzo (Esplora `/address/:addr/txs`).
class ChainAddressTx {
  const ChainAddressTx({
    required this.txid,
    required this.confirmed,
    this.blockHeight,
  });

  final String txid;
  final bool confirmed;
  final int? blockHeight;
}

/// Spesa di un output (Esplora `/tx/:txid/outspends`).
class ChainOutspend {
  const ChainOutspend({
    required this.vout,
    required this.spent,
    this.spendingTxid,
  });

  final int vout;
  final bool spent;
  final String? spendingTxid;
}

/// Astrazione minima della chain per il servizio swap — iniettabile nei test.
abstract class ChainApi {
  /// Altezza corrente della chain (best chain).
  Future<int> tipHeight();

  /// Stato di [txid]; `null` se la tx è sconosciuta.
  Future<ChainTxStatus?> txStatus(String txid);

  /// Raw hex della transazione [txid]; `null` se sconosciuta.
  ///
  /// PERCHÉ: il provider deve verificare QUALE output paga l'HTLC (script +
  /// importo) prima di pagare la invoice — dal solo status non basta.
  Future<String?> txHex(String txid);

  /// Transazioni che toccano [address] (mempool + chain).
  Future<List<ChainAddressTx>> addressTxs(String address);

  /// Spese degli output della tx [txid] (per rilevare claim/refund dell'HTLC).
  Future<List<ChainOutspend>> outspends(String txid);

  /// Trasmette la tx raw e ritorna il txid.
  Future<String> broadcast(String rawTxHex);
}

/// Errore di trasporto/risposta del [ChainApi].
class ChainApiException implements Exception {
  ChainApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client Esplora (mempool.guide): default del PoC per il watch degli
/// indirizzi HTLC.
///
/// PERCHÉ (Blueprint §1.6): il nodo bitcoind locale non ha indice indirizzi →
/// osservare uno script richiederebbe `scantxoutset` a ogni tick. Esplora
/// espone address/txs e outspends in una chiamata. ⚠️ Trade-off noto: il
/// provider interroga un servizio terzo per il watch (privacy/dipendenza) —
/// il watcher bitcoind-only è un'opzione futura.
class EsploraChainApi implements ChainApi {
  EsploraChainApi({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<int> tipHeight() async {
    final res = await _http.get(_uri('/blocks/tip/height')).timeout(timeout);
    if (res.statusCode != 200) {
      throw ChainApiException('tip height non disponibile (${res.statusCode})');
    }
    return int.parse(res.body.trim());
  }

  @override
  Future<ChainTxStatus?> txStatus(String txid) async {
    final res = await _http.get(_uri('/tx/$txid/status')).timeout(timeout);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw ChainApiException('tx status fallito (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return ChainTxStatus(
      txid: txid,
      confirmed: json['confirmed'] == true,
      blockHeight: json['block_height'] as int?,
    );
  }

  @override
  Future<String?> txHex(String txid) async {
    final res = await _http.get(_uri('/tx/$txid/hex')).timeout(timeout);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw ChainApiException('tx hex fallito (${res.statusCode})');
    }
    return res.body.trim();
  }

  @override
  Future<List<ChainAddressTx>> addressTxs(String address) async {
    final res = await _http.get(_uri('/address/$address/txs')).timeout(timeout);
    if (res.statusCode != 200) {
      throw ChainApiException('address txs fallite (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return [
      for (final e in list.cast<Map<String, dynamic>>())
        ChainAddressTx(
          txid: e['txid'] as String,
          confirmed:
              (e['status'] as Map<String, dynamic>?)?['confirmed'] == true,
          blockHeight:
              (e['status'] as Map<String, dynamic>?)?['block_height'] as int?,
        ),
    ];
  }

  @override
  Future<List<ChainOutspend>> outspends(String txid) async {
    final res = await _http.get(_uri('/tx/$txid/outspends')).timeout(timeout);
    if (res.statusCode != 200) {
      throw ChainApiException('outspends falliti (${res.statusCode})');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return [
      for (var i = 0; i < list.length; i++)
        ChainOutspend(
          vout: i,
          spent: (list[i] as Map<String, dynamic>)['spent'] == true,
          spendingTxid: (list[i] as Map<String, dynamic>)['txid'] as String?,
        ),
    ];
  }

  @override
  Future<String> broadcast(String rawTxHex) async {
    final res = await _http
        .post(
          _uri('/tx'),
          headers: {'Content-Type': 'text/plain'},
          body: rawTxHex,
        )
        .timeout(timeout);
    if (res.statusCode != 200) {
      throw ChainApiException(
        'broadcast fallito (${res.statusCode}): ${res.body}',
      );
    }
    return res.body.trim();
  }
}
