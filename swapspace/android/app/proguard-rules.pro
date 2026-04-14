# Keep useful stack traces in release for Firebase Crashlytics symbolication.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Keep Flutter plugin registrant entry points that can be resolved reflectively.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Keep classes implementing FlutterPlugin to avoid plugin registration edge-cases.
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
