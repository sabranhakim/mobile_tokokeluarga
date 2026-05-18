import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  late Dio dio;
  VoidCallback? onUnauthorized;

  ApiClient._init() {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.38.175.163:8000/api/v1',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Logging Interceptor to see network traffic in Debug Console
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('🌐 API_LOG: $obj'),
    ));

    // Error Handling Interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) {
        String message = '';
        final statusCode = e.response?.statusCode;
        
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message = 'Koneksi ke server terputus (Timeout). Periksa sinyal Anda.';
            break;
          case DioExceptionType.badResponse:
            if (statusCode == 401) {
              message = 'Sesi telah berakhir. Silakan login kembali.';
              onUnauthorized?.call();
            } else if (statusCode == 500) {
              message = 'Terjadi kesalahan pada server (Internal Server Error).';
            } else {
              message = e.response?.data?['message'] ?? 'Terjadi kesalahan pada server.';
            }
            break;
          case DioExceptionType.connectionError:
            message = 'Gagal terhubung ke server. Pastikan server aktif.';
            break;
          default:
            message = 'Terjadi kesalahan jaringan yang tidak terduga.';
        }

        // Wrap the original error with a cleaner message if possible
        debugPrint('❌ API_ERROR: $message ($statusCode)');
        return handler.next(e);
      },
    ));
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}
