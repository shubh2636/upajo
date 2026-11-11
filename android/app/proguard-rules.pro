# Flutter Proguard Rules for Upajo
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Razorpay SDK
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.tflite.** { *; }
-dontwarn com.tflite.**

# SQLite / Drift
-keep class org.sqlite.** { *; }
-keep class io.simform.drift.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keep class com.google.android.gms.** { *; }

# Security & Hardware Keystore Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Image Compression & Media
-keep class com.fluttercandies.flutter_image_compress.** { *; }

# Voice & Speech AI
-keep class com.csdcorp.speech_to_text.** { *; }
-keep class com.tundralabs.fluttertts.** { *; }

# PDF & Printing
-keep class net.nfet.flutter.printing.** { *; }

# Google Play Core / Deferred Components
-dontwarn com.google.android.play.core.**



