import 'package:uuid/uuid.dart';

class GroupMember {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'member'

  const GroupMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
      };

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'member',
      );
}

class GroupJoinRequest {
  final String uid;
  final String name;
  final String email;
  final DateTime requestedAt;

  const GroupJoinRequest({
    required this.uid,
    required this.name,
    required this.email,
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'requestedAt': requestedAt.toIso8601String(),
      };

  factory GroupJoinRequest.fromJson(Map<String, dynamic> json) =>
      GroupJoinRequest(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        requestedAt:
            DateTime.tryParse(json['requestedAt'] ?? '') ?? DateTime.now(),
      );
}

class GroupNotificationSettings {
  final bool fajrEnabled;
  final bool dhuhrEnabled;
  final bool asrEnabled;
  final bool maghribEnabled;
  final bool ishaEnabled;
  final int offsetMinutes; // how many minutes before namaz
  final bool hadithEnabled;

  const GroupNotificationSettings({
    this.fajrEnabled = true,
    this.dhuhrEnabled = true,
    this.asrEnabled = true,
    this.maghribEnabled = true,
    this.ishaEnabled = true,
    this.offsetMinutes = 10,
    this.hadithEnabled = true,
  });

  Map<String, bool> get enabledMap => {
        'Fajr': fajrEnabled,
        'Dhuhr': dhuhrEnabled,
        'Asr': asrEnabled,
        'Maghrib': maghribEnabled,
        'Isha': ishaEnabled,
      };

  Map<String, dynamic> toJson() => {
        'fajrEnabled': fajrEnabled,
        'dhuhrEnabled': dhuhrEnabled,
        'asrEnabled': asrEnabled,
        'maghribEnabled': maghribEnabled,
        'ishaEnabled': ishaEnabled,
        'offsetMinutes': offsetMinutes,
        'hadithEnabled': hadithEnabled,
      };

  factory GroupNotificationSettings.fromJson(Map<String, dynamic> json) =>
      GroupNotificationSettings(
        fajrEnabled: json['fajrEnabled'] ?? true,
        dhuhrEnabled: json['dhuhrEnabled'] ?? true,
        asrEnabled: json['asrEnabled'] ?? true,
        maghribEnabled: json['maghribEnabled'] ?? true,
        ishaEnabled: json['ishaEnabled'] ?? true,
        offsetMinutes: json['offsetMinutes'] ?? 10,
        hadithEnabled: json['hadithEnabled'] ?? true,
      );

  GroupNotificationSettings copyWith({
    bool? fajrEnabled,
    bool? dhuhrEnabled,
    bool? asrEnabled,
    bool? maghribEnabled,
    bool? ishaEnabled,
    int? offsetMinutes,
    bool? hadithEnabled,
  }) =>
      GroupNotificationSettings(
        fajrEnabled: fajrEnabled ?? this.fajrEnabled,
        dhuhrEnabled: dhuhrEnabled ?? this.dhuhrEnabled,
        asrEnabled: asrEnabled ?? this.asrEnabled,
        maghribEnabled: maghribEnabled ?? this.maghribEnabled,
        ishaEnabled: ishaEnabled ?? this.ishaEnabled,
        offsetMinutes: offsetMinutes ?? this.offsetMinutes,
        hadithEnabled: hadithEnabled ?? this.hadithEnabled,
      );
}

class GroupModel {
  final String id;
  final String name;
  final String adminUid;
  final String city;
  final String country;
  final int calculationMethod;
  final String inviteCode;
  final List<GroupMember> members;
  final List<GroupJoinRequest> joinRequests;
  final GroupNotificationSettings notificationSettings;
  final Map<String, String> customPrayerTimes;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.adminUid,
    required this.city,
    required this.country,
    this.calculationMethod = 1,
    required this.inviteCode,
    this.members = const [],
    this.joinRequests = const [],
    this.notificationSettings = const GroupNotificationSettings(),
    this.customPrayerTimes = const {},
    required this.createdAt,
  });

  /// Generate a new group with unique ID and invite code
  factory GroupModel.create({
    required String name,
    required String adminUid,
    required String adminName,
    required String adminEmail,
    required String city,
    required String country,
    int calculationMethod = 1,
    int offsetMinutes = 10,
    Map<String, String> customPrayerTimes = const {},
  }) {
    const uuid = Uuid();
    final id = uuid.v4();
    final inviteCode = 'NAM-${id.substring(0, 4).toUpperCase()}';

    return GroupModel(
      id: id,
      name: name,
      adminUid: adminUid,
      city: city,
      country: country,
      calculationMethod: calculationMethod,
      inviteCode: inviteCode,
      members: [
        GroupMember(
          uid: adminUid,
          name: adminName,
          email: adminEmail,
          role: 'admin',
        ),
      ],
      joinRequests: const [],
      notificationSettings:
          GroupNotificationSettings(offsetMinutes: offsetMinutes),
      customPrayerTimes: customPrayerTimes,
      createdAt: DateTime.now(),
    );
  }

  bool isMember(String uid) => members.any((m) => m.uid == uid);
  bool isAdmin(String uid) =>
      adminUid == uid || members.any((m) => m.uid == uid && m.isAdmin);
  bool isPrimaryAdmin(String uid) => adminUid == uid;
  bool isPendingRequest(String uid) => joinRequests.any((r) => r.uid == uid);
  int get memberCount => members.length;
  int get joinRequestCount => joinRequests.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'adminUid': adminUid,
        'city': city,
        'country': country,
        'calculationMethod': calculationMethod,
        'inviteCode': inviteCode,
        'members': members.map((m) => m.toJson()).toList(),
        'joinRequests': joinRequests.map((r) => r.toJson()).toList(),
        'notificationSettings': notificationSettings.toJson(),
        'customPrayerTimes': customPrayerTimes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        adminUid: json['adminUid'] ?? '',
        city: json['city'] ?? '',
        country: json['country'] ?? '',
        calculationMethod: json['calculationMethod'] ?? 1,
        inviteCode: json['inviteCode'] ?? '',
        members: (json['members'] as List<dynamic>? ?? [])
            .map((m) =>
                GroupMember.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
        joinRequests: (json['joinRequests'] as List<dynamic>? ?? [])
            .map((r) =>
                GroupJoinRequest.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        notificationSettings: GroupNotificationSettings.fromJson(
          Map<String, dynamic>.from(
              json['notificationSettings'] as Map<dynamic, dynamic>? ?? {}),
        ),
        customPrayerTimes: Map<String, String>.from(
          json['customPrayerTimes'] as Map<dynamic, dynamic>? ?? {},
        ),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  GroupModel copyWith({
    String? name,
    String? adminUid,
    String? city,
    String? country,
    int? calculationMethod,
    List<GroupMember>? members,
    List<GroupJoinRequest>? joinRequests,
    GroupNotificationSettings? notificationSettings,
    Map<String, String>? customPrayerTimes,
  }) =>
      GroupModel(
        id: id,
        name: name ?? this.name,
        adminUid: adminUid ?? this.adminUid,
        city: city ?? this.city,
        country: country ?? this.country,
        calculationMethod: calculationMethod ?? this.calculationMethod,
        inviteCode: inviteCode,
        members: members ?? this.members,
        joinRequests: joinRequests ?? this.joinRequests,
        notificationSettings: notificationSettings ?? this.notificationSettings,
        customPrayerTimes: customPrayerTimes ?? this.customPrayerTimes,
        createdAt: createdAt,
      );
}
