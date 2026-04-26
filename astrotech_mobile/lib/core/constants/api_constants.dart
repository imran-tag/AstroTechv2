class ApiConstants {
  ApiConstants._();

  // Base URL - environment-based configuration
  // Use --dart-define=API_URL=http://your-ip:3005/api/v1/affaires when building
  static String get baseUrl {
    const String envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // Android emulator → 10.0.2.2 maps to host localhost
    // iOS simulator   → localhost works (same machine)
    // Physical device → must use the Mac's LAN IP
    // Override at build time: --dart-define=API_URL=http://<ip>:3005/api/v1/affaires
    return 'http://10.122.130.108:3005/api/v1/affaires';
  }

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Mobile endpoints
  static const String mobileProfile = '/mobile/me';
  static const String mobileInterventions = '/mobile/interventions';
  static const String mobileSync = '/mobile/sync';

  // Mobile intervention endpoints (with id parameter)
  static String mobileInterventionDetail(int id) => '/mobile/interventions/$id';
  static String mobileInterventionStatus(int id) => '/mobile/interventions/$id/status';
  static String mobileInterventionWorkflow(int id) => '/mobile/interventions/$id/workflow';
  static String mobileInterventionPhotos(int id) => '/mobile/interventions/$id/photos';
  static String mobileInterventionPhoto(int interventionId, int photoId) =>
      '/mobile/interventions/$interventionId/photos/$photoId';
  static String mobileInterventionSignature(int id) => '/mobile/interventions/$id/signature';
  static String mobileInterventionTypedSignature(int id, String type) =>
      '/mobile/interventions/$id/signatures/$type';
  static String mobileInterventionInterruptions(int id) => '/mobile/interventions/$id/interruptions';
  static String mobileInterventionInterruption(int interventionId, String interruptionId) =>
      '/mobile/interventions/$interventionId/interruptions/$interruptionId';
  static String mobileInterventionTravelTime(int id) => '/mobile/interventions/$id/travel-time';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String technicianKey = 'technician_data';
}
