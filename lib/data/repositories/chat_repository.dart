import '../services/api_client.dart';
import '../../domain/models/chat_reply.dart';

class ChatRepository {
  const ChatRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ChatReply> send(
    String message,
    List<Map<String, String>> history,
  ) async {
    final result = await _apiClient.postJson('api/chat/messages', {
      'message': message,
      'history': history,
    }, const Duration(seconds: 40)) as Map<String, dynamic>;
    return ChatReply.fromJson(result);
  }
}
