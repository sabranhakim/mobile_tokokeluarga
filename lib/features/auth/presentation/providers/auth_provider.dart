import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/api_client.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiClient = ApiClient.instance;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> checkLoginStatus() async {
    // Menghapus token lama setiap kali aplikasi dimulai agar tidak auto-login
    await _storage.delete(key: 'auth_token');
    _isLoggedIn = false;
    _user = null;
    debugPrint('🔐 Sesi dibersihkan: Pengguna harus login ulang.');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
          'device_name': 'Mobile Device',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        final token = data['token'];
        final userData = data['user'];

        await _storage.write(key: 'auth_token', value: token);
        _apiClient.setToken(token);
        _user = UserModel.fromJson(userData);
        _isLoggedIn = true;

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _isLoggedIn = false;
    _user = null;
    notifyListeners();
  }
}
