import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../storage/session_storage.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/data/auth_user.dart';

class AppSession extends ChangeNotifier {
  AppSession({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;
  final SessionStorage _storage = SessionStorage();

  bool isAuthenticated = false;
  bool isInitializing = false;
  bool isBusy = false;
  String? errorMessage;
  String? accessToken;
  String? refreshToken;
  AuthUser? currentUser;

  Future<void> restore() async {
    isInitializing = true;
    notifyListeners();

    try {
      final stored = await _storage.load();
      if (stored != null) {
        accessToken = stored.accessToken;
        refreshToken = stored.refreshToken;
        currentUser = stored.user;
        isAuthenticated = true;

        final refreshed = await refreshAccessTokenIfPossible(
          clearOnFailure: true,
        );
        if (!refreshed) {
          await _clearLocalSession();
        }
      }
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      accessToken = result.accessToken;
      refreshToken = result.refreshToken;
      currentUser = result.user;
      isAuthenticated = true;
      await _storage.save(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
      );
      return true;
    } catch (_) {
      errorMessage =
          'Login failed. Check your email/password and make sure the Django server is running.';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> refreshAccessTokenIfPossible({
    bool clearOnFailure = false,
  }) async {
    if (refreshToken == null || refreshToken!.isEmpty || currentUser == null) {
      if (clearOnFailure) {
        await _clearLocalSession();
      }
      return false;
    }

    try {
      final newAccessToken = await _authRepository.refreshAccessToken(
        refreshToken: refreshToken!,
      );
      if (newAccessToken.isEmpty) {
        return false;
      }

      accessToken = newAccessToken;
      isAuthenticated = true;
      await _storage.save(
        accessToken: newAccessToken,
        refreshToken: refreshToken!,
        user: currentUser!,
      );
      notifyListeners();
      return true;
    } catch (_) {
      if (clearOnFailure) {
        await _clearLocalSession();
        notifyListeners();
      }
      return false;
    }
  }

  Future<T> withFreshToken<T>(
    Future<T> Function(String accessToken) action,
  ) async {
    final token = accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException('No access token is available.');
    }

    try {
      return await action(token);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;

      final refreshed = await refreshAccessTokenIfPossible(
        clearOnFailure: true,
      );
      if (!refreshed || accessToken == null || accessToken!.isEmpty) {
        rethrow;
      }

      return action(accessToken!);
    }
  }

  Future<void> logout() async {
    isBusy = true;
    notifyListeners();

    try {
      if (refreshToken != null && refreshToken!.isNotEmpty) {
        await _authRepository.logout(refreshToken: refreshToken!);
      }
    } catch (_) {
      // Local session still gets cleared.
    } finally {
      await _clearLocalSession();
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _clearLocalSession() async {
    await _storage.clear();
    accessToken = null;
    refreshToken = null;
    currentUser = null;
    errorMessage = null;
    isAuthenticated = false;
  }
}
