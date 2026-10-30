import 'package:flutter_test/flutter_test.dart';
import 'package:pawmart/data/repositories/auth_repository.dart';
import 'package:pawmart/data/repositories/chat_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/chat_reply.dart';
import 'package:pawmart/ui/features/auth/view_models/auth_view_model.dart';
import 'package:pawmart/ui/features/chat_ai/view_models/chat_ai_view_model.dart';

class _ChatRepository extends ChatRepository {
  _ChatRepository(super.client);

  final histories = <List<Map<String, String>>>[];
  final messages = <String>[];
  int calls = 0;

  @override
  Future<ChatReply> send(
    String message,
    List<Map<String, String>> history,
  ) async {
    calls++;
    messages.add(message);
    histories.add(history);
    if (calls == 1) throw StateError('temporary failure');
    return const ChatReply(
      answer: 'PawMart trả lời',
      products: [
        ChatProductLink(productId: 5, productName: 'Hạt mèo', price: 90000),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Chat giữ câu hỏi lỗi để thử lại và chỉ gửi lịch sử thành công',
    () async {
      final tokenStore = TokenStore();
      final client = ApiClient(
        baseUrl: 'http://localhost',
        tokenStore: tokenStore,
      );
      final auth = AuthViewModel(
        AuthRepository(client, tokenStore),
        tokenStore,
      );
      final repository = _ChatRepository(client);
      final model = ChatAiViewModel(repository, auth);

      expect(await model.send('  Giá sản phẩm?  '), isFalse);
      expect(model.entries.single.content, 'Giá sản phẩm?');
      expect(model.canRetry, isTrue);
      expect(await model.retry(), isTrue);
      expect(model.entries.map((entry) => entry.role), ['user', 'assistant']);
      expect(model.entries.last.products.single.productId, 5);
      expect(repository.histories, [isEmpty, isEmpty]);

      model.clear();
      expect(model.entries, isEmpty);
      expect(model.canRetry, isFalse);
      expect(await model.send('Bé ăn gì?', petName: 'Milo'), isTrue);
      expect(model.entries.first.content, 'Bé ăn gì?');
      expect(repository.messages.last, contains('Milo'));
      expect(repository.messages.last, contains('Bé ăn gì?'));
      model.dispose();
      auth.dispose();
      client.close();
    },
  );
}
