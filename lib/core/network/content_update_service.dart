import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';
import '../constants/api_constants.dart';

class ContentUpdateService {

  // 🔍 فحص هل في تحديث
  static Future<void> checkForUpdate() async {
    final db = AppDatabase.instance;

    try {
      final localVersion = await db.getContentVersion();

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/content_version.php'),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final serverVersion = data['version'];

      print('Local: $localVersion | Server: $serverVersion');

      if (serverVersion > localVersion) {
        await _downloadAndReplaceContent(serverVersion);
      }

    } catch (e) {
      print('Server not available yet');
      print('Content update error: $e');
    }
  }

  // ⬇️ تحميل وتحديث المحتوى
  static Future<void> _downloadAndReplaceContent(int newVersion) async {
    final db = AppDatabase.instance;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/content_package.php'),
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      final categories = data['categories'];
      final steps = data['steps'];

      final database = await db.database;

      await database.transaction((txn) async {
        // 🔥 حذف القديم
        await txn.delete(Tables.guidanceSteps);
        await txn.delete(Tables.categories);

        // ➕ إدخال categories
        for (var cat in categories) {
          await txn.insert(Tables.categories, cat);
        }

        // ➕ إدخال steps
        for (var step in steps) {
          await txn.insert(Tables.guidanceSteps, step);
        }
      });

      // 🔥 تحديث النسخة
      await db.setContentVersion(newVersion);

      print('Content updated to version $newVersion');

    } catch (e) {
      print('Server not available yet');
      print('Download content error: $e');
    }
  }
}