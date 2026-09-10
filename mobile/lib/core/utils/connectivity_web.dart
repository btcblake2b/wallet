import 'package:web/web.dart' as web;

Future<bool> hasInternet() async {
  // Use navigator.onLine for a fast web-friendly check. It can be imprecise
  // (e.g. behind captive portals), but is appropriate for deciding whether
  // to avoid network-only irreversible operations in a PWA.
  return web.window.navigator.onLine;
}
