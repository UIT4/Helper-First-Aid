import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'sync_service.dart';

class AuthResult {
  final bool ok;
  final String message;
  final Map<String, dynamic>? user;
  final bool serverReached;

  const AuthResult({
    required this.ok,
    required this.message,
    this.user,
    required this.serverReached,
  });
}

class AuthService {
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final deviceId = await SyncService.getOrCreateDeviceId();

    return _post(
      ApiConstants.authLogin,
      {
        'email': email.trim().toLowerCase(),
        'password': password,
        'device_id': deviceId,
      },
    );
  }

  static Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final deviceId = await SyncService.getOrCreateDeviceId();

    return _post(
      ApiConstants.authRegister,
      {
        'full_name': fullName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
        'device_id': deviceId,
      },
    );
  }

  static Future<AuthResult> _post(
      String url,
      Map<String, dynamic> payload,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('Auth response ${response.statusCode}: ${response.body}');

      Map<String, dynamic> decoded = {};
      if (response.body.trim().isNotEmpty) {
        final raw = jsonDecode(response.body);
        if (raw is Map<String, dynamic>) decoded = raw;
      }

      final ok = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (decoded['ok'] == true || decoded['success'] == true || decoded['status'] == 'success');

      return AuthResult(
        ok: ok,
        message: decoded['message']?.toString() ?? (ok ? 'Success' : 'Server rejected request'),
        user: decoded['user'] is Map<String, dynamic> ? decoded['user'] as Map<String, dynamic> : decoded,
        serverReached: true,
      );
    } catch (e) {
      debugPrint('Auth server skipped: $e');
      return AuthResult(
        ok: false,
        message: e.toString(),
        serverReached: false,
      );
    }
  }
}
