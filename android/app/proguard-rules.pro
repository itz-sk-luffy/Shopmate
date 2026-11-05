# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Workmanager Background Tasks
-keep class dev.fluttercommunity.workmanager.** { *; }
-keep class androidx.work.** { *; }

# Drift / SQLite3
-keep class org.sqlite.** { *; }
-keep class com.simonbinder.** { *; }
-dontwarn org.sqlite.**

# InAppWebView
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-keepattributes *Annotation*
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# Mobile Scanner
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Flutter Deferred Components (not used, ignore optional play core references)
-dontwarn com.google.android.play.core.**

# Bluetooth Thermal Printer
-keep class com.tablemi.flutter_bluetooth_basic.** { *; }
-dontwarn com.tablemi.flutter_bluetooth_basic.**

# Share Plus & File Picker
-keep class dev.fluttercommunity.plus.share.** { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Local Auth Biometrics
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn androidx.biometric.**


