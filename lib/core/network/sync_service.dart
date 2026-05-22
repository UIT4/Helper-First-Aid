import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../database/app_database.dart';

class SyncService {

  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');

    if (id == null || id.trim().isEmpty) {
      final random = Random();
      id = '${DateTime.now().millisecondsSinceEpoch}${random.nextInt(999999)}';
      await prefs.setString('device_id', id);
    }

    return id;
  }

  static Future<void> syncProfile() async {
    final db = AppDatabase.instance;
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('isGuest') ?? false) return;

    final profile = await db.getProfile();
    final user = await db.getCurrentUserAccount();
    if (profile == null && user == null) return;

    final contacts = await db.getContacts();
    final settings = await db.getSettings();
    final deviceId = await getOrCreateDeviceId();

    final payload = {
      'device_id': deviceId,
      'email': prefs.getString('userEmail') ?? user?['email'] ?? '',
      'full_name': profile?['full_name'] ?? user?['full_name'] ?? '',
      'password': user?['password'] ?? '',
      'account_created_at': user?['created_at'] ?? '',
      'age': profile?['age'],
      'sex': profile?['sex'] ?? '',
      'blood_type': profile?['blood_type'] ?? '',
      'allergies': profile?['allergies'] ?? '',
      'conditions': profile?['conditions'] ?? '',
      'medications': profile?['medications'] ?? '',
      'notes': profile?['notes'] ?? '',
      'language': settings['language'] ?? 'en',
      'country_code': settings['country_code'] ?? '+962',
      'emergency_number': settings['emergency_number'] ?? '911',
      'ambulance_number': settings['ambulance_number'] ?? '193',
      'fire_number': settings['fire_number'] ?? '199',
      'contacts': contacts.map((contact) {
        return {
          'contact_name': contact['name'] ?? contact['contact_name'] ?? '',
          'phone': contact['phone'] ?? '',
          'relation': contact['relation'] ?? '',
        };
      }).toList(),
    };

    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.syncProfile),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      debugPrint('Profile sync response: ${response.statusCode} ${response.body}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await db.markCurrentUserSynced();
      }
    } catch (e) {
      debugPrint('Profile sync skipped: $e');
    }
  }

  static Future<void> syncIncidents() async {
    final db = AppDatabase.instance;
    final incidents = await db.getUnsyncedIncidents();

    if (incidents.isEmpty) return;

    final deviceId = await getOrCreateDeviceId();

    final payload = {
      'device_id': incidents.first['device_id'] ?? deviceId,
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
