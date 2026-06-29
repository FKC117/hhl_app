import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.0.102:8000/api/v1';
      default:
        return 'http://127.0.0.1:8000/api/v1';
    }
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
