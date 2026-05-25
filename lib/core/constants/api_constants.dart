class ApiConstants {
  static const String baseUrl =
      'http://192.168.100.10/HELPER-FIRST-AID-PHP-DASHBOARD-/api';

  // AUTH
  static const String authLogin = '$baseUrl/auth_login.php';
  static const String authRegister = '$baseUrl/auth_register.php';
  static const String syncUser = '$baseUrl/sync_user.php';

  // OTP
  static const String sendOtp = '$baseUrl/send_otp.php';
  static const String verifyOtp = '$baseUrl/verify_otp.php';
  static const String resetPassword = '$baseUrl/reset_password.php';

  // INCIDENTS
  static const String syncIncidents = '$baseUrl/sync_incidents.php';
  static const String uploadIncidentImage =
      '$baseUrl/upload_incident_image.php';

  // CONTENT
  static const String contentVersion =
      '$baseUrl/content_version.php';
  static const String contentPackage =
      '$baseUrl/content_package.php';

  // PROFILE
  static const String syncProfile =
      '$baseUrl/sync_profile.php';

  static const String uploadProfileImage =
      '$baseUrl/upload_profile_image.php';
}