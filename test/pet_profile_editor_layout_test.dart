import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pawmart/data/repositories/pets_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/pet_profile.dart';
import 'package:pawmart/ui/core/app_theme.dart';
import 'package:pawmart/ui/features/pets/view_models/pets_view_model.dart';
import 'package:pawmart/ui/features/pets/views/pet_profiles_screen.dart';

class _RecordingPetsRepository extends PetsRepository {
  _RecordingPetsRepository()
    : super(ApiClient(baseUrl: 'http://localhost', tokenStore: TokenStore()));

  Map<String, Object?>? savedRequest;

  @override
  Future<PetProfile> update(int petId, Map<String, Object?> request) async {
    savedRequest = request;
    return PetProfile(
      petId: petId,
      petName: request['petName']! as String,
      petType: request['petType']! as String,
      ageMonths: request['ageMonths'] as int?,
      weightKg: request['weightKg'] as double?,
    );
  }
}

void main() {
  Future<void> openEditor(
    WidgetTester tester, {
    PetProfile? pet,
    PetsViewModel? viewModel,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = MaterialApp(
      theme: PawmartTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.25)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .96,
                ),
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => PetProfileEditorSheet(pet: pet),
              ),
              child: const Text('Mở hồ sơ'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      viewModel == null
          ? app
          : ChangeNotifierProvider<PetsViewModel>.value(
              value: viewModel,
              child: app,
            ),
    );
    await tester.tap(find.text('Mở hồ sơ'));
    await tester.pumpAndSettle();
  }

  testWidgets('Màn sửa hồ sơ vừa khung nhỏ với chữ lớn', (tester) async {
    const pet = PetProfile(
      petId: 1,
      petName: 'Miu',
      petType: 'CAT',
      breed: 'Mèo Anh lông ngắn',
      ageMonths: 18,
      weightKg: 4.2,
    );
    await openEditor(tester, pet: pet);

    expect(find.text('Chỉnh sửa hồ sơ'), findsOneWidget);
    expect(find.text('Thông tin cơ bản'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lỗi nhập liệu vẫn nhìn thấy cạnh nút lưu', (tester) async {
    await openEditor(tester);
    await tester.tap(find.text('Tạo hồ sơ'));
    await tester.pump();

    expect(find.text('Kiểm tra lại các ô được đánh dấu.'), findsOneWidget);
    expect(find.text('Tạo hồ sơ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nút lưu vẫn hiển thị khi bàn phím mở', (tester) async {
    const pet = PetProfile(petId: 1, petName: 'Miu', petType: 'CAT');
    await openEditor(tester, pet: pet);
    addTearDown(tester.view.resetViewInsets);

    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextFormField).first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();

    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(tester.getBottomLeft(find.text('Lưu thay đổi')).dy, lessThan(800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Thẻ hồ sơ dài không tràn trên điện thoại hẹp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const pet = PetProfile(
      petId: 1,
      petName: 'Mèo Miu rất dễ thương',
      petType: 'CAT',
      breed: 'Mèo Anh lông ngắn lai nhiều giống khác',
      ageMonths: 19,
      weightKg: 4.2,
      bodySize: 'SMALL',
      activityLevel: 'MODERATE',
      bodyConditionScore: 5,
      specialNotes: 'Dị ứng với một số thực phẩm, cần theo dõi khi đổi món.',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PawmartTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.25)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: PetProfileCard(
                pet: pet,
                onEdit: () {},
                onDelete: () {},
                onAssistant: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Chỉnh sửa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Lưu chỉnh sửa gửi đúng dữ liệu hồ sơ', (tester) async {
    final repository = _RecordingPetsRepository();
    final viewModel = PetsViewModel(repository);
    const pet = PetProfile(
      petId: 12,
      petName: 'Miu',
      petType: 'CAT',
      ageMonths: 18,
      weightKg: 4.2,
    );
    await openEditor(tester, pet: pet, viewModel: viewModel);
    final monthsField = find.widgetWithText(TextFormField, 'Tháng');
    await tester.ensureVisible(monthsField);
    await tester.pumpAndSettle();
    await tester.enterText(monthsField, '2');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();

    expect(repository.savedRequest, containsPair('petName', 'Miu'));
    expect(repository.savedRequest, containsPair('petType', 'CAT'));
    expect(repository.savedRequest, containsPair('ageMonths', 14));
    expect(repository.savedRequest, containsPair('weightKg', 4.2));
    expect(find.text('Chỉnh sửa hồ sơ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Không nhận số tháng từ 12 trở lên', (tester) async {
    await openEditor(tester);
    final monthsField = find.widgetWithText(TextFormField, 'Tháng');
    await tester.ensureVisible(monthsField);
    await tester.pumpAndSettle();
    await tester.enterText(monthsField, '12');
    tester.testTextInput.hide();
    await tester.tap(find.text('Tạo hồ sơ'));
    await tester.pump();

    expect(find.text('0–11 tháng'), findsOneWidget);
    expect(find.text('Kiểm tra lại các ô được đánh dấu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
