// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

bool isRunningAsPWA() {
  try {
    // Common checks for PWA standalone mode
    final displayModeStandalone =
        html.window.matchMedia('(display-mode: standalone)').matches;
    final navigatorStandalone =
        (html.window.navigator as dynamic).standalone == true;
    final referrerAndroid = html.document.referrer.startsWith('android-app://');
    return displayModeStandalone || navigatorStandalone || referrerAndroid;
  } catch (_) {
    return false;
  }
}

bool webNavigatorOnline() {
  try {
    // `onLine` can be nullable on some browsers; default to true when unknown.
    return html.window.navigator.onLine ?? true;
  } catch (_) {
    return true;
  }
}
