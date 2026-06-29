import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _defaultApiBaseUrl = String.fromEnvironment(
    'HHL_API_BASE_URL',
    defaultValue: 'https://hhl.analyticabd.xyz/api/v1',
  );

  static String get apiBaseUrl {
    final configured = _defaultApiBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured;
    }

    return 'https://hhl.analyticabd.xyz/api/v1';
  }

  static String get apiRootUrl {
    final value = apiBaseUrl;
    const suffix = '/api/v1';
    if (value.endsWith(suffix)) {
      return value.substring(0, value.length - suffix.length);
    }
    return value;
  }

  const ApiConfig._();
}
