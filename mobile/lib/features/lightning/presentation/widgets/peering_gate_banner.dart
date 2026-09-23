import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/cln_release_utils.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';

/// Avviso informativo: il nodo richiede `option_blake2b` (bit 68) e non ha
/// peer connessi, quindi i peer su release precedenti NON possono connettersi.
///
/// // PERCHÉ (P8): senza questo messaggio l'utente vede "0 peer" e un pulsante
/// "Connetti peer" che fallisce senza spiegazione — sembra un bug dell'app o
/// del bridge, mentre è una scelta del NODO (release `.4`+). Il widget è
/// **self-gating**: si disegna solo quando il gate è dimostrabile, così le
/// schermate che lo usano non duplicano la condizione.
class PeeringGateBanner extends StatelessWidget {
  const PeeringGateBanner({
    super.key,
    required this.version,
    required this.peersConnected,
  });

  /// Versione riportata da `get_info` (es. `v26.06.7-blake2b.4`).
  final String? version;

  /// Peer CONNESSI. `null` = dato non disponibile → nessun avviso.
  ///
  /// // PERCHÉ: con un bridge vecchio (senza `num_peers_connected`) non
  /// sappiamo se ci sono peer connessi: meglio nessun avviso che un falso.
  final int? peersConnected;

  /// Matrice di compatibilità pubblica (pagina Nodo del sito).
  static const String nodeDocsUrl = 'https://btcblake2b.org/node';

  @override
  Widget build(BuildContext context) {
    if (!clnRequiresBit68(version) || peersConnected != 0) {
      return const SizedBox.shrink();
    }
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.lightningPeeringGateTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(loc.lightningPeeringGateBody, style: theme.textTheme.bodySmall),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _openNodeDocs(),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(loc.lightningPeeringGateLink),
            ),
          ),
        ],
      ),
    );
  }

  /// Apre la pagina Nodo (matrice di compatibilità) nel browser di sistema.
  ///
  /// // PERCHÉ (fix 16/09): `canLaunchUrl` può tornare `false` per una
  /// dichiarazione di visibilità mancante nel manifest — il link non si apriva,
  /// in silenzio. Il lancio si tenta comunque e l'errore finisce nei log: un
  /// tap dell'utente non deve mai "non fare nulla" senza traccia.
  /// La dichiarazione `<queries>` per `https` è stata aggiunta al manifest.
  Future<void> _openNodeDocs() async {
    final uri = Uri.parse(nodeDocsUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[LoopEngineer] apertura $nodeDocsUrl fallita: $e');
    }
  }
}
