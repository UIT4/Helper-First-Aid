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

  static Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConstants.contentVersion))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isGuest') ?? false) return;

    if (!await isServerReachable()) {
      debugPrint('syncAll skipped: server unreachable');
      return;
    }

    await syncUser();
    await syncProfile();
    await syncIncidents();
    await downloadIncidents();
  }

  static Future<void> syncUser() async {
    final db = AppDatabase.instance;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isGuest') ?? false) return;

    final user = await db.getCurrentUserAccount();
    if (user == null) return;

    final deviceId = await getOrCreateDeviceId();
    final payload = {
      'device_id': deviceId,
      'full_name': user['full_name'] ?? '',
      'email': user['email'] ?? prefs.getString('userEmail') ?? '',
      'phone': user['phone'] ?? prefs.getString('userPhone') ?? '',
      'password': user['password'] ?? '',
      'created_at': user['created_at'] ?? '',
    };

    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.syncUser),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('User sync response: ${response.statusCode} ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          final serverUser = decoded['user'];
          if (serverUser is Map<String, dynamic>) {
            await db.saveServerUserPayload(
              Map<String, dynamic>.from(serverUser),
              password: user['password']?.toString() ?? '',
            );
          }
          await db.markCurrentUserSynced();
        }
      }
    } catch (e) {
      debugPrint('User sync skipped: $e');
    }
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
    final email = (user?['email'] ?? prefs.getString('userEmail') ?? '').toString().trim().toLowerCase();

    final payload = {
      'device_id': deviceId,
      'email': email,
      'full_name': profile?['full_name'] ?? user?['full_name'] ?? '',
      'phone': user?['phone'] ?? prefs.getString('userPhone') ?? '',
      'password': user?['password'] ?? '',
      'account_created_at': user?['created_at'] ?? '',
      'age': profile?['age'],
      'sex': profile?['sex'] ?? '',
      'blood_type': profile?['blood_type'] ?? '',
      'allergies': profile?['allergies'] ?? '',
      'conditions': profile?['conditions'] ?? '',
      'medications': profile?['medications'] ?? '',
      'notes': profile?['notes'] ?? '',
      'birth_date': prefs.getString('birthDate') ?? '',
      'country': settings['country'] ?? prefs.getString('country') ?? 'Jordan',
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
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('Profile sync response: ${response.statusCode} ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await db.markCurrentUserSynced();
        await db.markCurrentProfileSynced();
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
    final prefs = await SharedPreferences.getInstance();
    final user = await db.getCurrentUserAccount();
    final email = (user?['email'] ?? prefs.getString('userEmail') ?? '').toString().trim().toLowerCase();

    final payload = {
      'device_id': deviceId,
      'email': email,
      'incidents': incidents.map((incident) {
        return {
          'local_id': incident['id'],
          'device_id': incident['device_id'] ?? deviceId,
          'created_at': incident['created_at'],
          'occurred_at': incident['created_at'],
          'lang': incident['lang'] ?? 'en',
          'input_text': incident['input_text'] ?? '',
          'predicted_category_code':
          incident['predicted_category_code'] ?? incident['category_code'],
          'confidence': incident['confidence'],
          'urgency': _normalizeUrgency(incident['urgency']?.toString()),
          'lat': incident['lat'],
          'lng': incident['lng'],
          'location_source': incident['location_source'] ?? 'none',
          'notes': incident['notes'] ?? '',
        };
      }).toList(),
    };

    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.syncIncidents),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('Incident sync response: ${response.statusCode} ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final syncedList = decoded['synced'] ?? decoded['results'];
      if (syncedList is! List) return;

      for (final item in syncedList) {
        if (item is! Map) continue;

        if (item['status'] != 'synced') {
          debugPrint('Incident not synced: $item');
          continue;
        }

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


  static Future<void> downloadIncidents() async {
    final db = AppDatabase.instance;
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('isGuest') ?? false) return;

    final user = await db.getCurrentUserAccount();
    final email = (user?['email'] ?? prefs.getString('userEmail') ?? '').toString().trim().toLowerCase();

    if (email.isEmpty) return;

    try {
      final response = await http
          .post(
        Uri.parse(ApiConstants.getIncidents),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('Download incidents response: ${response.statusCode} ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) return;

      final incidents = decoded['incidents'];
      if (incidents is List) {
        await db.saveDownloadedIncidents(incidents);
      }
    } catch (e) {
      debugPrint('Download incidents skipped: $e');
    }
  }

  static String _normalizeUrgency(String? urgency) {
    final value = urgency?.trim().toLowerCase();

    switch (value) {
      case 'low':
        return 'low';
      case 'med':
      case 'medium':
        return 'medium';
      case 'high':
        return 'high';
      case 'critical':
      case 'extreme':
        return 'extreme';
      default:
        return 'medium';
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
