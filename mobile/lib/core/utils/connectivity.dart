// Conditional connectivity helper: uses a web implementation when compiled
// for the browser, otherwise uses the IO implementation.
import 'package:flutter/foundation.dart';

import 'connectivity_io.dart' if (dart.library.html) 'connectivity_web.dart'
    as impl;

// // PERCHÉ (S6): nei widget test la lookup DNS reale fallisce e bloccherebbe
// i flussi che richiedono internet (creazione/import). Hook sovrascrivibile.
bool _forceOnline = false;

@visibleForTesting
set connectivityOnlineForTest(bool value) {
  _forceOnline = value;
}

Future<bool> hasInternet() async {
  if (_forceOnline) return true;
  return impl.hasInternet();
}
