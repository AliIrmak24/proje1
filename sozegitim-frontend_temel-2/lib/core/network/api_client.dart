import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static String? customBaseUrl;
  static String? _workingBaseUrl;
  static const Duration requestTimeout = Duration(seconds: 12);
  static const Duration probeTimeout = Duration(milliseconds: 2500);

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
    final list = <String>[];
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      list.add(customBaseUrl!);
    }
    if (_workingBaseUrl != null && !list.contains(_workingBaseUrl)) {
      list.add(_workingBaseUrl!);
    }

    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      final h1 = 'http://$host:8000';
      if (!list.contains(h1)) list.add(h1);
      if (!list.contains('http://localhost:8000')) list.add('http://localhost:8000');
      if (!list.contains('http://127.0.0.1:8000')) list.add('http://127.0.0.1:8000');
      if (!list.contains('http://192.168.1.104:8000')) list.add('http://192.168.1.104:8000');
      if (!list.contains('http://192.168.1.105:8000')) list.add('http://192.168.1.105:8000');
      if (!list.contains('http://192.168.1.103:8000')) list.add('http://192.168.1.103:8000');
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidCandidates = [
        'http://192.168.1.104:8000',
        'http://192.168.1.105:8000',
        'http://192.168.1.103:8000',
        'http://192.168.1.102:8000',
        'http://192.168.1.106:8000',
        'http://10.0.2.2:8000',
        'http://localhost:8000',
        'http://127.0.0.1:8000',
      ];
      for (final c in androidCandidates) {
        if (!list.contains(c)) list.add(c);
      }
    } else {
      final defaultCandidates = [
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://192.168.1.104:8000',
        'http://192.168.1.105:8000',
      ];
      for (final c in defaultCandidates) {
        if (!list.contains(c)) list.add(c);
      }
    }
    return list;
  }

  String get baseUrl {
    if (_workingBaseUrl != null && _workingBaseUrl!.isNotEmpty) {
      return _workingBaseUrl!;
    }
    return candidateBaseUrls.first;
  }

  ApiClient();

  // Token ve başlıkları hazırla
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET Request (Otomatik çoklu IP adayı deneme ve kilitleme)
  Future<dynamic> get(String path) async {
    final candidates = candidateBaseUrls;
    dynamic lastError;

    for (final base in candidates) {
      try {
        final headers = await _getHeaders();
        final url = Uri.parse('$base$path');
        final timeout = (base == _workingBaseUrl || candidates.length == 1) ? requestTimeout : probeTimeout;
        final response = await http.get(url, headers: headers).timeout(timeout);

        if (response.statusCode == 200) {
          _workingBaseUrl = base;
          return json.decode(utf8.decode(response.bodyBytes));
        } else if (response.statusCode == 404) {
          _workingBaseUrl = base;
          throw Exception('Not found (404).');
        } else {
          _workingBaseUrl = base;
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e;
        final eStr = e.toString();
        if (eStr.contains('Not found (404)') || eStr.contains('Server error:')) {
          rethrow;
        }
        // Bağlantı hatası durumunda bir sonraki adayı dene
        continue;
      }
    }
    throw Exception('Sunucuya bağlanılamadı (Connection error). Lütfen sunucunun açık ve aynı ağda olduğunu kontrol edin: $lastError');
  }

  // POST Request
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final candidates = candidateBaseUrls;
    dynamic lastError;

    for (final base in candidates) {
      try {
        final headers = await _getHeaders();
        final url = Uri.parse('$base$path');
        final timeout = (base == _workingBaseUrl || candidates.length == 1) ? requestTimeout : probeTimeout;
        final response = await http.post(
          url,
          headers: headers,
          body: json.encode(body),
        ).timeout(timeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          _workingBaseUrl = base;
          return json.decode(utf8.decode(response.bodyBytes));
        } else {
          _workingBaseUrl = base;
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(errorData['detail'] ?? 'Operation failed: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e;
        final eStr = e.toString();
        if (eStr.contains('Operation failed:') || 
            (!eStr.contains('Connection error') && 
             !eStr.contains('SocketException') && 
             !eStr.contains('TimeoutException') && 
             !eStr.contains('Failed host lookup') && 
             !eStr.contains('Connection refused') && 
             !eStr.contains('ClientException'))) {
          // Bu bir HTTP hata yanıtıdır (örn 401 şifre yanlış), başka aday denemeye gerek yok
          rethrow;
        }
        continue;
      }
    }
    throw Exception('Sunucuya bağlanılamadı (Connection error): $lastError');
  }

  // PUT Request
  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final candidates = candidateBaseUrls;
    dynamic lastError;

    for (final base in candidates) {
      try {
        final headers = await _getHeaders();
        final url = Uri.parse('$base$path');
        final timeout = (base == _workingBaseUrl || candidates.length == 1) ? requestTimeout : probeTimeout;
        final response = await http.put(
          url,
          headers: headers,
          body: json.encode(body),
        ).timeout(timeout);

        if (response.statusCode == 200 || response.statusCode == 201) {
          _workingBaseUrl = base;
          return json.decode(utf8.decode(response.bodyBytes));
        } else {
          _workingBaseUrl = base;
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(errorData['detail'] ?? 'Operation failed: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e;
        final eStr = e.toString();
        if (eStr.contains('Operation failed:') || 
            (!eStr.contains('Connection error') && 
             !eStr.contains('SocketException') && 
             !eStr.contains('TimeoutException') && 
             !eStr.contains('Failed host lookup') && 
             !eStr.contains('Connection refused') && 
             !eStr.contains('ClientException'))) {
          rethrow;
        }
        continue;
      }
    }
    throw Exception('Sunucuya bağlanılamadı (Connection error): $lastError');
  }

  // DELETE Request
  Future<dynamic> delete(String path) async {
    final candidates = candidateBaseUrls;
    dynamic lastError;

    for (final base in candidates) {
      try {
        final headers = await _getHeaders();
        final url = Uri.parse('$base$path');
        final timeout = (base == _workingBaseUrl || candidates.length == 1) ? requestTimeout : probeTimeout;
        final response = await http.delete(url, headers: headers).timeout(timeout);

        if (response.statusCode == 200 || response.statusCode == 204) {
          _workingBaseUrl = base;
          if (response.body.isEmpty) return {};
          return json.decode(utf8.decode(response.bodyBytes));
        } else {
          _workingBaseUrl = base;
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          throw Exception(errorData['detail'] ?? 'Operation failed: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e;
        final eStr = e.toString();
        if (eStr.contains('Operation failed:') || 
            (!eStr.contains('Connection error') && 
             !eStr.contains('SocketException') && 
             !eStr.contains('TimeoutException') && 
             !eStr.contains('Failed host lookup') && 
             !eStr.contains('Connection refused') && 
             !eStr.contains('ClientException'))) {
          rethrow;
        }
        continue;
      }
    }
    throw Exception('Sunucuya bağlanılamadı (Connection error): $lastError');
  }
}