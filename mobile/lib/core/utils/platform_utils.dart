// Conditional export: re-export the appropriate implementation for the current
// platform so callers can import this file and use the top-level helpers.
export 'platform_utils_stub.dart'
    if (dart.library.html) 'platform_utils_web.dart';

// This file re-exports either `platform_utils_stub.dart` (non-web) or
// `platform_utils_web.dart` (web) depending on compilation target.
