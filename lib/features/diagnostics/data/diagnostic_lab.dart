class DiagnosticLab {
  const DiagnosticLab({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.about,
  });

  final int id;
  final String name;
  final String address;
  final String phone;
  final String about;

  factory DiagnosticLab.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;

    return DiagnosticLab(
      id: id,
      name: _firstNonEmpty([
        '${json['name'] ?? ''}',
        '${json['lab_name'] ?? ''}',
        'Lab #$id',
      ]),
      address: _firstNonEmpty([
        '${json['address'] ?? ''}',
        '${json['location'] ?? ''}',
        '${json['city'] ?? ''}',
        'Address not provided',
      ]),
      phone: _firstNonEmpty([
        '${json['phone'] ?? ''}',
        '${json['contact_number'] ?? ''}',
        'Not provided',
      ]),
      about: _firstNonEmpty([
        '${json['about'] ?? ''}',
        '${json['description'] ?? ''}',
        '${json['summary'] ?? ''}',
        'Diagnostic lab details will appear here when the backend returns them.',
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
