import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';

class _TokenStore extends TokenStore {
  @override
  Future<String?> read() async => 'admin-token';
}

void main() {
  test('product image URL is sent with the product', () async {
    final client = ApiClient(
      baseUrl: 'http://localhost:5165',
      tokenStore: _TokenStore(),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/products');
        expect(request.headers['authorization'], 'Bearer admin-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['images'], [
          {
            'imageUrl': 'https://example.com/product.jpg',
            'isPrimary': true,
            'displayOrder': 0,
          },
        ]);
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.close);

    await client.postJson('api/products', {
      'images': [
        {
          'imageUrl': 'https://example.com/product.jpg',
          'isPrimary': true,
          'displayOrder': 0,
        },
      ],
    });
  });

  test('picked product image is uploaded as multipart data', () async {
    final bytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ]);
    final file = XFile.fromData(
      bytes,
      name: 'san-pham.png',
      path: 'san-pham.png',
    );
    final client = ApiClient(
      baseUrl: 'http://localhost:5165',
      tokenStore: _TokenStore(),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/admin/products/42/images/upload');
        expect(request.headers['authorization'], 'Bearer admin-token');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(
          utf8.decode(request.bodyBytes, allowMalformed: true),
          contains('name="file"; filename="san-pham.png"'),
        );
        expect(request.bodyBytes, containsAllInOrder(bytes));
        return http.Response('{"imageUrl":"/uploads/products/test.png"}', 200);
      }),
    );
    addTearDown(client.close);

    await client.postMultipart(
      'api/admin/products/42/images/upload',
      fileFieldName: 'file',
      file: file,
    );
  });
}
