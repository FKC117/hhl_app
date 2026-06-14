class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.title,
    required this.phoneNumber,
  });

  final int id;
  final String title;
  final String phoneNumber;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;

    return EmergencyContact(
      id: id,
      title: _firstNonEmpty([
        '${json['title'] ?? ''}',
        '${json['name'] ?? ''}',
        'Emergency contact',
      ]),
      phoneNumber: _firstNonEmpty([
        '${json['phone_number'] ?? ''}',
        '${json['phone'] ?? ''}',
        '${json['contact_number'] ?? ''}',
        'Not provided',
      ]),
    );
  }
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && trimmed != 'null') {
      return trimmed;
    }
  }
  return '';
}
