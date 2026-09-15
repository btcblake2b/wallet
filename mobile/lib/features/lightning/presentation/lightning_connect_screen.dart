import 'package:flutter/material.dart';

import '../../../core/models/lightning_connection.dart';
import '../../../core/services/lightning/lightning_connection_store.dart';
import '../../../core/services/lightning/lightning_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_background.dart';
import '../../../l10n/app_localizations.dart';

/// Connessione a un nodo Lightning: incolla la stringa NIP-47 e connetti.
class LightningConnectScreen extends StatefulWidget {
  const LightningConnectScreen({
    super.key,
    required this.lightningService,
    required this.connectionStore,
  });

  final LightningService lightningService;
  final LightningConnectionStore connectionStore;

  @override
  State<LightningConnectScreen> createState() => _LightningConnectScreenState();
}

class _LightningConnectScreenState extends State<LightningConnectScreen> {
  final TextEditingController _uriController = TextEditingController();
  bool _connecting = false;
  bool _invalidUri = false;

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() {
      _connecting = true;
      _invalidUri = false;
    });

    LightningConnection connection;
    try {
      connection = LightningConnection.fromUri(_uriController.text);
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _invalidUri = true;
      });
      return;
    }

    try {
      await widget.lightningService.connect(connection);
      // PERCHÉ: la URI contiene il secret di sessione → solo secure storage.
      await widget.connectionStore.save(connection);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on LightningException catch (e) {
      if (!mounted) return;
      setState(() => _connecting = false);
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.lightningErrorGeneric(e.message))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AppBackground(
      accent: AppTheme.lightningAccent,
      child: Scaffold(
        appBar: AppBar(title: Text(loc.lightningConnectTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(loc.lightningConnectHint),
            const SizedBox(height: 12),
            TextField(
              controller: _uriController,
              maxLines: 3,
              minLines: 3,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'nostr+walletconnect://…',
                errorText: _invalidUri ? loc.lightningConnectInvalidUri : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              loc.lightningConnectInfo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _connecting ? null : _connect,
              icon: _connecting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(loc.lightningConnectButton),
            ),
          ],
        ),
      ),
    );
  }
}
