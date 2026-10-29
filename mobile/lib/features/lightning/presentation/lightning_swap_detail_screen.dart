import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/config/bitcoin_network_config.dart';
import '../../../core/services/swap/swap_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';
import 'swap_error_text.dart';
import 'widgets/swap_field_row.dart';

/// Dettaglio di UNA transazione dello storico swap (P9).
///
/// // PERCHÉ (07/10/2026): dopo un pagamento via provider l'utente deve poter
/// // rileggere cosa è successo — importo, data, stato, hash e transazioni —
/// // e, se lo swap è fallito, recuperare i fondi senza tornare a cercare la
/// // sessione. Il dettaglio è di sola LETTURA tranne la copia dei dati e il
/// // refund: gli stessi dati che l'app ha già (nessun segreto, nessuna rete).
///
/// Ritorna `true` da [Navigator.pop] se è stato trasmesso un refund (il
/// chiamante ricarica lo storico).
class LightningSwapDetailScreen extends StatefulWidget {
  const LightningSwapDetailScreen({
    super.key,
    required this.session,
    required this.recoveryBlob,
    this.onRefund,
  });

  final SwapSession session;

  /// Blob di recupero precalcolato dal chiamante (stessa sorgente dello
  /// storico: nessuna dipendenza dal servizio in questa schermata).
  final String recoveryBlob;

  /// Azione di rimborso: ritorna il txid trasmesso o lancia [SwapException].
  /// `null` = refund non disponibile (stato non rimborsabile o wallet mancante).
  final Future<String> Function()? onRefund;

  @override
  State<LightningSwapDetailScreen> createState() =>
      _LightningSwapDetailScreenState();
}

class _LightningSwapDetailScreenState extends State<LightningSwapDetailScreen> {
  bool _busy = false;

  SwapSession get _s => widget.session;

  /// Abbreviazione riconoscibile: testa + coda (hash/txid/indirizzi).
  String _short(String value) => value.length > 24
      ? '${value.substring(0, 12)}…${value.substring(value.length - 8)}'
      : value;

  /// Importo in evidenza: quello della INVOICE (quanto va al destinatario);
  /// se la sessione è antecedente al 07/10/2026 l'importo non è persistito →
  /// si mostra il totale bloccato.
  String get _amount => NumberFormat.decimalPattern()
      .format(_s.amountSats ?? _s.fundingAmountSats);

  String get _locked =>
      NumberFormat.decimalPattern().format(_s.fundingAmountSats);

  String get _date => DateFormat('dd/MM/yyyy · HH:mm')
      .format(DateTime.fromMillisecondsSinceEpoch(_s.createdAt * 1000));

  String _stateLabel(AppLocalizations loc) => switch (_s.state) {
        SwapClientState.awaitingFunding => loc.swapStateAwaitingFunding,
        SwapClientState.confirming => loc.swapStateConfirming,
        SwapClientState.paying => loc.swapStatePaying,
        SwapClientState.paid => loc.swapStatePaid,
        SwapClientState.claiming => loc.swapStateClaiming,
        SwapClientState.completed => loc.swapStateCompleted,
        SwapClientState.paymentFailed => loc.swapStatePaymentFailed,
        SwapClientState.expired => loc.swapStateExpired,
        SwapClientState.refunded => loc.swapStateRefunded,
      };

  Future<void> _copyBlob() async {
    final loc = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: widget.recoveryBlob));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.lightningSwapBlobCopied)),
    );
  }

  Future<void> _refund() async {
    final loc = AppLocalizations.of(context);
    final action = widget.onRefund;
    if (action == null || _busy) return;
    setState(() => _busy = true);
    try {
      final txid = await action();
      if (!mounted) return;
      debugPrint('[LoopEngineer] SwapDetail: refund trasmesso $txid');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.lightningSwapRefundSent(_short(txid))),
        ),
      );
      // PERCHÉ: lo stato "vero" arriva dal provider al prossimo refresh —
      // qui si torna allo storico che si ricarica.
      Navigator.of(context).pop(true);
    } on SwapException catch (e) {
      if (!mounted) return;
      final message = e.code == 'REFUND_TOO_EARLY'
          ? loc.lightningSwapRefundNotYet(_s.cltvHeight)
          : (swapErrorReason(loc, e.code) ?? e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningSwapDetailTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$_amount sat',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _stateLabel(loc),
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: AppTheme.lightningAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Importo invoice = quanto va al destinatario; il totale
                // bloccato aggiunge le fee (claim, ed eventuale servizio).
                if (_s.amountSats != null)
                  _row(loc.lightningSwapAmount, '$_amount sat'),
                _row(loc.lightningSwapTotal, '$_locked sat'),
                _row(loc.lightningSwapDetailCreated, _date),
                if (_s.walletName != null)
                  _row(loc.lightningSwapWalletLabel, _s.walletName!),
                const SizedBox(height: 4),
                Text(
                  loc.lightningSwapCltv(_s.cltvHeight),
                  style: theme.textTheme.bodySmall,
                ),
                if (_s.state.isRefundable && widget.onRefund != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    loc.lightningSwapRefundHint,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _refund,
                    icon: const Icon(Icons.undo),
                    label: Text(loc.lightningSwapRefund),
                  ),
                ],
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              children: [
                _sectionTitle(loc.lightningSwapDetailSummary),
                SwapFieldRow(
                  label: loc.lightningSwapHtlc,
                  value: _short(_s.htlcAddress),
                  copyValue: _s.htlcAddress,
                  monospace: true,
                ),
                if (_s.fundingTxid != null)
                  SwapFieldRow(
                    label: loc.lightningSwapDetailFundingTx,
                    value: _short(_s.fundingTxid!),
                    copyValue: _s.fundingTxid,
                    explorerUrl:
                        BitcoinNetworkConfig.txExplorerUrl(_s.fundingTxid!),
                    monospace: true,
                  ),
                if (_s.claimTxid != null)
                  SwapFieldRow(
                    label: loc.lightningSwapClaimTxid,
                    value: _short(_s.claimTxid!),
                    copyValue: _s.claimTxid,
                    explorerUrl:
                        BitcoinNetworkConfig.txExplorerUrl(_s.claimTxid!),
                    hint: loc.lightningSwapClaimHint,
                    monospace: true,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              children: [
                _sectionTitle(loc.lightningSwapDetailProtocol),
                SwapFieldRow(
                  label: loc.lightningSwapDetailSwapId,
                  value: _short(_s.swapId),
                  copyValue: _s.swapId,
                  monospace: true,
                ),
                SwapFieldRow(
                  label: loc.lightningSwapDetailPaymentHash,
                  value: _short(_s.paymentHashHex),
                  copyValue: _s.paymentHashHex,
                  monospace: true,
                ),
                SwapFieldRow(
                  label: loc.lightningSwapDetailProvider,
                  value: _short(_s.providerPubkey),
                  copyValue: _s.providerPubkey,
                  monospace: true,
                ),
                SwapFieldRow(
                  label: loc.lightningSwapDetailInvoice,
                  value: _short(_s.invoice),
                  copyValue: _s.invoice,
                ),
                if (_s.errorCode != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      // PERCHÉ: motivo localizzato se il codice è noto, testo
                      // del provider come fallback (utile al supporto).
                      swapErrorReason(loc, _s.errorCode!) ??
                          '${_s.errorCode}: ${_s.errorMessage ?? ''}',
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              children: [
                _sectionTitle(loc.lightningSwapRecoveryTitle),
                Text(
                  loc.lightningSwapRecoveryHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _copyBlob,
                  icon: const Icon(Icons.copy),
                  label: Text(loc.lightningSwapCopyBlob),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) => GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      );

  /// Riga etichetta/valore (stesso pattern della card sessione: mai overflow).
  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
