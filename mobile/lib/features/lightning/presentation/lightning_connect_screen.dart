import 'dart:async';

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

  /// Nodi usati di recente (più recente per primo) — menu a tendina.
  List<LightningConnection> _history = const [];

  /// Voce selezionata nel menu (deve esistere tra le voci, altrimenti Flutter
  /// solleva un'asserzione).
  String? _selectedUri;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

  /// Carica lo storico dei nodi dal secure storage (best-effort).
  Future<void> _loadHistory() async {
    final history = await widget.connectionStore.history();
    if (!mounted) return;
    setState(() {
      _history = history;
      if (history.isEmpty) return;
      final uris = <String>[for (final c in history) c.toUri()];
      final typed = _uriController.text.trim();
      if (typed.isEmpty) {
        // PERCHÉ: chi riapre questa schermata vuole quasi sempre tornare
        // all'ultimo nodo → campo già compilato e voce selezionata, un tocco
        // solo per ricollegarsi.
        _selectedUri = uris.first;
        _uriController.text = uris.first;
      } else {
        // La selezione deve puntare a una voce esistente: un valore fuori
        // lista farebbe scattare un'asserzione di Flutter.
        _selectedUri = uris.contains(typed) ? typed : null;
      }
    });
  }

  /// Etichetta compatta per il menu: Lightning Address (se c'è) o pubkey
  /// abbreviata.
  ///
  /// // PERCHÉ mai il secret: è un segreto di sessione, non un'etichetta.
  String _historyLabel(LightningConnection connection) {
    final short = connection.walletPubkey.length > 12
        ? '${connection.walletPubkey.substring(0, 12)}…'
        : connection.walletPubkey;
    final lud16 = connection.lud16;
    return (lud16 != null && lud16.isNotEmpty) ? '$lud16 · $short' : short;
  }

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

    // PERCHÉ: il nodo entra nello storico appena l'URI è valida, NON solo a
    // collegamento riuscito — così un nodo offline (o un'app chiusa durante
    // l'handshake) resta nel menu a tendina e il tentativo successivo è un
    // solo tocco, senza dover conservare a mano la stringa NIP-47.
    await widget.connectionStore.remember(connection);

    try {
      await widget.lightningService.connect(connection);
      // PERCHÉ: la URI contiene il secret di sessione → solo secure storage.
      await widget.connectionStore.save(connection);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on LightningException catch (e) {
      if (!mounted) return;
      setState(() => _connecting = false);
      // Il nodo è già nello storico: ricarico per far comparire il menu subito.
      unawaited(_loadHistory());
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
            // PERCHÉ (18/09/2026): menu a tendina coi nodi già usati — riproporre
            // un nodo noto evita di dover conservare a mano la stringa NIP-47.
            if (_history.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedUri,
                decoration: InputDecoration(
                  labelText: loc.lightningConnectRecentNodes,
                ),
                items: [
                  for (final connection in _history)
                    DropdownMenuItem(
                      value: connection.toUri(),
                      child: Text(
                        _historyLabel(connection),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
                onChanged: _connecting
                    ? null
                    : (uri) {
                        if (uri == null) return;
                        setState(() {
                          _selectedUri = uri;
                          _uriController.text = uri;
                        });
                      },
              ),
              const SizedBox(height: 12),
            ],
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
