import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/note_item.dart';
import 'screens/home.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsService().load();
  await NotificationService().initialize();

  try {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];
    final notes = savedNotes
        .map((jsonString) => NoteItem.fromJsonString(jsonString))
        .toList();
    final syncedNotes = await NotificationService().syncNotificationsForNotes(notes);
    await prefs.setStringList(
      'notes',
      syncedNotes.map((note) => note.toJsonString()).toList(),
    );
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SettingsService _settings = SettingsService();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _settings.isDark.addListener(_onSettingsChanged);
    _settings.eyeComfort.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.isDark.removeListener(_onSettingsChanged);
    _settings.eyeComfort.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.isDark.value;
    final eyeComfort = _settings.eyeComfort.value;

    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: eyeComfort ? Colors.amber : Colors.indigo,
      brightness: isDark ? Brightness.dark : Brightness.light,
    );

    final theme = eyeComfort
        ? base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: Colors.amber.shade600,
              secondary: Colors.orange.shade400,
              tertiary: Colors.yellow.shade600,
              surface: isDark ? Colors.grey.shade900 : Colors.yellow.shade50,
            ),
            scaffoldBackgroundColor: isDark
                ? Colors.grey.shade900
                : Colors.yellow.shade50,
          )
        : base;

    final appBarBackgroundColor = theme.scaffoldBackgroundColor;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tazk',
      theme: theme.copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: appBarBackgroundColor,
          foregroundColor: isDark ? Colors.white : Colors.black,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
          actionsIconTheme: IconThemeData(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
