class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> groupIds;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.groupIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'groupIds': groupIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        photoUrl: json['photoUrl'],
        groupIds: List<String>.from(json['groupIds'] ?? []),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );

  UserModel copyWith({
    String? name,
    String? photoUrl,
    List<String>? groupIds,
  }) =>
      UserModel(
        uid: uid,
        name: name ?? this.name,
        email: email,
        photoUrl: photoUrl ?? this.photoUrl,
        groupIds: groupIds ?? this.groupIds,
        createdAt: createdAt,
      );
}
