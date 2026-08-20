// class Customer {
//   final int id;
//   final String name;
//   final String phone;
//   final String? email;
//   final String tin;        // tax identification number
//   final String address;
//   final DateTime createdAt;

//   Customer({
//     required this.id,
//     required this.name,
//     required this.phone,
//     this.email,
//    required this.tin,
//    required this.address,
//     required this.createdAt,
//   });

//   factory Customer.fromJson(Map<String, dynamic> json) {
//     return Customer(
//       id: json["id"],
//       name: json["name"],
//       phone: json["phone"],
//       email: json["email"],
//       tin: json["tin"],
//       address: json["address"],
//       createdAt: DateTime.parse(json["created_at"]),
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       "name": name,
//       "phone": phone,
//       "email": email,
//       "tin": tin,
//       "address": address,
//     };
//   }
// }


class Customer {
  final int id;
  final String name;

  // Optional fields
  final String? phone;
  final String? tin;
  final String? area;
  final String address;
  final int? salespersonId;  

  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.tin,
    this.area,
    required this.address,
    this.salespersonId,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json["id"],
      name: json["name"],
      phone: json["phone"],        // nullable
      tin: json["tin"],            // nullable
      area: json["area"],          // nullable
      salespersonId: json["salesperson_id"],    // ✅
      address: json["address"] ?? "",
      createdAt: DateTime.parse(json["created_at"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "phone": phone,
      "tin": tin,
      "area": area,
      "address": address,
    };
  }
}
 