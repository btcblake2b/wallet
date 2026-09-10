import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  /// SHA256 dell'impronta di firma dell'APK (buildSignature).
  /// In debug mode viene stampata a console. Da popolare per la prima release.
  /// Lascia vuoto per disabilitare il controllo di integrità.
  @EnviedField(varName: 'APP_SIGNATURE', defaultValue: '')
  static final String appSignature = _Env.appSignature;
}
