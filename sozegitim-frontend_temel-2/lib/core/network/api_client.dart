import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/token_storage.dart';

/// Sunucunun verdiği hata yanıtı.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Hiçbir sunucu adresine ulaşılamadı.
class ConnectionException implements Exception {
  @override
  String toString() => 'Sunucuya bağlanılamadı. Lütfen sunucunun açık ve aynı ağda olduğunu kontrol edin.';
}

class ApiClient {
  // Yayın derlemesinde: flutter build apk --dart-define=API_BASE_URL=https://alan-adi
  static const String configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String? customBaseUrl;
  static String? _workingBaseUrl;
  static const Duration requestTimeout = Duration(seconds: 12);
  static const Duration probeTimeout = Duration(milliseconds: 2500);

  static const List<String> _lanCandidates = [
    'http://192.168.1.104:8000',
    'http://192.168.1.105:8000',
    'http://192.168.1.103:8000',
    'http://192.168.1.102:8000',
    'http://192.168.1.106:8000',
  ];

  static Future<void> initCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('custom_server_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        customBaseUrl = savedUrl;
        _workingBaseUrl = savedUrl;
      }
    } catch (_) {}
  }

  static Future<void> saveCustomBaseUrl(String? url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url == null || url.trim().isEmpty) {
        customBaseUrl = null;
        _workingBaseUrl = null;
        await prefs.remove('custom_server_url');
      } else {
        String cleanUrl = url.trim();
        if (cleanUrl.endsWith('/')) {
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
        }
        if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
          cleanUrl = 'http://$cleanUrl';
        }
        customBaseUrl = cleanUrl;
        _workingBaseUrl = cleanUrl;
        await prefs.setString('custom_server_url', cleanUrl);
      }
    } catch (_) {}
  }

  static List<String> get candidateBaseUrls {
    if (configuredBaseUrl.isNotEmpty) return const [configuredBaseUrl];

    final candidates = <String>{
      ?customBaseUrl,
      ?_workingBaseUrl,
    };

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      candidates.addAll(['http://$host:8000', 'http://localhost:8000', 'http://127.0.0.1:8000']);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      candidates.addAll(_lanCandidates);
      candidates.addAll(['http://10.0.2.2:8000', 'http://localhost:8000', 'http://127.0.0.1:8000']);
    } else {
      candidates.addAll(['http://localhost:8000', 'http://127.0.0.1:8000']);
      candidates.addAll(_lanCandidates);
    }
    return candidates.toList();
  }

  String get baseUrl {
    if (_workingBaseUrl != null && _workingBaseUrl!.isNotEmpty) {
      return _workingBaseUrl!;
    }
    return candidateBaseUrls.first;
  }

  ApiClient();

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, Map<String, dynamic> body) => _send('POST', path, body: body);

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send('PUT', path, body: body);

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) => _send('DELETE', path, body: body);

  // Adayları sırayla dener; yanıt veren ilk adres sonraki isteklerde önce kullanılır
  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? body}) async {
    final candidates = candidateBaseUrls;
    final token = await TokenStorage.read();

    for (final base in candidates) {
      final timeout = (base == _workingBaseUrl || candidates.length == 1) ? requestTimeout : probeTimeout;
      final request = http.Request(method, Uri.parse('$base$path'));
      request.headers['Content-Type'] = 'application/json; charset=UTF-8';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (body != null) {
        request.body = json.encode(body);
      }

      final http.Response response;
      try {
        response = await request.send().then(http.Response.fromStream).timeout(timeout);
      } on TimeoutException {
        continue;
      } on http.ClientException {
        continue;
      }

      _workingBaseUrl = base;
      final text = utf8.decode(response.bodyBytes);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return text.isEmpty ? <String, dynamic>{} : json.decode(text);
      }
      throw ApiException(response.statusCode, _errorMessage(text, response.statusCode));
    }
    throw ConnectionException();
  }

  String _errorMessage(String text, int statusCode) {
    try {
      final detail = (json.decode(text) as Map<String, dynamic>)['detail'];
      if (detail is String) return detail;
    } catch (_) {}
    return 'İşlem başarısız oldu ($statusCode).';
  }
}
