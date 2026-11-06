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

class CatalogReviewSummary {
  const CatalogReviewSummary({
    required this.modelStatus,
    required this.imageStatus,
    required this.priceStatus,
    required this.productStatus,
    required this.publicPreview,
    required this.officialUrl,
    this.shortDescription,
  });

  final String modelStatus;
  final String imageStatus;
  final String priceStatus;
  final String productStatus;
  final bool publicPreview;
  final String officialUrl;
  final String? shortDescription;

  factory CatalogReviewSummary.fromJson(Map<String, dynamic> json) =>
      CatalogReviewSummary(
        modelStatus: json['modelStatus'] as String? ?? 'NEEDS_REVIEW',
        imageStatus: json['imageStatus'] as String? ?? 'NEEDS_REVIEW',
        priceStatus: json['priceStatus'] as String? ?? 'NEEDS_REVIEW',
        productStatus: json['productStatus'] as String? ?? 'NEEDS_REVIEW',
        publicPreview: json['publicPreview'] as bool? ?? false,
        officialUrl: json['officialUrl'] as String? ?? '',
        shortDescription: json['shortDescription'] as String?,
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
    this.packageSize,
    this.lifeStage,
    this.feedingGuide,
    this.catalogReview,
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
  final String? packageSize;
  final String? lifeStage;
  final String? feedingGuide;
  final CatalogReviewSummary? catalogReview;

  bool get isPreview => !isActive && catalogReview?.publicPreview == true;
  bool get hasPublishedPrice =>
      price > 0 &&
      (catalogReview == null ||
          catalogReview!.priceStatus == 'VERIFIED' ||
          catalogReview!.priceStatus == 'OWNER_SET');
  bool get hasVerifiedImage =>
      catalogReview == null || catalogReview!.imageStatus == 'VERIFIED';
  bool get canPurchase =>
      isActive &&
      stockQuantity > 0 &&
      (catalogReview == null ||
          (catalogReview!.imageStatus == 'VERIFIED' &&
              ((catalogReview!.modelStatus == 'VERIFIED' &&
                      catalogReview!.priceStatus == 'VERIFIED' &&
                      catalogReview!.productStatus == 'VERIFIED') ||
                  (catalogReview!.priceStatus == 'OWNER_SET' &&
                      catalogReview!.productStatus == 'OWNER_APPROVED'))));

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
    packageSize: json['packageSize'] as String?,
    lifeStage: json['lifeStage'] as String?,
    feedingGuide: json['feedingGuide'] as String?,
    catalogReview: json['catalogReview'] is Map<String, dynamic>
        ? CatalogReviewSummary.fromJson(
            json['catalogReview'] as Map<String, dynamic>,
          )
        : null,
  );
}
