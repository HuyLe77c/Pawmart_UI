import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../data/repositories/pets_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../../domain/models/pet_profile.dart';
import '../../../core/app_theme.dart';
import '../../../core/widgets/feedback_states.dart';
import '../view_models/pets_view_model.dart';
import '../../../core/picked_image.dart';
import '../../../core/widgets/pet_illustrations.dart';

class PetProfilesScreen extends StatelessWidget {
  const PetProfilesScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) =>
        PetsViewModel(PetsRepository(context.read<ApiClient>()))..load(),
    child: const _PetProfilesContent(),
  );
}

class _PetProfilesContent extends StatelessWidget {
  const _PetProfilesContent();

  Future<void> _openForm(BuildContext context, {PetProfile? pet}) async {
    final viewModel = context.read<PetsViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .96,
      ),
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider<PetsViewModel>.value(
        value: viewModel,
        child: PetProfileEditorSheet(pet: pet),
      ),
    );
  }

  Future<void> _delete(BuildContext context, PetProfile pet) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hồ sơ thú cưng?'),
        content: Text('Hồ sơ ${pet.petName} sẽ bị xóa khỏi tài khoản.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    final viewModel = context.read<PetsViewModel>();
    if (!await viewModel.delete(pet.petId) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Không xóa được hồ sơ.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<PetsViewModel>(
    builder: (context, model, _) => Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F5ED),
        title: const Text(
          'Hồ sơ của tôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm hồ sơ',
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_rounded, color: PawmartColors.green),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () => context.read<AuthViewModel>().signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: PetProfileBackdrop(
        child: model.isLoading && model.pets.isEmpty
            ? const LoadingState()
            : model.errorMessage != null && model.pets.isEmpty
            ? ErrorPanel(message: model.errorMessage!, onRetry: model.load)
            : model.pets.isEmpty
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: RefreshIndicator(
                    onRefresh: model.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                      children: [
                        const _AccountHeader(),
                        const SizedBox(height: 22),
                        Card(
                          child: EmptyState(
                            title: 'Thêm thành viên bốn chân',
                            message: 'Lưu tuổi, giống và cân nặng để nhận gợi ý thức ăn phù hợp.',
                            actionLabel: 'Tạo hồ sơ cho bé',
                            onAction: () => _openForm(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: RefreshIndicator(
                    onRefresh: model.load,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                      itemCount: model.pets.length + 2,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == 0) return const _AccountHeader();
                        if (index == 1) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(2, 12, 0, 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Các bé của tôi',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${model.pets.length} thành viên trong gia đình',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: PawmartColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _openForm(context),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Thêm bé'),
                                ),
                              ],
                            ),
                          );
                        }
                        final pet = model.pets[index - 2];
                        return PetProfileCard(
                          key: ValueKey(pet.petId),
                          pet: pet,
                          onEdit: () => _openForm(context, pet: pet),
                          onDelete: () => _delete(context, pet),
                          onAssistant: () => context.go(
                            '/customer/assistant?petId=${pet.petId}',
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
      ),
    ),
  );
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().user;
    final pets = context.watch<PetsViewModel>().pets;
    final name = user?.fullName.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: PawmartColors.greenDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .2)),
        boxShadow: [
          BoxShadow(
            color: PawmartColors.greenDark.withValues(alpha: .12),
            offset: const Offset(0, 10),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2D7A4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    name.isEmpty ? 'P' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: PawmartColors.greenDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GIA ĐÌNH PAWMART',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF2D7A4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name.isEmpty ? 'Tài khoản PawMart' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (user?.email.isNotEmpty == true)
                      Text(
                        user!.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC9E9D8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final roomy = constraints.maxWidth > 460;
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nhà có boss,\nvui mỗi ngày.',
                      style: TextStyle(
                        fontSize: roomy ? 34 : 26,
                        height: 1.16,
                        letterSpacing: -.8,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFF8E9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: roomy ? 154 : 116,
                    child: const PetFamilyArtwork(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Một góc nhỏ dành riêng cho những thành viên bốn chân bạn yêu thương.',
            style: TextStyle(
              color: Color(0xFFC9E9D8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _FamilyCount(
                  icon: Icons.pets_outlined,
                  value: '${pets.length}',
                  label: 'thú cưng',
                ),
                if (pets.any((pet) => pet.petType == 'DOG'))
                  _FamilyCount(
                    icon: Icons.favorite_outline,
                    value:
                        '${pets.where((pet) => pet.petType == 'DOG').length}',
                    label: 'bé chó',
                  ),
                if (pets.any((pet) => pet.petType == 'CAT'))
                  _FamilyCount(
                    icon: Icons.favorite_outline,
                    value:
                        '${pets.where((pet) => pet.petType == 'CAT').length}',
                    label: 'bé mèo',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyCount extends StatelessWidget {
  const _FamilyCount({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: const Color(0xFFC9E9D8)),
      const SizedBox(width: 7),
      Text(
        '$value $label',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    ],
  );
}

class PetProfileCard extends StatelessWidget {
  const PetProfileCard({
    super.key,
    required this.pet,
    required this.onEdit,
    required this.onDelete,
    required this.onAssistant,
  });
  final PetProfile pet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssistant;

  @override
  Widget build(BuildContext context) {
    final species = switch (pet.petType) {
      'CAT' => 'Mèo',
      'DOG' => 'Chó',
      _ => 'Thú cưng',
    };
    final gender = switch (pet.gender) {
      'MALE' => 'Đực',
      'FEMALE' => 'Cái',
      _ => 'Chưa rõ',
    };
    final imageUrl = pet.imageUrl?.trim().isNotEmpty != true
        ? null
        : context.read<ApiClient>().resolveMediaUri(pet.imageUrl!).toString();
    final missing = [
      if (pet.breed?.trim().isNotEmpty != true) 'giống',
      if (pet.ageMonths == null) 'tuổi',
      if (pet.weightKg == null) 'cân nặng',
      if (pet.gender == 'UNKNOWN') 'giới tính',
    ];
    return Card(
      elevation: 1,
      shadowColor: PawmartColors.greenDark.withValues(alpha: .08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: const BorderSide(color: Color(0xFFE2E6D9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76,
                  height: 84,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: pet.petType == 'DOG'
                        ? PawmartColors.amberPale
                        : PawmartColors.greenPale,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: imageUrl == null
                      ? PetPortraitArtwork(petType: pet.petType)
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              PetPortraitArtwork(petType: pet.petType),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        species.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                          color: PawmartColors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pet.petName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pet.breed?.trim().isNotEmpty == true
                            ? pet.breed!
                            : 'Chưa thêm giống',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: PawmartColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn hồ sơ',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: PawmartColors.error,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Xóa hồ sơ',
                            style: TextStyle(color: PawmartColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PawmartColors.cream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth < 240 ||
                              MediaQuery.textScalerOf(context).scale(14) > 21
                          ? 2
                          : 3;
                      return Wrap(
                        runSpacing: 14,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth / columns,
                            child: _PetMetric(
                              icon: Icons.cake_outlined,
                              label: 'Tuổi',
                              value: _age(pet.ageMonths),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth / columns,
                            child: _PetMetric(
                              icon: Icons.monitor_weight_outlined,
                              label: 'Cân nặng',
                              value: pet.weightKg == null
                                  ? 'Chưa rõ'
                                  : '${pet.weightKg} kg',
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth / columns,
                            child: _PetMetric(
                              icon: pet.gender == 'MALE'
                                  ? Icons.male_rounded
                                  : pet.gender == 'FEMALE'
                                  ? Icons.female_rounded
                                  : Icons.pets_outlined,
                              label: 'Giới tính',
                              value: gender,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (pet.bodySize != null ||
                    pet.activityLevel != null ||
                    pet.bodyConditionScore != null) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (pet.bodySize != null)
                        _PetTag(
                          label: switch (pet.bodySize) {
                            'SMALL' => 'Dáng nhỏ',
                            'MEDIUM' => 'Dáng vừa',
                            'LARGE' => 'Dáng lớn',
                            _ => pet.bodySize!,
                          },
                        ),
                      if (pet.activityLevel != null)
                        _PetTag(
                          label: switch (pet.activityLevel) {
                            'LOW' => 'Ít vận động',
                            'MODERATE' => 'Vận động vừa',
                            'HIGH' => 'Nhiều năng lượng',
                            _ => pet.activityLevel!,
                          },
                        ),
                      if (pet.bodyConditionScore != null)
                        _PetTag(label: 'Thể trạng ${pet.bodyConditionScore}/9'),
                    ],
                  ),
                ],
                if (pet.feedingHabits?.trim().isNotEmpty == true ||
                    pet.foodPreferences?.trim().isNotEmpty == true ||
                    pet.specialNotes?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    title: const Text(
                      'Hiểu bé hơn',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Thói quen, khẩu vị & lưu ý',
                      style: TextStyle(
                        fontSize: 12,
                        color: PawmartColors.muted,
                      ),
                    ),
                    children: [
                      if (pet.feedingHabits?.trim().isNotEmpty == true)
                        _PetDetail(
                          icon: Icons.schedule_outlined,
                          title: 'Thói quen ăn uống',
                          text: pet.feedingHabits!,
                        ),
                      if (pet.foodPreferences?.trim().isNotEmpty == true)
                        _PetDetail(
                          icon: Icons.restaurant_outlined,
                          title: 'Khẩu vị yêu thích',
                          text: pet.foodPreferences!,
                        ),
                      if (pet.specialNotes?.trim().isNotEmpty == true)
                        _PetDetail(
                          icon: Icons.favorite_outline_rounded,
                          title: 'Lưu ý chăm sóc',
                          text: pet.specialNotes!,
                        ),
                    ],
                  ),
                ],
                if (missing.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 16,
                        color: PawmartColors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Thông tin cơ bản: ${4 - missing.length}/4',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (4 - missing.length) / 4,
                      minHeight: 4,
                      backgroundColor: PawmartColors.greenPale,
                      semanticsLabel: 'Mức hoàn thiện thông tin cơ bản',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bổ sung ${missing.join(', ')} để PawMart hiểu bé hơn.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PawmartColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onEdit,
                        child: const Text('Chỉnh sửa'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: onAssistant,
                        child: const Text('Tư vấn'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _age(int? months) {
    if (months == null) return 'Chưa rõ';
    final years = months ~/ 12;
    final remain = months % 12;
    if (years == 0) return '$months tháng';
    return remain == 0 ? '$years tuổi' : '$years tuổi $remain tháng';
  }
}

class _PetDetail extends StatelessWidget {
  const _PetDetail({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: PawmartColors.green),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: PawmartColors.muted,
                ),
              ),
              const SizedBox(height: 3),
              Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PetMetric extends StatelessWidget {
  const _PetMetric({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: PawmartColors.green),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: PawmartColors.muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _PetTag extends StatelessWidget {
  const _PetTag({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: PawmartColors.greenPale,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: PawmartColors.greenDark,
      ),
    ),
  );
}

class PetProfileEditorSheet extends StatefulWidget {
  const PetProfileEditorSheet({super.key, this.pet});
  final PetProfile? pet;

  @override
  State<PetProfileEditorSheet> createState() => _PetFormSheetState();
}

class _PetFormSheetState extends State<PetProfileEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _ageYears;
  late final TextEditingController _ageMonths;
  late final TextEditingController _weight;
  late final TextEditingController _notes;
  late final TextEditingController _feedingHabits;
  late final TextEditingController _foodPreferences;
  late String _type;
  late String _gender;
  String? _bodySize;
  String? _activityLevel;
  int? _bodyConditionScore;
  XFile? _selectedPhoto;
  bool _saving = false;
  String? _error;

  static const _maxPhotoBytes = 20 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _name = TextEditingController(text: pet?.petName ?? '');
    _breed = TextEditingController(text: pet?.breed ?? '');
    _ageYears = TextEditingController(
      text: pet?.ageMonths == null ? '' : '${pet!.ageMonths! ~/ 12}',
    );
    _ageMonths = TextEditingController(
      text: pet?.ageMonths == null ? '' : '${pet!.ageMonths! % 12}',
    );
    _weight = TextEditingController(text: pet?.weightKg?.toString() ?? '');
    _notes = TextEditingController(text: pet?.specialNotes ?? '');
    _feedingHabits = TextEditingController(text: pet?.feedingHabits ?? '');
    _foodPreferences = TextEditingController(text: pet?.foodPreferences ?? '');
    _type = pet?.petType ?? 'DOG';
    _gender = pet?.gender ?? 'UNKNOWN';
    _bodySize = pet?.bodySize;
    _activityLevel = pet?.activityLevel;
    _bodyConditionScore = pet?.bodyConditionScore;
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _ageYears.dispose();
    _ageMonths.dispose();
    _weight.dispose();
    _notes.dispose();
    _feedingHabits.dispose();
    _foodPreferences.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'Kiểm tra lại các ô được đánh dấu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final yearsText = _ageYears.text.trim();
    final monthsText = _ageMonths.text.trim();
    final weightText = _weight.text.trim().replaceAll(',', '.');
    final ageMonths = yearsText.isEmpty && monthsText.isEmpty
        ? null
        : (int.parse(yearsText.isEmpty ? '0' : yearsText) * 12) +
              int.parse(monthsText.isEmpty ? '0' : monthsText);
    final weight = weightText.isEmpty ? null : double.tryParse(weightText);
    final PetsViewModel viewModel;
    try {
      viewModel = context.read<PetsViewModel>();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Không mở được chức năng lưu hồ sơ. Hãy đóng và thử lại.';
      });
      return;
    }

    final bool saved;
    try {
      saved = await viewModel.save(
        petId: widget.pet?.petId,
        request: {
          'petName': _name.text.trim(),
          'petType': _type,
          'gender': _gender,
          'breed': _breed.text.trim().isEmpty ? null : _breed.text.trim(),
          'ageMonths': ageMonths,
          'weightKg': weight,
          'specialNotes': _notes.text.trim().isEmpty
              ? null
              : _notes.text.trim(),
          'bodySize': _bodySize,
          'activityLevel': _activityLevel,
          'bodyConditionScore': _bodyConditionScore,
          'feedingHabits': _feedingHabits.text.trim().isEmpty
              ? null
              : _feedingHabits.text.trim(),
          'foodPreferences': _foodPreferences.text.trim().isEmpty
              ? null
              : _foodPreferences.text.trim(),
        },
        photo: _selectedPhoto,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Không lưu được hồ sơ thú cưng. Vui lòng thử lại.';
      });
      return;
    }
    if (!mounted) return;
    if (saved) {
      final photoError = viewModel.errorMessage;
      if (photoError != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(photoError)));
      }
      Navigator.pop(context);
    } else {
      setState(() {
        _saving = false;
        _error = viewModel.errorMessage;
      });
    }
  }

  Future<void> _choosePhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        setState(() => _error = 'Ảnh phải có định dạng JPG, PNG hoặc WebP.');
        return;
      }
      if (await file.length() > _maxPhotoBytes) {
        setState(() => _error = 'Ảnh vượt quá giới hạn 20 MB.');
        return;
      }
      setState(() {
        _selectedPhoto = file;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không mở được camera hoặc thư viện ảnh.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final keyboard = MediaQuery.viewInsetsOf(context).bottom;
      final available = (constraints.maxHeight - keyboard)
          .clamp(0.0, double.infinity)
          .toDouble();
      final preferred = MediaQuery.sizeOf(context).height * .94;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SizedBox(
          height: available < preferred ? available : preferred,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: PawmartColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: PawmartColors.greenDark,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 17, 12, 18),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.pet == null
                                        ? 'Tạo hồ sơ cho bé'
                                        : 'Chỉnh sửa hồ sơ',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    widget.pet == null
                                        ? 'Để PawMart hiểu bé hơn mỗi ngày'
                                        : 'Cập nhật thông tin của ${widget.pet!.petName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFC9E9D8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Đóng',
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PetPhotoPicker(
                            selectedPhoto: _selectedPhoto,
                            existingImageUrl: widget.pet?.imageUrl,
                            onCamera: () => _choosePhoto(ImageSource.camera),
                            onGallery: () => _choosePhoto(ImageSource.gallery),
                          ),
                          const SizedBox(height: 16),
                          _PetFormSection(
                            icon: Icons.badge_outlined,
                            title: 'Thông tin cơ bản',
                            subtitle: 'Những điều đầu tiên cần biết về bé',
                            children: [
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Tên thú cưng *',
                                  hintText: 'Ví dụ: Miu, Bông, Lucky',
                                ),
                                validator: (v) =>
                                    (v?.trim().isNotEmpty ?? false)
                                    ? null
                                    : 'Nhập tên thú cưng.',
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bé là',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _PetTypeChoice(
                                          label: 'Chó',
                                          icon: Icons.pets_outlined,
                                          selected: _type == 'DOG',
                                          onTap: () =>
                                              setState(() => _type = 'DOG'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _PetTypeChoice(
                                          label: 'Mèo',
                                          icon: Icons.pets_rounded,
                                          selected: _type == 'CAT',
                                          onTap: () =>
                                              setState(() => _type = 'CAT'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Giới tính',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ChoiceChip(
                                        label: const Text('Đực'),
                                        avatar: const Icon(
                                          Icons.male_rounded,
                                          size: 18,
                                        ),
                                        selected: _gender == 'MALE',
                                        onSelected: (_) =>
                                            setState(() => _gender = 'MALE'),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Cái'),
                                        avatar: const Icon(
                                          Icons.female_rounded,
                                          size: 18,
                                        ),
                                        selected: _gender == 'FEMALE',
                                        onSelected: (_) =>
                                            setState(() => _gender = 'FEMALE'),
                                      ),
                                      ChoiceChip(
                                        label: const Text('Chưa rõ'),
                                        selected: _gender == 'UNKNOWN',
                                        onSelected: (_) =>
                                            setState(() => _gender = 'UNKNOWN'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextFormField(
                                controller: _breed,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Giống',
                                  hintText: 'Ví dụ: Poodle, Anh lông ngắn',
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tuổi của bé',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _ageYears,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Năm',
                                            hintText: '1',
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return null;
                                            }
                                            final years = int.tryParse(
                                              v.trim(),
                                            );
                                            return years == null ||
                                                    years < 0 ||
                                                    years > 50
                                                ? '0–50 năm'
                                                : null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _ageMonths,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Tháng',
                                            hintText: '6',
                                          ),
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return null;
                                            }
                                            final months = int.tryParse(
                                              v.trim(),
                                            );
                                            final years =
                                                int.tryParse(
                                                  _ageYears.text.trim(),
                                                ) ??
                                                0;
                                            return months == null ||
                                                    months < 0 ||
                                                    months > 11 ||
                                                    (years == 50 && months > 0)
                                                ? '0–11 tháng'
                                                : null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextFormField(
                                controller: _weight,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Cân nặng (kg)',
                                  hintText: '4,2',
                                ),
                                validator: (v) {
                                  if ((v ?? '').trim().isEmpty) {
                                    return null;
                                  }
                                  final n = double.tryParse(
                                    v!.trim().replaceAll(',', '.'),
                                  );
                                  return n == null || n <= 0 || n > 999
                                      ? 'Cân nặng không hợp lệ.'
                                      : null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _PetFormSection(
                            icon: Icons.monitor_heart_outlined,
                            title: 'Thể trạng & vận động',
                            subtitle: 'Giúp tư vấn khẩu phần phù hợp hơn',
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _bodySize,
                                decoration: const InputDecoration(
                                  labelText: 'Kích cỡ của bé',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'SMALL',
                                    child: Text('Nhỏ'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MEDIUM',
                                    child: Text('Vừa'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'LARGE',
                                    child: Text('Lớn'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _bodySize = value),
                              ),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _activityLevel,
                                decoration: const InputDecoration(
                                  labelText: 'Mức vận động',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'LOW',
                                    child: Text('Ít vận động'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MODERATE',
                                    child: Text('Vận động vừa'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'HIGH',
                                    child: Text('Vận động nhiều'),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _activityLevel = value),
                              ),
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: _bodyConditionScore,
                                decoration: const InputDecoration(
                                  labelText: 'Điểm thể trạng (1–9)',
                                  helperText:
                                      'Nếu chưa rõ, hãy hỏi bác sĩ thú y.',
                                ),
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('Chưa rõ'),
                                  ),
                                  ...List.generate(
                                    9,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('${i + 1}/9'),
                                    ),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _bodyConditionScore = value),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _PetFormSection(
                            icon: Icons.restaurant_menu_rounded,
                            title: 'Ăn uống & sức khỏe',
                            subtitle: 'Cá nhân hóa gợi ý cho riêng bé',
                            children: [
                              TextFormField(
                                controller: _feedingHabits,
                                maxLength: 500,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Thói quen ăn',
                                  hintText: 'Ăn chậm, thích nhiều bữa nhỏ…',
                                ),
                              ),
                              TextFormField(
                                controller: _foodPreferences,
                                maxLength: 500,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Sở thích ăn uống',
                                  hintText: 'Thích cá, không thích hạt lớn…',
                                ),
                              ),
                              TextFormField(
                                controller: _notes,
                                maxLines: 3,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: const InputDecoration(
                                  labelText: 'Sức khỏe và dị ứng',
                                  hintText: 'Điều cần lưu ý khi chọn thức ăn',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: PawmartColors.line)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_error != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 17,
                                  color: PawmartColors.error,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: PawmartColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(
                                widget.pet == null
                                    ? 'Tạo hồ sơ'
                                    : 'Lưu thay đổi',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PetTypeChoice extends StatelessWidget {
  const _PetTypeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? PawmartColors.green : PawmartColors.cream,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : PawmartColors.green,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : PawmartColors.ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PetFormSection extends StatelessWidget {
  const _PetFormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: PawmartColors.line),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: PawmartColors.greenPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: PawmartColors.green),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PawmartColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: 12),
          children[index],
        ],
      ],
    ),
  );
}

class _PetPhotoPicker extends StatelessWidget {
  const _PetPhotoPicker({
    required this.selectedPhoto,
    required this.existingImageUrl,
    required this.onCamera,
    required this.onGallery,
  });

  final XFile? selectedPhoto;
  final String? existingImageUrl;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final existingUri = existingImageUrl == null || existingImageUrl!.isEmpty
        ? null
        : context
              .read<ApiClient>()
              .resolveMediaUri(existingImageUrl!)
              .toString();
    Widget placeholder() => const ColoredBox(
      color: Colors.white,
      child: Icon(Icons.pets_rounded, size: 46, color: PawmartColors.green),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PawmartColors.greenPale,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Chọn ảnh của bé',
            child: GestureDetector(
              onTap: onGallery,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: 110,
                      height: 122,
                      child: selectedPhoto != null
                          ? PickedImage(
                              file: selectedPhoto!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => placeholder(),
                            )
                          : existingUri == null
                          ? placeholder()
                          : Image.network(
                              existingUri,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => placeholder(),
                            ),
                    ),
                  ),
                  Positioned(
                    right: -5,
                    bottom: -5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: PawmartColors.green,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh của bé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PawmartColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Thêm ảnh để hồ sơ gần gũi hơn.',
                  style: TextStyle(
                    fontSize: 12,
                    color: PawmartColors.muted,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 17),
                    label: const Text('Thư viện'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.photo_camera_outlined, size: 17),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
