import 'package:dio/dio.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/features/prayer/model/prayer_time_model.dart';

class PrayerService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.prayerApiBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Fetch prayer times for a city on a specific date
  static Future<PrayerTimeModel?> fetchByCity({
    required String city,
    required String country,
    int method = AppConstants.defaultMethod,
    DateTime? date,
  }) async {
    try {
      final d = date ?? DateTime.now();
      final dateStr = '${d.day}-${d.month}-${d.year}';

      final response = await _dio.get(
        '/timingsByCity/$dateStr',
        queryParameters: {
          'city': city,
          'country': country,
          'method': method,
        },
      );

      if (response.statusCode == 200) {
        return PrayerTimeModel.fromJson(response.data);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Prayer API error: $e');
    }
    return null;
  }

  /// Fetch prayer times by coordinates (lat/lng)
  static Future<PrayerTimeModel?> fetchByCoordinates({
    required double latitude,
    required double longitude,
    int method = AppConstants.defaultMethod,
    DateTime? date,
  }) async {
    try {
      final d = date ?? DateTime.now();
      final dateStr = '${d.day}-${d.month}-${d.year}';

      final response = await _dio.get(
        '/timings/$dateStr',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'method': method,
        },
      );

      if (response.statusCode == 200) {
        return PrayerTimeModel.fromJson(response.data);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Prayer API error: $e');
    }
    return null;
  }
}
