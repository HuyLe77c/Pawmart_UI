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
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNotifierProvider<PetsViewModel>.value(
        value: viewModel,
        child: _PetFormSheet(pet: pet),
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
        centerTitle: true,
        title: const Text(
          'Hồ sơ thú cưng',
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
                children: const [
                  SizedBox(height: 90),
                  EmptyState(
                    title: 'Thêm thành viên bốn chân',
                    message: 'Lưu tuổi, giống và cân nặng để nhận gợi ý thức ăn phù hợp.',
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: model.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                itemCount: model.pets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final pet = model.pets[index];
                  return _PetCard(
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

class _PetCard extends StatelessWidget {
  const _PetCard({
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
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: PawmartColors.greenPale,
                child: pet.imageUrl == null
                    ? Icon(
                        pet.petType == 'CAT' ? Icons.pets : Icons.pets_outlined,
                        color: PawmartColors.green,
                      )
                    : ClipOval(
                        child: Image.network(
                          context
                              .read<ApiClient>()
                              .resolveMediaUri(pet.imageUrl!)
                              .toString(),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            pet.petType == 'CAT'
                                ? Icons.pets
                                : Icons.pets_outlined,
                            color: PawmartColors.green,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.petName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${pet.petType == 'CAT'
                          ? 'Mèo'
                          : pet.petType == 'DOG'
                          ? 'Chó'
                          : 'Thú cưng'} · ${pet.breed ?? 'Chưa rõ giống'}',
                      style: const TextStyle(
                        color: PawmartColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_age(pet.ageMonths)} · ${pet.weightKg == null ? 'Chưa có cân nặng' : '${pet.weightKg} kg'}',
                      style: const TextStyle(
                        color: PawmartColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (pet.bodySize != null ||
                        pet.activityLevel != null ||
                        pet.bodyConditionScore != null)
                      Text(
                        [
                          if (pet.bodySize != null)
                            'Size ${switch (pet.bodySize) {
                              'SMALL' => 'nhỏ',
                              'MEDIUM' => 'vừa',
                              'LARGE' => 'lớn',
                              _ => pet.bodySize!,
                            }}',
                          if (pet.activityLevel != null)
                            'Vận động ${switch (pet.activityLevel) {
                              'LOW' => 'ít',
                              'MODERATE' => 'vừa',
                              'HIGH' => 'nhiều',
                              _ => pet.activityLevel!,
                            }}',
                          if (pet.bodyConditionScore != null)
                            'Thể trạng ${pet.bodyConditionScore}/9',
                        ].join(' · '),
                        style: const TextStyle(
                          color: PawmartColors.muted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (pet.specialNotes?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pet.specialNotes!,
                style: const TextStyle(color: PawmartColors.muted),
              ),
            ),
          ],
          if (pet.feedingHabits?.isNotEmpty ?? false)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Thói quen ăn: ${pet.feedingHabits}',
                style: const TextStyle(color: PawmartColors.muted),
              ),
            ),
          if (pet.foodPreferences?.isNotEmpty ?? false)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sở thích: ${pet.foodPreferences}',
                style: const TextStyle(color: PawmartColors.muted),
              ),
            ),
          const Divider(height: 28),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Chỉnh sửa'),
              ),
              const Spacer(),
              TextButton(onPressed: onAssistant, child: const Text('Tư vấn')),
              IconButton(
                tooltip: 'Xóa',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: PawmartColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  static String _age(int? months) {
    if (months == null) return 'Chưa có tuổi';
    final years = months ~/ 12;
    final remain = months % 12;
    if (years == 0) return '$months tháng tuổi';
    return remain == 0 ? '$years tuổi' : '$years tuổi $remain tháng';
  }
}

class _PetFormSheet extends StatefulWidget {
  const _PetFormSheet({this.pet});
  final PetProfile? pet;

  @override
  State<_PetFormSheet> createState() => _PetFormSheetState();
}

class _PetFormSheetState extends State<_PetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _age;
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
    _age = TextEditingController(
      text: pet?.ageMonths == null
          ? ''
          : (pet!.ageMonths! / 12).toStringAsFixed(
              pet.ageMonths! % 12 == 0 ? 0 : 1,
            ),
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
    _age.dispose();
    _weight.dispose();
    _notes.dispose();
    _feedingHabits.dispose();
    _foodPreferences.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final ageText = _age.text.trim().replaceAll(',', '.');
    final weightText = _weight.text.trim().replaceAll(',', '.');
    final years = ageText.isEmpty ? null : double.tryParse(ageText);
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
          'ageMonths': years == null ? null : (years * 12).round(),
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      decoration: const BoxDecoration(
        color: PawmartColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.pet == null ? 'Thêm hồ sơ thú cưng' : 'Cập nhật hồ sơ',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _PetPhotoPicker(
                selectedPhoto: _selectedPhoto,
                existingImageUrl: widget.pet?.imageUrl,
                onCamera: () => _choosePhoto(ImageSource.camera),
                onGallery: () => _choosePhoto(ImageSource.gallery),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Tên thú cưng'),
                validator: (v) => (v?.trim().isNotEmpty ?? false)
                    ? null
                    : 'Nhập tên thú cưng.',
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'DOG',
                    label: Text('Chó'),
                    icon: Icon(Icons.pets),
                  ),
                  ButtonSegment(
                    value: 'CAT',
                    label: Text('Mèo'),
                    icon: Icon(Icons.pets_outlined),
                  ),
                ],
                selected: {_type == 'CAT' ? 'CAT' : 'DOG'},
                onSelectionChanged: (selected) =>
                    setState(() => _type = selected.first),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breed,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Giống'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _age,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tuổi (năm)',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(
                          v.trim().replaceAll(',', '.'),
                        );
                        return n == null || n < 0 || n > 50
                            ? 'Tuổi không hợp lệ.'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cân nặng (kg)',
                      ),
                      validator: (v) {
                        if ((v ?? '').trim().isEmpty) return null;
                        final n = double.tryParse(
                          v!.trim().replaceAll(',', '.'),
                        );
                        return n == null || n <= 0 || n > 999
                            ? 'Cân nặng không hợp lệ.'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bodySize,
                decoration: const InputDecoration(labelText: 'Kích cỡ của bé'),
                items: const [
                  DropdownMenuItem(value: 'SMALL', child: Text('Nhỏ')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Vừa')),
                  DropdownMenuItem(value: 'LARGE', child: Text('Lớn')),
                ],
                onChanged: (value) => setState(() => _bodySize = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: 'Mức vận động'),
                items: const [
                  DropdownMenuItem(value: 'LOW', child: Text('Ít')),
                  DropdownMenuItem(value: 'MODERATE', child: Text('Vừa')),
                  DropdownMenuItem(value: 'HIGH', child: Text('Nhiều')),
                ],
                onChanged: (value) => setState(() => _activityLevel = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _bodyConditionScore,
                decoration: const InputDecoration(
                  labelText: 'Điểm thể trạng (1–9, nếu đã biết)',
                  helperText:
                      'Nên hỏi bác sĩ thú y nếu chưa biết cách đánh giá.',
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _feedingHabits,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Thói quen ăn',
                  hintText: 'Ví dụ: ăn chậm, thích nhiều bữa nhỏ',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _foodPreferences,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Sở thích ăn uống',
                  hintText: 'Ví dụ: thích cá, không thích hạt lớn',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú sức khỏe và dị ứng',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: PawmartColors.error),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu hồ sơ'),
              ),
            ],
          ),
        ),
      ),
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
    final api = context.read<ApiClient>();
    final existingUri = existingImageUrl == null || existingImageUrl!.isEmpty
        ? null
        : api.resolveMediaUri(existingImageUrl!).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh thú cưng',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 144,
              height: 120,
              child: selectedPhoto != null
                  ? Image.file(File(selectedPhoto!.path), fit: BoxFit.cover)
                  : existingUri == null
                  ? const ColoredBox(
                      color: PawmartColors.greenPale,
                      child: Icon(
                        Icons.pets,
                        size: 42,
                        color: PawmartColors.green,
                      ),
                    )
                  : Image.network(
                      existingUri,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: PawmartColors.greenPale,
                        child: Icon(
                          Icons.pets,
                          size: 42,
                          color: PawmartColors.green,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Chụp ảnh'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Thư viện'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
