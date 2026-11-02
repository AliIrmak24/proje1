import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;

  AuthProvider({required this.apiClient});

  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;

  // Profil bilgilerini yerel depolamaya kaydet
  Future<void> _saveLocalProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user_profile', json.encode(user.toJson()));
    } catch (_) {}
  }

  // Yerel depolamadan kullanıcı profilini oku
  Future<UserModel?> _loadLocalProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('saved_user_profile');
      if (userStr != null && userStr.isNotEmpty) {
        final Map<String, dynamic> data = json.decode(userStr);
        return UserModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _setCurrentUser(UserModel user) async {
    _currentUser = user;
    _isAuthenticated = true;
    await _saveLocalProfile(user);
    notifyListeners();
  }

  // Profil bilgilerini backend'den (/api/users/me) çek (Bağlantı yoksa yereli koru)
  Future<void> fetchUserProfile() async {
    try {
      final data = await apiClient.get('/api/users/me');
      await _setCurrentUser(UserModel.fromJson(data as Map<String, dynamic>));
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clearSession();
      }
    } on ConnectionException {
      // Çevrimdışı / Sunucu kapalı modunda mevcut profili bozma
      _isAuthenticated = _currentUser != null;
      notifyListeners();
    }
  }

  // Oyun etkinliğinin XP'sini sunucudan al; kazanılan XP'yi döndürür
  Future<int> awardActivityXp(String activity, int correctAnswers) async {
    if (_currentUser == null) return 0;

    try {
      final res = await apiClient.post('/api/quiz/activity', {
        'activity': activity,
        'correct_answers': correctAnswers,
      });
      await applyXpResult(res as Map<String, dynamic>);
      return (res['earned_xp'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  // Sunucunun döndürdüğü güncel XP ve seviyeyi profile işle
  Future<void> applyXpResult(Map<String, dynamic> result) async {
    if (_currentUser == null) return;
    await _setCurrentUser(_currentUser!.copyWith(
      xp: (result['total_xp'] as num).toInt(),
      level: (result['current_level'] as num).toInt(),
    ));
  }

  // Giriş Yap (Login)
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.post('/api/users/login', {
        'username': username,
        'password': password,
      });

      await TokenStorage.write(response['access_token'] as String);
      await _setCurrentUser(UserModel.fromJson(response['user'] as Map<String, dynamic>));
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kayıt Ol (Register)
  Future<bool> register(String email, String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiClient.post('/api/users/register', {
        'email': email,
        'username': username,
        'password': password,
      });

      return await login(username, password);
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Profil bilgilerini güncelle
  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    String? bio,
    String? language,
    String? cefrLevel,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (bio != null) updateData['bio'] = bio;
      if (language != null) updateData['language'] = language;
      if (cefrLevel != null) updateData['cefr_level'] = cefrLevel;

      final response = await apiClient.put('/api/users/me', updateData);
      await _setCurrentUser(UserModel.fromJson(response as Map<String, dynamic>));
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Şifre değiştir
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiClient.post('/api/users/change-password', {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      // Eski jetonlar geçersizleştiği için bu cihazın jetonu yenilenir
      await TokenStorage.write(response['access_token'] as String);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hesabı kalıcı olarak sil
  Future<bool> deleteAccount(String password) async {
    _error = null;
    try {
      await apiClient.delete('/api/users/me', body: {'password': password});
      await _clearSession();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await TokenStorage.clear();
    await prefs.remove('saved_user_profile');
    await prefs.remove('placement_prompted');
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Çıkış Yap (Logout)
  Future<void> logout() async {
    try {
      await apiClient.post('/api/users/logout', {});
    } catch (_) {
      // Sunucuya ulaşılamasa da bu cihazdaki oturum kapatılır
    }
    await _clearSession();
  }

  // Uygulama açılışında oturum kontrolü
  Future<void> checkAuth() async {
    final token = await TokenStorage.read();

    if (token != null && token.isNotEmpty) {
      // Daha önce giriş yapmış kullanıcı
      final localProfile = await _loadLocalProfile();
      if (localProfile != null) {
        _currentUser = localProfile;
        _isAuthenticated = true;
        notifyListeners();
      }

      await fetchUserProfile();
    } else {
      // İlk kez açılış veya çıkış yapılmış durum: Giriş/Kayıt ekranı açılmalı
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    }
  }
}
