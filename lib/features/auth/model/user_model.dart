class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? fcmToken;
  final List<String> groupIds;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.fcmToken,
    this.groupIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
        'groupIds': groupIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawCreated = json['createdAt'];
    if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      try {
        // If it's a Firestore Timestamp or has toDate()
        parsedDate = (rawCreated as dynamic).toDate();
      } catch (_) {
        parsedDate = DateTime.now();
      }
    }

    return UserModel(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      fcmToken: json['fcmToken']?.toString(),
      groupIds: (json['groupIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: parsedDate,
    );
  }

  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? fcmToken,
    List<String>? groupIds,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        fcmToken: fcmToken ?? this.fcmToken,
        groupIds: groupIds ?? this.groupIds,
        createdAt: createdAt,
      );
}
