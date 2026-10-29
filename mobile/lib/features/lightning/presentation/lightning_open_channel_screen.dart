import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/lightning_utxo.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lightning_peer_utils.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/info_dot.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/info_hints_l10n.dart';

/// Apertura di un canale Lightning verso un peer del nodo remoto (NCC).
class LightningOpenChannelScreen extends StatefulWidget {
  const LightningOpenChannelScreen({super.key, required this.lightningService});

  final LightningService lightningService;

  @override
  State<LightningOpenChannelScreen> createState() =>
      _LightningOpenChannelScreenState();
}

class _LightningOpenChannelScreenState
    extends State<LightningOpenChannelScreen> {
  final TextEditingController _nodeIdController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isPrivate = false;
  bool _opening = false;
  bool _invalid = false;

  // ── Coin control opzionale (A8) ─────────────────────────────
  // PERCHÉ: parità con i tool degli operatori (ThunderHub XBT) — si sceglie
  // quali output on-chain finanziano il canale. `null` = non ancora caricati.
  List<LightningUtxo>? _utxos;
  bool _loadingUtxos = false;
  bool _utxosFailed = false;
  /// Outpoint `txid:vout` scelti dall'utente.
  final Set<String> _selected = <String>{};

  String _outpoint(LightningUtxo u) => '${u.txid}:${u.vout}';

  int get _selectedSats => (_utxos ?? const <LightningUtxo>[])
      .where((u) => _selected.contains(_outpoint(u)))
      .fold<int>(0, (sum, u) => sum + u.amountSats);

  /// Carica gli output on-chain del nodo alla prima espansione della sezione.
  ///
  /// // PERCHÉ: il coin control è opzionale — chi non lo usa non paga una
  /// chiamata di rete, e un errore qui NON deve impedire l'apertura del canale
  /// (si ricade sulla scelta automatica del nodo, con un avviso).
  Future<void> _loadUtxos() async {
    setState(() {
      _loadingUtxos = true;
      _utxosFailed = false;
    });
    try {
      final list = await widget.lightningService.listUtxos();
      if (!mounted) return;
      setState(() => _utxos = list);
    } catch (e) {
      if (!mounted) return;
      debugPrint('[LoopEngineer] coin control: listUtxos fallita → $e');
      setState(() => _utxosFailed = true);
    } finally {
      if (mounted) setState(() => _loadingUtxos = false);
    }
  }

  @override
  void dispose() {
    _nodeIdController.dispose();
    _hostController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final loc = AppLocalizations.of(context);
    // PERCHÉ: dagli explorer/chat si copia la stringa compatta
    // `pubkey@host:port`: la separiamo nei due campi richiesti dal nodo.
    final parsed = parseNodeConnectionString(_nodeIdController.text);
    final nodeId = parsed.nodeId;
    var host = _hostController.text.trim();
    if (host.isEmpty && parsed.host != null) {
      host = parsed.host!;
      _hostController.text = host;
    }
    final sats = int.tryParse(_amountController.text.trim());
    // PERCHÉ: il nodo richiede una pubkey valida (66 hex = 33 byte compressi),
    // un host nella forma host:porta (se presente) e un importo > 0.
    final validNodeId = isValidLightningNodeId(nodeId);
    final validHost = host.isEmpty || isValidPeerHost(host);
    if (!validNodeId || !validHost || sats == null || sats <= 0) {
      setState(() => _invalid = true);
      return;
    }

    setState(() {
      _opening = true;
      _invalid = false;
    });
    try {
      await widget.lightningService.openChannel(
        nodeId: nodeId,
        amountSats: sats,
        host: host,
        isPrivate: _isPrivate,
        // PERCHÉ (A8): se l'utente ha scelto degli output si finanzia il canale
        // con quelli; lista vuota = il nodo sceglie da sé (comportamento
        // storico, invariato per chi non apre la sezione).
        utxos: _selected.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningChannelOpened)),
      );
      Navigator.of(context).pop(true);
    } on LightningException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.isPermissionDenied
                ? loc.lightningErrorRestricted
                : loc.lightningErrorGeneric(e.message),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningOpenChannel)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nodeIdController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.lightningOpenChannelNodeId,
                helperText: loc.lightningOpenChannelHint,
                errorText: _invalid ? loc.lightningOpenChannelInvalid : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.lightningOpenChannelHost,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: loc.lightningOpenChannelAmount,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
              title: Row(
                children: [
                  Text(loc.lightningOpenChannelPrivate),
                  const InfoDot(id: InfoHintId.openChannelPrivate),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // PERCHÉ (A8): coin control opzionale. Gli output non confermati o
            // riservati dal nodo non sono selezionabili (un canale non può
            // essere finanziato da un output non ancora spendibile).
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(loc.lightningCoinControlTitle),
              subtitle: Text(
                _selected.isEmpty
                    ? loc.lightningCoinControlNoneSelected
                    : '${loc.lightningCoinControlSelectedTotal}: '
                        '$_selectedSats sat',
              ),
              onExpansionChanged: (open) async {
                if (open && _utxos == null && !_loadingUtxos) {
                  await _loadUtxos();
                }
              },
              children: [
                Text(
                  loc.lightningCoinControlHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_loadingUtxos)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (_utxosFailed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(loc.lightningCoinControlUnavailable),
                  )
                else
                  for (final u in _utxos ?? const <LightningUtxo>[])
                    CheckboxListTile(
                      dense: true,
                      value: _selected.contains(_outpoint(u)),
                      onChanged: u.isConfirmed && !u.reserved
                          ? (checked) => setState(() {
                                final key = _outpoint(u);
                                if (checked ?? false) {
                                  _selected.add(key);
                                } else {
                                  _selected.remove(key);
                                }
                              })
                          : null,
                      title: Text('${u.amountSats} sat'),
                      subtitle: Text(
                        u.isConfirmed
                            ? u.shortTxid
                            : '${u.shortTxid} · '
                                '${loc.lightningCoinControlUnconfirmed}',
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _opening ? null : _open,
              icon: _opening
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_link),
              label: Text(loc.lightningOpenChannel),
            ),
          ],
        ),
      ),
    );
  }
}
