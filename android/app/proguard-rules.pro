# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Ayah models just in case (though safer to rely on @HiveType)
-keep class com.example.daily_ayah.models.** { *; }

# Google Play Core (Deferred Components) - Fix for R8 build error
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Home Widget Provider (Critical: Prevent renaming/removal)
-keep class com.example.daily_ayah.DailyAyahWidgetProvider { *; }

# Home Widget Plugin
-keep class es.antonborri.home_widget.** { *; }
