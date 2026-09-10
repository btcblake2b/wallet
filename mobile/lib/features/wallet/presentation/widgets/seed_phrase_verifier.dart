import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Widget riutilizzabile di verifica del backup seed (3 parole casuali).
///
/// Estratto da `BackupSeedScreen` (S3) per essere condiviso con il wallet
/// detail: genera 3 indici casuali, mostra i campi di input, valida le
/// risposte (trim + lowercase) e notifica il successo via [onVerified].
///
/// PERCHÉ: stessa UX della creazione wallet — l'utente dimostra di aver
/// salvato la seed inserendo 3 parole. L'algoritmo di generazione degli
/// indici e le `Key('verify_field_$j')` sono IDENTICI a quelli storici per
/// non rompere i test esistenti (`Random(42)`, E2E).
class SeedPhraseVerifier extends StatefulWidget {
  const SeedPhraseVerifier({
    super.key,
    required this.seed,
    required this.onVerified,
    this.onChanged,
    this.random,
  });

  /// La seed phrase da verificare (12+ parole separate da spazi).
  final String seed;

  /// Chiamato quando le 3 parole richieste sono corrette.
  final VoidCallback onVerified;

  /// Notifica a ogni cambiamento di input (es. reset timer auto-hide).
  final VoidCallback? onChanged;

  /// Random iniettabile per test deterministici.
  final Random? random;

  @override
  State<SeedPhraseVerifier> createState() => _SeedPhraseVerifierState();
}

class _SeedPhraseVerifierState extends State<SeedPhraseVerifier> {
  late final List<int> _verifyIndices;
  final _verifyControllers = List.generate(3, (_) => TextEditingController());
  String? _verifyError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // PERCHÉ: indici casuali fissati UNA volta all'apertura, non rigenerati a
    // ogni rebuild. Default `Random.secure()` (CSPRNG) — audit F8: in un
    // contesto seed un PRNG prevedibile (CWE-338) indebolisce la verifica.
    // I test iniettano un `Random` deterministico per restare stabili.
    final rng = widget.random ?? Random.secure();
    final indices = <int>{};
    while (indices.length < 3) {
      indices.add(rng.nextInt(12));
    }
    _verifyIndices = indices.toList()..sort();
  }

  @override
  void dispose() {
    for (final c in _verifyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _words => widget.seed.trim().split(RegExp(r'\s+')).toList();

  bool _isCorrect(int j) {
    if (_verifyIndices[j] >= _words.length) return false;
    final expected = _words[_verifyIndices[j]].toLowerCase();
    return _verifyControllers[j].text.trim().toLowerCase() == expected;
  }

  void _verify() {
    final loc = AppLocalizations.of(context);
    final words = _words;
    // PERCHÉ: una seed valida ha almeno 12 parole; sotto questa soglia
    // non ha senso confrontare (coerente con BackupSeedScreen storico).
    if (words.length < 12) {
      setState(() {
        _verifyError = loc.backupSeedVerifyError;
        _submitted = true;
      });
      return;
    }
    for (var j = 0; j < 3; j++) {
      final expected = words[_verifyIndices[j]].toLowerCase();
      final actual = _verifyControllers[j].text.trim().toLowerCase();
      if (actual != expected) {
        setState(() {
          _verifyError = loc.backupSeedVerifyError;
          _submitted = true;
        });
        return;
      }
    }
    setState(() {
      _verifyError = null;
      _submitted = false;
    });
    widget.onVerified();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var j = 0; j < 3; j++) ...[
          TextField(
            key: Key('verify_field_$j'),
            controller: _verifyControllers[j],
            decoration: InputDecoration(
              labelText: loc.backupSeedWordLabel(_verifyIndices[j] + 1),
              border: const OutlineInputBorder(),
              // PERCHÉ (UX): feedback visivo per-campo — ✓ quando il campo è
              // corretto, ✗ dopo un submit fallito sui campi errati non vuoti.
              suffixIcon: _isCorrect(j)
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : (_submitted && _verifyControllers[j].text.trim().isNotEmpty
                      ? const Icon(Icons.cancel, color: Colors.red)
                      : null),
            ),
            autocorrect: false,
            textInputAction:
                j < 2 ? TextInputAction.next : TextInputAction.done,
            onChanged: (_) {
              widget.onChanged?.call();
              setState(() {});
            },
            onSubmitted: (_) => j < 2 ? null : _verify(),
          ),
          const SizedBox(height: 12),
        ],
        if (_verifyError != null) ...[
          Text(
            _verifyError!,
            style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _verify,
          icon: const Icon(Icons.verified),
          label: Text(loc.backupSeedVerifyTitle),
        ),
      ],
    );
  }
}
