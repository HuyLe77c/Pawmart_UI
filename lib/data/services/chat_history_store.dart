import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu lịch sử hội thoại AI trên thiết bị, tách theo tài khoản và từng màn
/// hình, để hội thoại không mất khi chuyển trang hoặc khởi động lại ứng dụng.
///
/// Các thao tác ghi/xóa được xếp hàng để một lần ghi chậm không ghi đè lên
/// lần xóa mới hơn (ví dụ: xóa hội thoại ngay sau khi gửi tin nhắn).
class ChatHistoryStore {
  ChatHistoryStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// Giữ tối đa 40 lượt gần nhất; mỗi lần gửi API chỉ dùng 12 lượt cuối.
  static const maxEntries = 40;

  final FlutterSecureStorage _storage;
  Future<void> _queue = Future<void>.value();

  String _key(String userId, String scope) =>
      'pawmart.chat_history.$scope.$userId';

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _queue.then((_) => action()).catchError((_) {});
    _queue = next;
    return next;
  }

  Future<List<Map<String, dynamic>>> read(String userId, String scope) async {
    await _queue;
    try {
      final raw = await _storage.read(key: _key(userId, scope));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> write(
    String userId,
    String scope,
    List<Map<String, dynamic>> entries,
  ) {
    final payload = entries.length > maxEntries
        ? entries.sublist(entries.length - maxEntries)
        : entries;
    return _enqueue(() async {
      try {
        await _storage.write(
          key: _key(userId, scope),
          value: jsonEncode(payload),
        );
      } catch (_) {
        // Lịch sử chỉ là tiện ích: lỗi lưu không được chặn việc gửi tin nhắn.
      }
    });
  }

  Future<void> clear(String userId, String scope) => _enqueue(() async {
    try {
      await _storage.delete(key: _key(userId, scope));
    } catch (_) {
      // Không có gì để xóa hoặc thiết bị không cho xóa: bỏ qua.
    }
  });
}
