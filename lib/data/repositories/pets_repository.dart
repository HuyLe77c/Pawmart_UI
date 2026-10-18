import '../../domain/models/pet_profile.dart';
import '../services/api_client.dart';

class PetsRepository {
  const PetsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<PetProfile>> list() async =>
      (await _apiClient.getJson('api/pets') as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PetProfile.fromJson)
          .toList(growable: false);

  Future<PetProfile> create(Map<String, Object?> request) async =>
      PetProfile.fromJson(
        await _apiClient.postJson('api/pets', request) as Map<String, dynamic>,
      );

  Future<PetProfile> update(int petId, Map<String, Object?> request) async =>
      PetProfile.fromJson(
        await _apiClient.putJson('api/pets/$petId', request)
            as Map<String, dynamic>,
      );

  Future<PetProfile> uploadImage(int petId, String filePath) async =>
      PetProfile.fromJson(
        await _apiClient.postMultipart(
          'api/pets/$petId/image',
          fileFieldName: 'file',
          filePath: filePath,
        ) as Map<String, dynamic>,
      );

  Future<void> delete(int petId) async => _apiClient.delete('api/pets/$petId');
}
