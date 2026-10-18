import '../../domain/models/order.dart';
import '../services/api_client.dart';

class RecommendationRepository {
  const RecommendationRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<RecommendationResult> recommend(int petId) async =>
      RecommendationResult.fromJson(
        await _apiClient.postJson('api/chat/recommendations', {'petId': petId})
            as Map<String, dynamic>,
      );
}
