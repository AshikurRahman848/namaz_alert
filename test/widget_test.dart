import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_alert/core/constants/app_constants.dart';
import 'package:namaz_alert/features/group/model/group_model.dart';
import 'package:namaz_alert/features/prayer/model/prayer_time_model.dart';

void main() {
  test('PrayerTimeModel time parsing test', () {
    const rawTimes = {
      'data': {
        'timings': {
          'Fajr': '04:45 (+06)',
          'Sunrise': '05:50 (+06)',
          'Dhuhr': '11:45 (+06)',
          'Asr': '15:10 (+06)',
          'Maghrib': '17:35 (+06)',
          'Isha': '18:50 (+06)',
        },
        'date': {
          'gregorian': {'date': '18-10-2026'},
          'hijri': {
            'day': '07',
            'month': {'en': 'Jumada al-awwal'},
            'year': '1448',
          },
        },
      },
    };

    final model = PrayerTimeModel.fromJson(rawTimes);
    expect(model.fajr, '04:45');
    expect(model.dhuhr, '11:45');
    expect(model.asr, '15:10');
    expect(model.maghrib, '17:35');
    expect(model.isha, '18:50');
  });

  test('GroupModel creation and admin role test', () {
    final group = GroupModel.create(
      name: 'BrainStation Namaz Group',
      adminUid: 'uid_123',
      adminName: 'Admin User',
      adminEmail: 'admin@test.com',
      city: 'Dhaka',
      country: 'Bangladesh',
      offsetMinutes: 10,
    );

    expect(group.name, 'BrainStation Namaz Group');
    expect(group.isAdmin('uid_123'), true);
    expect(group.isMember('uid_123'), true);
    expect(group.inviteCode.startsWith('NAM-'), true);
    expect(group.notificationSettings.offsetMinutes, 10);
  });
}
