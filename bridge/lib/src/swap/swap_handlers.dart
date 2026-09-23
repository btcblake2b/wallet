import '../logger.dart';
import '../protocol.dart';
import 'swap_service.dart';
import 'swap_store.dart';

/// Dispatch delle richieste swap (payload già decifrato e correlato dal
/// transport; qui solo metodo + parametri + identità del client).
///
/// PERCHÉ (Blueprint §2.6): `swap_create` e `swap_funding` sono idempotenti
/// per `request_id` — su Nostr le risposte possono perdersi e il client
/// ritenta: una ripetizione NON deve creare una seconda sessione o doppio
/// stato (qui passano fondi).
class SwapHandlers {
  SwapHandlers({
    required SwapService service,
    required SwapStore store,
    Logger? logger,
  })  : _service = service,
        _store = store,
        _logger = logger ?? Logger();

  final SwapService _service;
  final SwapStore _store;
  final Logger _logger;

  static const Set<String> _idempotentMethods = {
    'swap_create',
    'swap_funding',
  };

  static const Set<String> supportedMethods = {
    'swap_quote',
    'swap_create',
    'swap_funding',
    'swap_status',
  };

  /// Esegue [method] per il client [clientPubkey].
  ///
  /// Lancia [RpcError] con codici del protocollo swap (INVOICE_INVALID,
  /// QUOTE_EXPIRED, DUPLICATE_SWAP, RATE_LIMITED, AMOUNT_TOO_SMALL/…).
  Future<Map<String, dynamic>> handle({
    required String method,
    required Map<String, dynamic> params,
    required String requestId,
    required String clientPubkey,
  }) async {
    final cacheKey = '$clientPubkey:$method:$requestId';
    final idempotent =
        requestId.isNotEmpty && _idempotentMethods.contains(method);
    if (idempotent) {
      final cached = _store.idempotentResponse(cacheKey);
      if (cached != null) {
        _logger.debug(
          'swap $method: risposta idempotente per ${_shortId(requestId)}',
        );
        return cached;
      }
    }

    late final Map<String, dynamic> result;
    switch (method) {
      case 'swap_quote':
        result = await _service.quote(
          bolt11: _str(params, 'invoice'),
          clientPubkey: clientPubkey,
          refundPubkeyHex: _str(params, 'refund_pubkey'),
        );
      case 'swap_create':
        result = await _service.create(
          quoteId: _str(params, 'quote_id'),
          clientPubkey: clientPubkey,
        );
      case 'swap_funding':
        result = await _service.registerFunding(
          swapId: _str(params, 'swap_id'),
          clientPubkey: clientPubkey,
          fundingTxid: _str(params, 'funding_txid'),
        );
      case 'swap_status':
        result = await _service.status(
          swapId: _str(params, 'swap_id'),
          clientPubkey: clientPubkey,
        );
      default:
        throw const RpcError('NOT_IMPLEMENTED', 'metodo swap non supportato.');
    }

    if (idempotent) {
      await _store.rememberResponse(cacheKey, result);
    }
    return result;
  }

  static String _shortId(String id) =>
      id.length > 8 ? '${id.substring(0, 8)}…' : id;

  static String _str(Map<String, dynamic> params, String key) {
    final value = params[key];
    if (value is String && value.isNotEmpty) return value;
    throw RpcError('BAD_REQUEST', 'parametro "$key" mancante.');
  }
}
