import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<Map<String, dynamic>> getJson(
    String baseUrl,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: _sanitizeQuery(queryParameters));

    final response = await _httpClient.get(
      uri,
      headers: {'Accept': 'application/json', ...?headers},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessageFromResponse(response),
        statusCode: response.statusCode,
      );
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      'The server returned an unexpected response shape.',
    );
  }

  Future<Map<String, dynamic>> postJson(
    String baseUrl,
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessageFromResponse(response),
        statusCode: response.statusCode,
      );
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      'The server returned an unexpected response shape.',
    );
  }

  Future<Map<String, dynamic>> patchJson(
    String baseUrl,
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');

    final response = await _httpClient.patch(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessageFromResponse(response),
        statusCode: response.statusCode,
      );
    }

    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      'The server returned an unexpected response shape.',
    );
  }

  Future<http.Response> getBinary(
    String baseUrl,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: _sanitizeQuery(queryParameters));

    final response = await _httpClient.get(uri, headers: {...?headers});

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessageFromResponse(response),
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Map<String, String>? _sanitizeQuery(Map<String, String>? queryParameters) {
    if (queryParameters == null) return null;

    final cleaned = <String, String>{};
    for (final entry in queryParameters.entries) {
      if (entry.value.trim().isNotEmpty) {
        cleaned[entry.key] = entry.value;
      }
    }
    return cleaned.isEmpty ? null : cleaned;
  }

  String _errorMessageFromResponse(http.Response response) {
    final fallback = 'Request failed with status ${response.statusCode}.';
    final body = response.body.trim();
    if (body.isEmpty) {
      return fallback;
    }

    try {
      final dynamic decoded = jsonDecode(body);
      final extracted = _extractError(decoded);
      return extracted.isEmpty ? fallback : extracted;
    } catch (_) {
      return fallback;
    }
  }

  String _extractError(dynamic value) {
    if (value is String) {
      return value.trim();
    }
    if (value is List) {
      for (final item in value) {
        final extracted = _extractError(item);
        if (extracted.isNotEmpty) return extracted;
      }
      return '';
    }
    if (value is Map) {
      const preferredKeys = ['detail', 'non_field_errors', 'error', 'message'];
      for (final key in preferredKeys) {
        final extracted = _extractError(value[key]);
        if (extracted.isNotEmpty) return extracted;
      }
      for (final entry in value.entries) {
        final extracted = _extractError(entry.value);
        if (extracted.isNotEmpty) {
          final key = '${entry.key}'.trim();
          return key.isEmpty ? extracted : '$key: $extracted';
        }
      }
    }
    return '';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

