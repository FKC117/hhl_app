import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_user.dart';

class SessionStorage {
  static const _accessTokenKey = 'session_access_token';
  static const _refreshTokenKey = 'session_refresh_token';
  static const _userJsonKey = 'session_user_json';

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userJsonKey, jsonEncode(user.toJson()));
  }

  Future<StoredSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    final refreshToken = prefs.getString(_refreshTokenKey);
    final userJson = prefs.getString(_userJsonKey);

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        userJson == null ||
        userJson.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(userJson);
    if (decoded is! Map<String, dynamic>) return null;

    return StoredSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(decoded),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userJsonKey);
  }
}

class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;
}
