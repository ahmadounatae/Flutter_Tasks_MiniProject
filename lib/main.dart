// lib/main.dart
// Point d'entrée de l'application TaskMaster

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'controllers/theme_controller.dart';
import 'utils/app_theme.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialiser les formats de date en français
  await initializeDateFormatting('fr_FR', null);
  runApp(const TaskMasterApp());
}

class TaskMasterApp extends StatefulWidget {
  const TaskMasterApp({super.key});

  @override
  State<TaskMasterApp> createState() => _TaskMasterAppState();
}

class _TaskMasterAppState extends State<TaskMasterApp> {
  final _themeCtrl = ThemeController();

  @override
  void initState() {
    super.initState();
    _themeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _themeCtrl.removeListener(() => setState(() {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskMaster',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeCtrl.themeMode,
      home: const SplashView(),
    );
  }
}
