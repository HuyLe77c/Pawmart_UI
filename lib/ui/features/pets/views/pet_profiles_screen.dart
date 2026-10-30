import 'dart:io';

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
      body: model.isLoading && model.pets.isEmpty
          ? const LoadingState()
          : model.errorMessage != null && model.pets.isEmpty
          ? ErrorPanel(message: model.errorMessage!, onRetry: model.load)
          : model.pets.isEmpty
          ? RefreshIndicator(
              onRefresh: model.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  const _AccountHeader(),
                  const SizedBox(height: 34),
                  const EmptyState(
                    title: 'Thêm thành viên bốn chân',
                    message: 'Lưu tuổi, giống và cân nặng để nhận gợi ý thức ăn phù hợp.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tạo hồ sơ cho bé'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: model.load,
              child: ListView.separated(
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
                          const Expanded(
                            child: Text(
                              'Các bé của tôi',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
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
                    pet: pet,
                    onEdit: () => _openForm(context, pet: pet),
                    onDelete: () => _delete(context, pet),
                    onAssistant: () =>
                        context.go('/customer/assistant?petId=${pet.petId}'),
                  );
                },
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
    final name = user?.fullName.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PawmartColors.greenDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: .16),
            child: Text(
              name.isEmpty ? 'P' : name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Tài khoản PawMart' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
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
    );
  }
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
    final weight = pet.weightKg == null ? 'Chưa rõ' : '${pet.weightKg} kg';
    final imageUrl = pet.imageUrl?.trim().isNotEmpty != true
        ? null
        : context.read<ApiClient>().resolveMediaUri(pet.imageUrl!).toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PawmartColors.greenPale,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageUrl == null
                        ? const Icon(
                            Icons.pets_rounded,
                            size: 34,
                            color: PawmartColors.green,
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.pets_rounded,
                              size: 34,
                              color: PawmartColors.green,
                            ),
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
                            letterSpacing: 1,
                            fontWeight: FontWeight.w800,
                            color: PawmartColors.green,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pet.petName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: PawmartColors.ink,
                          ),
                        ),
                        Text(
                          pet.breed?.trim().isNotEmpty == true
                              ? pet.breed!
                              : 'Chưa thêm giống',
                          maxLines: 1,
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
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
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
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PetMetric(
                    icon: Icons.cake_outlined,
                    label: 'Tuổi',
                    value: _age(pet.ageMonths),
                  ),
                ),
                Container(
                  width: 1,
                  height: 42,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: PawmartColors.line,
                ),
                Expanded(
                  child: _PetMetric(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Cân nặng',
                    value: weight,
                  ),
                ),
              ],
            ),
            if (pet.bodySize != null ||
                pet.activityLevel != null ||
                pet.bodyConditionScore != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  if (pet.bodySize != null)
                    _PetTag(
                      label: switch (pet.bodySize) {
                        'SMALL' => 'Size nhỏ',
                        'MEDIUM' => 'Size vừa',
                        'LARGE' => 'Size lớn',
                        _ => pet.bodySize!,
                      },
                    ),
                  if (pet.activityLevel != null)
                    _PetTag(
                      label: switch (pet.activityLevel) {
                        'LOW' => 'Ít vận động',
                        'MODERATE' => 'Vận động vừa',
                        'HIGH' => 'Vận động nhiều',
                        _ => pet.activityLevel!,
                      },
                    ),
                  if (pet.bodyConditionScore != null)
                    _PetTag(label: 'Thể trạng ${pet.bodyConditionScore}/9'),
                ],
              ),
            ],
            if (pet.specialNotes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PawmartColors.cream,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 17,
                      color: PawmartColors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pet.specialNotes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: PawmartColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: onEdit,
                    child: const Text('Chỉnh sửa'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAssistant,
                    child: const Text('Tư vấn'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: PawmartColors.green),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: PawmartColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: PawmartColors.ink,
          ),
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
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: PawmartColors.cream,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: PawmartColors.muted,
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
                          ? Image.file(
                              File(selectedPhoto!.path),
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
