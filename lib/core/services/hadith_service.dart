import 'package:dio/dio.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/features/hadith/model/hadith_model.dart';

class HadithService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.hadithApiBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static const List<String> _books = [
    'bukhari',
    'muslim',
    'abu-daud',
    'tirmidzi',
    'nasai',
  ];

  /// Fetch a random hadith from a random book
  static Future<HadithModel?> fetchRandom() async {
    try {
      final book = _books[DateTime.now().millisecond % _books.length];
      final hadithNumber = (DateTime.now().millisecondsSinceEpoch % 100) + 1;

      final response = await _dio.get(
        '/books/$book',
        queryParameters: {
          'range': '$hadithNumber-$hadithNumber',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final hadiths = data['data']?['hadiths'] as List?;
        if (hadiths != null && hadiths.isNotEmpty) {
          return HadithModel(
            text: hadiths.first['arab'] ?? '',
            textBengali: hadiths.first['id'] ?? '',
            book: book,
            number: hadithNumber,
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Hadith API error: $e');
    }
    return null;
  }
}
