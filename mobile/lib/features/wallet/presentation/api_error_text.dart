import '../../../core/services/bitcoin_service.dart';
import '../../../core/services/explorer_api.dart';
import '../../../l10n/app_localizations.dart';

/// Codice stabile per la UI a partire da un'eccezione di lettura rete/API.
/// PERCHÉ: il testo mostrato deve distinguere rate limit / servizio giù /
/// rete / timeout; il codice evita di dipendere dal messaggio (tecnico).
String apiErrorCode(Object error) {
  if (error is ApiException) return error.code;
  if (error is CircuitBreakerOpenException) return 'service_unavailable';
  return 'generic';
}

/// Motivo localizzato per i casi distinti (rate limit / servizio giù /
/// rete / timeout). Ritorna null per i casi generici: la UI mostra il suo
/// messaggio di default.
String? apiErrorReason(AppLocalizations loc, String code) {
  switch (code) {
    case 'rate_limited':
      return loc.explorerErrorRateLimited;
    case 'node_unavailable':
    case 'internal_error':
    case 'service_unavailable':
      return loc.explorerErrorNodeUnavailable;
    case 'timeout':
      return loc.explorerErrorTimeout;
    case 'network':
      return loc.explorerErrorNetwork;
    default:
      return null;
  }
}
