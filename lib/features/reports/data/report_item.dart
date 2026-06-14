import '../../documents/data/document_item.dart';

class ReportItem extends DocumentItem {
  const ReportItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.status,
    required this.labName,
  }) : super(sourceName: labName, downloadPath: '/reports/$id/download/');

  final String labName;

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;
    final title = _firstNonEmpty([
      '${json['title'] ?? ''}',
      '${json['report_name'] ?? ''}',
      '${json['test_name'] ?? ''}',
      'Report #$id',
    ]);

    return ReportItem(
      id: id,
      title: title,
      subtitle: _firstNonEmpty([
        '${json['summary'] ?? ''}',
        '${json['description'] ?? ''}',
        '${json['remarks'] ?? ''}',
        'Medical report document ready for secure access.',
      ]),
      status: _firstNonEmpty([
        '${json['status'] ?? ''}',
        '${json['report_status'] ?? ''}',
        'available',
      ]),
      labName: _firstNonEmpty([
        '${json['lab_name'] ?? ''}',
        '${json['lab'] ?? ''}',
        _nestedValue(json['lab_detail'], ['name', 'title']),
        'HHL Diagnostics',
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

String _nestedValue(dynamic raw, List<String> keys) {
  if (raw is! Map<String, dynamic>) return '';
  for (final key in keys) {
    final value = '${raw[key] ?? ''}'.trim();
    if (value.isNotEmpty && value != 'null') return value;
  }
  return '';
}
