class UpsellProduct {
  final String sku;
  final String displayName;
  final String imageUrl;
  final String type;
  final String category;
  final double
      price; // Changed to double to handle potentially floating point prices

  UpsellProduct({
    required this.sku,
    required this.displayName,
    required this.imageUrl,
    required this.type,
    required this.category,
    required this.price,
  });

  factory UpsellProduct.fromJson(Map<String, dynamic> json) {
    return UpsellProduct(
      sku: json['sku'] ?? '',
      displayName: json['display_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as double),
    );
  }
}
