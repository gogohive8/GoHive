import 'dart:developer' as developer;

class User {
  final String id;
  final String username;
  final String profileImage;

  User({
    required this.id,
    required this.username,
    required this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    developer.log('User.fromJson keys: ${json.keys.toList()}',
        name: 'User.fromJson');
    return User(
      id: json['userID']?.toString() ?? json['id']?.toString() ?? 'unknown',
      username: json['username']?.toString() ?? 'Unknown',
      profileImage: json['avatar']?.toString() ?? '',
    );
  }
}
