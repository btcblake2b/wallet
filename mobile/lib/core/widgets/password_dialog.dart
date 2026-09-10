import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class PasswordDialog {
  /// Shows a dialog to create a new password (returns password or null).
  static Future<String?> showCreatePasswordDialog(BuildContext context) {
    final pwController = TextEditingController();
    final pwConfirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc.passwordDialogCreateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pwController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: loc.passwordDialogCreateHint),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pwConfirmController,
                obscureText: true,
                decoration:
                    InputDecoration(labelText: loc.passwordDialogCreateConfirm),
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
                final pw = pwController.text;
                final pw2 = pwConfirmController.text;
                // PERCHÉ (audit F5): min 8 caratteri, allineato alla policy.
                if (pw.isEmpty || pw.length < 8) return;
                if (pw != pw2) return;
                Navigator.of(context).pop(pw);
              },
              child: Text(loc.passwordDialogCreate),
            ),
          ],
        );
      },
    );
  }

  /// Shows a dialog to enter password (returns password or null).
  static Future<String?> showEnterPasswordDialog(
    BuildContext context, {
    String? reason,
  }) {
    final pwController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(reason ?? loc.passwordDialogEnterTitle),
          content: TextField(
            controller: pwController,
            obscureText: true,
            decoration: InputDecoration(labelText: loc.passwordDialogEnterHint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(loc.passwordDialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(pwController.text),
              child: Text(loc.passwordDialogEnter),
            ),
          ],
        );
      },
    );
  }
}
