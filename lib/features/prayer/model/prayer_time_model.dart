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
    if (json.containsKey('data')) {
      final data = json['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final dateData = data['date'];
      final gregorian = dateData['gregorian'];
      final hijri = dateData['hijri'];

      return PrayerTimeModel(
        fajr: _cleanTime(timings['Fajr']?.toString() ?? ''),
        sunrise: _cleanTime(timings['Sunrise']?.toString() ?? ''),
        dhuhr: _cleanTime(timings['Dhuhr']?.toString() ?? ''),
        asr: _cleanTime(timings['Asr']?.toString() ?? ''),
        maghrib: _cleanTime(timings['Maghrib']?.toString() ?? ''),
        isha: _cleanTime(timings['Isha']?.toString() ?? ''),
        date: gregorian['date']?.toString() ?? '',
        hijriDate:
            '${hijri['day']} ${hijri['month']['en']} ${hijri['year']} AH',
      );
    } else {
      return PrayerTimeModel(
        fajr: _cleanTime(json['fajr']?.toString() ?? ''),
        sunrise: _cleanTime(json['sunrise']?.toString() ?? ''),
        dhuhr: _cleanTime(json['dhuhr']?.toString() ?? ''),
        asr: _cleanTime(json['asr']?.toString() ?? ''),
        maghrib: _cleanTime(json['maghrib']?.toString() ?? ''),
        isha: _cleanTime(json['isha']?.toString() ?? ''),
        date: json['date']?.toString() ?? '',
        hijriDate: json['hijriDate']?.toString() ?? '',
      );
    }
  }

  /// Remove timezone offset like "(+06)" from time strings
  static String _cleanTime(String time) {
    if (time.isEmpty) return '00:00';
    return time.split(' ').first.trim();
  }

  /// Convert "HH:mm" string to DateTime (today's date)
  DateTime toDateTime(String timeStr) {
    final clean = _cleanTime(timeStr);
    final parts = clean.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
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
