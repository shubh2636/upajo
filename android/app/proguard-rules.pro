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

# SQLite / Drift
-keep class org.sqlite.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Play Core / Deferred Components
-dontwarn com.google.android.play.core.**


