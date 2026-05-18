import 'package:dio/dio.dart';
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

  AuthProvider() {
    // Register global unauthorized callback
    _apiClient.onUnauthorized = () {
      logout(callServer: false); // Logout without calling server to avoid 401 loop
    };
  }

  Future<void> checkLoginStatus() async {
    final token = await _storage.read(key: 'auth_token');
    
    if (token != null) {
      _apiClient.setToken(token);
      // Optional: Fetch user profile to verify token is still valid
      try {
        final response = await _apiClient.dio.get('/me');
        if (response.statusCode == 200) {
          _user = UserModel.fromJson(response.data['data']);
          _isLoggedIn = true;
          debugPrint('✅ Auto-login berhasil untuk: ${_user?.name}');
        } else {
          await logout(callServer: false);
        }
      } catch (e) {
        debugPrint('⚠️ Gagal memverifikasi token saat startup: $e');
        // If it's a 401, logout will be handled by interceptor
        // For connection errors, we might want to keep the session
        if (e is DioException && e.response?.statusCode == 401) {
           await logout(callServer: false);
        } else {
           // For other errors, assume token is still valid but server is offline
           _isLoggedIn = true; 
        }
      }
    } else {
      _isLoggedIn = false;
      _user = null;
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
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
        return null; // Success
      }
      return 'Email atau password salah';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      
      if (e is DioException) {
        if (e.response?.statusCode == 422) {
          return e.response?.data?['message'] ?? 'Data tidak valid';
        }
        return 'Gagal terhubung ke server. Periksa koneksi Anda.';
      }
      return 'Terjadi kesalahan sistem';
    }
  }

  Future<void> logout({bool callServer = true}) async {
    if (callServer && _isLoggedIn) {
      try {
        debugPrint('📡 Mencoba logout dari server...');
        await _apiClient.dio.post('/logout');
      } catch (e) {
        debugPrint('⚠️ Logout server gagal (mungkin token sudah expired): $e');
      }
    }

    await _storage.delete(key: 'auth_token');
    _apiClient.clearToken();
    _isLoggedIn = false;
    _user = null;
    debugPrint('🚪 Logout berhasil, sesi dibersihkan.');
    notifyListeners();
  }
}
