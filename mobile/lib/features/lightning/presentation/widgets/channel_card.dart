import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/lightning_channel.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/info_dot.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/info_hints_l10n.dart';

/// Card di un canale Lightning: stato, peer, capacità e saldi (in **sat**).
///
/// Nota unità: il protocollo porta msat (spec dln) — qui si usano i getter
/// `*Sats` del modello, così la UI è sempre in satoshi.
class LightningChannelCard extends StatelessWidget {
  const LightningChannelCard({super.key, required this.channel, this.onTap});

  final LightningChannel channel;
  final VoidCallback? onTap;

  static String _short(String value) => value.length <= 14
      ? value
      : '${value.substring(0, 6)}…${value.substring(value.length - 4)}';

  static String _fmt(int sats) => NumberFormat.decimalPattern().format(sats);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stateColor =
        channel.isUsable ? Colors.greenAccent : Colors.orangeAccent;
    final idLabel = channel.shortChannelId ?? _short(channel.id);
    final peerLabel = channel.peerLabel ?? _short(channel.peerPubkey);
    final htlcs = channel.htlcCount ?? 0;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      channel.state,
                      style: TextStyle(
                        color: stateColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (htlcs > 0) ...[
                    const SizedBox(width: 6),
                    // PERCHÉ (I2): un HTLC in volo è un'informazione operativa
                    // che va vista subito (pagamento in corso o bloccato).
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${loc.lightningChannelHtlcs}: $htlcs',
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(idLabel, style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${loc.lightningChannelPeer}: $peerLabel',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ChannelStat(
                    label: loc.lightningChannelCapacity,
                    value: '${_fmt(channel.capacitySats)} sat',
                  ),
                  const InfoDot(id: InfoHintId.channelCapacity),
                  _ChannelStat(
                    label: loc.lightningChannelSpendable,
                    value: channel.spendableSats == null
                        ? '—'
                        : '${_fmt(channel.spendableSats!)} sat',
                  ),
                  _ChannelStat(
                    label: loc.lightningChannelReceivable,
                    value: channel.receivableSats == null
                        ? '—'
                        : '${_fmt(channel.receivableSats!)} sat',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelStat extends StatelessWidget {
  const _ChannelStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
