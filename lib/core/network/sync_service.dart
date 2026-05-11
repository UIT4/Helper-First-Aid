import 'dart:convert';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';
import '../constants/api_constants.dart';

class SyncService {
  static Future<void> syncIncidents() async {
    final db = AppDatabase.instance;

    // 1. Get unsynced incidents
    final incidents = await db.getUnsyncedIncidents();

    if (incidents.isEmpty) return;

    // 2. Prepare payload
    final payload = {
      'incidents': incidents.map((e) => {
        'local_id': e['id'],
        'device_id': e['device_id'],
        'occurred_at': e['created_at'],
        'category_code': e['predicted_category'],
        'lang': e['lang'],
      }).toList(),
    };


    try {
      // 3. Send POST request
      final response = await http.post(
        Uri.parse(ApiConstants.syncIncidents),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      print('Response status: ${response.statusCode}');

      // 4. Handle response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['results'] != null) {
          for (var item in data['results']) {
            await db.markIncidentSynced(
              item['local_id'],
              item['server_id'],
            );
          }
        }
      }
    } catch (e) {
      print('Server not available yet');
      print('Sync error: $e');
    }
  }
}