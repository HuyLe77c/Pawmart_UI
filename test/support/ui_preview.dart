import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawmart/ui/core/app_theme.dart';

Future<void> loadPreviewFonts() async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final config = File('.dart_tool/package_config.json').absolute;
  final packages = jsonDecode(await config.readAsString())['packages'] as List;
  final flutter = packages.firstWhere((value) => value['name'] == 'flutter');
  final fonts = Directory.fromUri(
    config.uri.resolve(flutter['rootUri'] as String),
  ).uri.resolve('../../bin/cache/artifacts/material_fonts/');
  for (final family in ['Roboto', 'Ahem']) {
    await (FontLoader(family)..addFont(
          File.fromUri(fonts.resolve('roboto-regular.ttf'))
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  }
  await (FontLoader('MaterialIcons')..addFont(
        File.fromUri(fonts.resolve('MaterialIcons-Regular.otf'))
            .readAsBytes()
            .then(ByteData.sublistView),
      ))
      .load();
}

ThemeData get previewTheme {
  final theme = PawmartTheme.light;
  const text = WidgetStatePropertyAll(
    TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
  );
  return theme.copyWith(
    chipTheme: theme.chipTheme.copyWith(
      labelStyle: theme.chipTheme.labelStyle?.copyWith(fontFamily: 'Roboto'),
      secondaryLabelStyle: theme.chipTheme.secondaryLabelStyle?.copyWith(
        fontFamily: 'Roboto',
      ),
    ),
    textTheme: theme.textTheme.apply(fontFamily: 'Roboto'),
    appBarTheme: theme.appBarTheme.copyWith(
      titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'Roboto',
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(textStyle: text),
    ),
    textButtonTheme: TextButtonThemeData(
      style: theme.textButtonTheme.style?.copyWith(textStyle: text),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style?.copyWith(textStyle: text),
    ),
  );
}

Future<void> capturePreview(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('.dart_tool/ui-previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
