import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _keyUserData = 'session_user_data';

  /// Save user map to disk after login
  static Future<void> saveSession(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, jsonEncode(userData));
  }

  /// Load persisted session (returns null if none)
  static Future<Map<String, dynamic>?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUserData);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Clear session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserData);
  }
}