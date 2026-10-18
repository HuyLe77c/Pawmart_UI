import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ui/core/app_dependencies.dart';
import 'ui/core/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies.create(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:5165',
      ),
    );
    _dependencies.authViewModel.initialize();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider.value(value: _dependencies.apiClient),
      Provider.value(value: _dependencies),
      Provider.value(value: _dependencies.authRepository),
      ChangeNotifierProvider.value(value: _dependencies.authViewModel),
    ],
    child: MaterialApp.router(
      title: 'PawMart',
      debugShowCheckedModeBanner: false,
      theme: PawmartTheme.light,
      routerConfig: _dependencies.router,
    ),
  );

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }
}
