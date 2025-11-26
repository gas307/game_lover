class AppUser {
  final String id;
  final String nickname;
  final String? email;
  final bool isAdmin;

  AppUser({
    required this.id,
    required this.nickname,
    this.email,
    required this.isAdmin,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      nickname: data['nickname'] ?? '',
      email: data['email'],
      isAdmin: (data['isAdmin'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nickname': nickname,
      'email': email,
      'isAdmin': isAdmin,
    };
  }
}
