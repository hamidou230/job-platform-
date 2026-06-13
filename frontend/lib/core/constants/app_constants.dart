import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // 👉 Téléphone réel (même Wi-Fi) : remplace par l'IP du PC, ex: http://192.168.1.10:3000/api
  static const String _manualBaseUrl = '';

  /// URL de l'API selon la plateforme :
  /// - Android émulateur → 10.0.2.2
  /// - Linux / macOS / Windows / Web / iOS simulateur → localhost
  static String get baseUrl {
    if (_manualBaseUrl.isNotEmpty) return _manualBaseUrl;
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  static const String tokenKey = 'access_token';
  static const int defaultPageSize = 10;
}
