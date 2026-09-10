// Conditional export: use platform-specific secure storage implementation.
export 'secure_seed_storage_io.dart'
    if (dart.library.html) 'secure_seed_storage_web.dart';
