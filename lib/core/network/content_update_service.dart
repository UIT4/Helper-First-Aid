import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../database/app_database.dart';

class ContentUpdateService {
  static Future<void> checkForUpdate({bool force = false}) async {
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

      debugPrint(
        'Content version | local: $localVersion | server: $serverVersion | force: $force',
      );

      if (force || serverVersion > localVersion) {
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
            final code = (cat['code'] ?? cat['CODE'] ?? '').toString();

            if (code.trim().isEmpty) continue;

            await txn.insert(Tables.categories, {
              'code': code,
              'name_en': (cat['name_en'] ?? '').toString(),
              'name_ar': (cat['name_ar'] ?? '').toString(),
              'urgency_level': (cat['urgency_level'] ?? 'medium').toString(),
              'icon_key': (cat['icon_key'] ?? '').toString(),
              'sort_order': _toInt(cat['sort_order']) ?? 1,
              'is_active': _toInt(cat['is_active']) ?? 1,
            });
          }
        }

        for (final step in steps) {
          if (step is Map<String, dynamic>) {
            final categoryCode = (step['category_code'] ?? '').toString();

            if (categoryCode.trim().isEmpty) continue;

            await txn.insert(Tables.guidanceSteps, {
              'category_code': categoryCode,
              'step_no': _toInt(step['step_no']) ?? 1,
              'title_en': (step['title_en'] ?? '').toString(),
              'title_ar': (step['title_ar'] ?? '').toString(),
              'body_en': (step['body_en'] ?? '').toString(),
              'body_ar': (step['body_ar'] ?? '').toString(),
              'warning_en': (step['warning_en'] ?? '').toString(),
              'warning_ar': (step['warning_ar'] ?? '').toString(),
              'image_path': (step['image_path'] ?? '').toString(),
              'image_asset':
              (step['image_asset'] ?? step['image_path'] ?? '').toString(),
              'updated_at':
              (step['updated_at'] ?? DateTime.now().toIso8601String())
                  .toString(),
              'is_active': _toInt(step['is_active']) ?? 1,
            });
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