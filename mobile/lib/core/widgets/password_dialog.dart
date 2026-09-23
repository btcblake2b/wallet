import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PasswordDialog {
  /// Shows a dialog to create a new password (returns password or null).
  static Future<String?> showCreatePasswordDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CreatePasswordDialog(),
    );
  }

  /// Shows a dialog to enter password (returns password or null).
  static Future<String?> showEnterPasswordDialog(
    BuildContext context, {
    String? reason,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EnterPasswordDialog(reason: reason),
    );
  }
}

/// Dialog di creazione password come widget stateful: i controller vanno
/// disposed (audit SEC-09) e i campi disabilitano suggerimenti/memorizzazione
/// della tastiera (nessun autocorrect, nessun learning IME).
class _CreatePasswordDialog extends StatefulWidget {
  const _CreatePasswordDialog();

  @override
  State<_CreatePasswordDialog> createState() => _CreatePasswordDialogState();
}

class _CreatePasswordDialogState extends State<_CreatePasswordDialog> {
  final _pwController = TextEditingController();
  final _pwConfirmController = TextEditingController();

  @override
  void dispose() {
    _pwController.dispose();
    _pwConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.passwordDialogCreateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pwController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            decoration: InputDecoration(
              labelText: loc.passwordDialogCreateHint,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pwConfirmController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            decoration: InputDecoration(
              labelText: loc.passwordDialogCreateConfirm,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(loc.passwordDialogCancel),
        ),
        FilledButton(
          onPressed: () {
            final pw = _pwController.text;
            final pw2 = _pwConfirmController.text;
            // PERCHÉ (audit F5): min 8 caratteri, allineato alla policy.
            if (pw.isEmpty || pw.length < 8) return;
            if (pw != pw2) return;
            Navigator.of(context).pop(pw);
          },
          child: Text(loc.passwordDialogCreate),
        ),
      ],
    );
  }
}

/// Dialog di inserimento password come widget stateful (dispose del
/// controller e hardening tastiera — audit SEC-09).
class _EnterPasswordDialog extends StatefulWidget {
  const _EnterPasswordDialog({this.reason});

  final String? reason;

  @override
  State<_EnterPasswordDialog> createState() => _EnterPasswordDialogState();
}

class _EnterPasswordDialogState extends State<_EnterPasswordDialog> {
  final _pwController = TextEditingController();

  @override
  void dispose() {
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.reason ?? loc.passwordDialogEnterTitle),
      content: TextField(
        controller: _pwController,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        decoration: InputDecoration(labelText: loc.passwordDialogEnterHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(loc.passwordDialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_pwController.text),
          child: Text(loc.passwordDialogEnter),
        ),
      ],
    );
  }
}
