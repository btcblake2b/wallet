import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
