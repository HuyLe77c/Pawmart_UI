import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:pawmart/data/repositories/auth_repository.dart';
import 'package:pawmart/data/repositories/chat_repository.dart';
import 'package:pawmart/data/services/api_client.dart';
import 'package:pawmart/data/services/token_store.dart';
import 'package:pawmart/domain/models/chat_reply.dart';
import 'package:pawmart/ui/core/app_theme.dart';
import 'package:pawmart/ui/features/auth/view_models/auth_view_model.dart';
import 'package:pawmart/ui/features/chat_ai/view_models/chat_ai_view_model.dart';
import 'package:pawmart/ui/features/chat_ai/views/chat_ai_screen.dart';
import 'package:pawmart/ui/features/pets/views/pet_profiles_screen.dart';

class _Tokens extends TokenStore {
  @override
  Future<String?> read() async => null;
}

class _Chat extends ChatRepository {
  _Chat(super.client);
  final messages = <String>[];
  Completer<ChatReply>? pending;
  bool fail = false;
  @override
  Future<ChatReply> send(
    String message,
    List<Map<String, String>> history,
  ) async {
    messages.add(message);
    if (fail) throw StateError('Offline');
    return pending?.future ??
        const ChatReply(
          answer: 'Bạn nên chọn thức ăn phù hợp với tuổi, cân nặng và nhu cầu của bé. Khi đổi thức ăn, hãy chuyển dần trong 7–10 ngày.',
          products: [],
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final configFile = File('.dart_tool/package_config.json').absolute;
      final packages =
          jsonDecode(await configFile.readAsString())['packages'] as List;
      final flutterPackage = packages.firstWhere(
        (package) => package['name'] == 'flutter',
      );
      final flutterDirectory = Directory.fromUri(
        configFile.uri.resolve(flutterPackage['rootUri'] as String),
      );
      final fontDirectory = flutterDirectory.uri.resolve(
        '../../bin/cache/artifacts/material_fonts/',
      );
      for (final family in ['Roboto', 'Ahem']) {
        final loader = FontLoader(family)
          ..addFont(
            File.fromUri(fontDirectory.resolve('roboto-regular.ttf'))
                .readAsBytes()
                .then((bytes) => ByteData.sublistView(bytes)),
          );
        await loader.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(
          File.fromUri(fontDirectory.resolve('MaterialIcons-Regular.otf'))
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await icons.load();
    }
  });
  late ApiClient client;
  late AuthViewModel auth;
  late _Chat repository;
  late ChatAiViewModel chat;
  final captureKey = GlobalKey();
  String? copiedText;

  setUp(() async {
    copiedText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
    final tokens = _Tokens();
    client = ApiClient(
      baseUrl: 'http://localhost',
      tokenStore: tokens,
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode([
            {
              'petId': 1,
              'petName': 'Miu',
              'petType': 'CAT',
              'gender': 'FEMALE',
              'breed': 'Mèo Anh lông ngắn',
              'ageMonths': 18,
              'weightKg': 4.2,
              'bodySize': 'SMALL',
              'activityLevel': 'MODERATE',
              'feedingHabits': 'Ăn hai bữa mỗi ngày, lúc 7 giờ và 18 giờ.',
              'foodPreferences': 'Thích cá hồi và pate mềm.',
              'specialNotes': 'Nhạy cảm với thịt gà. Theo dõi khi đổi thức ăn.',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    auth = AuthViewModel(AuthRepository(client, tokens), tokens);
    await auth.initialize();
    repository = _Chat(client);
    chat = ChatAiViewModel(repository, auth);
  });
  tearDown(() {
    chat.dispose();
    auth.dispose();
    client.close();
  });

  Future<void> mount(
    WidgetTester tester,
    Widget page, {
    Size size = const Size(390, 900),
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: client),
          ChangeNotifierProvider<AuthViewModel>.value(value: auth),
        ],
        child: RepaintBoundary(
          key: captureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: PawmartTheme.light.copyWith(
              textTheme: PawmartTheme.light.textTheme.apply(
                fontFamily: 'Roboto',
              ),
              appBarTheme: PawmartTheme.light.appBarTheme.copyWith(
                titleTextStyle: PawmartTheme.light.appBarTheme.titleTextStyle
                    ?.copyWith(fontFamily: 'Roboto'),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: PawmartTheme.light.filledButtonTheme.style?.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              snackBarTheme: const SnackBarThemeData(
                contentTextStyle: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                ),
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: page,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> snapshot(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('.dart_tool/ui-previews/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final size in [
    const Size(360, 800),
    const Size(900, 900),
    const Size(740, 400),
  ]) {
    testWidgets('Chat welcome adapts to $size and prompts fill composer', (
      tester,
    ) async {
      await mount(
        tester,
        ChatAiScreen(viewModel: chat),
        size: size,
        scale: 1.25,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Ăn ngon, lớn khỏe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ăn ngon, lớn khỏe'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        contains('độ tuổi'),
      );
      expect(repository.messages, isEmpty);
      expect(tester.takeException(), isNull);
    });
    testWidgets('Pet profiles adapt to $size', (tester) async {
      await mount(tester, const PetProfilesScreen(), size: size, scale: 1.25);
      await tester.scrollUntilVisible(
        find.text('1 thành viên trong gia đình'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 thành viên trong gia đình'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Hiểu bé hơn'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hiểu bé hơn'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Khẩu vị yêu thích'));
      expect(find.text('Thích cá hồi và pate mềm.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Chat sends, copies answers, and confirms before clearing', (
    tester,
  ) async {
    await mount(tester, ChatAiScreen(viewModel: chat));
    final send = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Gửi câu hỏi',
    );
    expect(tester.widget<IconButton>(send).onPressed, isNull);
    await tester.enterText(
      find.byType(TextField),
      'Đổi thức ăn cho bé thế nào?',
    );
    await tester.pump();
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(repository.messages, ['Đổi thức ăn cho bé thế nào?']);
    expect(find.text('Sao chép'), findsOneWidget);
    await tester.tap(find.text('Sao chép'));
    await tester.pumpAndSettle();
    expect(copiedText, contains('7–10 ngày'));
    ScaffoldMessenger.of(tester.element(find.byType(TextField)))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await snapshot(tester, 'chat-conversation');
    await tester.tap(find.byTooltip('Xóa hội thoại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giữ lại'));
    await tester.pumpAndSettle();
    expect(chat.entries, hasLength(2));
    await tester.tap(find.byTooltip('Xóa hội thoại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa hội thoại'));
    await tester.pumpAndSettle();
    expect(chat.entries, isEmpty);
    expect(find.text('Chăm bé dễ hơn,\ncùng PawMart.'), findsOneWidget);
  });

  testWidgets('Chat shows pending and retries after an error', (tester) async {
    await mount(tester, ChatAiScreen(viewModel: chat));
    repository.pending = Completer<ChatReply>();
    await tester.enterText(find.byType(TextField), 'Chăm bé thế nào?');
    await tester.pump();
    await tester.tap(find.byTooltip('Gửi câu hỏi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('PawMart đang tìm câu trả lời…'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is IconButton && widget.tooltip == 'Gửi câu hỏi',
            ),
          )
          .onPressed,
      isNull,
    );
    repository.pending!.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa nhận được câu trả lời'), findsOneWidget);
    repository.pending = null;
    await tester.ensureVisible(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(chat.errorMessage, isNull);
    expect(chat.entries, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile visual previews', (tester) async {
    await mount(tester, ChatAiScreen(viewModel: chat));
    await snapshot(tester, 'chat-welcome');
    await mount(tester, const PetProfilesScreen());
    await snapshot(tester, 'pet-profiles');
    await tester.ensureVisible(find.text('Hiểu bé hơn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hiểu bé hơn'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Khẩu vị yêu thích'));
    await snapshot(tester, 'pet-details');
    expect(tester.takeException(), isNull);
  });
}
