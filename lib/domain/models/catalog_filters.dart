class CatalogFilters {
  const CatalogFilters({
    this.petType = 'ALL',
    this.categoryId,
    this.breed,
    this.brand,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
  });

  final String petType;
  final int? categoryId;
  final String? breed;
  final String? brand;
  final int? minPrice;
  final int? maxPrice;
  final bool inStockOnly;

  int get activeCount => [
    petType != 'ALL',
    categoryId != null,
    breed?.isNotEmpty == true,
    brand?.isNotEmpty == true,
    minPrice != null || maxPrice != null,
    inStockOnly,
  ].where((active) => active).length;

  CatalogFilters without(String field) => CatalogFilters(
    petType: field == 'petType' ? 'ALL' : petType,
    categoryId: field == 'category' ? null : categoryId,
    breed: field == 'breed' || field == 'petType' ? null : breed,
    brand: field == 'brand' ? null : brand,
    minPrice: field == 'price' ? null : minPrice,
    maxPrice: field == 'price' ? null : maxPrice,
    inStockOnly: field == 'stock' ? false : inStockOnly,
  );
}
