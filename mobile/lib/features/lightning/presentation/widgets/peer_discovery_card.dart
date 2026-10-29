import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/external_links.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';

/// Card "Trova peer e liquidità": dove guardare per scegliere un peer, ottenere
/// liquidità in entrata e proteggere i canali.
///
/// // PERCHÉ (26/10): su questa rete non esistono Amboss o 1ML, e la community
/// chiede esattamente questo ("dove trovo peer?"). L'app è un client di nodo
/// remoto: non può inventare un catalogo, ma può portare l'utente ai punti di
/// riferimento reali (explorer del grafo, LSP, swap, torri) invece di lasciarlo
/// con un campo pubkey vuoto.
///
/// I link sono **esterni** e nessun dato nostro viene inviato: si apre il
/// browser di sistema.
class PeerDiscoveryCard extends StatelessWidget {
  const PeerDiscoveryCard({super.key});

  /// Explorer del grafo Lightning blake2b (Paperclip): nodi, canali, capacità.
  static const String networkExplorerUrl =
      'https://lightning.paperclippool.xyz/network';

  /// LSP Paperclip: liquidità in entrata pagata on-chain in XBT.
  static const String lspUrl = 'https://lightning.paperclippool.xyz/liquidity';

  /// Nodex (Kilombino): canali, fee dei due versi, uptime, operatori.
  static const String nodexUrl = 'https://nodex.kilombino.com';

  /// Lightning Fork Swap: swap non-custodial LN ↔ on-chain per la liquidità.
  static const String swapUrl = 'https://lightningfork.com';

  /// Torri pubbliche XBT per nodi **lnd** (`wtclient`), non per CLN.
  static const String watchtowerKilombino =
      '033f366c8e43b040dbc27648d68e123650ec1f23176de092f39b9e0a7fb4f2a95d@'
      'b44c2u3dar4fdhb4m4vsp3v6kzohh2cqrggk2io74v4olr4nn5nytyad.onion:9911';
  static const String watchtowerLogosnaut =
      '0241c33c761228149d03318170a8a951f6ffa0222d20406330de9096eec074feb2@'
      'av7mamacxs4z7fj2xwnob3vn62kcmf7chsy3ckrasebo6qdbubcby4ad.onion:9911';

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.travel_explore, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.lightningDiscoveryTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(loc.lightningDiscoveryBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          _linkRow(
            context,
            icon: Icons.hub_outlined,
            title: loc.lightningDiscoveryNetworkTitle,
            body: loc.lightningDiscoveryNetworkBody,
            url: networkExplorerUrl,
          ),
          _linkRow(
            context,
            icon: Icons.call_received,
            title: loc.lightningDiscoveryLspTitle,
            body: loc.lightningDiscoveryLspBody,
            url: lspUrl,
          ),
          _linkRow(
            context,
            icon: Icons.insights_outlined,
            title: loc.lightningDiscoveryNodexTitle,
            body: loc.lightningDiscoveryNodexBody,
            url: nodexUrl,
          ),
          _linkRow(
            context,
            icon: Icons.swap_horiz,
            title: loc.lightningDiscoverySwapTitle,
            body: loc.lightningDiscoverySwapBody,
            url: swapUrl,
          ),
          const Divider(height: 24),
          Text(
            loc.lightningDiscoveryWatchtowerTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            loc.lightningDiscoveryWatchtowerBody,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          _towerRow(context, 'Kilombino', watchtowerKilombino),
          _towerRow(context, 'logosnaut', watchtowerLogosnaut),
        ],
      ),
    );
  }

  /// Riga cliccabile che apre un servizio esterno nel browser di sistema.
  Widget _linkRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required String url,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => PeerDiscoveryCard.openUrl(context, url),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(body, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16),
          ],
        ),
      ),
    );
  }

  /// Riga di sola copia: gli URI delle torri si incollano in `lnd.conf`/`lncli`.
  Widget _towerRow(BuildContext context, String name, String uri) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _copy(context, uri),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$name — ${uri.split('@').first.substring(0, 12)}…',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const Icon(Icons.copy, size: 16),
          ],
        ),
      ),
    );
  }

  /// Apre un link esterno nel browser di sistema, con feedback se fallisce.
  ///
  /// // PERCHÉ (27/10): l'implementazione vive in `core/utils/external_links.dart`
  /// // — la usano anche le schermate esercente. Questo metodo resta il punto
  /// // d'ingresso storico della card (nessun call-site da cambiare).
  static Future<void> openUrl(BuildContext context, String url) =>
      openExternalUrl(context, url);

  Future<void> _copy(BuildContext context, String value) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text(loc.lightningCopied)));
  }
}
