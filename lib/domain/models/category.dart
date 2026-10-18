class Category {
  const Category({
    required this.categoryId,
    required this.categoryName,
    required this.sortOrder,
    required this.isActive,
    this.imageUrl,
    this.description,
  });

  final int categoryId;
  final String categoryName;
  final String? imageUrl;
  final String? description;
  final int sortOrder;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    categoryId: json['categoryId'] as int,
    categoryName: json['categoryName'] as String,
    imageUrl: json['imageUrl'] as String?,
    description: json['description'] as String?,
    sortOrder: json['sortOrder'] as int? ?? 0,
    isActive: json['isActive'] as bool? ?? true,
  );
}
