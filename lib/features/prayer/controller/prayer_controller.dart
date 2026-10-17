import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/core/services/hadith_service.dart';
import 'package:namaz_alert/core/services/prayer_service.dart';
import 'package:namaz_alert/features/hadith/model/hadith_model.dart';
import 'package:namaz_alert/features/prayer/model/prayer_time_model.dart';

class PrayerController extends GetxController {
  final _storage = GetStorage();

  final Rx<PrayerTimeModel?> todayPrayers = Rx<PrayerTimeModel?>(null);
  final Rx<HadithModel?> todayHadith = Rx<HadithModel?>(null);
  final RxBool isLoadingPrayers = false.obs;
  final RxBool isLoadingHadith = false.obs;
  final RxString city = AppConstants.defaultCity.obs;
  final RxString country = AppConstants.defaultCountry.obs;
  final RxString nextPrayerName = ''.obs;
  final RxString nextPrayerTime = ''.obs;
  final RxString countdown = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTodayPrayers();
    fetchTodayHadith();
    // Update countdown every minute
    ever(todayPrayers, (_) => _updateNextPrayer());
  }

  Future<void> fetchTodayPrayers({String? cityOverride, String? countryOverride}) async {
    isLoadingPrayers.value = true;

    try {
      final result = await PrayerService.fetchByCity(
        city: cityOverride ?? city.value,
        country: countryOverride ?? country.value,
      );

      if (result != null) {
        todayPrayers.value = result;
        _saveToStorage(result);
        _updateNextPrayer();
      }
    } finally {
      isLoadingPrayers.value = false;
    }
  }

  Future<void> fetchTodayHadith() async {
    isLoadingHadith.value = true;
    try {
      final hadith = await HadithService.fetchRandom();
      todayHadith.value = hadith;
    } finally {
      isLoadingHadith.value = false;
    }
  }

  void _updateNextPrayer() {
    final prayers = todayPrayers.value;
    if (prayers == null) return;

    final now = DateTime.now();
    String? name;
    DateTime? time;

    for (final entry in prayers.allPrayers.entries) {
      final dt = prayers.toDateTime(entry.value);
      if (dt.isAfter(now)) {
        name = entry.key;
        time = dt;
        break;
      }
    }

    if (name != null && time != null) {
      nextPrayerName.value = name;
      nextPrayerTime.value = _formatTime(time);
      final diff = time.difference(now);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      countdown.value = h > 0 ? '${h}h ${m}m remaining' : '${m}m remaining';
    } else {
      nextPrayerName.value = 'Fajr';
      nextPrayerTime.value = prayers.fajr;
      countdown.value = 'Tomorrow';
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  void _saveToStorage(PrayerTimeModel model) {
    _storage.write(AppConstants.keyPrayerTimes, model.toJson());
    _storage.write(
        AppConstants.keyLastPrayerFetch, DateTime.now().toIso8601String());
  }
}
