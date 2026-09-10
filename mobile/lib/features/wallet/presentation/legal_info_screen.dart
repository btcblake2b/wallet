import 'package:flutter/material.dart';

import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';

// PERCHÉ (A3 + audit legale 2026-09-07): contenuti legali mostrati in-app.
// Il dominio ufficiale non è ancora stato acquistato (D4); quando sarà
// online, valutare il link esterno alla versione definitiva.
//
// Audit legale: testi riscritti per essere ACCURATI — l'API terza è
// dichiarata (mempool.guide, unica fonte dal 2026-09-08), rimossa la
// clausola "reverse solicitation" (nozione MiFID fuori contesto), aggiunto
// il disclaimer sulla natura sperimentale della rete fork. Il controvalore
// fiat (CoinGecko) è stato rimosso il 07/09/2026: la rete blake2b non ha
// prezzo di mercato.

// PERCHÉ (audit legale): contatti centralizzati. Dominio ufficiale attivo
// dal 07/09/2026: btcblake2b.org (contact@). La via raccomandata per le
// segnalazioni di sicurezza resta la GitHub Security Advisory (privata).
const String kContactEmail = 'contact@btcblake2b.org';
const String kCopyrightHolder = 'Filippo Santagiuliana';

class LegalInfoScreen extends StatelessWidget {
  const LegalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.legalInfoTitle),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disclaimer completo
              _buildSection(
                context,
                icon: Icons.warning_amber_rounded,
                title: loc.legalInfoTitle,
                content: loc.homeSecurityWarning,
              ),
              const SizedBox(height: 24),
              // Termini di Servizio (in-app, provvisori)
              _buildSection(
                context,
                icon: Icons.description_outlined,
                title: loc.onboardingLinkTerms,
                content: loc.legalTermsContent,
              ),
              const SizedBox(height: 24),
              // Privacy Policy (in-app, provvisoria)
              _buildSection(
                context,
                icon: Icons.privacy_tip_outlined,
                title: loc.onboardingLinkPrivacy,
                content: loc.legalPrivacyContent(kCopyrightHolder, kContactEmail),
              ),
              const SizedBox(height: 24),
              // Licenza MIT
              _buildSection(
                context,
                icon: Icons.description_outlined,
                title: loc.legalMitLicense,
                content: 'Copyright (c) 2025-2026 Filippo Santagiuliana\n\n'
                    'Permission is hereby granted, free of charge, to any person '
                    'obtaining a copy of this software and associated documentation '
                    'files (the "Software"), to deal in the Software without '
                    'restriction, including without limitation the rights to use, '
                    'copy, modify, merge, publish, distribute, sublicense, and/or '
                    'sell copies of the Software, and to permit persons to whom the '
                    'Software is furnished to do so, subject to the following '
                    'conditions:\n\n'
                    'The above copyright notice and this permission notice shall be '
                    'included in all copies or substantial portions of the Software.\n\n'
                    'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, '
                    'EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES '
                    'OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND '
                    'NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT '
                    'HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, '
                    'WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING '
                    'FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR '
                    'OTHER DEALINGS IN THE SOFTWARE.',
              ),
              const SizedBox(height: 24),
              // Contatti sicurezza
              _buildSection(
                context,
                icon: Icons.security_outlined,
                title: loc.legalSecurityTitle,
                content: loc.legalSecurityContact(kContactEmail),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Btc Blake2b Wallet',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
