import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oturum jetonunu cihazın güvenli deposunda tutar.
class TokenStorage {
  TokenStorage._();

  static const _key = 'auth_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String?> read() async {
    final token = await _storage.read(key: _key);
    if (token != null) return token;

    // Eski sürümlerde jeton düz metin saklanıyordu; bir kez taşınır
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_key);
    if (legacyToken == null) return null;
    await prefs.remove(_key);
    await _storage.write(key: _key, value: legacyToken);
    return legacyToken;
  }

  static Future<void> write(String token) => _storage.write(key: _key, value: token);

  static Future<void> clear() => _storage.delete(key: _key);
}
