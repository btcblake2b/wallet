import 'package:flutter/material.dart';

import '../../../../core/models/lightning_channel.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../l10n/app_localizations.dart';
import 'peer_discovery_card.dart';

/// Card «non puoi ancora ricevere» — presentazionale, senza I/O.
///
/// // PERCHÉ (adozione, 26/10): sulla rete blake2b i nodi pubblici sono ~55,
/// // quindi un nodo senza canali in entrata è la norma, non l'eccezione.
/// // Senza questo avviso l'utente crea una fattura, la condivide e il
/// // pagamento semplicemente non parte: sembra un bug dell'app o del bridge.
///
/// // PERCHÉ separata dalla variante che carica i canali: *Canali* e
/// // *Gestione nodo* hanno già la lista in memoria — una seconda
/// // `listChannels()` sarebbe un round-trip inutile sul relay.
class InboundLiquidityNotice extends StatelessWidget {
  const InboundLiquidityNotice({
    super.key,
    required this.inboundSats,
    this.onRefresh,
  });

  /// Liquidità in entrata in satoshi. `null` = non nota → nessun avviso
  /// (mai un falso allarme quando il dato non è affidabile).
  final int? inboundSats;

  /// Rilegge i canali («Ricontrolla»). `null` = nessun pulsante.
  final Future<void> Function()? onRefresh;

  /// Regola unica per l'inbound utilizzabile: `receivable` del nodo con
  /// fallback sul saldo remoto, esclusi i canali chiusi (stessa regola della
  /// schermata di gestione nodo).
  static int inboundOf(Iterable<LightningChannel> channels) =>
      channels.where((c) => !c.isClosed).fold<int>(
            0,
            (sum, c) => sum + (c.receivableSats ?? c.remoteBalanceSats),
          );

  @override
  Widget build(BuildContext context) {
    if (inboundSats != 0) return const SizedBox.shrink();
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
              const Icon(
                Icons.call_received,
                size: 18,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.lightningInboundMissingTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.lightningInboundMissingBody,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => PeerDiscoveryCard.openUrl(
                  context,
                  PeerDiscoveryCard.lspUrl,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(loc.lightningInboundMissingCta),
              ),
              if (onRefresh != null)
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text(loc.lightningInboundMissingRefresh),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
