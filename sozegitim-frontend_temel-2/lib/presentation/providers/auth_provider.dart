import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;

  AuthProvider({required this.apiClient});

  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  // Login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // --- TEST İÇİN ADMIN HESABI (ARKA KAPI) ---
    if (username == 'admin' && password == '1234') {
      final prefs = await SharedPreferences.getInstance();
      // Test için sahte bir bilet (token) oluşturuyoruz
      await prefs.setString('auth_token', 'test_admin_token_999');
      _isAuthenticated = true;
      _isLoading = false;
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

  // Register
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

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _isAuthenticated = false;
    notifyListeners();
  }

  // Check auth status when app starts
  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      _isAuthenticated = true;
      notifyListeners();
    }
  }
}