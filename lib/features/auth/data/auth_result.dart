import 'auth_user.dart';

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: '${json['access'] ?? ''}'.trim(),
      refreshToken: '${json['refresh'] ?? ''}'.trim(),
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
