import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../domain/models/pet_profile.dart';
import '../../../core/app_dependencies.dart';
import '../../../core/widgets/pet_illustrations.dart';
import '../../../core/app_theme.dart';
import '../view_models/chat_ai_view_model.dart';
import 'chat_product_links.dart';

class ChatAiScreen extends StatelessWidget {
  const ChatAiScreen({super.key, this.viewModel, this.pet});
  final ChatAiViewModel? viewModel;
  final PetProfile? pet;

  @override
  Widget build(BuildContext context) {
    final profile = pet;
    final injected = viewModel;
    final body = _ChatBody(pet: profile);
    if (injected != null) {
      return ChangeNotifierProvider.value(value: injected, child: body);
    }
    final dependencies = context.read<AppDependencies>();
    if (profile == null) {
      return ChangeNotifierProvider.value(
        value: dependencies.chatAiViewModel,
        child: body,
      );
    }
    return ChangeNotifierProvider(
      key: ValueKey(profile.petId),
      create: (_) => ChatAiViewModel(
        ChatRepository(dependencies.apiClient),
        dependencies.authViewModel,
        historyStore: dependencies.chatHistoryStore,
        historyScope: 'pet-${profile.petId}',
      ),
      child: body,
    );
  }
}

class _ChatBody extends StatefulWidget {
  const _ChatBody({this.pet});
  final PetProfile? pet;
  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(ChatAiViewModel model) async {
    final text = _composer.text.trim();
    if (text.isEmpty ||
        text.length >
            ChatAiViewModel.messageLimit(petName: widget.pet?.petName) ||
        model.isSending) {
      return;
    }
    _composer.clear();
    final reply = model.send(text, petName: widget.pet?.petName);
    _scrollToEnd();
    await reply;
    if (mounted) _scrollToEnd();
  }

  Future<void> _clear(ChatAiViewModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bắt đầu hội thoại mới?'),
        content: const Text(
          'Các tin nhắn trong hội thoại này sẽ được xóa khỏi thiết bị.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa hội thoại'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted && !model.isSending) model.clear();
  }

  void _usePrompt(String text) {
    _composer.text = text;
    _composer.selection = TextSelection.collapsed(offset: text.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Consumer<ChatAiViewModel>(
    builder: (context, model, _) => Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        leading: IconButton(
          tooltip: widget.pet == null ? 'Về trang chủ' : 'Quay lại hồ sơ',
          onPressed: () {
            if (widget.pet != null && context.canPop()) {
              context.pop();
            } else {
              context.go(
                widget.pet == null ? '/customer/home' : '/customer/profile',
              );
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        titleSpacing: 0,
        title: const Row(
          children: [
            _AssistantAvatar(size: 42),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hỏi PawMart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Trợ lý AI cho bạn & bé',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: PawmartColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa hội thoại',
            onPressed: model.entries.isEmpty || model.isSending
                ? null
                : () => _clear(model),
            icon: const Icon(Icons.edit_square, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              if (widget.pet case final pet?)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PawmartColors.greenPale,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 50,
                          child: PetPortraitArtwork(petType: pet.petType),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Đang hỏi về ${pet.petName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: PawmartColors.greenDark,
                                ),
                              ),
                              const Text(
                                'Hội thoại riêng cho hồ sơ này',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PawmartColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  children: [
                    if (model.entries.isEmpty)
                      _ChatWelcome(onPrompt: _usePrompt),
                    if (model.entries.isNotEmpty) ...[
                      const Center(
                        child: Text(
                          'Cuộc trò chuyện của bạn với PawMart',
                          style: TextStyle(
                            fontSize: 12,
                            color: PawmartColors.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    for (final entry in model.entries) ...[
                      _ChatBubble(role: entry.role, text: entry.content),
                      if (entry.products.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ChatProductLinks(products: entry.products),
                      ],
                      const SizedBox(height: 22),
                    ],
                    if (model.isSending)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            _AssistantAvatar(size: 32),
                            SizedBox(width: 12),
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'PawMart đang tìm câu trả lời…',
                                style: TextStyle(color: PawmartColors.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (model.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PawmartColors.amberPale,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 20),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Chưa nhận được câu trả lời',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(model.errorMessage!),
                            if (model.canRetry)
                              TextButton.icon(
                                onPressed: () async {
                                  await model.retry();
                                  if (mounted) _scrollToEnd();
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Thử lại'),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: PawmartColors.line)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _composer,
                              focusNode: _focus,
                              minLines: 1,
                              maxLines: 5,
                              maxLength: ChatAiViewModel.messageLimit(
                                petName: widget.pet?.petName,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                labelText: 'Câu hỏi của bạn',
                                hintText: 'Hôm nay bé cần gì?',
                                counterText: '',
                                filled: true,
                                fillColor: PawmartColors.cream,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _composer,
                            builder: (context, value, _) => IconButton.filled(
                              tooltip: 'Gửi câu hỏi',
                              style: IconButton.styleFrom(
                                minimumSize: const Size(50, 50),
                              ),
                              onPressed:
                                  model.isSending || value.text.trim().isEmpty
                                  ? null
                                  : () => _send(model),
                              icon: const Icon(Icons.arrow_upward_rounded),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Hội thoại được lưu trên thiết bị cho tài khoản này.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: PawmartColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: PawmartColors.greenDark,
      borderRadius: BorderRadius.circular(size * .32),
    ),
    child: Icon(Icons.pets_rounded, color: Colors.white, size: size * .52),
  );
}

class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome({required this.onPrompt});
  final ValueChanged<String> onPrompt;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      const _AssistantAvatar(size: 60),
      const SizedBox(height: 24),
      Text(
        'Chăm bé dễ hơn,\ncùng PawMart.',
        style: Theme.of(context).textTheme.headlineLarge
            ?.copyWith(fontSize: 32, height: 1.18),
      ),
      const SizedBox(height: 12),
      const Text(
        'Tìm món ăn hợp khẩu vị, chọn đồ dùng hay hỏi một điều về bé. Mình ở đây để giúp bạn.',
        style: TextStyle(color: PawmartColors.muted, fontSize: 15, height: 1.6),
      ),
      const SizedBox(height: 28),
      const Text(
        'BẮT ĐẦU TỪ ĐÂU?',
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
          color: PawmartColors.green,
        ),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth >= 540
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final prompt in const [
                (
                  Icons.restaurant_rounded,
                  'Ăn ngon, lớn khỏe',
                  'Chọn thức ăn theo tuổi và nhu cầu',
                  'Làm sao chọn thức ăn phù hợp với độ tuổi của thú cưng?',
                ),
                (
                  Icons.favorite_outline_rounded,
                  'Hiểu bé mỗi ngày',
                  'Thói quen và cách chăm sóc',
                  'Tôi cần lưu ý gì khi chăm sóc thú cưng mới về nhà?',
                ),
                (
                  Icons.shopping_bag_outlined,
                  'Sắm đồ cho bé',
                  'Tìm sản phẩm ở PawMart',
                  'PawMart có những sản phẩm nào dành cho mèo?',
                ),
                (
                  Icons.local_shipping_outlined,
                  'Mua sắm thuận tiện',
                  'Hỏi về đơn hàng và giao hàng',
                  'Tôi có thể xem và theo dõi đơn hàng của mình ở đâu?',
                ),
              ])
                SizedBox(
                  width: width,
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: PawmartColors.line),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onPrompt(prompt.$4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              prompt.$1,
                              color: PawmartColors.green,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prompt.$2,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    prompt.$3,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: PawmartColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.north_west_rounded,
                              size: 16,
                              color: PawmartColors.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 12),
    ],
  );
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.role, required this.text});
  final String role;
  final String text;
  @override
  Widget build(BuildContext context) {
    final assistant = role == 'assistant';
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: assistant ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * (assistant ? 1 : .88),
          ),
          child: Column(
            crossAxisAlignment: assistant
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (assistant) ...[
                      const _AssistantAvatar(size: 24),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      assistant ? 'PawMart' : 'Bạn',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PawmartColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: assistant ? Colors.white : PawmartColors.greenDark,
                  border: assistant
                      ? Border.all(color: PawmartColors.line)
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(assistant ? 4 : 20),
                    bottomRight: Radius.circular(assistant ? 20 : 4),
                  ),
                ),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: assistant ? PawmartColors.ink : Colors.white,
                    height: 1.6,
                  ),
                ),
              ),
              if (assistant)
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép câu trả lời.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Sao chép', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
