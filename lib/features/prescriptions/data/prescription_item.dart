import '../../documents/data/document_item.dart';

class PrescriptionItem extends DocumentItem {
  const PrescriptionItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.status,
    required this.appointmentLabel,
  }) : super(
         sourceName: appointmentLabel,
         downloadPath: '/prescriptions/$id/download/',
       );

  final String appointmentLabel;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;

    return PrescriptionItem(
      id: id,
      title: _firstNonEmpty([
        '${json['title'] ?? ''}',
        '${json['prescription_name'] ?? ''}',
        'Prescription #$id',
      ]),
      subtitle: _firstNonEmpty([
        '${json['summary'] ?? ''}',
        '${json['description'] ?? ''}',
        'Prescription document ready for secure access.',
      ]),
      status: _firstNonEmpty(['${json['status'] ?? ''}', 'available']),
      appointmentLabel: _firstNonEmpty([
        '${json['appointment_label'] ?? ''}',
        '${json['appointment'] ?? ''}',
        'Appointment reference',
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
