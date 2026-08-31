# ---- Flutter ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# ---- Supabase / Ktor / kotlinx.serialization ----
-keep class io.github.jan.supabase.** { *; }
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keepattributes *Annotation*, InnerClasses, Signature, RuntimeVisibleAnnotations
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.json.** { kotlinx.serialization.KSerializer serializer(...); }

# ---- Geolocator / Play Services location ----
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }

# ---- image_picker / url_launcher / sign_in_with_apple ----
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }

# Keep model classes that are (de)serialised by name
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
