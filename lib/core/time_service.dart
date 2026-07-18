import 'package:flutter/foundation.dart';
import 'api_client.dart';

class TimeService {
  static final TimeService instance = TimeService._init();

  DateTime? _serverSnapshot;
  DateTime? _deviceSnapshot;
  String? _serverTimezone;

  TimeService._init();

  bool get isInitialized => _serverSnapshot != null;

  Duration get _elapsedSinceSnapshot {
    if (_deviceSnapshot == null) return Duration.zero;
    return DateTime.now().difference(_deviceSnapshot!);
  }

  Future<void> init() async {
    try {
      final response = await ApiClient.instance.dio.get('/server-time');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final serverStr = response.data['data']['server_time'] as String;
        _serverTimezone = response.data['data']['timezone'] as String?;

        _serverSnapshot = DateTime.parse(serverStr);
        _deviceSnapshot = DateTime.now();

        debugPrint('⏰ TimeService: server snapshot=$_serverSnapshot | timezone=$_serverTimezone');
      }
    } catch (e) {
      debugPrint('⏰ TimeService: init gagal — $e');
    }
  }

  /// Mengembalikan current time berdasarkan server snapshot + elapsed device time
  DateTime now() {
    if (_serverSnapshot != null) {
      return _serverSnapshot!.add(_elapsedSinceSnapshot);
    }
    return DateTime.now();
  }
}
