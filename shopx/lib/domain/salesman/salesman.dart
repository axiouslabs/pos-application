class Salesman {
  final int? id;
  final String username;
  final String email;
  final String phone;
  final String? password; // Only used when creating

  Salesman({
    this.id,
    required this.username,
    required this.email,
    required this.phone,
    this.password,
  });

  factory Salesman.fromJson(Map<String, dynamic> json) {
    return Salesman(
      id: json["id"],
      username: json["username"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "email": email,
      "phone": phone,
      if (password != null) "password": password,
    };
  }
}
