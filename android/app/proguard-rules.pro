# Flutter ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep application classes
-keep class com.trae.agent.** { *; }

# Keep Model classes
-keep class com.trae.agent.models.** { *; }

# Keep HTTP client classes
-keep class org.apache.** { *; }
-dontwarn org.apache.**

# Keep JSON serialization
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }

# Keep Gson/Json
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes RuntimeException
-dontwarn com.google.gson.**

# Desugaring
-dontwarn java.time.**
-keep class java.time.** { *; }
