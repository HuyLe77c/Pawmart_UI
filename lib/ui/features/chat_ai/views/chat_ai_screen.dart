import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_dependencies.dart';
import '../../../core/app_theme.dart';
import '../view_models/chat_ai_view_model.dart';
import 'chat_product_links.dart';

class ChatAiScreen extends StatelessWidget {
  const ChatAiScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: context.read<AppDependencies>().chatAiViewModel,
    child: const _ChatBody(),
  );
}

class _ChatBody extends StatefulWidget {
  const _ChatBody();

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(ChatAiViewModel model) async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();
    await model.send(text);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<ChatAiViewModel>(
    builder: (context, model, _) => Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Về trang chủ',
          onPressed: () => context.go('/customer/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hỏi PawMart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Trợ lý mua sắm và chăm sóc thú cưng',
              style: TextStyle(fontSize: 11, color: PawmartColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa hội thoại',
            onPressed: model.entries.isEmpty || model.isSending
                ? null
                : model.clear,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              children: [
                const _ChatBubble(
                  role: 'assistant',
                  text: 'Chào bạn! Mình có thể giúp tìm sản phẩm, xem đơn hàng và giải đáp câu hỏi về thú cưng. Bạn cần gì hôm nay?',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Hội thoại chỉ được giữ trong phiên sử dụng này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PawmartColors.muted, fontSize: 11),
                  ),
                ),
                for (final entry in model.entries) ...[
                  _ChatBubble(role: entry.role, text: entry.content),
                  if (entry.products.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ChatProductLinks(products: entry.products),
                  ],
                  const SizedBox(height: 12),
                ],
                if (model.isSending)
                  const _ChatBubble(role: 'assistant', text: 'Đang trả lời…'),
                if (model.errorMessage != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: PawmartColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(model.errorMessage!)),
                          if (model.canRetry)
                            TextButton(
                              onPressed: model.retry,
                              child: const Text('Thử lại'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: PawmartColors.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Gửi câu hỏi',
                    onPressed: model.isSending ? null : () => _send(model),
                    icon: model.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.role, required this.text});
  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final assistant = role == 'assistant';
    return Align(
      alignment: assistant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: assistant ? Colors.white : PawmartColors.greenDark,
          border: assistant ? Border.all(color: PawmartColors.line) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(assistant ? 5 : 18),
            bottomRight: Radius.circular(assistant ? 18 : 5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: assistant ? PawmartColors.ink : Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
