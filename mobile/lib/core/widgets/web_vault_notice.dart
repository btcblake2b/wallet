import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'glass_container.dart';

/// Avviso esplicito sulla variante browser/PWA: dove vivono le chiavi e quale
/// rischio resta.
///
/// // PERCHÉ (26/10): sul web la seed cifrata vive in `localStorage` (con
/// // backup IndexedDB) e la chiave AES è avvolta dalla password: è il massimo
/// // ragionevole per un browser, ma un XSS **mentre il vault è sbloccato**
/// // legge le chiavi in memoria. Un utente deve saperlo PRIMA di metterci
/// // fondi veri, non scoprirlo da un audit. Su mobile questo rischio non
/// // esiste (keyring del sistema operativo).
class WebVaultNotice extends StatelessWidget {
  const WebVaultNotice({super.key, this.isWeb = kIsWeb, this.origin});

  /// Seam iniettabile: `kIsWeb` è una costante di compilazione e nei test vale
  /// sempre `false` (stessa convenzione di `hideNodeConnect`/`filterRelays`).
  final bool isWeb;

  /// Origine da cui gira l'app (es. `https://app.btcblake2b.org`). `null` =
  /// leggila da `Uri.base` (comportamento reale nel browser).
  final String? origin;

  /// Pagina di download dell'APK (distribuzione diretta, nessuno store).
  static const String downloadUrl = 'https://btcblake2b.org/download';

  /// Dominio ufficiale della PWA (target di deploy, ADR 2026-09-18).
  static const String officialOrigin = 'https://app.btcblake2b.org';

  /// `true` se l'app gira su un'origine diversa da quella ufficiale.
  ///
  /// // PERCHÉ (R3, 26/10): il fork non è sugli store e il dominio si digita a
  /// // mano: una copia del sito su un dominio simile è l'attacco più sfruttato
  /// // e l'app non poteva accorgersene. Qui l'origine REALE (letta a runtime)
  /// // viene mostrata all'utente, quindi una copia mostra il proprio dominio.
  static bool isUnofficialOrigin(String origin) {
    final normalized = origin.trim().toLowerCase();
    if (normalized == officialOrigin) return false;
    // Sviluppo locale: non è un attacco, è `scripts/serve-pwa.ps1`.
    final host = Uri.tryParse(normalized)?.host ?? '';
    return !(host == 'localhost' || host == '127.0.0.1' || host == '::1');
  }

  static bool isLocalOrigin(String origin) {
    final host = Uri.tryParse(origin.trim().toLowerCase())?.host ?? '';
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  @override
  Widget build(BuildContext context) {
    if (!isWeb) return const SizedBox.shrink();
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shownOrigin = origin ?? Uri.base.origin;
    final unofficial = isUnofficialOrigin(shownOrigin);
    final originLabel = unofficial
        ? loc.webVaultOriginUnofficial(shownOrigin)
        : isLocalOrigin(shownOrigin)
            ? loc.webVaultOriginDev(shownOrigin)
            : loc.webVaultOriginOfficial(shownOrigin);
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                unofficial ? Icons.gpp_bad : Icons.public,
                size: 18,
                color: unofficial ? Colors.redAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.webVaultNoticeTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            originLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: unofficial ? Colors.redAccent : null,
              fontWeight: unofficial ? FontWeight.w700 : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(loc.webVaultNoticeBody, style: theme.textTheme.bodySmall),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openDownload(context),
              icon: const Icon(Icons.download, size: 16),
              label: Text(loc.webVaultNoticeDownload),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDownload(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);
    try {
      await launchUrl(
        Uri.parse(downloadUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // PERCHÉ: come nel resto dell'app — un tap non deve mai "non fare nulla"
      // in silenzio.
      debugPrint('[LoopEngineer] apertura $downloadUrl fallita: $e');
      messenger.showSnackBar(
        SnackBar(content: Text(loc.lightningDiscoveryOpenFailed)),
      );
    }
  }
}
