// PERCHÉ (C002 + audit legale 2026-09-07): Schermata About con attribuzioni
// licenze open-source. Soddisfa l'obbligo Apache-2.0 §4(d) di rendere
// accessibili le attribuzioni all'interno dell'app stessa.
//
// Audit legale: versione letta dinamicamente (niente hardcode), copyright
// unificato, link al repo GitHub reale, chip "Firebase" rimossa (il fork non
// ha più backend Firebase → dichiarazione falsa).

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';

// PERCHÉ (audit legale): repo pubblico del progetto — il link precedente
// puntava a un repo inesistente (btc-blake2b-wallet/mobile).
const String kThirdPartyLicensesUrl =
    'https://raw.githubusercontent.com/btcblake2b/wallet/main/THIRD_PARTY_LICENSES.md';

/// Versione formattata dell'app (da PackageInfo).
String _formatVersion(PackageInfo info) =>
    'v${info.version}+${info.buildNumber}';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // PERCHÉ (audit legale): niente versione hardcoded che deriva rispetto a
  // pubspec.yaml — letta da PackageInfo (package già in uso in SecurityService).
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = _formatVersion(info));
    } catch (_) {
      // PERCHÉ: PackageInfo può fallire in ambienti di test → versione vuota.
    }
  }

  Future<void> _openLicenses() async {
    final uri = Uri.parse(kThirdPartyLicensesUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Text(
            loc.appTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _version,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(loc.aboutDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          // ── Licenza ──
          Text(loc.aboutLicenseTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'MIT License — Copyright (c) 2025-2026 Filippo Santagiuliana',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          // ── Licenze terze parti ──
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(loc.aboutThirdPartyLicenses),
            subtitle: Text(loc.aboutThirdPartyLicensesDesc),
            trailing: const Icon(Icons.open_in_new),
            onTap: _openLicenses,
          ),
          const Divider(),
          // ── Tecnologie ──
          Text(loc.aboutBuiltWith, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // PERCHÉ (audit legale): chip "Firebase" rimossa — il fork non
              // usa più Firebase (dichiarazione falsa).
              _TechChip('Flutter', Icons.flutter_dash),
              _TechChip('Dart', Icons.code),
              _TechChip('Bitcoin', Icons.currency_bitcoin),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            loc.aboutDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TechChip extends StatelessWidget {
  const _TechChip(this.label, this.icon);
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
