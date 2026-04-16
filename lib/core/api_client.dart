import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  late Dio dio;

  ApiClient._init() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:8000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // TODO: Add Interceptor to attach Sanctum Token from Secure Storage
    // For now, if you are testing without login, you might need to 
    // disable 'auth:sanctum' in Laravel or use a hardcoded token.
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer \$token';
  }
}
