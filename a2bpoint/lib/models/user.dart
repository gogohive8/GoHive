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
    return User(
      id: json['id']?.toString() ?? 
          json['userID']?.toString() ?? 
          json['user_id']?.toString() ?? 
          'unknown',
      username: json['username']?.toString() ?? 'Unknown User',
      profileImage: json['profileImage']?.toString() ?? 
                   json['profile_image']?.toString() ?? 
                   json['avatar']?.toString() ?? 
                   '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profileImage': profileImage,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, profileImage: $profileImage)';
  }
}
