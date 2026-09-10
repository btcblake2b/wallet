// PERCHÉ (C003+C008): Modello dati per l'onboarding legale.
// I dati di residenza fiscale e reverse solicitation NON vengono mai
// inviati al server — sono conservati esclusivamente in locale
// (flutter_secure_storage) in coerenza con l'architettura zero-knowledge.
//
// NOTA: Classe Dart pura (non Freezed) per evitare problemi di
// compatibilità SDK con il generatore (richiede >=3.8.0, progetto a 3.3.0).
//
// Campi:
// - residenzaFiscale: codice ISO 3166-1 alpha-2 del paese (es. "IT")
// - reverseSolicitationAccepted: timestamp di accettazione reverse solicitation
// - termsAccepted: timestamp di accettazione Termini di Servizio
// - privacyPolicyAccepted: timestamp di accettazione Privacy Policy
// - ageConfirmed: true se l'utente ha dichiarato età >= 16 anni (C008)

class OnboardingData {
  const OnboardingData({
    required this.residenzaFiscale,
    required this.reverseSolicitationAccepted,
    required this.termsAccepted,
    required this.privacyPolicyAccepted,
    required this.ageConfirmed,
  });

  final String residenzaFiscale;
  final DateTime reverseSolicitationAccepted;
  final DateTime termsAccepted;
  final DateTime privacyPolicyAccepted;
  final bool ageConfirmed;

  Map<String, dynamic> toJson() => {
        'residenzaFiscale': residenzaFiscale,
        'reverseSolicitationAccepted':
            reverseSolicitationAccepted.toIso8601String(),
        'termsAccepted': termsAccepted.toIso8601String(),
        'privacyPolicyAccepted': privacyPolicyAccepted.toIso8601String(),
        'ageConfirmed': ageConfirmed,
      };

  factory OnboardingData.fromJson(Map<String, dynamic> json) => OnboardingData(
        residenzaFiscale: json['residenzaFiscale'] as String,
        reverseSolicitationAccepted:
            DateTime.parse(json['reverseSolicitationAccepted'] as String),
        termsAccepted: DateTime.parse(json['termsAccepted'] as String),
        privacyPolicyAccepted:
            DateTime.parse(json['privacyPolicyAccepted'] as String),
        ageConfirmed: json['ageConfirmed'] as bool,
      );

  @override
  String toString() => 'OnboardingData(residenzaFiscale: $residenzaFiscale, '
      'ageConfirmed: $ageConfirmed)';
}
