/// Firebase configuration constants
class FirebaseConfig {
  static const String projectId = 'YOUR_PROJECT_ID';
  static const String apiKey = 'YOUR_API_KEY';
  static const String appId = 'YOUR_APP_ID';
  static const String messagingSenderId = 'YOUR_MESSAGING_SENDER_ID';
  static const String databaseUrl = 'YOUR_DATABASE_URL';
}

/// App configuration constants
class AppConfig {
  static const String appName = 'Personal Expense Tracker';
  static const String appVersion = '1.0.0';
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
