import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pawmart/data/repositories/catalog_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/catalog_filters.dart';
import 'package:pawmart/ui/features/catalog/view_models/catalog_view_model.dart';

class _Tokens extends TokenStore {
  @override
  Future<String?> read() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiClient client;
  late CatalogViewModel model;
  late int total;
  final requests = <Map<String, String>>[];
  Completer<http.Response>? recovery;

  http.Response response(int page, int count, {String? name}) => http.Response(
    jsonEncode({
      'page': page,
      'pageSize': 12,
      'totalItems': count,
      'items': page > (count + 11) ~/ 12
          ? []
          : [
              {
                'productId': page,
                'categoryId': 1,
                'productName': name ?? 'Product $page',
                'price': 200000,
                'stockQuantity': 10,
                'targetPetType': 'DOG',
                'images': [],
              },
            ],
    }),
    200,
  );

  setUp(() {
    total = 36;
    requests.clear();
    recovery = null;
    client = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: _Tokens(),
      httpClient: MockClient((request) async {
        if (request.url.path == '/api/categories') {
          return http.Response('[]', 200);
        }
        final query = Map<String, String>.of(request.url.queryParameters);
        requests.add(query);
        final page = int.parse(query['page']!);
        if (recovery != null && page == 2 && query['search'] != 'new') {
          return recovery!.future;
        }
        return response(
          page,
          total,
          name: query['search'] == 'new' ? 'New search' : null,
        );
      }),
    );
    model = CatalogViewModel(CatalogRepository(client));
  });
  tearDown(() {
    model.dispose();
    client.close();
  });

  test(
    'Refresh recovers to the last valid page with all filters preserved',
    () async {
      await model.applyFilters(
        const CatalogFilters(
          petType: 'DOG',
          breed: 'Poodle',
          categoryId: 1,
          minPrice: 100000,
          maxPrice: 300000,
          brand: 'Royal Canin',
          inStockOnly: true,
        ),
      );
      await model.setSort('price_asc');
      await model.setSearch('food');
      await model.goToPage(3);
      expect(model.currentPage, 3);
      total = 15;
      final before = requests.length;
      await model.load();
      expect(requests.skip(before).map((query) => query['page']), ['3', '2']);
      expect(model.currentPage, 2);
      expect(model.totalPages, 2);
      expect(model.products.single.productId, 2);
      final previous = Map<String, String>.of(requests[before])..remove('page');
      final recovered = Map<String, String>.of(requests.last)..remove('page');
      expect(recovered, previous);
      expect(model.errorMessage, isNull);
      expect(model.isLoading, isFalse);
    },
  );

  test(
    'An empty catalog resets to page one without repeatedly querying',
    () async {
      await model.load();
      await model.goToPage(3);
      total = 0;
      final before = requests.length;
      await model.load();
      expect(requests.length, before + 1);
      expect(model.currentPage, 1);
      expect(model.totalItems, 0);
      expect(model.totalPages, 0);
      expect(model.products, isEmpty);
      expect(model.isLoading, isFalse);
    },
  );

  test('A late recovery response cannot replace a newer search', () async {
    await model.load();
    await model.goToPage(3);
    total = 15;
    recovery = Completer<http.Response>();
    final oldRequest = model.load();
    await pumpEventQueue();
    expect(requests.last['page'], '2');
    await model.setSearch('new');
    recovery!.complete(response(2, 15));
    await oldRequest;
    expect(model.currentPage, 1);
    expect(model.products.single.productName, 'New search');
    expect(model.search, 'new');
    expect(model.isLoading, isFalse);
  });
}
