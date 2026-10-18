import 'dart:math';
import 'package:dio/dio.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/features/hadith/model/hadith_model.dart';

class HadithService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.hadithApiBase,
    connectTimeout: const Duration(seconds: 4),
    receiveTimeout: const Duration(seconds: 4),
  ));

  /// Curated authentic Hadiths (always available offline)
  static const List<HadithModel> _curatedHadiths = [
    HadithModel(
      book: 'bukhari',
      number: 1,
      text:
          'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
      textBengali:
          'রাসূলুল্লাহ সাল্লাল্লাহু আলাইহি ওয়াসাল্লাম বলেছেনঃ সকল কাজের ফলাফল নিয়তের উপর নির্ভরশীল। আর প্রত্যেক ব্যক্তি যা নিয়ত করবে তাই পাবে।',
    ),
    HadithModel(
      book: 'bukhari',
      number: 10,
      text: 'الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ',
      textBengali:
          'রাসূলুল্লাহ সাল্লাল্লাহু আলাইহি ওয়াসাল্লাম বলেছেনঃ মুসলমান তো সেই ব্যক্তি যার জিহ্বা ও হাত থেকে অন্য মুসলমান নিরাপদ থাকে।',
    ),
    HadithModel(
      book: 'bukhari',
      number: 13,
      text:
          'لاَ يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ',
      textBengali:
          'রাসূলুল্লাহ সাল্লাল্লাহু আলাইহি ওয়াসাল্লাম বলেছেনঃ তোমাদের মধ্যে কেউ ততক্ষণ পর্যন্ত খাঁটি মুমিন হতে পারবে না, যতক্ষণ না সে তার ভাইয়ের জন্য তা ভালোবাসে যা সে নিজের জন্য ভালোবাসে।',
    ),
    HadithModel(
      book: 'muslim',
      number: 223,
      text: 'الطَّهُورُ شَطْرُ الإِيمَانِ وَالْحَمْدُ لِلَّهِ تَمْلأُ الْمِيزَانَ',
      textBengali:
          'রাসূলুল্লাহ সাল্লাল্লাহু আলাইহি ওয়াসাল্লাম বলেছেনঃ পবিত্রতা ঈমানের অর্ধেক এবং ‘আলহামদুলিল্লাহ’ মিযান বা পরিমাপের পাল্লা পূর্ণ করে দেয়।',
    ),
    HadithModel(
      book: 'bukhari',
      number: 5027,
      text: 'خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ',
      textBengali:
          'রাসূলুল্লাহ সাল্লাল্লাহু আলাইহি ওয়াসাল্লাম বলেছেনঃ তোমাদের মধ্যে সর্বোত্তম ব্যক্তি সে, যে নিজে কুরআন শিখে এবং অন্যকে তা শেখায়।',
    ),
    HadithModel(
      book: 'tirmidzi',
      number: 1956,
      text: 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
      textBengali:
          'রাসূলুল্লাহ সাল্লাল্লাহু আলাইহি ওয়াসাল্লাম বলেছেনঃ তোমার ভাইয়ের মুখের দিকে তাকিয়ে তোমার মৃদু হাসাটাও একটি সাদাকাহ।',
    ),
    HadithModel(
      book: 'muslim',
      number: 2564,
      text:
          'إِنَّ اللَّهَ لاَ يَنْظُرُ إِلَى صُوَرِكُمْ وَأَمْوَالِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ وَأَعْمَالِكُمْ',
      textBengali:
          'নিশ্চয়ই আল্লাহ তোমাদের চেহারা ও ধন-সম্পদের দিকে তাকান না, বরং তিনি তাকান তোমাদের অন্তর ও আমলের দিকে।',
    ),
    HadithModel(
      book: 'bukhari',
      number: 6011,
      text:
          'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ',
      textBengali:
          'যে ব্যক্তি আল্লাহ ও শেষ দিবসের প্রতি বিশ্বাস রাখে, সে যেন ভালো কথা বলে অথবা চুপ থাকে।',
    ),
  ];

  /// Fetch a random hadith from CDN API, falling back to curated list
  static Future<HadithModel> fetchRandom() async {
    final random = Random();
    final hadithNumber = random.nextInt(100) + 1;

    try {
      final response = await _dio.get(
        '/editions/ben-bukhari/$hadithNumber.json',
      );

      if (response.statusCode == 200 && response.data != null) {
        final hadiths = response.data['hadiths'] as List?;
        if (hadiths != null && hadiths.isNotEmpty) {
          final first = hadiths.first;
          final rawText = first['text']?.toString() ?? '';

          // Optionally fetch Arabic text
          String arabicText = '';
          try {
            final araResp = await _dio.get(
              '/editions/ara-bukhari1/$hadithNumber.json',
            );
            if (araResp.statusCode == 200) {
              final araList = araResp.data['hadiths'] as List?;
              if (araList != null && araList.isNotEmpty) {
                arabicText = araList.first['text']?.toString() ?? '';
              }
            }
          } catch (_) {}

          return HadithModel(
            text: arabicText.isNotEmpty
                ? arabicText
                : 'قال رسول الله صلى الله عليه وسلم',
            textBengali: rawText,
            book: 'bukhari',
            number: hadithNumber,
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Hadith API error, using curated offline fallback: $e');
    }

    // Curated offline fallback (never fails!)
    return _curatedHadiths[random.nextInt(_curatedHadiths.length)];
  }
}
