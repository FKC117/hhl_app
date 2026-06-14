class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.phone,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String phone;

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? email : value;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone': phone,
    };
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      email: '${json['email'] ?? ''}'.trim(),
      firstName: '${json['first_name'] ?? ''}'.trim(),
      lastName: '${json['last_name'] ?? ''}'.trim(),
      role: '${json['role'] ?? ''}'.trim(),
      phone: '${json['phone'] ?? ''}'.trim(),
    );
  }
}
