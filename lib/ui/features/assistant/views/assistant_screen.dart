import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/app_dependencies.dart';
import '../../../core/app_theme.dart';
import '../../../core/formatters.dart';
import '../view_models/assistant_view_model.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => AssistantViewModel(
      context.read<AppDependencies>().petsRepository,
      context.read<AppDependencies>().recommendationRepository,
    )..loadPets(),
    child: const _AssistantBody(),
  );
}

class _AssistantBody extends StatelessWidget {
  const _AssistantBody();

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
    body: Consumer<AssistantViewModel>(
      builder: (context, model, _) {
        if (model.isLoadingPets)
          return const Center(child: CircularProgressIndicator());
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
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                children: [
                  const _Bubble(
                    message: 'Chào bạn! Mình là trợ lý PawMart. Chọn hồ sơ của bé và gửi yêu cầu để nhận tư vấn dinh dưỡng từ thông tin đã lưu.',
                    assistant: true,
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
                    _Bubble(
                      message: 'Tư vấn cho ${pet.petName}',
                      assistant: false,
                    ),
                    const SizedBox(height: 14),
                    _Bubble(message: result.advice, assistant: true),
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
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFECE9E3))),
              ),
              child: Row(
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
                      onChanged: model.isThinking ? null : model.selectPet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Nhận tư vấn',
                    onPressed: model.isThinking ? null : model.ask,
                    icon: model.isThinking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
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
