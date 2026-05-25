import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import 'sync_service.dart';

class AuthResult {
  final bool serverReached;
  final bool ok;
  final String message;
  final Map<String, dynamic>? user;

  const AuthResult({
    required this.serverReached,
    required this.ok,
    required this.message,
    this.user,
  });
}

class AuthService {
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final deviceId = await SyncService.getOrCreateDeviceId();

      final response = await http
          .post(
        Uri.parse(ApiConstants.authLogin),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password.trim(),
          'device_id': deviceId,
        }),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('LOGIN STATUS: ${response.statusCode}');
      debugPrint('LOGIN BODY: ${response.body}');

      Map<String, dynamic> decoded = {};

      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        return AuthResult(
          serverReached: true,
          ok: false,
          message: 'Invalid JSON response from server',
        );
      }

      final success = decoded['success'] == true;

      ok: response.statusCode == 200 && success;
      return AuthResult(
        serverReached: true,
        ok: response.statusCode == 200 && success,
        message: decoded['message']?.toString() ?? '',
        user: decoded['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded['user'])
            : null,
      );
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      return const AuthResult(
        serverReached: false,
        ok: false,
        message: 'Server unreachable',
      );
    }
  }

  static Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final deviceId = await SyncService.getOrCreateDeviceId();

      final response = await http
          .post(
        Uri.parse(ApiConstants.authRegister),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password.trim(),
          'device_id': deviceId,
        }),
      )
          .timeout(const Duration(seconds: 12));

      debugPrint('REGISTER STATUS: ${response.statusCode}');
      debugPrint('REGISTER BODY: ${response.body}');

      Map<String, dynamic> decoded = {};

      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } catch (_) {
        return AuthResult(
          serverReached: true,
          ok: false,
          message: 'Invalid JSON response from server',
        );
      }

      final success = decoded['success'] == true;
      ok: response.statusCode == 200 && success;

      return AuthResult(
        serverReached: true,
        ok: response.statusCode >= 200 &&
            response.statusCode < 300 &&
            success,
        message: decoded['message']?.toString() ?? '',
        user: decoded['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(decoded['user'])
            : null,
      );
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');

      return const AuthResult(
        serverReached: false,
        ok: false,
        message: 'Server unreachable',
      );
    }
  }
}