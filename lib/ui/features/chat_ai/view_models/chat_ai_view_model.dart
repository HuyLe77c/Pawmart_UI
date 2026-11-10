import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/chat_history_store.dart';
import '../../../../domain/models/chat_reply.dart';
import '../../auth/view_models/auth_view_model.dart';

class ChatEntry {
  const ChatEntry(
    this.role,
    this.content, {
    this.requestContent,
    this.products = const [],
  });
  final String role;
  final String content;
  final String? requestContent;
  final List<ChatProductLink> products;

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (requestContent != null) 'requestContent': requestContent,
    if (products.isNotEmpty)
      'products': [
        for (final product in products)
          {
            'productId': product.productId,
            'productName': product.productName,
            'price': product.price,
          },
      ],
  };

  static ChatEntry? fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    final content = json['content'];
    if (role is! String || content is! String) return null;
    if (role != 'user' && role != 'assistant') return null;
    return ChatEntry(
      role,
      content,
      requestContent: json['requestContent'] as String?,
      products: (json['products'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatProductLink.fromJson)
          .toList(growable: false),
    );
  }
}

class ChatAiViewModel extends ChangeNotifier {
  ChatAiViewModel(
    this._repository,
    this._auth, {
    ChatHistoryStore? historyStore,
    this.historyScope = 'chat',
  }) : _store = historyStore {
    _userId = _auth.user?.userId;
    _auth.addListener(_onAuthChanged);
    _restore();
  }

  final ChatRepository _repository;
  final AuthViewModel _auth;
  final ChatHistoryStore? _store;
  final String historyScope;
  String? _userId;
  final List<ChatEntry> entries = [];
  bool isSending = false;
  String? errorMessage;
  bool _hasFailedMessage = false;
  int _generation = 0;
  int _restoreToken = 0;
  bool _disposed = false;

  bool get canRetry => _hasFailedMessage && !isSending;

  void _onAuthChanged() {
    final next = _auth.user?.userId;
    if (next == _userId) return;
    _userId = next;
    _generation++;
    _restoreToken++;
    entries.clear();
    errorMessage = null;
    _hasFailedMessage = false;
    notifyListeners();
    _restore();
  }

  Future<void> _restore() async {
    final store = _store;
    final userId = _userId;
    if (store == null || userId == null) return;
    final token = ++_restoreToken;
    final stored = await store.read(userId, historyScope);
    if (token != _restoreToken || userId != _userId) return;
    if (stored.isEmpty || entries.isNotEmpty) return;
    final restored = <ChatEntry>[];
    for (final json in stored) {
      try {
        final entry = ChatEntry.fromJson(json);
        if (entry != null) restored.add(entry);
      } catch (_) {
        // Bỏ qua bản ghi không đọc được.
      }
    }
    if (restored.isEmpty) return;
    entries.addAll(restored);
    // Hội thoại kết thúc bằng câu hỏi chưa có câu trả lời thì cho thử lại.
    _hasFailedMessage = restored.last.role == 'user';
    notifyListeners();
  }

  void _persist() {
    final store = _store;
    final userId = _userId;
    if (store == null || userId == null) return;
    final snapshot = entries
        .map((entry) => entry.toJson())
        .toList(growable: false);
    unawaited(store.write(userId, historyScope, snapshot));
  }

  static String _petPrefix(String? name) =>
      name == null ? '' : 'Hồ sơ thú cưng đang chọn: $name. Câu hỏi: ';

  static int messageLimit({String? petName}) =>
      2000 - _petPrefix(petName).length;

  Future<bool> send(String text, {String? petName}) async {
    final message = text.trim();
    if (message.isEmpty ||
        message.length > messageLimit(petName: petName) ||
        isSending) {
      return false;
    }
    if (_hasFailedMessage && entries.isNotEmpty) entries.removeLast();
    entries.add(
      ChatEntry(
        'user',
        message,
        requestContent: petName == null
            ? null
            : '${_petPrefix(petName)}$message',
      ),
    );
    _hasFailedMessage = false;
    _persist();
    return _complete();
  }

  Future<bool> retry() async {
    if (!canRetry || entries.isEmpty) return false;
    return _complete();
  }

  Future<bool> _complete() async {
    final generation = _generation;
    isSending = true;
    errorMessage = null;
    notifyListeners();
    try {
      final latest = entries.last;
      final previous = entries.take(entries.length - 1).toList();
      final history = previous.length > 12
          ? previous.skip(previous.length - 12)
          : previous;
      final reply = await _repository.send(
        latest.requestContent ?? latest.content,
        history
            .map(
              (entry) => {
                'role': entry.role,
                'content': entry.requestContent ?? entry.content,
              },
            )
            .toList(),
      );
      if (generation != _generation) return false;
      entries.add(
        ChatEntry('assistant', reply.answer, products: reply.products),
      );
      _hasFailedMessage = false;
      _persist();
      return true;
    } on ApiException catch (error) {
      if (generation != _generation) return false;
      errorMessage = error.statusCode == 503 || error.statusCode == 502
          ? 'Chat AI tạm thời không khả dụng. Vui lòng thử lại.'
          : error.userMessage;
      _hasFailedMessage = true;
      return false;
    } catch (_) {
      if (generation != _generation) return false;
      errorMessage = 'Không nhận được phản hồi. Vui lòng thử lại.';
      _hasFailedMessage = true;
      return false;
    } finally {
      isSending = false;
      if (!_disposed) notifyListeners();
    }
  }

  void clear() {
    _generation++;
    _restoreToken++;
    entries.clear();
    errorMessage = null;
    _hasFailedMessage = false;
    final store = _store;
    final userId = _userId;
    if (store != null && userId != null) {
      unawaited(store.clear(userId, historyScope));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _restoreToken++;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
