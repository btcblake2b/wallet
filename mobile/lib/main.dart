import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/locale_provider.dart';
import 'core/services/security_service.dart';
import 'core/services/theme_provider.dart';

/// Minimal fallback UI shown when [BtcBlake2bWalletApp.bootstrap]
/// throws — e.g. quando un service non riesce a inizializzarsi.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0b0f19),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  "Impossibile avviare l'app",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error'.replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFf7931a),
                    foregroundColor: const Color(0xFF0b0f19),
                  ),
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ricarica la pagina'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PERCHÉ: fork blake2b senza backend Firebase e senza telemetria Sentry →
  // bootstrap sincrono semplice. La sicurezza del device resta invariata.
  late final AppServices services;
  try {
    services = await BtcBlake2bWalletApp.bootstrap();
  } catch (e, st) {
    if (kDebugMode) debugPrint('bootstrap failed: $e\n$st');
    runApp(_BootstrapErrorApp(error: e));
    return;
  }

  // Error handler: stampa in console.
  FlutterError.onError = (errorDetails) {
    debugPrint(
      '[FlutterError] ${errorDetails.exception}\n${errorDetails.stack}',
    );
    FlutterError.presentError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] $error\n$stack');
    return false;
  };

  // Blocca l'app se il dispositivo è rooted/jailbroken
  if (!await SecurityService().enforceDeviceSecurity()) {
    return; // Non raggiungibile, ma per sicurezza
  }

  // PERCHÉ (integrità): in release verifica che l'APK sia firmato con il
  // certificato atteso (APP_SIGNATURE in .env). Fail-closed: se la firma non
  // corrisponde o c'è un errore, l'app non parte. In debug il check è
  // skippato (stampa solo la firma corrente per la configurazione).
  if (!await SecurityService().verifyIntegrity()) {
    debugPrint('SECURITY: Integrity check FAILED — avvio app bloccato');
    return; // Fail-closed
  }

  // PERCHÉ (audit A6): attiva la protezione screenshot globale (release
  // native). Le singole schermate seed la integrano, ma la base copre tutta
  // l'app (saldi, invio, import).
  await SecurityService().init();

  // Initialize UI providers (locale + tema) con la preferenza persistita.
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  await BtcBlake2bWalletApp.initProviders(
    localeProvider: localeProvider,
    themeProvider: themeProvider,
  );

  runApp(
    BtcBlake2bWalletApp(
      services: services,
      localeProvider: localeProvider,
      themeProvider: themeProvider,
    ),
  );
}
