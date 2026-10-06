import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
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

  // Profil bilgilerini backend'den (/api/users/me) çek (Bağlantı yoksa yereli koru)
  Future<void> fetchUserProfile() async {
    try {
      final data = await apiClient.get('/api/users/me');
      if (data is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(data);
        _isAuthenticated = true;
        await _saveLocalProfile(_currentUser!);
        notifyListeners();
      }
    } catch (e) {
      // Eğer token geçersiz (401) ise oturumu kapat; ağ hatası ise çevrimdışı devam et
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        await logout();
      } else {
        // Çevrimdışı / Sunucu kapalı modunda mevcut profili bozma
        _isAuthenticated = true;
        notifyListeners();
      }
    }
  }

  // Yerel XP ve Seviye artırma (Duolingo tarzı çevrimdışı anında ilerleme)
  Future<void> addXp(int xpToAdd) async {
    if (_currentUser == null) return;

    final newXp = (_currentUser!.xp) + xpToAdd;
    final newLevel = (newXp ~/ 100) + 1;

    _currentUser = _currentUser!.copyWith(
      xp: newXp,
      level: newLevel,
    );
    await _saveLocalProfile(_currentUser!);
    notifyListeners();

    // Arka planda sunucuya da iletmeyi dene (isteğe bağlı, hata verirse yut)
    try {
      await apiClient.post('/api/quiz/submit', {
        'score': xpToAdd ~/ 10,
        'total_questions': xpToAdd ~/ 10,
      });
    } catch (_) {}
  }

  // Giriş Yap (Login)
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Test / Hızlı admin hesabı (Her zaman çevrimdışı da geçerli)
    if (username.toLowerCase() == 'admin' && password == '1234') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'test_admin_token_999');
      _currentUser = const UserModel(
        id: 1,
        username: 'Admin',
        fullName: 'Ali Irmak',
        email: 'admin@sozegitim.com',
        phoneNumber: '+905551234567',
        bio: 'SözEğitim İngilizce Öğrencisi',
        xp: 1300,
        level: 14,
        language: 'tr',
      );
      _isAuthenticated = true;
      _isLoading = false;
      await _saveLocalProfile(_currentUser!);
      notifyListeners();
      return true;
    }

    try {
      final response = await apiClient.post('/api/users/login', {
        'username': username,
        'password': password,
      });

      final token = response['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        _isAuthenticated = true;

        if (response['user'] != null && response['user'] is Map<String, dynamic>) {
          _currentUser = UserModel.fromJson(response['user']);
          await _saveLocalProfile(_currentUser!);
        } else {
          await fetchUserProfile();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
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
      _error = e.toString().replaceAll('Exception: ', '');
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
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 1. Önce yerelde hemen güncelle (Sıfır gecikme)
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        username: username ?? _currentUser!.username,
        email: email ?? _currentUser!.email,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        bio: bio ?? _currentUser!.bio,
        language: language ?? _currentUser!.language,
      );
      await _saveLocalProfile(_currentUser!);
      notifyListeners();
    }

    // 2. Sunucu açıksa sunucuya da gönder
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (bio != null) updateData['bio'] = bio;
      if (language != null) updateData['language'] = language;

      final response = await apiClient.put('/api/users/me', updateData);
      if (response is Map<String, dynamic>) {
        _currentUser = UserModel.fromJson(response);
        await _saveLocalProfile(_currentUser!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Sunucuya ulaşılamasa bile yerelde kaydedildiği için kullanıcıya başarılı hissettir
      return true;
    }
  }

  // Şifre değiştir
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiClient.post('/api/users/change-password', {
        'old_password': oldPassword,
        'new_password': newPassword,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Çıkış Yap (Logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('saved_user_profile');
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Uygulama açılışında oturum kontrolü
  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      // Daha önce giriş yapmış kullanıcı
      final localProfile = await _loadLocalProfile();
      if (localProfile != null) {
        _currentUser = localProfile;
        _isAuthenticated = true;
        notifyListeners();
      } else {
        _currentUser = const UserModel(
          id: 1,
          username: 'Admin',
          fullName: 'Ali Irmak',
          email: 'admin@sozegitim.com',
          xp: 1300,
          level: 14,
        );
        _isAuthenticated = true;
        notifyListeners();
      }

      if (token != 'test_admin_token_999') {
        fetchUserProfile();
      }
    } else {
      // İlk kez açılış veya çıkış yapılmış durum: Giriş/Kayıt ekranı açılmalı
      _isAuthenticated = false;
      _currentUser = null;
      notifyListeners();
    }
  }
}