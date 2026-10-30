import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../core/app_dependencies.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../../chat_ai/view_models/chat_ai_view_model.dart';
import '../../chat_ai/views/chat_product_links.dart';
import '../view_models/assistant_view_model.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => AssistantViewModel(
          context.read<AppDependencies>().petsRepository,
          context.read<AppDependencies>().recommendationRepository,
        )..loadPets(),
      ),
      ChangeNotifierProvider(
        create: (context) => ChatAiViewModel(
          ChatRepository(context.read<AppDependencies>().apiClient),
          context.read<AppDependencies>().authViewModel,
        ),
      ),
    ],
    child: const _AssistantBody(),
  );
}

class _AssistantBody extends StatefulWidget {
  const _AssistantBody();

  @override
  State<_AssistantBody> createState() => _AssistantBodyState();
}

class _AssistantBodyState extends State<_AssistantBody> {
  final _question = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _question.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendQuestion(ChatAiViewModel chat, String petName) async {
    final question = _question.text.trim();
    if (question.isEmpty || chat.isSending) return;
    _question.clear();
    FocusScope.of(context).unfocus();
    await chat.send(question, petName: petName);
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.pets_rounded, color: PawmartColors.green, size: 24),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tư vấn dinh dưỡng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                'Tư vấn theo hồ sơ thú cưng',
                style: TextStyle(fontSize: 11, color: PawmartColors.green),
              ),
            ],
          ),
        ],
      ),
    ),
    body: Consumer2<AssistantViewModel, ChatAiViewModel>(
      builder: (context, model, chat, _) {
        if (model.isLoadingPets) {
          return const Center(child: CircularProgressIndicator());
        }
        if (model.errorMessage != null && model.pets.isEmpty) {
          return _State(
            message: model.errorMessage!,
            action: 'Thử lại',
            onPressed: model.loadPets,
          );
        }
        if (model.pets.isEmpty) {
          return _State(
            message: 'Thêm hồ sơ thú cưng để nhận tư vấn phù hợp cho bé.',
            action: 'Đến hồ sơ',
            onPressed: () => context.go('/customer/profile'),
          );
        }
        final pet =
            model.pets
                .where((item) => item.petId == model.selectedPetId)
                .firstOrNull ??
            model.pets.first;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: PawmartColors.greenPale,
              child: Row(
                children: [
                  const Icon(
                    Icons.pets_rounded,
                    color: PawmartColors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đang tư vấn cho: ${pet.petName}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/customer/profile'),
                    child: const Text('Hồ sơ'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                children: [
                  const _IntroCard(),
                  const SizedBox(height: 18),
                  Text(
                    'Tư vấn cho ${pet.petName}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhận gợi ý dinh dưỡng theo hồ sơ, hoặc hỏi bất kỳ điều gì ở ô bên dưới.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: PawmartColors.muted),
                  ),
                  if (model.isThinking) ...[
                    const SizedBox(height: 18),
                    const _Bubble(
                      message: 'Đang phân tích hồ sơ của bé…',
                      assistant: true,
                    ),
                  ],
                  if (model.unavailableMessage != null) ...[
                    const SizedBox(height: 18),
                    _Bubble(
                      message: model.unavailableMessage!,
                      assistant: true,
                    ),
                  ],
                  if (model.errorMessage != null) ...[
                    const SizedBox(height: 18),
                    _Bubble(message: model.errorMessage!, assistant: true),
                  ],
                  if (model.result case final result?) ...[
                    const SizedBox(height: 18),
                    _AdviceCard(advice: result.advice),
                    if (result.sources.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Card(
                        child: ExpansionTile(
                          leading: const Icon(
                            Icons.menu_book_outlined,
                            color: PawmartColors.green,
                          ),
                          title: Text(
                            'Nguồn tham khảo (${result.sources.length})',
                          ),
                          subtitle: const Text(
                            'Chạm để xem và sao chép liên kết',
                          ),
                          children: [
                            for (final source in result.sources)
                              ListTile(
                                dense: true,
                                title: Text(source.title),
                                trailing: const Icon(
                                  Icons.copy_rounded,
                                  size: 18,
                                ),
                                onTap: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: source.url),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã sao chép liên kết nguồn',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (result.products.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      Text(
                        'Sản phẩm phù hợp',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...result.products.map(
                        (product) => Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: PawmartColors.greenPale,
                              child: Icon(
                                Icons.pets_rounded,
                                color: PawmartColors.green,
                              ),
                            ),
                            title: Text(
                              product.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              formatVnd(product.price),
                              style: const TextStyle(
                                color: PawmartColors.green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                context.push('/products/${product.productId}'),
                          ),
                        ),
                      ),
                    ],
                  ],
                  if (chat.entries.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Câu hỏi của bạn',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    for (final entry in chat.entries) ...[
                      _Bubble(
                        message: entry.content,
                        assistant: entry.role == 'assistant',
                      ),
                      if (entry.products.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ChatProductLinks(products: entry.products),
                      ],
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (chat.isSending)
                    const _Bubble(message: 'Đang trả lời…', assistant: true),
                  if (chat.errorMessage != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.error_outline,
                          color: PawmartColors.error,
                        ),
                        title: Text(chat.errorMessage!),
                        trailing: chat.canRetry
                            ? TextButton(
                                onPressed: chat.retry,
                                child: const Text('Thử lại'),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFECE9E3))),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: pet.petId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              hintText: 'Chọn hồ sơ thú cưng',
                              prefixIcon: Icon(Icons.pets_outlined, size: 20),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: model.pets
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.petId,
                                    child: Text(
                                      p.petName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: model.isThinking || chat.isSending
                                ? null
                                : (petId) {
                                    model.selectPet(petId);
                                    chat.clear();
                                  },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: model.isThinking ? null : model.ask,
                          icon: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                          ),
                          label: const Text('Gợi ý'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _question,
                            minLines: 1,
                            maxLines: 3,
                            maxLength: 2000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Nhập câu hỏi của bạn…',
                              prefixIcon: Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Gửi câu hỏi tùy ý',
                          onPressed: chat.isSending
                              ? null
                              : () => _sendQuestion(chat, pet.petName),
                          icon: chat.isSending
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
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.assistant});
  final String message;
  final bool assistant;

  @override
  Widget build(BuildContext context) => Align(
    alignment: assistant ? Alignment.centerLeft : Alignment.centerRight,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (assistant) ...[
          const CircleAvatar(
            radius: 13,
            backgroundColor: PawmartColors.green,
            child: Icon(Icons.pets_rounded, color: Colors.white, size: 13),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 310),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: assistant ? Colors.white : PawmartColors.green,
              border: assistant
                  ? Border.all(color: const Color(0xFFECE9E3))
                  : null,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: assistant ? null : Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: PawmartColors.greenPale,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          backgroundColor: PawmartColors.green,
          child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trợ lý PawMart',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Hỏi tự do hoặc nhận gợi ý theo hồ sơ thú cưng.',
                style: TextStyle(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advice});
  final String advice;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: PawmartColors.line),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pets_rounded, color: PawmartColors.green, size: 19),
            SizedBox(width: 8),
            Text(
              'Gợi ý dinh dưỡng',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(advice, style: const TextStyle(height: 1.5, fontSize: 14)),
      ],
    ),
  );
}

class _State extends StatelessWidget {
  const _State({
    required this.message,
    required this.action,
    required this.onPressed,
  });
  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets_rounded, color: PawmartColors.green, size: 44),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton(onPressed: onPressed, child: Text(action)),
        ],
      ),
    ),
  );
}
