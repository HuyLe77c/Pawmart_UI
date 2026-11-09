import 'package:flutter_test/flutter_test.dart';
import 'package:pawmart/data/repositories/auth_repository.dart';
import 'package:pawmart/data/repositories/chat_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/chat_history_store.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/app_user.dart';
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

  test('Chat khôi phục hội thoại đã lưu cho tài khoản', () async {
    final tokenStore = TokenStore();
    final client = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: tokenStore,
    );
    final auth = AuthViewModel(_AuthRepository(client, tokenStore), tokenStore);
    expect(await auth.signIn('customer@pawmart.vn', 'secret'), isTrue);

    final store = _MemoryChatHistoryStore();
    final repository = _ChatRepository(client);
    final first = ChatAiViewModel(repository, auth, historyStore: store);

    expect(await first.send('Giá hạt mèo?'), isFalse);
    expect(first.entries.single.content, 'Giá hạt mèo?');

    final reopened = ChatAiViewModel(repository, auth, historyStore: store);
    await pumpEventQueue();
    expect(reopened.entries.map((entry) => entry.content), ['Giá hạt mèo?']);
    expect(reopened.canRetry, isTrue);

    expect(await reopened.retry(), isTrue);
    expect(reopened.entries.map((entry) => entry.role), ['user', 'assistant']);

    reopened.clear();
    final cleared = ChatAiViewModel(repository, auth, historyStore: store);
    await pumpEventQueue();
    expect(cleared.entries, isEmpty);

    first.dispose();
    reopened.dispose();
    cleared.dispose();
    auth.dispose();
    client.close();
  });
}

class _AuthRepository extends AuthRepository {
  _AuthRepository(super.client, super.tokenStore);

  @override
  Future<AppUserSession> login({
    required String email,
    required String password,
  }) async => AppUserSession(
    accessToken: 'token',
    expiresAtUtc: DateTime.utc(2030),
    user: AppUser(
      userId: 'customer-1',
      email: email,
      fullName: 'Khách hàng',
      role: 'CUSTOMER',
    ),
  );
}

class _MemoryChatHistoryStore extends ChatHistoryStore {
  final saved = <String, List<Map<String, dynamic>>>{};
  String _key(String userId, String scope) => '$scope:$userId';

  @override
  Future<List<Map<String, dynamic>>> read(String userId, String scope) async =>
      saved[_key(userId, scope)] ?? const [];

  @override
  Future<void> write(
    String userId,
    String scope,
    List<Map<String, dynamic>> entries,
  ) async {
    saved[_key(userId, scope)] = entries;
  }

  @override
  Future<void> clear(String userId, String scope) async {
    saved.remove(_key(userId, scope));
  }
}
