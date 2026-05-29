// core/config/app_config.dart

class AppConfig {
  /// Master switch for all Firebase services (Auth, Firestore, Storage, Analytics, AppCheck)
  /// Set to false to run the app in Local-First Offline MVP mode.
  static const bool enableFirebase = true;
  
  /// Master switch for the background SyncEngine
  static const bool enableCloudSync = false;
  
  /// Master switch for Google Authentication requirement
  /// If false, the app will skip login and rely purely on local Hive database.
  static const bool enableFirebaseAuth = true;
  
  /// Master switch for cloud backup features in UI
  static const bool enableCloudBackup = false;
}
