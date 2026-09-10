// PERCHÉ (C003+C008): Onboarding legale obbligatorio prima dell'uso dell'app.
//
// C003 — Reverse Solicitation (Art. 61 MiCA):
//   L'utente dichiara il paese di residenza fiscale e accetta
//   che il servizio è fornito su sua esclusiva iniziativa.
//
// C008 — Age verification (GDPR Art. 8):
//   L'utente dichiara di avere almeno 16 anni. Senza questa
//   dichiarazione, non può procedere.
//
// TUTTI i dati sono salvati ESCLUSIVAMENTE in locale
// (flutter_secure_storage). Nulla viene inviato al server.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/models/onboarding_data.dart';
import '../../../l10n/app_localizations.dart';
import '../../wallet/presentation/legal_info_screen.dart';

/// Paesi UE/SEE + Svizzera in formato ISO 3166-1 alpha-2.
/// PERCHÉ: la reverse solicitation è rilevante per i residenti
/// nell'Area Economica Europea. La Svizzera è inclusa per i trattati
/// bilaterali con l'UE in materia finanziaria.
const _euEeaCountries = <MapEntry<String, String>>[
  MapEntry('AT', 'Austria'),
  MapEntry('BE', 'Belgio'),
  MapEntry('BG', 'Bulgaria'),
  MapEntry('CH', 'Svizzera'),
  MapEntry('CY', 'Cipro'),
  MapEntry('CZ', 'Repubblica Ceca'),
  MapEntry('DE', 'Germania'),
  MapEntry('DK', 'Danimarca'),
  MapEntry('EE', 'Estonia'),
  MapEntry('ES', 'Spagna'),
  MapEntry('FI', 'Finlandia'),
  MapEntry('FR', 'Francia'),
  MapEntry('GR', 'Grecia'),
  MapEntry('HR', 'Croazia'),
  MapEntry('HU', 'Ungheria'),
  MapEntry('IE', 'Irlanda'),
  MapEntry('IS', 'Islanda'),
  MapEntry('IT', 'Italia'),
  MapEntry('LI', 'Liechtenstein'),
  MapEntry('LT', 'Lituania'),
  MapEntry('LU', 'Lussemburgo'),
  MapEntry('LV', 'Lettonia'),
  MapEntry('MT', 'Malta'),
  MapEntry('NL', 'Paesi Bassi'),
  MapEntry('NO', 'Norvegia'),
  MapEntry('PL', 'Polonia'),
  MapEntry('PT', 'Portogallo'),
  MapEntry('RO', 'Romania'),
  MapEntry('SE', 'Svezia'),
  MapEntry('SI', 'Slovenia'),
  MapEntry('SK', 'Slovacchia'),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _onboardingService = OnboardingService();

  // PERCHÉ: TapGestureRecognizer per link inline Terms/Privacy —
  // GestureDetector dentro CheckboxListTile non riceve i tap perché
  // il parent CheckboxListTile li cattura per il toggle checkbox.
  late final TapGestureRecognizer _termsTapRecognizer;
  late final TapGestureRecognizer _privacyTapRecognizer;

  String? _selectedCountry;
  bool _reverseSolicitation = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _ageConfirmed = false;
  bool _submitting = false;

  // PERCHÉ: il pulsante CONTINUA è abilitato solo quando TUTTE le
  // condizioni sono soddisfatte (paese selezionato + 4 checkbox)
  @override
  void initState() {
    super.initState();
    _termsTapRecognizer = TapGestureRecognizer()..onTap = _openTerms;
    _privacyTapRecognizer = TapGestureRecognizer()..onTap = _openPrivacy;
  }

  @override
  void dispose() {
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _selectedCountry != null &&
      _reverseSolicitation &&
      _termsAccepted &&
      _privacyAccepted &&
      _ageConfirmed &&
      !_submitting;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // PERCHÉ: doppio check — _canContinue già verifica ma validiamo
    // anche qui per sicurezza
    if (!_canContinue) return;

    setState(() => _submitting = true);

    try {
      final now = DateTime.now().toUtc();
      final data = OnboardingData(
        residenzaFiscale: _selectedCountry!,
        reverseSolicitationAccepted: now,
        termsAccepted: now,
        privacyPolicyAccepted: now,
        ageConfirmed: _ageConfirmed,
      );

      await _onboardingService.complete(data);

      if (!mounted) return;

      // PERCHÉ: dopo il completamento, navighiamo alla HomeScreen
      // usando GoRouter per una navigazione pulita che sostituisce lo stack
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.onboardingSubmitError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openTerms() async {
    // PERCHÉ (A3): i documenti sono mostrati in-app — il dominio ufficiale
    // non è ancora disponibile. Sostituire con il link esterno quando il
    // sito sarà pubblicato.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LegalInfoScreen()),
    );
  }

  Future<void> _openPrivacy() async {
    // PERCHÉ (A3): stessa schermata interna per Privacy Policy.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LegalInfoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Intestazione ──
                  Icon(
                    Icons.language,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.onboardingTitle,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.onboardingSubtitle,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── Progress bar (4 step) ──
                  Row(
                    children: [
                      for (var i = 0; i < _totalSteps; i++)
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i <= _currentStep
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.onboardingStepOf(_currentStep + 1, _totalSteps),
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── Stepper: step corrente con transizione ──
                  // // PERCHÉ (S4): stepper custom con AnimatedSwitcher invece
                  // del PageView: evita i problemi di altezza variabile degli
                  // step e la navigazione resta solo via bottoni (mai swipe),
                  // garantendo che ogni gate legale sia soddisfatto.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentStep),
                      child: _buildCurrentStep(context, loc, theme),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Bottoni di navigazione ──
                  _buildNavButtons(context, loc, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Wizard a 4 step (S4)
  // ──────────────────────────────────────────────────────────────

  static const int _totalSteps = 4;

  int _currentStep = 0;

  /// Il pulsante Avanti è abilitato solo se lo step corrente è completo.
  bool get _canGoNext {
    switch (_currentStep) {
      case 0:
        return _selectedCountry != null;
      case 1:
        return _reverseSolicitation;
      case 2:
        return _ageConfirmed;
      case 3:
        return _termsAccepted && _privacyAccepted;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_canGoNext || _currentStep >= _totalSteps - 1) return;
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep <= 0) return;
    setState(() => _currentStep--);
  }

  Widget _buildCurrentStep(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildStepCountry(context, loc, theme);
      case 1:
        return _buildStepReverse(loc, theme);
      case 2:
        return _buildStepAge(loc, theme);
      case 3:
        return _buildStepTerms(context, loc, theme);
      default:
        return _buildStepCountry(context, loc, theme);
    }
  }

  Widget _buildStepCountry(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.onboardingResidenceLabel,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // ignore: deprecated_member_use
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _selectedCountry,
          decoration: InputDecoration(
            labelText: loc.onboardingResidenceLabel,
            hintText: loc.onboardingResidenceHint,
            border: const OutlineInputBorder(),
          ),
          items: _euEeaCountries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text('${entry.value} (${entry.key})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCountry = value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return loc.onboardingValidationResidence;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStepReverse(AppLocalizations loc, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.onboardingReverseSolicitation,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // ── Checkbox: Reverse Solicitation (C003) ──
        CheckboxListTile(
          value: _reverseSolicitation,
          onChanged: (v) {
            setState(() => _reverseSolicitation = v ?? false);
          },
          title: Text(loc.onboardingReverseSolicitation),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildStepAge(AppLocalizations loc, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.onboardingAgeConfirm,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // ── Checkbox: Age Gate (C008) ──
        CheckboxListTile(
          value: _ageConfirmed,
          onChanged: (v) {
            setState(() => _ageConfirmed = v ?? false);
          },
          title: Text(loc.onboardingAgeConfirm),
          subtitle: Text(
            loc.onboardingAgeSubtitle,
            style: theme.textTheme.bodySmall,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildStepTerms(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          loc.onboardingTermsTitle,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // ── Checkbox: Accetto i Termini (C003) ──
        CheckboxListTile(
          key: const Key('onboarding_terms_check'),
          value: _termsAccepted,
          onChanged: (v) {
            setState(() => _termsAccepted = v ?? false);
          },
          title: Text.rich(
            TextSpan(
              text: loc.onboardingTermsAccept,
              children: [
                TextSpan(
                  text: loc.onboardingLinkTerms,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _termsTapRecognizer,
                ),
              ],
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        // ── Checkbox: Privacy Policy (C003) ──
        CheckboxListTile(
          key: const Key('onboarding_privacy_check'),
          value: _privacyAccepted,
          onChanged: (v) {
            setState(() => _privacyAccepted = v ?? false);
          },
          title: Text.rich(
            TextSpan(
              text: loc.onboardingPrivacyAccept,
              children: [
                TextSpan(
                  text: loc.onboardingLinkPrivacy,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: _privacyTapRecognizer,
                ),
              ],
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildNavButtons(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final isLast = _currentStep == _totalSteps - 1;
    return Row(
      children: [
        if (_currentStep > 0) ...[
          OutlinedButton(
            onPressed: _prevStep,
            child: Text(loc.onboardingStepBack),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: isLast
              ? FilledButton(
                  onPressed: _canContinue ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(loc.onboardingContinue),
                )
              : FilledButton(
                  onPressed: _canGoNext ? _nextStep : null,
                  child: Text(loc.onboardingStepNext),
                ),
        ),
      ],
    );
  }
}
