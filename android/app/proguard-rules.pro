# Flutter & Firebase ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter embedding
-keep class androidx.appcompat.app.AppCompatViewImpl { *; }
-keep class com.google.android.material.** { *; }

# Firebase Core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Crashlytics
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep Riverpod (code generation)
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.analytics.** { *; }

# Keep Data Classes (models) for Firestore serialization
-keep class com.amedspor.manager.data.models.** { *; }

# Keep Repository classes
-keep class com.amedspor.manager.data.repositories.** { *; }

# Reduce log verbosity in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
