import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../database/app_database.dart';

class SyncService {
  static Future<void> syncIncidents() async {
    final db = AppDatabase.instance;
    final incidents = await db.getUnsyncedIncidents();

    if (incidents.isEmpty) return;

    final payload = {
      'device_id': incidents.first['device_id'] ?? 'unknown-device',
      'incidents': incidents.map((incident) {
        return {
          'local_id': incident['id'],
          'created_at': incident['created_at'],
          'lang': incident['lang'],
          'input_text': incident['input_text'],
          'predicted_category_code': incident['predicted_category_code'],
          'confidence': incident['confidence'],
          'urgency': incident['urgency'],
          'lat': incident['lat'],
          'lng': incident['lng'],
          'location_source': incident['location_source'],
          'notes': incident['notes'] ?? '',
        };
      }).toList(),
    };

    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.syncIncidents),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('Sync response: ${response.statusCode} ${response.body}');

      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final syncedList = decoded['synced'] ?? decoded['results'];
      if (syncedList is! List) return;

      for (final item in syncedList) {
        if (item is! Map) continue;
        final localId = _toInt(item['local_id']);
        final serverId = _toInt(item['server_id']);

        if (localId != null && serverId != null) {
          await db.markIncidentSynced(localId, serverId);
        }
      }
    } catch (e) {
      debugPrint('Incident sync skipped: $e');
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
