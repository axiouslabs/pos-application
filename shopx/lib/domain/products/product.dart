class Product {
   final String? id;        // id comes only when product is fetched from backend
  final String name;       // product name
  final String nameAr; // ✅ NEW
  final double price;      // product price
  final String category;   // product category (Tea, Coffee, etc.)
   final double quantity;    // initial stock (numeric)
  final List<String> images;   // <-- ADD THIS
  final String code; 
  final double vat;




  const Product({
    this.id,
    required this.name,
    required this.nameAr,
    required this.price,
    required this.category,
     required this.quantity,
   
      this.images = const [],     // <-- default empty
        required this.code,
        required this.vat
  });

 
  // Convert JSON → Product (used when fetching products from backend)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"]?.toString(),
     name: json["name"] ?? "",
nameAr: json["name_ar"] ?? "",
      price: double.tryParse(json["price"].toString()) ?? 0.0,
      category: json["category"] ?? "",
        
         quantity: double.tryParse(json["quantity"].toString()) ?? 0.0,
         code: json["code"]?.toString() ?? "", 
         vat: double.tryParse(json["vat"].toString()) ?? 0.0,
         images: json["images"] != null
          ? List<String>.from(json["images"])
          : [],
    );
  }

 // Convert Product → JSON (send to backend)
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "name_ar": nameAr, // ✅ NEW
      "price": price,
      "category": category,
       "quantity": quantity,    
        "code": code, 
        "vat": vat,  
    };
  }
}