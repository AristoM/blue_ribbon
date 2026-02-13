class UpsellProduct {
  final String sku;
  final String displayName;
  final String imageUrl;
  final String type;
  final String category;
  final double price;
  final double? strikeThroughPrice;
  final String shareLink;

  UpsellProduct({
    required this.sku,
    required this.displayName,
    required this.imageUrl,
    required this.type,
    required this.category,
    required this.price,
    this.strikeThroughPrice,
    required this.shareLink,
  });

  factory UpsellProduct.fromJson(Map<String, dynamic> json) {
    return UpsellProduct(
      sku: json['sku'] ?? '',
      displayName: json['display_name'] ?? '',
      imageUrl: json['image_url'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      strikeThroughPrice: (json['strike_through_price'] as num?)?.toDouble(),
      shareLink: json['share_link'] ?? '',
    );
  }
}
