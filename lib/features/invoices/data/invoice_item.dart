import '../../documents/data/document_item.dart';

class InvoiceItem extends DocumentItem {
  const InvoiceItem({
    required super.id,
    required super.title,
    required super.subtitle,
    required super.status,
    required this.invoiceType,
    required this.amount,
    required this.fileName,
    required this.appointmentId,
    required this.diagnosticOrderId,
  }) : super(sourceName: invoiceType, downloadPath: '/invoices/$id/download/');

  final String invoiceType;
  final String amount;
  final String fileName;
  final int appointmentId;
  final int diagnosticOrderId;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;
    final amount = _formatMoney('${json['total'] ?? ''}');
    final invoiceType = _firstNonEmpty([
      '${json['invoice_type_display'] ?? ''}',
      '${json['invoice_type'] ?? ''}',
      '${json['type'] ?? ''}',
      'Invoice',
    ]);
    final createdAt = _formatDate('${json['created_at'] ?? ''}');

    return InvoiceItem(
      id: id,
      title: _firstNonEmpty([
        '${json['invoice_number'] ?? ''}',
        '${json['title'] ?? ''}',
        '${json['invoice_name'] ?? ''}',
        'Invoice #$id',
      ]),
      subtitle: _firstNonEmpty([
        '$invoiceType - $amount${createdAt.isEmpty ? '' : ' - $createdAt'}',
        '${json['summary'] ?? ''}',
        '${json['description'] ?? ''}',
        'Invoice document ready for secure access.',
      ]),
      status: _firstNonEmpty(['${json['status'] ?? ''}', 'available']),
      invoiceType: invoiceType,
      amount: amount,
      fileName: _firstNonEmpty([
        '${json['file_name'] ?? ''}',
        '${json['invoice_number'] ?? ''}.pdf',
        'invoice_$id.pdf',
      ]),
      appointmentId: json['appointment'] is int
          ? json['appointment'] as int
          : int.tryParse('${json['appointment']}') ?? 0,
      diagnosticOrderId: json['diagnostic_order'] is int
          ? json['diagnostic_order'] as int
          : int.tryParse('${json['diagnostic_order']}') ?? 0,
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

String _formatMoney(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == 'null') {
    return 'Amount not listed';
  }
  if (trimmed.toLowerCase().contains('bdt')) {
    return trimmed;
  }
  return 'BDT $trimmed';
}

String _formatDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == 'null') {
    return '';
  }

  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) {
    return '';
  }

  final monthNames = const [
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

  return '${monthNames[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}
