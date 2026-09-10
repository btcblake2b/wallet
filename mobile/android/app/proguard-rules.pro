# ProGuard/R8 rules per Flutter app
# Generated per btc_blake2b_wallet

# ──────────────────────────────────────────────────────────────
# Flutter / Dart
# ──────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ──────────────────────────────────────────────────────────────
# Keep app entry points
# ──────────────────────────────────────────────────────────────
-keep class com.btcblake2b.wallet.** { *; }
# ──────────────────────────────────────────────────────────────
# Plugin-specific rules
# ──────────────────────────────────────────────────────────────

# local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# flutter_secure_storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# mobile_scanner (camera/QR)
-keep class dev.steenbakker.mobile_scanner.** { *; }

# nearby_connections
-keep class com.google.android.gms.nearby.** { *; }

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# flutter_blue_plus
-keep class com.boskokg.flutter_blue_plus.** { *; }

# flutter_webrtc
-keep class com.cloudwebrtc.webrtc.** { *; }

# screen_protector
-keep class com.prongbang.screenprotector.** { *; }

# flutter_jailbreak_detection
-keep class com.xraph.plugin.flutter_jailbreak_detection.** { *; }

# package_info_plus
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# ──────────────────────────────────────────────────────────────
# General Android best practices
# ──────────────────────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
