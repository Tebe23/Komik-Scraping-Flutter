import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';
import 'screens/main_layout.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'services/notification_service.dart';
import 'services/update_checker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request storage permission
  if (Platform.isAndroid) {
    await Permission.storage.request();
  }

  // Enable high refresh rate
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    // Ignore error on devices that don't support it
  }

  // Initialize services
  await NotificationService().initialize();
  await UpdateCheckerService().initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeService _themeService = ThemeService();
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final isDark = await _themeService.isDarkMode();
    setState(() => _isDarkMode = isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KomikApp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainLayout(),
    );
  }
}
