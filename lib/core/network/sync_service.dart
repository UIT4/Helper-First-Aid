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
      'device_id': incidents.first['device_id'],
      'incidents': incidents.map((e) => {
        'local_id': e['id'],
        'created_at': e['created_at'],
        'lang': e['lang'],
        'input_text': e['input_text'],
        'predicted_category_code': e['predicted_category_code'],
        'confidence': e['confidence'],
        'urgency': e['urgency'],
        'lat': e['lat'],
        'lng': e['lng'],
        'location_source': e['location_source'],
        'notes': e['notes'] ?? '',
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

      print('Sync payload: ${jsonEncode(payload)}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // 4. Handle response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final syncedList = data['synced'] ?? data['results'];

        if (syncedList != null) {
          for (var item in syncedList) {
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