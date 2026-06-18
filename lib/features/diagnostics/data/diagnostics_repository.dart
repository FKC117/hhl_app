import '../../../core/api/api_client.dart';
import '../../../core/config/api_config.dart';
import 'diagnostic_lab.dart';

class DiagnosticsRepository {
  DiagnosticsRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<DiagnosticLab>> fetchLabs() async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/diagnostics/labs/',
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DiagnosticLab.fromJson)
          .toList();
    }

    return const [];
  }

  Future<DiagnosticLab> fetchLabDetail(int labId) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/diagnostics/labs/$labId/',
    );
    return DiagnosticLab.fromJson(json);
  }

  Future<List<DiagnosticTest>> fetchLabTests({
    required int labId,
    String? search,
    String? department,
  }) async {
    final json = await _apiClient.getJson(
      ApiConfig.apiBaseUrl,
      '/diagnostics/labs/$labId/tests/',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (department != null && department.trim().isNotEmpty)
          'department': department.trim(),
      },
    );

    final dynamic raw = json['results'] ?? json['data'] ?? json;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(DiagnosticTest.fromJson)
          .toList();
    }

    return const [];
  }

  Future<DiagnosticDraftResult> createDraftOrder({
    required int labId,
    required List<int> tests,
    required String patientNote,
    String? preferredDate,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/diagnostics/orders/draft/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {
        'lab': labId,
        'tests': tests,
        'patient_note': patientNote,
        if (preferredDate != null && preferredDate.trim().isNotEmpty)
          'preferred_date': preferredDate.trim(),
      },
    );

    return DiagnosticDraftResult.fromJson(json);
  }

  Future<PaymentRecord> initiatePayment({
    required int orderId,
    required String accessToken,
    required String gateway,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/payments/initiate/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {
        'source_type': 'DIAGNOSTIC',
        'source_id': orderId,
        'gateway': gateway,
      },
    );

    return PaymentRecord.fromJson(json);
  }

  Future<PaymentRecord> completeManualPayment({
    required int paymentId,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/payments/$paymentId/complete/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: const {},
    );

    return PaymentRecord.fromJson(json);
  }

  Future<DiagnosticDraftResult> confirmOrder({
    required int orderId,
    required int paymentId,
    required String accessToken,
  }) async {
    final json = await _apiClient.postJson(
      ApiConfig.apiBaseUrl,
      '/diagnostics/orders/$orderId/confirm/',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {'payment_id': paymentId},
    );

    return DiagnosticDraftResult.fromJson(json);
  }
}

class DiagnosticTest {
  const DiagnosticTest({
    required this.id,
    required this.name,
    required this.department,
    required this.price,
    required this.description,
    required this.preparationNote,
  });

  final int id;
  final String name;
  final String department;
  final String price;
  final String description;
  final String preparationNote;

  factory DiagnosticTest.fromJson(Map<String, dynamic> json) {
    final id = json['id'] is int
        ? json['id'] as int
        : int.tryParse('${json['id']}') ?? 0;
    final rawPrice = '${json['price'] ?? json['fee'] ?? json['amount'] ?? ''}'
        .trim();

    return DiagnosticTest(
      id: id,
      name: _firstNonEmpty([
        '${json['name'] ?? ''}',
        '${json['test_name'] ?? ''}',
        'Test #$id',
      ]),
      department: _firstNonEmpty([
        '${json['department_name'] ?? ''}',
        '${json['department'] ?? ''}',
        _nestedValue(json['department_detail'], ['name', 'title']),
        'General',
      ]),
      price: rawPrice.isEmpty
          ? 'Price not listed'
          : rawPrice.toLowerCase().contains('bdt')
          ? rawPrice
          : 'BDT $rawPrice',
      description: _firstNonEmpty([
        '${json['description'] ?? ''}',
        '${json['summary'] ?? ''}',
        '${json['instructions'] ?? ''}',
        'Diagnostic test details will appear here when the backend returns them.',
      ]),
      preparationNote: _firstNonEmpty([
        '${json['preparation_note'] ?? ''}',
        '${json['instructions'] ?? ''}',
      ]),
    );
  }
}

class DiagnosticDraftResult {
  const DiagnosticDraftResult({
    required this.id,
    required this.status,
    this.statusDisplay = '',
    this.totalAmount = '',
    this.preferredDate = '',
  });

  final int id;
  final String status;
  final String statusDisplay;
  final String totalAmount;
  final String preferredDate;

  factory DiagnosticDraftResult.fromJson(Map<String, dynamic> json) {
    return DiagnosticDraftResult(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      status: '${json['status'] ?? 'draft'}'.trim(),
      statusDisplay: '${json['status_display'] ?? ''}'.trim(),
      totalAmount: _formatMoney('${json['total_amount'] ?? ''}'.trim()),
      preferredDate: '${json['preferred_date'] ?? ''}'.trim(),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.gateway,
    required this.status,
    required this.transactionId,
  });

  final int id;
  final String amount;
  final String gateway;
  final String status;
  final String transactionId;

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      amount: _formatMoney('${json['amount'] ?? ''}'.trim()),
      gateway: '${json['gateway'] ?? ''}'.trim(),
      status: '${json['status'] ?? ''}'.trim(),
      transactionId: '${json['transaction_id'] ?? ''}'.trim(),
    );
  }
}

String _formatMoney(String raw) {
  if (raw.isEmpty) return 'Amount not listed';
  if (raw.toLowerCase().contains('bdt')) return raw;
  return 'BDT $raw';
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
    if (value.isNotEmpty && value != 'null') {
      return value;
    }
  }
  return '';
}
