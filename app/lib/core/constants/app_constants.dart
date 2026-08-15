class AppConstants {
  static const String apiKey = '24241291';
  static const String baseUrl = 'https://labs.anontech.info/cse489/exm3/api.php';
  static const String imageBaseUrl = 'https://labs.anontech.info/cse489/exm3/';

  static const String jobPollingTask = 'job_polling_task_2';
  static const String offlineSyncTask = 'offline_sync_task_2';
  static const int pollIntervalMinutes = 15;

  static const double defaultLat = 23.8103;
  static const double defaultLon = 90.4125;
  static const double defaultZoom = 12.0;

  static const String dbName = 'smart_landmarks2.db';
  static const int dbVersion = 1;

  static const String landmarksTable = 'landmarks';
  static const String visitHistoryTable = 'visit_history';
  static const String pendingVisitsTable = 'pending_visits';
}
