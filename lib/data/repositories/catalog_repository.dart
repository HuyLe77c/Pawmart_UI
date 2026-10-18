import '../../domain/models/category.dart';
import '../../domain/models/paged_result.dart';
import '../../domain/models/product.dart';
import '../../domain/models/promotion.dart';
import '../services/api_client.dart';

class CatalogRepository {
  const CatalogRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<PagedResult<Product>> search({
    String? search,
    int? categoryId,
    String? petType,
    String sort = 'newest',
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      'sort': sort,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (categoryId != null) 'categoryId': '$categoryId',
      if (petType != null && petType != 'ALL') 'petType': petType,
    };
    final json = await _apiClient.getJson(
      'api/products',
      query: query,
    ) as Map<String, dynamic>;
    return PagedResult(
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(growable: false),
      page: json['page'] as int? ?? page,
      pageSize: json['pageSize'] as int? ?? pageSize,
      totalItems: json['totalItems'] as int? ?? 0,
    );
  }

  Future<Product> getProduct(int productId) async => Product.fromJson(
    await _apiClient.getJson('api/products/$productId') as Map<String, dynamic>,
  );

  Future<List<Category>> categories() async =>
      (await _apiClient.getJson('api/categories') as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList(growable: false);

  Future<List<Promotion>> activePromotions() async =>
      (await _apiClient.getJson('api/promotions') as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(Promotion.fromJson)
          .toList(growable: false);
}
