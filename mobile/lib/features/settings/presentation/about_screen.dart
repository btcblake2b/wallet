// PERCHÉ (C002 + audit legale 2026-09-07): Schermata About con attribuzioni
// licenze open-source. Soddisfa l'obbligo Apache-2.0 §4(d) di rendere
// accessibili le attribuzioni all'interno dell'app stessa.
//
// Audit legale: versione letta dinamicamente (niente hardcode), copyright
// unificato, link al repo GitHub reale, chip "Firebase" rimossa (il fork non
// ha più backend Firebase → dichiarazione falsa).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';

// PERCHÉ (fix 2.6): le attribuzioni sono un ASSET LOCALE dell'app — visibili
// offline e senza chiamate di rete a terzi (prima si apriva
// raw.githubusercontent.com nel browser esterno). L'URL pubblico resta per il
// fallback esplicito se l'asset non è disponibile (build anomala).
const String kThirdPartyLicensesAsset = 'assets/legal/THIRD_PARTY_LICENSES.md';

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

  /// Apre la schermata licenze IN-APP (asset locale, offline-first).
  void _openLicenses() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const _LicensesScreen()),
    );
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

/// Schermata delle licenze terze parti letta dall'asset locale.
///
/// PERCHÉ (fix 2.6): l'obbligo Apache-2.0 §4(d) richiede che le attribuzioni
/// siano accessibili NELL'app, non su un sito esterno raggiungibile solo con
/// la rete. Il fallback online è un'azione esplicita dell'utente.
class _LicensesScreen extends StatelessWidget {
  const _LicensesScreen();

  Future<void> _openOnline() async {
    final uri = Uri.parse(kThirdPartyLicensesUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Scaffold(
      appBar: AppBar(title: Text(loc.aboutThirdPartyLicenses)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(kThirdPartyLicensesAsset),
        builder: (context, snapshot) {
          if (snapshot.hasData && (snapshot.data ?? '').isNotEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                snapshot.data!,
                // PERCHÉ: il file è markdown/testo puro generato dallo
                // script — font monospace per leggibilità, niente parsing.
                style: textStyle?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            // PERCHÉ: mai un vicolo cieco — se l'asset manca, l'utente può
            // ancora consultare le attribuzioni online (scelta esplicita).
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.aboutThirdPartyLicensesDesc,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _openOnline,
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(loc.aboutLicensesOpenOnline),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
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
