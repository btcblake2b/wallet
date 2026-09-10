// Conditional export: use the platform-specific implementation.
export 'biometric_service_io.dart'
    if (dart.library.html) 'biometric_service_web.dart';
