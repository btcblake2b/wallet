import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  /// SHA256 dell'impronta di firma dell'APK (buildSignature).
  /// In debug mode viene stampata a console. Da popolare per la prima release.
  /// In release il controllo è FAIL-CLOSED (audit SEC-06): se vuota, l'app
  /// non parte — non è un interruttore per disabilitare la verifica.
  @EnviedField(varName: 'APP_SIGNATURE', defaultValue: '')
  static final String appSignature = _Env.appSignature;
}
