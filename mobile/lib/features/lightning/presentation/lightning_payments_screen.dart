import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/lightning_htlc.dart';
import '../../../core/models/lightning_invoice_record.dart';
import '../../../core/models/lightning_payment_record.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../l10n/app_localizations.dart';

/// Cosa si sta guardando nella schermata Pagamenti.
enum _PaymentsMode { invoices, pays, htlcs }

/// Pagamenti del nodo: storico delle fatture con stato (I3c-1).
///
/// // FLOW: Pagamenti del nodo Lightning
/// STEP 1: list_invoices / list_pays / get_pending_htlcs (in base al selettore)
/// STEP 2: "Carica altri" appende la pagina successiva (offset = già caricate)
class LightningPaymentsScreen extends StatefulWidget {
  const LightningPaymentsScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  /// Dimensione pagina: il bridge limita a 100, 25 tiene i payload piccoli.
  static const int pageSize = 25;

  @override
  State<LightningPaymentsScreen> createState() =>
      _LightningPaymentsScreenState();
}

class _LightningPaymentsScreenState extends State<LightningPaymentsScreen> {
  _PaymentsMode _mode = _PaymentsMode.invoices;
  List<LightningInvoiceRecord> _invoices = const [];
  List<LightningPaymentRecord> _pays = const [];
  List<LightningHtlc> _htlcs = const [];
  bool _hasMore = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Cambia sezione: azzera le pagine e ricarica (i conteggi sono diversi).
  void _switchMode(_PaymentsMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _pays = const [];
      _htlcs = const [];
      _hasMore = false;
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      switch (_mode) {
        case _PaymentsMode.invoices:
          final page = await widget.lightningService.listInvoices(
            limit: LightningPaymentsScreen.pageSize,
          );
          if (!mounted) return;
          setState(() {
            _invoices = page;
            _hasMore = page.length == LightningPaymentsScreen.pageSize;
          });
          debugPrint('[LoopEngineer] pagamenti: ${page.length} fatture');
        case _PaymentsMode.pays:
          final page = await widget.lightningService.listPays(
            limit: LightningPaymentsScreen.pageSize,
          );
          if (!mounted) return;
          setState(() {
            _pays = page;
            _hasMore = page.length == LightningPaymentsScreen.pageSize;
          });
          debugPrint('[LoopEngineer] pagamenti: ${page.length} pagamenti');
        case _PaymentsMode.htlcs:
          // PERCHÉ: gli HTLC sono pochi per definizione (uno per pagamento in
          // volo): nessuna paginazione, si caricano tutti insieme.
          final htlcs = await widget.lightningService.listPendingHtlcs();
          if (!mounted) return;
          setState(() {
            _htlcs = htlcs;
            _hasMore = false;
          });
          debugPrint('[LoopEngineer] pagamenti: ${htlcs.length} htlcs');
      }
    } on LightningException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loading = true);
    try {
      if (_mode == _PaymentsMode.invoices) {
        final page = await widget.lightningService.listInvoices(
          limit: LightningPaymentsScreen.pageSize,
          offset: _invoices.length,
        );
        if (!mounted) return;
        setState(() {
          _invoices = [..._invoices, ...page];
          _hasMore = page.length == LightningPaymentsScreen.pageSize;
        });
      } else {
        final page = await widget.lightningService.listPays(
          limit: LightningPaymentsScreen.pageSize,
          offset: _pays.length,
        );
        if (!mounted) return;
        setState(() {
          _pays = [..._pays, ...page];
          _hasMore = page.length == LightningPaymentsScreen.pageSize;
        });
      }
    } on LightningException catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(LightningException e) {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.isPermissionDenied
              ? loc.lightningErrorRestricted
              : loc.lightningErrorGeneric(e.message),
        ),
      ),
    );
  }

  static String _date(DateTime d) => DateFormat('dd/MM/yyyy · HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningPayments)),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SegmentedButton<_PaymentsMode>(
                segments: [
                  ButtonSegment<_PaymentsMode>(
                    value: _PaymentsMode.invoices,
                    label: Text(loc.lightningInvoices),
                  ),
                  ButtonSegment<_PaymentsMode>(
                    value: _PaymentsMode.pays,
                    label: Text(loc.lightningPays),
                  ),
                  ButtonSegment<_PaymentsMode>(
                    value: _PaymentsMode.htlcs,
                    label: Text(loc.lightningChannelHtlcs),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) =>
                    _switchMode(selection.first),
              ),
              const SizedBox(height: 16),
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    if (_mode == _PaymentsMode.invoices)
                      if (_invoices.isEmpty)
                        _emptyRow(theme, loc.lightningInvoicesEmpty)
                      else
                        for (final invoice in _invoices)
                          _invoiceRow(loc, theme, invoice)
                    else if (_mode == _PaymentsMode.pays)
                      if (_pays.isEmpty)
                        _emptyRow(theme, loc.lightningPaysEmpty)
                      else
                        for (final pay in _pays) _payRow(loc, theme, pay)
                    else if (_htlcs.isEmpty)
                      _emptyRow(theme, loc.lightningHtlcsEmpty)
                    else
                      for (final htlc in _htlcs)
                        _htlcRow(loc, theme, htlc),
                  ],
                ),
              ),
              if (_hasMore) ...[
                const SizedBox(height: 12),
                Center(
                  child: FilledButton.tonalIcon(
                    onPressed: _loading ? null : _loadMore,
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(loc.lightningMovementsLoadMore),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyRow(ThemeData theme, String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(message, style: theme.textTheme.bodyMedium),
      );

  /// Riga di un pagamento in uscita: importo, fee e stato.
  Widget _payRow(
    AppLocalizations loc,
    ThemeData theme,
    LightningPaymentRecord pay,
  ) {
    final (color, label) = switch (pay.status.toLowerCase()) {
      'complete' => (Colors.greenAccent, loc.lightningPaymentCompleted),
      'failed' => (Colors.redAccent, loc.lightningPaymentFailed),
      _ => (Colors.orangeAccent, loc.lightningPaymentPending),
    };
    final date = pay.date;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.arrow_upward_rounded, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '-${NumberFormat.decimalPattern().format(pay.amountSats)} sat',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (date != null)
                  Text(_date(date), style: theme.textTheme.bodySmall),
                if (pay.feeSats > 0)
                  Text(
                    '${loc.lightningPaymentFee}: ${pay.feeSats} sat',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  /// Riga di un HTLC: importo, direzione, scadenza e stato grezzo.
  Widget _htlcRow(AppLocalizations loc, ThemeData theme, LightningHtlc htlc) {
    final color = htlc.isIncoming ? Colors.greenAccent : Colors.orangeAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              htlc.isIncoming ? Icons.south_west : Icons.north_east,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberFormat.decimalPattern().format(htlc.amountSats)} sat',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  htlc.isIncoming
                      ? loc.lightningHtlcIncoming
                      : loc.lightningHtlcOutgoing,
                  style: theme.textTheme.bodySmall,
                ),
                // PERCHÉ: lo stato grezzo resta visibile — l'etichetta "in
                // corso" è una derivazione, non una verità del nodo.
                Text(htlc.state, style: theme.textTheme.bodySmall),
                if (htlc.expiry != null)
                  Text(
                    '${loc.lightningOnchainBlockHeight} ${htlc.expiry}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (htlc.pending)
            Text(
              loc.lightningHtlcInProgress,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.orangeAccent, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _invoiceRow(
    AppLocalizations loc,
    ThemeData theme,
    LightningInvoiceRecord invoice,
  ) {
    final state = invoice.state;
    // PERCHÉ: colori coerenti col resto dell'app (verde = positivo/ricevuto,
    // arancio = attenzione, grigio = non più valido).
    final (color, label) = switch (state) {
      LightningInvoiceState.paid => (
          Colors.greenAccent,
          loc.lightningInvoiceStatusPaid,
        ),
      LightningInvoiceState.pending => (
          Colors.orangeAccent,
          loc.lightningInvoiceStatusPending,
        ),
      LightningInvoiceState.expired => (
          Colors.grey,
          loc.lightningInvoiceStatusExpired,
        ),
      LightningInvoiceState.unknown => (
          Colors.grey,
          invoice.status,
        ),
    };
    final paidDate = invoice.paidDate;
    final expiry = invoice.expiryDate;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.bolt, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${NumberFormat.decimalPattern().format(invoice.amountSats)} sat',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  state == LightningInvoiceState.paid && paidDate != null
                      ? loc.lightningInvoicePaidOn(_date(paidDate))
                      : (expiry == null
                          ? label
                          : loc.lightningInvoiceExpiresOn(_date(expiry))),
                  style: theme.textTheme.bodySmall,
                ),
                if (invoice.description != null)
                  Text(
                    invoice.description!,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
