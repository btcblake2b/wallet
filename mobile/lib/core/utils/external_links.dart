import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Apre un link esterno nel browser di sistema, con feedback se fallisce.
///
/// // PERCHÉ (27/10): la stessa azione serve in tre aree dell'app (Lightning,
/// // esercente, impostazioni). Una sola implementazione evita che in uno solo
/// // dei punti un tap "non faccia nulla" in silenzio — e tiene le feature
/// // libere di importarsi a vicenda solo per un helper.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final loc = AppLocalizations.of(context);
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (e) {
    // PERCHÉ: `canLaunchUrl` può tornare `false` per una dichiarazione di
    // visibilità mancante nel manifest — il lancio si tenta comunque e
    // l'errore resta nei log: un tap dell'utente non deve mai "non fare nulla"
    // senza traccia.
    debugPrint('[LoopEngineer] apertura $url fallita: $e');
    messenger.showSnackBar(
      SnackBar(content: Text(loc.lightningDiscoveryOpenFailed)),
    );
  }
}
