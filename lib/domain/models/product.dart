class ProductImage {
  const ProductImage({
    required this.imageUrl,
    required this.isPrimary,
    required this.displayOrder,
  });

  final String imageUrl;
  final bool isPrimary;
  final int displayOrder;

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    imageUrl: json['imageUrl'] as String,
    isPrimary: json['isPrimary'] as bool? ?? false,
    displayOrder: json['displayOrder'] as int? ?? 0,
  );
}

class Product {
  const Product({
    required this.productId,
    required this.categoryId,
    required this.productName,
    required this.price,
    required this.stockQuantity,
    required this.lowStockThreshold,
    required this.targetPetType,
    required this.isFeatured,
    required this.isActive,
    required this.images,
    this.sku,
    this.brand,
    this.description,
    this.ingredients,
    this.nutritionInfo,
  });

  final int productId;
  final int categoryId;
  final String productName;
  final double price;
  final int stockQuantity;
  final int lowStockThreshold;
  final String targetPetType;
  final bool isFeatured;
  final bool isActive;
  final List<ProductImage> images;
  final String? sku;
  final String? brand;
  final String? description;
  final String? ingredients;
  final String? nutritionInfo;

  String? get primaryImageUrl {
    if (images.isEmpty) return null;
    return images
        .firstWhere((image) => image.isPrimary, orElse: () => images.first)
        .imageUrl;
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    productId: json['productId'] as int,
    categoryId: json['categoryId'] as int,
    productName: json['productName'] as String,
    price: (json['price'] as num).toDouble(),
    stockQuantity: json['stockQuantity'] as int,
    lowStockThreshold: json['lowStockThreshold'] as int? ?? 5,
    targetPetType: json['targetPetType'] as String? ?? 'ALL',
    isFeatured: json['isFeatured'] as bool? ?? false,
    isActive: json['isActive'] as bool? ?? true,
    images: (json['images'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProductImage.fromJson)
        .toList(growable: false),
    sku: json['sku'] as String?,
    brand: json['brand'] as String?,
    description: json['description'] as String?,
    ingredients: json['ingredients'] as String?,
    nutritionInfo: json['nutritionInfo'] as String?,
  );
}
