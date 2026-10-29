import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/wallet_record.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/external_links.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// «Converti in BTC»: come un esercente esce da XBT.
///
/// // PERCHÉ (leva 4, parte B — 27/10): un esercente non tiene XBT «per
/// // sempre»: a un certo punto vuole BTC (o pagare un fornitore). La
/// // conversione XBT↔BTC è CROSS-CHAIN e la fanno solo servizi di terzi
/// // non-custodial (Paperclip Bridge, Lightning Fork Swap). Noi NON possiamo
/// // farla: sarebbe un servizio di cambio (CASP/OAM, vedi legal.md).
///
/// // PERCHÉ quindi una schermata e non un semplice link: l'esercente deve
/// // (a) avere sotto mano il PROPRIO indirizzo da incollare là, (b) sapere
/// // cosa non deve mai fare (seed, importi a occhio), (c) non credere che
/// // l'app custodisca o garantisca il cambio.
class MerchantConvertScreen extends StatelessWidget {
  const MerchantConvertScreen({
    super.key,
    required this.wallet,
    this.extraWallets = const [],
  });

  final WalletRecord wallet;

  /// Altri wallet selezionabili per copiare l'indirizzo (il primo è [wallet]).
  final List<WalletRecord> extraWallets;

  /// Bridge non-custodial XBT ↔ BTC (Paperclip): incassa solo a fattura pagata.
  static const String paperclipBridgeUrl =
      'https://lightning.paperclip-xbt.xyz/bridge';

  /// Swap non-custodial della community (Lightning Fork Swap).
  static const String lightningForkUrl = 'https://lightningfork.com';

  List<WalletRecord> get _wallets => [wallet, ...extraWallets];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.merchantConvertTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Text(
                loc.merchantConvertIntro,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.merchantConvertAddressTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.merchantConvertAddressBody,
                    style: theme.textTheme.bodySmall,
                  ),
                  for (final w in _wallets) ...[
                    const SizedBox(height: 10),
                    _addressRow(context, loc, theme, w),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _serviceRow(
              context,
              loc: loc,
              theme: theme,
              icon: Icons.currency_bitcoin,
              title: loc.merchantConvertPaperclipTitle,
              body: loc.merchantConvertPaperclipBody,
              url: paperclipBridgeUrl,
            ),
            _serviceRow(
              context,
              loc: loc,
              theme: theme,
              icon: Icons.swap_horiz,
              title: loc.merchantConvertForkTitle,
              body: loc.merchantConvertForkBody,
              url: lightningForkUrl,
            ),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.gpp_maybe, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        loc.merchantConvertWarningTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.merchantConvertWarningBody,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressRow(
    BuildContext context,
    AppLocalizations loc,
    ThemeData theme,
    WalletRecord w,
  ) {
    final label = (w.name == null || w.name!.trim().isEmpty)
        ? loc.merchantConvertUnnamedWallet
        : w.name!.trim();
    return InkWell(
      onTap: () => _copy(context, loc, w.publicAddress),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    w.publicAddress,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _serviceRow(
    BuildContext context, {
    required AppLocalizations loc,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String body,
    required String url,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () => openExternalUrl(context, url),
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
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
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

  Future<void> _copy(
    BuildContext context,
    AppLocalizations loc,
    String value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text(loc.lightningCopied)));
  }
}
