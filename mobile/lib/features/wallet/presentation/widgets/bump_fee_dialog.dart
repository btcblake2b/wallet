// FLOW: Aumento Fee RBF (BIP125)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/bitcoin_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Dialog di scelta della nuova fee per il bump (RBF, S8/C).
///
/// // PERCHÉ: estratto in un widget dedicato per non gonfiare
/// `wallet_detail_screen.dart` e per essere testabile in isolamento, come
/// `TransactionHistorySection`. Mostra SOLO le opzioni raccomandate valide
/// (sat/vB > fee originale) più l'opzione Custom: `bumpFee` rifiuta con
/// [ArgumentError] una fee non maggiore dell'originale, quindi la UI
/// previene l'errore a monte.
///
/// Ritorna la nuova fee scelta in sat/vB, oppure `null` se annullato.
Future<int?> showBumpFeeDialog(
  BuildContext context, {
  required int originalFeeRateSatVb,
  FeeEstimates? estimates,
}) {
  return showDialog<int>(
    context: context,
    builder: (ctx) => _BumpFeeDialog(
      originalFeeRateSatVb: originalFeeRateSatVb,
      estimates: estimates,
    ),
  );
}

class _BumpFeeDialog extends StatefulWidget {
  const _BumpFeeDialog({
    required this.originalFeeRateSatVb,
    required this.estimates,
  });

  final int originalFeeRateSatVb;
  final FeeEstimates? estimates;

  @override
  State<_BumpFeeDialog> createState() => _BumpFeeDialogState();
}

class _BumpFeeDialogState extends State<_BumpFeeDialog> {
  // Indice dell'opzione selezionata in [_options] (0 = Custom quando non
  // ci sono raccomandate valide); inizializza alla prima raccomandata valida.
  late int _choice;
  final _customCtrl = TextEditingController();
  String? _customError;

  /// Opzioni raccomandate valide (sat/vB > fee originale).
  List<int> get _validRates {
    final e = widget.estimates;
    if (e == null) return const [];
    return [
      e.lowSatVb,
      e.normalSatVb,
      e.highSatVb,
    ].where((r) => r > widget.originalFeeRateSatVb).toList();
  }

  @override
  void initState() {
    super.initState();
    // // PERCHÉ: se esistono raccomandate valide la più prudente è la più
    // bassa tra quelle > originale (normal o high a seconda del mempool).
    final rates = _validRates;
    _choice = rates.isEmpty ? 0 : 0;
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  /// Restituisce la fee selezionata, o null se la selezione è incompleta
  /// (custom vuoto/non valido) — in tal caso mostra l'errore inline.
  int? _resolveChoice() {
    final rates = _validRates;
    final isCustom = _choice == rates.length;
    if (!isCustom) return rates[_choice];
    final raw = _customCtrl.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= widget.originalFeeRateSatVb) {
      setState(() => _customError = 'err');
      return null;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rates = _validRates;
    // Indice "custom": dopo tutte le raccomandate valide.
    final customIndex = rates.length;
    final selectedCustom = _choice == customIndex;

    return AlertDialog(
      title: Text(loc.walletDetailBumpFeeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.walletDetailBumpFeeCurrent(widget.originalFeeRateSatVb),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            // PERCHÉ: avviso esplicito di doppia spesa accidentale — se il
            // replacement viene minato la tx originale non confermerà mai.
            Text(
              loc.walletDetailBumpFeeWarning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.estimates == null) ...[
              Text(
                loc.walletDetailBumpFeeUnavailable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ] else if (rates.isEmpty) ...[
              // // PERCHÉ: tutte le raccomandate ≤ originale (mempool sceso):
              // l'utente deve poter inserire un valore custom più alto.
              Text(
                loc.walletDetailBumpFeeUnavailable,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            RadioGroup<int>(
              groupValue: _choice,
              onChanged: (v) => setState(() => _choice = v ?? _choice),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < rates.length; i++)
                    RadioListTile<int>(
                      value: i,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_rateLabel(loc, rates[i])),
                      subtitle: Text('${rates[i]} sat/vB'),
                    ),
                  RadioListTile<int>(
                    value: customIndex,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(loc.sendScreenFeeCustom),
                  ),
                ],
              ),
            ),
            if (selectedCustom) ...[
              const SizedBox(height: 4),
              TextField(
                controller: _customCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: loc.sendScreenFeeCustomHint,
                  suffixText: 'sat/vB',
                  errorText: _customError != null
                      ? loc.walletDetailBumpFeeErrorFee
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.walletDetailClose),
        ),
        FilledButton(
          onPressed: () {
            final fee = _resolveChoice();
            if (fee != null) Navigator.pop(context, fee);
          },
          child: Text(loc.walletDetailTxBumpFee),
        ),
      ],
    );
  }

  String _rateLabel(AppLocalizations loc, int rate) {
    // // PERCHÉ: associa il valore raccomandato all'etichetta di provenienza
    // (low/normal/high) confrontando con le stime originali.
    final e = widget.estimates!;
    if (rate == e.highSatVb) return loc.sendScreenFeeHigh;
    if (rate == e.normalSatVb) return loc.sendScreenFeeNormal;
    return loc.sendScreenFeeLow;
  }
}
