# Force R8 to complete compilation even with missing transitive dependencies
-ignorewarnings

# FirebaseInstanceId is managed dynamically via BOM, suppress false missing triggers
-dontwarn com.google.firebase.iid.**
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**

# Standard Flutter embedding retention
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
