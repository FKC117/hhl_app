class AmbulanceRequestItem {
  const AmbulanceRequestItem({
    required this.id,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.contactNumber,
    required this.status,
    required this.statusDisplay,
    required this.notes,
    required this.createdAtLabel,
  });

  final int id;
  final String pickupAddress;
  final String destinationAddress;
  final String contactNumber;
  final String status;
  final String statusDisplay;
  final String notes;
  final String createdAtLabel;

  factory AmbulanceRequestItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;

    return AmbulanceRequestItem(
      id: id,
      pickupAddress: _firstNonEmpty([
        '${json['pickup_address'] ?? ''}',
        'Pickup not provided',
      ]),
      destinationAddress: _firstNonEmpty([
        '${json['destination_address'] ?? ''}',
        'Destination not provided',
      ]),
      contactNumber: _firstNonEmpty([
        '${json['contact_number'] ?? ''}',
        'Contact not provided',
      ]),
      status: _firstNonEmpty([
        '${json['status'] ?? ''}',
        'REQUESTED',
      ]),
      statusDisplay: _firstNonEmpty([
        '${json['status_display'] ?? ''}',
        _humanizeStatus('${json['status'] ?? ''}'),
        'Requested',
      ]),
      notes: _firstNonEmpty([
        '${json['notes'] ?? ''}',
        'No extra notes added.',
      ]),
      createdAtLabel: _formatCreatedAt('${json['created_at'] ?? ''}'),
    );
  }

  static String _humanizeStatus(String value) {
    if (value.trim().isEmpty) return '';
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _formatCreatedAt(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Created time unavailable';

    final local = parsed.toLocal();
    final month = _monthName(local.month);
    final hour = local.hour == 0 || local.hour == 12
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$month ${local.day}, ${local.year} at $hour:$minute $suffix';
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return 'Unknown';
    return months[month - 1];
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
