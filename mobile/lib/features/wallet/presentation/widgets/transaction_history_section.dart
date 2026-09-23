import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/transaction_record.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/info_dot.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/info_hints_l10n.dart';

/// Sezione storico transazioni (componente isolato).
///
/// // PERCHÉ: estratta in un widget dedicato per non gonfiare
/// `wallet_detail_screen.dart` e per essere testabile in isolamento.
/// Stati gestiti: loading, errore (con retry), vuoto, lista.
class TransactionHistorySection extends StatefulWidget {
  const TransactionHistorySection({
    super.key,
    required this.transactions,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.isBumpable,
    this.onBumpFee,
    this.noteFor,
    this.onSetNote,
    this.onExport,
  });

  final List<TransactionRecord> transactions;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  /// True se la tx è "bumpabile" (RBF, S8/C): pending outgoing nostra con
  /// parametri di sessione. Predicato fornito dal detail (dove vive la
  /// logica di business), così questa sezione resta dumb e testabile.
  final bool Function(TransactionRecord tx)? isBumpable;

  /// Esegue il flusso "Aumenta fee" per la tx (auth + scelta fee + bump).
  /// Invocato DOPO la chiusura del dialog di dettaglio.
  final Future<void> Function(TransactionRecord tx)? onBumpFee;

  /// Nota utente della tx (`null` se assente). Predicato del chiamante.
  /// // PERCHÉ: le note vivono nel `WalletRecord` (persistite col wallet), non
  /// in questa sezione — che resta dumb e testabile in isolamento.
  final String? Function(TransactionRecord tx)? noteFor;

  /// Salva la nota della tx (stringa vuota = rimuovi).
  /// // PERCHÉ: nullable → chiamanti e test che non gestiscono note usano la
  /// sezione esattamente come prima (zero breaking).
  final Future<void> Function(TransactionRecord tx, String note)? onSetNote;

  /// Esporta lo storico (CSV/JSON). Assente → l'azione non è offerta.
  /// // PERCHÉ: la formattazione e la consegna vivono nel chiamante: questa
  /// sezione resta dumb (nessun accesso a clipboard/file).
  final VoidCallback? onExport;

  @override
  State<TransactionHistorySection> createState() =>
      _TransactionHistorySectionState();
}

class _TransactionHistorySectionState extends State<TransactionHistorySection> {
  // Chiuso di default: con molti elementi il dettaglio resta compatto e
  // l'utente espande lo storico solo quando gli serve.
  bool _expanded = false;

  static String _formatBtc(int sats) =>
      '${(sats / 100000000).toStringAsFixed(8)} BTC';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return GlassContainer(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc.walletDetailTransactions,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    // PERCHÉ: l'export si offre solo quando c'è qualcosa da
                    // esportare e non c'è un caricamento/errore in corso.
                    if (widget.onExport != null &&
                        !widget.isLoading &&
                        widget.error == null &&
                        widget.transactions.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: widget.onExport,
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: Text(loc.walletDetailTxExport),
                        ),
                      ),
                    if (widget.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (widget.error != null)
                      _buildError(context, loc)
                    else if (widget.transactions.isEmpty)
                      _buildEmpty(context, loc)
                    else
                      ...widget.transactions
                          .map((tx) => _buildRow(context, tx)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text(
            loc.walletDetailTxError,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(loc.walletDetailTxRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.walletDetailTxEmpty,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, TransactionRecord tx) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isIncoming = tx.direction == TxDirection.incoming;
    // // PERCHÉ: verde per entrate, arancione brand per uscite — codifica
    // cromatica coerente con gli SnackBar di successo/errore dell'app.
    final color = isIncoming ? Colors.green : theme.colorScheme.primary;
    final sign = isIncoming ? '+' : '-';
    final label =
        isIncoming ? loc.walletDetailTxIncoming : loc.walletDetailTxOutgoing;
    final date = tx.timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(tx.timestamp!)
        : '';
    final note = widget.noteFor?.call(tx);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // // PERCHÉ: il ListTile deve avere un Material ancestore, altrimenti
      // Flutter segnala "background color or ink splashes may be invisible"
      // (GlassContainer è un DecoratedBox con colore).
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
              color: color,
              size: 20,
            ),
          ),
          title: Text(
            '$label · $sign${_formatBtc(tx.amountSats)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          // PERCHÉ: la nota utente si aggiunge alla data — è l'informazione con
          // cui l'utente riconosce la transazione, quindi resta sul tile senza
          // dover aprire il dettaglio.
          subtitle: (date.isEmpty && note == null)
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (date.isNotEmpty)
                      Text(date, style: const TextStyle(fontSize: 13)),
                    if (note != null)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
          // PERCHÉ (audit P1-c): la tx espulsa/sostituita (nostra outgoing non
          // più nel mempool) ha precedenza — non è "in attesa" né orfana.
          trailing: tx.isEvicted
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.remove_circle_outline,
                        size: 12,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        loc.walletDetailTxReplaced,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : tx.isOrphan
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            loc.walletDetailTxOrphan,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : tx.isPending
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            loc.walletDetailTxPending,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
          onTap: () => _showDetails(context, tx),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, TransactionRecord tx) {
    final loc = AppLocalizations.of(context);
    final note = widget.noteFor?.call(tx);
    final isIncoming = tx.direction == TxDirection.incoming;
    final sign = isIncoming ? '+' : '-';
    final date = tx.timestamp != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(tx.timestamp!)
        : tx.isEvicted
            ? loc.walletDetailTxReplaced
            : tx.isOrphan
                ? loc.walletDetailTxOrphan
                : loc.walletDetailTxPending;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text(loc.walletDetailTxDetails),
            const InfoDot(id: InfoHintId.bumpFee),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(
                ctx,
                isIncoming
                    ? loc.walletDetailTxIncoming
                    : loc.walletDetailTxOutgoing,
                '$sign${_formatBtc(tx.amountSats)}',
              ),
              _detailRow(ctx, loc.walletDetailTxDate, date),
              if (tx.feeSats != null)
                _detailRow(ctx, loc.walletDetailTxFee, '${tx.feeSats} sat'),
              _detailRow(
                ctx,
                loc.walletDetailTxConfirmations,
                tx.isEvicted
                    ? loc.walletDetailTxReplaced
                    : tx.isOrphan
                        ? loc.walletDetailTxOrphan
                        : tx.isPending
                            ? loc.walletDetailTxPending
                            : '${tx.confirmations}',
              ),
              if (tx.blockHeight != null)
                _detailRow(
                  ctx,
                  loc.walletDetailTxBlockHeight,
                  '${tx.blockHeight}',
                ),
              // PERCHÉ: la nota è un dato dell'utente, non della chain — la
              // mostro anche quando è vuota ("—"), così la matita ha sempre un
              // punto di riferimento nel dettaglio.
              _detailRow(ctx, loc.walletDetailTxNote, note ?? '—'),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                'TXID',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                tx.txid,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          // PERCHÉ: un solo dialog alla volta — come per il bump, la matita
          // chiude il dettaglio e apre l'editor della nota.
          if (widget.onSetNote != null)
            IconButton(
              tooltip: note == null
                  ? loc.walletDetailTxNoteAdd
                  : loc.walletDetailTxNoteEdit,
              icon: const Icon(Icons.edit_note),
              onPressed: () {
                Navigator.pop(ctx);
                _editNote(context, tx);
              },
            ),
          // PERCHÉ (S8/C): l'azione di bump è disponibile SOLO per tx
          // pending nostra con parametri in sessione — il predicato è del
          // chiamante (wallet_detail), qui resta un bottone condizionale.
          if (widget.isBumpable?.call(tx) == true && widget.onBumpFee != null)
            TextButton(
              onPressed: () {
                // // PERCHÉ: chiudo il dettaglio prima di avviare il flusso
                // bump (nuovi dialog), evitando dialog sovrapposti.
                Navigator.pop(ctx);
                widget.onBumpFee!(tx);
              },
              child: Text(loc.walletDetailTxBumpFee),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.walletDetailClose),
          ),
        ],
      ),
    );
  }

  /// Apre l'editor della nota e delega la persistenza al chiamante.
  ///
  /// // PERCHÉ: qui resta solo il flusso di UI — la nota finisce nel
  /// `WalletRecord` attraverso `onSetNote` (il widget resta dumb).
  Future<void> _editNote(BuildContext context, TransactionRecord tx) async {
    final loc = AppLocalizations.of(context);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => _EditTxNoteDialog(
        initialNote: widget.noteFor?.call(tx) ?? '',
        title: loc.walletDetailTxNote,
        hint: loc.walletDetailTxNoteHint,
        saveLabel: loc.walletDetailSave,
        removeLabel: loc.walletDetailTxNoteRemove,
        cancelLabel: loc.walletDetailClose,
      ),
    );
    if (value == null) return;
    debugPrint(
      '[LoopEngineer] nota tx ${tx.txid} '
      '${value.trim().isEmpty ? 'da rimuovere' : 'da salvare'}',
    );
    await widget.onSetNote?.call(tx, value);
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor della nota di una transazione.
///
/// // PERCHÉ: widget dedicato (non un dialog inline) perché possiede il
/// `TextEditingController` e lo smaltisce in `dispose()`: il chiamante non deve
/// mai fare `dispose()` dopo `await showDialog()` — il dialog si smonta in modo
/// asincrono e l'assert "_dependents.isEmpty" scatta in faccia all'utente
/// (lezione 2026-09-06).
/// Ritorna la nota (stringa vuota = rimuovi) oppure `null` se annullato.
class _EditTxNoteDialog extends StatefulWidget {
  const _EditTxNoteDialog({
    required this.initialNote,
    required this.title,
    required this.hint,
    required this.saveLabel,
    required this.removeLabel,
    required this.cancelLabel,
  });

  final String initialNote;
  final String title;
  final String hint;
  final String saveLabel;
  final String removeLabel;
  final String cancelLabel;

  @override
  State<_EditTxNoteDialog> createState() => _EditTxNoteDialogState();
}

class _EditTxNoteDialogState extends State<_EditTxNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        minLines: 1,
        maxLines: 3,
        // PERCHÉ: limite esplicito — la nota è persistita nel record del wallet
        // (storage locale), non deve poter crescere senza controllo.
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        // PERCHÉ: "Rimuovi" compare solo se c'è qualcosa da rimuovere.
        if (widget.initialNote.trim().isNotEmpty)
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(widget.removeLabel),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}
