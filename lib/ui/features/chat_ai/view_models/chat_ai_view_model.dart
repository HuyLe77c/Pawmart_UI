import 'package:flutter/foundation.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/services/api_client.dart';
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
}

class ChatAiViewModel extends ChangeNotifier {
  ChatAiViewModel(this._repository, this._auth) {
    _userId = _auth.user?.userId;
    _auth.addListener(_onAuthChanged);
  }

  final ChatRepository _repository;
  final AuthViewModel _auth;
  String? _userId;
  final List<ChatEntry> entries = [];
  bool isSending = false;
  String? errorMessage;
  bool _hasFailedMessage = false;
  int _generation = 0;

  bool get canRetry => _hasFailedMessage && !isSending;

  void _onAuthChanged() {
    final next = _auth.user?.userId;
    if (next != _userId) {
      _userId = next;
      clear();
    }
  }

  Future<bool> send(String text, {String? petName}) async {
    final message = text.trim();
    if (message.isEmpty || message.length > 2000 || isSending) return false;
    if (_hasFailedMessage && entries.isNotEmpty) entries.removeLast();
    entries.add(
      ChatEntry(
        'user',
        message,
        requestContent: petName == null
            ? null
            : 'Hồ sơ thú cưng đang chọn: $petName. Câu hỏi: $message',
      ),
    );
    _hasFailedMessage = false;
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
      notifyListeners();
    }
  }

  void clear() {
    _generation++;
    entries.clear();
    errorMessage = null;
    _hasFailedMessage = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
