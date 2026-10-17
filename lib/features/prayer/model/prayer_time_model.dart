class PrayerTimeModel {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String date;
  final String hijriDate;

  const PrayerTimeModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.hijriDate,
  });

  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    final timings = json['data']['timings'] as Map<String, dynamic>;
    final dateData = json['data']['date'];
    final gregorian = dateData['gregorian'];
    final hijri = dateData['hijri'];

    return PrayerTimeModel(
      fajr: _cleanTime(timings['Fajr'] ?? ''),
      sunrise: _cleanTime(timings['Sunrise'] ?? ''),
      dhuhr: _cleanTime(timings['Dhuhr'] ?? ''),
      asr: _cleanTime(timings['Asr'] ?? ''),
      maghrib: _cleanTime(timings['Maghrib'] ?? ''),
      isha: _cleanTime(timings['Isha'] ?? ''),
      date: gregorian['date'] ?? '',
      hijriDate:
          '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH',
    );
  }

  /// Remove timezone offset like "(+06)" from time strings
  static String _cleanTime(String time) {
    return time.split(' ').first;
  }

  /// Convert "HH:mm" string to DateTime (today's date)
  DateTime toDateTime(String timeStr) {
    final parts = timeStr.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// All 5 prayer times as a Map
  Map<String, String> get allPrayers => {
        'Fajr': fajr,
        'Dhuhr': dhuhr,
        'Asr': asr,
        'Maghrib': maghrib,
        'Isha': isha,
      };

  Map<String, dynamic> toJson() => {
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'date': date,
        'hijriDate': hijriDate,
      };
}
