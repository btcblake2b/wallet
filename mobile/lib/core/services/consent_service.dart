import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Gestione del consenso privacy (GDPR) — sostituisce il `logConsent` Firebase.
///
/// PERCHÉ: il fork blake2b è un wallet 100% locale senza backend; il consenso
/// viene memorizzato SOLO sul device (nessun dato su server). La versione
/// consente di richiedere nuovamente il consenso quando la policy cambia.
class ConsentService {
  ConsentService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _consentVersionKey = 'consent_version';
  static const _consentTimestampKey = 'consent_timestamp';

  /// `true` se l'utente ha già accettato la versione [version] del consenso.
  Future<bool> hasAcceptedConsent(String version) async {
    try {
      final stored = await _storage.read(key: _consentVersionKey);
      return stored == version;
    } catch (_) {
      // PERCHÉ: se lo storage non è leggibile, meglio richiedere il consenso
      // piuttosto che assumere l'accettazione.
      return false;
    }
  }

  /// Registra l'accettazione della versione [version] del consenso.
  Future<void> recordConsent({required String version}) async {
    // PERCHÉ: timestamp UTC per tracciabilità GDPR locale.
    await _storage.write(key: _consentVersionKey, value: version);
    await _storage.write(
      key: _consentTimestampKey,
      value: DateTime.now().toUtc().toIso8601String(),
    );
  }
}
