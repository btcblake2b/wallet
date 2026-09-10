import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../config/env.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  /// Istanza di test ISOLATA (non il singleton) con comportamento reale
  /// iniettabile.
  ///
  /// PERCHÉ (audit P1-2): nei test `kDebugMode` è sempre `true`, quindi i rami
  /// più critici (integrità fail-closed, reference counting di protectScreen,
  /// kill) sarebbero irraggiungibili. Questo costruttore (pattern già accettato
  /// nel progetto: `BalanceCache.resetForTest`) li rende testabili senza mai
  /// chiamare i plugin nativi. Il singleton di produzione non è toccato.
  @visibleForTesting
  SecurityService.test({
    bool emulateNative = false,
    Future<String> Function()? getSignature,
    Future<bool> Function()? isJailbroken,
    Future<void> Function()? screenshotOn,
    Future<void> Function()? screenshotOff,
    void Function()? onForceKill,
  }) {
    _emulateNative = emulateNative;
    _testing = true;
    _getSignatureOverride = getSignature;
    _isJailbrokenOverride = isJailbroken;
    _screenshotOnOverride = screenshotOn;
    _screenshotOffOverride = screenshotOff;
    _forceKillOverride = onForceKill;
  }

  /// True quando il runtime è un device nativo in release (o un test che lo
  /// emula con [SecurityService.test]). Default identico al comportamento
  /// originale: `!kIsWeb && !kDebugMode`.
  bool _emulateNative = false;

  /// True solo sulle istanze create da [SecurityService.test]: inibisce
  /// `exit()` in [enforceDeviceSecurity] (mai uscire dal processo nei test).
  bool _testing = false;

  Future<String> Function()? _getSignatureOverride;
  Future<bool> Function()? _isJailbrokenOverride;
  Future<void> Function()? _screenshotOnOverride;
  Future<void> Function()? _screenshotOffOverride;
  void Function()? _forceKillOverride;

  bool get _isNative => _emulateNative || (!kIsWeb && !kDebugMode);

  /// Protezione globale attiva all'avvio: non viene MAI disattivata dalle
  /// singole schermate (vedi [protectScreen]).
  bool _globalProtection = false;

  /// Contatore delle schermate protette: con route annidate (detail → send)
  /// la protezione resta attiva finché l'ultima schermata protetta si chiude.
  int _protectCount = 0;

  Future<void> init() async {
    if (_globalProtection) return;
    _globalProtection = true;
    if (!_isNative) return;
    // PERCHÉ (audit A6): attiva FLAG_SECURE per l'intera app (release native).
    await (_screenshotOnOverride ?? ScreenProtector.preventScreenshotOn)();
  }

  Future<bool> isDeviceSecure() async {
    if (!_isNative) return true; // Web/debug non ha jailbreak/root

    bool jailbroken =
        await (_isJailbrokenOverride ??
            () => FlutterJailbreakDetection.jailbroken)();
    // In a strict wallet, we might want to block developer mode too
    // bool developerMode = await FlutterJailbreakDetection.developerMode;

    return !jailbroken;
  }

  /// Verifica la sicurezza del dispositivo e, se non sicuro, mostra
  /// un dialog non dismissable e forza la chiusura dell'app.
  /// Restituisce `true` se il dispositivo è sicuro (l'app può continuare).
  /// Se `false`, il metodo NON ritorna mai — termina l'app.
  Future<bool> enforceDeviceSecurity({BuildContext? context}) async {
    final isSecure = await isDeviceSecure();
    if (isSecure) return true;

    // Blocco totale: mostra dialog e poi forza chiusura
    if (context != null && context.mounted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.security, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text('Dispositivo non sicuro'),
              ],
            ),
            content: const Text(
              'È stato rilevato un dispositivo rooted o jailbroken.\n\n'
              'Per proteggere i tuoi fondi Bitcoin, questa app non può '
              'funzionare su dispositivi compromessi.\n\n'
              'Motivi di sicurezza:\n'
              '• La seed phrase potrebbe essere rubata\n'
              '• Le chiavi private potrebbero essere intercettate\n'
              '• La crittografia potrebbe essere bypassata',
            ),
            actions: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _forceKill();
                },
                icon: const Icon(Icons.close),
                label: const Text('Esci'),
              ),
            ],
          ),
        ),
      );
    }

    _forceKill();
    // Non ritorna mai — ma per sicurezza:
    return false;
  }

  void _forceKill() {
    if (!_isNative) return;
    // PERCHÉ (test): mai `exit()` in un test — l'override registra l'evento.
    if (_testing) {
      _forceKillOverride?.call();
      return;
    }
    try {
      exit(1);
    } catch (_) {
      // Last resort
      // ignore: deprecated_member_use
      exit(1);
    }
  }

  /// Confronto puro firme attese vs corrente (estratto per testabilità).
  ///
  /// PERCHÉ (audit R2/F5): la decisione di integrità non dipende né dalla
  /// piattaforma né da `Env` — riceve i valori come input e restituisce l'esito:
  /// - lista configurata vuota ⇒ NON verificabile ⇒ `false` (fail-closed);
  /// - match case-insensitive (Android può variare) ⇒ `true`;
  /// - lista multi-firma (csv) ⇒ `true` se ALMENO una corrisponde;
  /// - nessun match ⇒ `false`.
  ///
  /// PERCHÉ (fix v0.1.1): il confronto è insensibile ai separatori di formato
  /// (`31:F8:8D:…` da keytool/.env, `31F88D…` da package_info_plus Android,
  /// `31-F8-8D-…` stile Apple): entrambi i lati vengono normalizzati. Senza
  /// questo, l'APK release non avviava: firma attesa con ":" vs firma runtime
  /// senza separator ⇒ mismatch ⇒ fail-closed (splash con logo su schermo nero).
  @visibleForTesting
  static bool evaluateIntegrity({
    required String currentSignature,
    required String configuredSignatures,
  }) {
    if (configuredSignatures.isEmpty) return false;
    final expectedSignatures = configuredSignatures
        .split(',')
        .map(_normalizeSignature)
        .where((s) => s.isNotEmpty)
        .toList();
    // PERCHÉ (fail-closed): se dopo la normalizzazione non resta alcuna firma
    // attesa (es. config = "," o soli spazi) NON è verificabile ⇒ false.
    if (expectedSignatures.isEmpty) return false;

    final current = _normalizeSignature(currentSignature);
    for (final expected in expectedSignatures) {
      if (current == expected) {
        return true;
      }
    }
    return false;
  }

  /// Normalizza una firma per il confronto: minuscolo e senza separatori
  /// (`:`, `-`, spazi). Il confronto resta esatto sui 64 nibble dello SHA-256.
  static String _normalizeSignature(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s:-]'), '');

  /// Checks the application integrity by comparing the build signature.
  /// In debug mode, prints the current signature so you can add it to .env.
  Future<bool> verifyIntegrity() async {
    if (!_isNative) {
      if (!kIsWeb && kDebugMode) {
        // In debug: stampa la firma attuale per facilitare la configurazione
        try {
          final sig = await getAppSignature();
          debugPrint('SECURITY: Current build signature: $sig');
          debugPrint('SECURITY: Add this to .env as APP_SIGNATURE=$sig');
        } catch (_) {}
      }
      return true;
    }

    if (Env.appSignature.isEmpty) {
      // PERCHÉ (audit R2/F5): fail-closed in release — senza APP_SIGNATURE un
      // APK ripacchettato/firmato con chiave diversa non sarebbe rilevabile.
      // Configurare la firma dal log di una build debug ("Add this to .env as
      // APP_SIGNATURE=…").
      debugPrint(
        'SECURITY: APP_SIGNATURE non configurata — integrità non verificabile, '
        'avvio bloccato (fail-closed).',
      );
      return false;
    }

    try {
      final currentSignature =
          await (_getSignatureOverride ?? getAppSignature)();
      final integrityOk = evaluateIntegrity(
        currentSignature: currentSignature,
        configuredSignatures: Env.appSignature,
      );
      if (!integrityOk) {
        // PERCHÉ (diagnosi v0.1.1): un mismatch in release si manifesta solo
        // con l'app che non parte; questo log rende immediata la causa.
        // Le firme sono dati pubblici (incorporate nell'APK stesso).
        debugPrint(
          'SECURITY: signature mismatch — corrente=[$currentSignature] '
          'attesa=[${Env.appSignature}]',
        );
      }
      return integrityOk;
    } catch (e) {
      if (kDebugMode) debugPrint('SECURITY: Integrity check error: $e');
      // In caso di errore, meglio bloccare (fail-secure)
      return false;
    }
  }

  Future<String> getAppSignature() async {
    if (kIsWeb) return 'web-signature';
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.buildSignature;
  }

  Future<void> protectScreen(bool protect) async {
    if (!_isNative) return;
    if (protect) {
      _protectCount++;
      if (_protectCount == 1) {
        await (_screenshotOnOverride ?? ScreenProtector.preventScreenshotOn)();
      }
    } else {
      if (_protectCount > 0) _protectCount--;
      // PERCHÉ (audit A6): se la protezione globale è attiva non si spegne
      // mai; altrimenti si disattiva solo quando si chiude l'ultima schermata
      // protetta (evita di togliere FLAG_SECURE a una route sottostante).
      if (_protectCount == 0 && !_globalProtection) {
        await (_screenshotOffOverride ?? ScreenProtector.preventScreenshotOff)();
      }
    }
  }
}
