class ApiConstants {
  static const String baseUrl =
      'http://192.168.100.10/HELPER-FIRST-AID-PHP-DASHBOARD-/api';

  static const String syncIncidents = '$baseUrl/sync_incidents.php';
  static const String contentVersion = '$baseUrl/content_version.php';
  static const String contentPackage = '$baseUrl/content_package.php';
  static const String syncProfile = '$baseUrl/sync_profile.php';
  static const String uploadIncidentImage = '$baseUrl/upload_incident_image.php';
  static const String uploadProfileImage = '$baseUrl/upload_profile_image.php';
}