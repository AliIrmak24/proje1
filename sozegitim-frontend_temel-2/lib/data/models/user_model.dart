class UserModel {
  final int id;
  final String username;
  final String email;
  final int xp;
  final int level;
  final String? fullName;
  final String? phoneNumber;
  final String? bio;
  final String? avatarUrl;
  final String? language;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.xp,
    required this.level,
    this.fullName,
    this.phoneNumber,
    this.bio,
    this.avatarUrl,
    this.language,
    this.createdAt,
  });

  int get xpInCurrentLevel => xp % 100;
  int get xpToNextLevel => 100 - (xp % 100);
  double get levelProgress => (xp % 100) / 100.0;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      language: json['language'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'xp': xp,
      'level': level,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'bio': bio,
      'avatar_url': avatarUrl,
      'language': language,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    int? xp,
    int? level,
    String? fullName,
    String? phoneNumber,
    String? bio,
    String? avatarUrl,
    String? language,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
