import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/info_hints_l10n.dart';

/// "Come funziona": la guida per principianti, IN-APP.
///
/// PERCHÉ (26/10): i pallini ⓘ spiegano un campo alla volta, ma chi apre l'app
/// per la prima volta non sa quali domande farsi. La guida riusa le STESSE
/// stringhe degli hint (`infoTitle`/`infoBody`) in ordine didattico: una sola
/// verità da tradurre, due modi di raggiungerla (contesto e capitolo).
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key, this.openUrl});

  /// Seam iniettabile: nei test evita di aprire davvero il browser.
  final Future<void> Function(Uri uri)? openUrl;

  /// Guida lunga sul sito (inglese: default per le lingue non tradotte).
  ///
  /// PERCHÉ senza `.html`: Cloudflare Pages risponde 308 sulla forma `.html`
  /// (stesso criterio di `WebVaultNotice.downloadUrl`) — un redirect in meno
  /// per l'utente e link coerente con il resto dell'app.
  static const String learnUrlEn = 'https://btcblake2b.org/learn';

  /// Guida lunga sul sito in italiano.
  static const String learnUrlIt = 'https://btcblake2b.org/it/learn';

  /// PERCHÉ: la guida lunga esiste in due lingue; per le altre si apre quella
  /// inglese invece di un 404 (il sito non ha altre traduzioni).
  static String learnUrlFor(String languageCode) =>
      languageCode == 'it' ? learnUrlIt : learnUrlEn;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(loc.guideTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassContainer(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.guideTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(loc.guideIntro, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    loc.guideHintsNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final section in GuideSection.values) ...[
              _sectionTitle(loc.guideSectionTitle(section), theme),
              _sectionCard([
                for (final topic in guideTopicsOf(section))
                  _topicTile(topic, loc, theme),
              ]),
            ],
            _buildFullGuideCard(context, loc, theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 4),
      // PERCHÉ: Material trasparente tra la card e gli ExpansionTile — senza,
      // i tap non mostrano l'ink splash (stesso criterio di SettingsScreen).
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    );
  }

  Widget _topicTile(GuideTopic topic, AppLocalizations loc, ThemeData theme) {
    return ExpansionTile(
      leading: Icon(topic.icon, size: 20),
      title: Text(loc.infoTitle(topic.id)),
      // PERCHÉ: `childrenPadding` invece di un Padding interno → il testo
      // resta allineato al titolo su qualsiasi larghezza.
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.infoBody(topic.id), style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildFullGuideCard(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.guideFullGuideTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(loc.guideFullGuideDesc, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => _openFullGuide(context),
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: Text(loc.guideFullGuideOpen),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullGuide(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);
    final uri = Uri.parse(
      learnUrlFor(Localizations.localeOf(context).languageCode),
    );
    try {
      final opener = openUrl;
      if (opener != null) {
        await opener(uri);
        return;
      }
      if (!await canLaunchUrl(uri)) {
        throw StateError('canLaunchUrl=false');
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // PERCHÉ: come nel resto dell'app — un tap non deve mai "non fare nulla"
      // in silenzio; la guida resta comunque consultabile qui dentro.
      debugPrint('[LoopEngineer] apertura guida $uri fallita: $e');
      messenger.showSnackBar(SnackBar(content: Text(loc.guideOpenFailed)));
    }
  }
}

/// Capitoli della guida: raggruppano gli [InfoHintId] in ordine didattico.
enum GuideSection { basics, security, transactions, lightning, advanced }

/// Un argomento della guida = un concetto già spiegato dai pallini ⓘ.
class GuideTopic {
  const GuideTopic(this.id, this.icon);

  final InfoHintId id;
  final IconData icon;
}

/// Mappa capitolo → argomenti. L'ordine delle liste è l'ordine di lettura.
const Map<GuideSection, List<GuideTopic>> kGuideTopics = {
  GuideSection.basics: [
    GuideTopic(InfoHintId.whatIsWallet, Icons.account_balance_wallet_outlined),
    GuideTopic(InfoHintId.selfCustody, Icons.vpn_key_outlined),
    GuideTopic(InfoHintId.networkBlake2b, Icons.hub_outlined),
    GuideTopic(InfoHintId.lightningVsOnchain, Icons.bolt_outlined),
    GuideTopic(InfoHintId.privacyBasics, Icons.visibility_off_outlined),
  ],
  GuideSection.security: [
    GuideTopic(InfoHintId.seedPhrase, Icons.receipt_long_outlined),
    GuideTopic(InfoHintId.appEncryption, Icons.lock_outline),
    GuideTopic(InfoHintId.watchOnly, Icons.remove_red_eye_outlined),
    GuideTopic(InfoHintId.signVerify, Icons.verified_outlined),
  ],
  GuideSection.transactions: [
    GuideTopic(InfoHintId.receiveAddress, Icons.qr_code_2_outlined),
    GuideTopic(InfoHintId.balanceUtxo, Icons.account_balance_outlined),
    GuideTopic(InfoHintId.confirmations, Icons.check_circle_outline),
    GuideTopic(InfoHintId.feeConcept, Icons.local_gas_station_outlined),
    GuideTopic(InfoHintId.changeAddress, Icons.swap_horiz),
  ],
  GuideSection.lightning: [
    GuideTopic(InfoHintId.channelCapacity, Icons.pie_chart_outline),
    GuideTopic(InfoHintId.channelReserve, Icons.savings_outlined),
    GuideTopic(InfoHintId.htlc, Icons.timer_outlined),
    GuideTopic(InfoHintId.toSelfDelay, Icons.hourglass_bottom_outlined),
    GuideTopic(InfoHintId.openChannelPrivate, Icons.lock_person_outlined),
    GuideTopic(InfoHintId.routingFees, Icons.alt_route_outlined),
    GuideTopic(InfoHintId.forceClose, Icons.gavel_outlined),
    GuideTopic(InfoHintId.peers, Icons.people_outline),
    GuideTopic(InfoHintId.nodeManagement, Icons.dns_outlined),
  ],
  GuideSection.advanced: [
    GuideTopic(InfoHintId.coinControl, Icons.tune_outlined),
    GuideTopic(InfoHintId.dustLimit, Icons.change_history),
    GuideTopic(InfoHintId.feeRate, Icons.speed_outlined),
    GuideTopic(InfoHintId.batchSend, Icons.call_split_outlined),
    GuideTopic(InfoHintId.bumpFee, Icons.trending_up),
    GuideTopic(InfoHintId.xpub, Icons.key_outlined),
  ],
};

/// Argomenti del capitolo [section] (lista vuota se non configurato).
List<GuideTopic> guideTopicsOf(GuideSection section) =>
    kGuideTopics[section] ?? const <GuideTopic>[];

extension GuideSectionL10n on AppLocalizations {
  String guideSectionTitle(GuideSection section) => switch (section) {
        GuideSection.basics => guideSectionBasics,
        GuideSection.security => guideSectionSecurity,
        GuideSection.transactions => guideSectionTransactions,
        GuideSection.lightning => guideSectionLightning,
        GuideSection.advanced => guideSectionAdvanced,
      };
}
