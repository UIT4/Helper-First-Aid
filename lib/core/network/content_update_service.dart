import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../database/app_database.dart';

class ContentUpdateService {
  static Future<void> checkForUpdate() async {
    final db = AppDatabase.instance;

    try {
      final localVersion = await db.getContentVersion();
      final response = await http
          .get(Uri.parse(ApiConstants.contentVersion))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final serverVersion = _toInt(decoded['version']);
      if (serverVersion == null) return;

      debugPrint('Content version | local: $localVersion | server: $serverVersion');

      if (serverVersion > localVersion) {
        await _downloadAndReplaceContent(serverVersion);
      }
    } catch (e) {
      debugPrint('Content update skipped: $e');
    }
  }

  static Future<void> _downloadAndReplaceContent(int newVersion) async {
    final db = AppDatabase.instance;

    try {
      final response = await http
          .get(Uri.parse(ApiConstants.contentPackage))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final categories = decoded['categories'];
      final steps = decoded['steps'];

      if (categories is! List || steps is! List) return;

      final database = await db.database;

      await database.transaction((txn) async {
        await txn.delete(Tables.guidanceSteps);
        await txn.delete(Tables.categories);

        for (final cat in categories) {
          if (cat is Map<String, dynamic>) {
            await txn.insert(Tables.categories, cat);
          }
        }

        for (final step in steps) {
          if (step is Map<String, dynamic>) {
            await txn.insert(Tables.guidanceSteps, step);
          }
        }
      });

      await db.setContentVersion(newVersion);
      debugPrint('Content updated to version $newVersion');
    } catch (e) {
      debugPrint('Content package download skipped: $e');
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
