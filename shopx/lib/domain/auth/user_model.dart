class UserModel {
  final int id;
  final String username;
  final String email;
  final String userType;
  final String phone;
  final String token;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.userType,
    required this.phone,
    required this.token
  });

  // ✅ Clean - only handles user data, not token
  factory UserModel.fromJson(Map<String, dynamic> json) {
  // If backend sends: { "user": {...}, "token": "..." }
  final data = json["user"] ?? json;

  return UserModel(
    id: data["id"],
    username: data["username"],
    email: data["email"],
    userType: data["user_type"],
    phone: data["phone"] ?? "",
token: json["accessToken"] ?? json["token"] ?? "",
  );
}


  // factory UserModel.fromJson(Map<String, dynamic> json) {
  //   return UserModel(
  //     id: json['id'] ?? json['user']['id'],
  //     username: json['username'] ?? json['user']['username'],
  //     email: json['email'] ?? json['user']['email'],
  //     userType: json['user_type'] ?? json['user']['user_type'],
  //     phone: json['phone'] ?? json['user']['phone'] ?? '', // ✅ Safe default
  //       token: json['token'] ?? '',
  //   );
  // }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'user_type': userType,
      'phone': phone,
      'token': token,
    };
  }
}
