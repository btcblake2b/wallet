// PERCHÉ (C003+C008): Servizio di persistenza per i dati di onboarding.
// Usa flutter_secure_storage per garantire che i dati di residenza fiscale
// e le preferenze legali restino sul dispositivo e non vengano mai
// trasmessi al server (zero-knowledge by design).
//
// Pattern coerente con _disclaimerAccepted in home_screen.dart.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/onboarding_data.dart';

class OnboardingService {
  OnboardingService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _completedKey = 'onboarding_completed';
  static const _dataKey = 'onboarding_data';

  // PERCHÉ: verifica se l'utente ha già completato l'onboarding
  // per decidere se mostrare OnboardingScreen o SplashScreen → HomeScreen
  Future<bool> isCompleted() async {
    final value = await _storage.read(key: _completedKey);
    return value == 'true';
  }

  // PERCHÉ: salva i dati onboarding. Il flag 'completed' è separato
  // dai dati per permettere letture veloci senza deserializzare JSON
  Future<void> complete(OnboardingData data) async {
    // DEBUG: traccia il completamento per audit di conformità
    debugPrint(
      '[LoopEngineer] OnboardingService.complete: '
      'residenza=${data.residenzaFiscale}, '
      'ageConfirmed=${data.ageConfirmed}',
    );

    await Future.wait([
      _storage.write(key: _completedKey, value: 'true'),
      _storage.write(key: _dataKey, value: jsonEncode(data.toJson())),
    ]);
  }

  // PERCHÉ: recupera i dati di onboarding per visualizzazione
  // nelle info legali o per modifiche future (es. cambio residenza)
  Future<OnboardingData?> getData() async {
    final json = await _storage.read(key: _dataKey);
    if (json == null) return null;
    try {
      return OnboardingData.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('[LoopEngineer] OnboardingService.getData: parse error $e');
      return null;
    }
  }
}
