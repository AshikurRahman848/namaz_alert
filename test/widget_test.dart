import 'package:flutter_test/flutter_test.dart';
import 'package:namaz_alert/features/auth/model/user_model.dart';
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
    expect(group.customPrayerTimes.isEmpty, true);

    final updated = group.copyWith(customPrayerTimes: {'Dhuhr': '13:30'});
    expect(updated.customPrayerTimes['Dhuhr'], '13:30');

    // Test secondary admin promotion
    const newAdmin = GroupMember(
      uid: 'uid_456',
      name: 'Co Admin',
      email: 'coadmin@test.com',
      role: 'admin',
    );
    final groupWithTwoAdmins = group.copyWith(
      members: [...group.members, newAdmin],
    );
    expect(groupWithTwoAdmins.isAdmin('uid_123'), true);
    expect(groupWithTwoAdmins.isPrimaryAdmin('uid_123'), true);
    expect(groupWithTwoAdmins.isAdmin('uid_456'), true);
    expect(groupWithTwoAdmins.isPrimaryAdmin('uid_456'), false);
    expect(groupWithTwoAdmins.isAdmin('stranger'), false);
  });

  test('GroupJoinRequest serialization and model handling', () {
    final req = GroupJoinRequest(
      uid: 'user_456',
      name: 'Test Member',
      email: 'member@test.com',
      requestedAt: DateTime.now(),
    );

    final json = req.toJson();
    final parsed = GroupJoinRequest.fromJson(json);
    expect(parsed.uid, 'user_456');
    expect(parsed.name, 'Test Member');
    expect(parsed.email, 'member@test.com');

    final group = GroupModel.create(
      name: 'Dhaka Mosque Group',
      adminUid: 'admin_1',
      adminName: 'Admin',
      adminEmail: 'admin@test.com',
      city: 'Dhaka',
      country: 'Bangladesh',
    ).copyWith(joinRequests: [parsed]);

    expect(group.joinRequestCount, 1);
    expect(group.isPendingRequest('user_456'), true);
    expect(group.isPendingRequest('unknown_user'), false);
  });

  test('GroupModel.fromJson parses dynamic nested maps without casting error', () {
    final Map<String, dynamic> rawDoc = {
      'id': 'grp-789',
      'name': 'Test Dynamic Group',
      'adminUid': 'adm_1',
      'city': 'Dhaka',
      'country': 'Bangladesh',
      'calculationMethod': 1,
      'inviteCode': 'NAM-TEST',
      'members': <dynamic>[
        <dynamic, dynamic>{
          'uid': 'adm_1',
          'name': 'Admin User',
          'email': 'admin@test.com',
          'role': 'admin',
        }
      ],
      'joinRequests': <dynamic>[
        <dynamic, dynamic>{
          'uid': 'req_1',
          'name': 'Requester',
          'email': 'req@test.com',
          'requestedAt': '2026-11-15T12:00:00.000',
        }
      ],
      'notificationSettings': <dynamic, dynamic>{
        'offsetMinutes': 15,
      },
      'customPrayerTimes': <dynamic, dynamic>{
        'Fajr': '05:00',
      },
    };

    final group = GroupModel.fromJson(rawDoc);
    expect(group.id, 'grp-789');
    expect(group.members.length, 1);
    expect(group.members.first.name, 'Admin User');
    expect(group.joinRequests.length, 1);
    expect(group.joinRequests.first.name, 'Requester');
    expect(group.notificationSettings.offsetMinutes, 15);
    expect(group.customPrayerTimes['Fajr'], '05:00');
  });

  test('UserModel serialization and deserialization test', () {
    final user = UserModel(
      uid: 'user_xyz',
      name: 'Muslim User',
      email: 'user@example.com',
      photoUrl: 'https://example.com/photo.png',
      fcmToken: 'fcm_123',
      groupIds: ['grp-1', 'grp-2'],
      createdAt: DateTime.parse('2026-11-17T12:00:00.000Z'),
    );

    final json = user.toJson();
    final parsed = UserModel.fromJson(json);

    expect(parsed.uid, 'user_xyz');
    expect(parsed.name, 'Muslim User');
    expect(parsed.email, 'user@example.com');
    expect(parsed.photoUrl, 'https://example.com/photo.png');
    expect(parsed.fcmToken, 'fcm_123');
    expect(parsed.groupIds, ['grp-1', 'grp-2']);
    expect(parsed.createdAt.toIso8601String(), '2026-11-17T12:00:00.000Z');
  });
}
