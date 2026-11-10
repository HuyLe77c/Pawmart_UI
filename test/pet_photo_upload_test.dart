import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawmart/data/repositories/pets_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';

class _TokenStore extends TokenStore {
  @override
  Future<String?> read() async => 'test-token';
}

void main() {
  test('uploads a picked pet photo as multipart data', () async {
    final bytes = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]);
    final file = XFile.fromData(bytes, name: 'meo.png', path: 'meo.png');
    final client = ApiClient(
      baseUrl: 'http://localhost:5165',
      tokenStore: _TokenStore(),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/pets/12/image');
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        final body = request.bodyBytes;
        expect(
          utf8.decode(body, allowMalformed: true),
          contains('name="file"; filename="meo.png"'),
        );
        expect(body, containsAllInOrder(bytes));
        return http.Response(
          jsonEncode({
            'petId': 12,
            'petName': 'Mèo',
            'petType': 'CAT',
            'imageUrl': '/uploads/pets/meo.png',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.close);

    final saved = await PetsRepository(client).uploadImage(12, file);
    expect(saved.imageUrl, '/uploads/pets/meo.png');
  });
}
