import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._init();
  late Dio dio;

  ApiClient._init() {
    dio = Dio(
      BaseOptions(
        // Sesuaikan dengan IP Laravel kamu
        // 10.0.2.2 adalah localhost untuk Android Emulator
        baseUrl: 'http://10.0.2.2:8000/api',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Bisa tambahkan Interceptor untuk Token Auth di sini nanti
  }
}
