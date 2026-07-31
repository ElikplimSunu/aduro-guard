import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'services/gemma.dart';
import 'services/prefs.dart';
import 'services/registry.dart';
import 'services/tts.dart';
import 'theme/theme.dart';

/// Lets screens refresh when the user navigates back to them.
final routeObserver = RouteObserver<PageRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.instance.load();
  Registry.instance.load(); // warm the snapshot; screens await it again
  // Deliberately NOT warming a voice here. Voice models load through native
  // sherpa-onnx code, so a corrupt or mismatched one aborts the process
  // instead of throwing; warming at launch turns that into an app that
  // cannot start at all and can only be recovered by clearing data. Voices
  // warm on the result screen instead, where a failure costs one screen.
  // Load the model on launch, not on the first scan: a cold 2.4GB load
  // competing with whatever else the phone is running is exactly when it
  // fails, and it fails in front of the user. Best effort, never throws.
  if (Prefs.instance.modelFile.isNotEmpty) Gemma.instance.warmUp();
  runApp(const AduroApp());
}

class AduroApp extends StatefulWidget {
  const AduroApp({super.key});

  /// Called by Settings when the user changes appearance.
  static void setThemeMode(BuildContext context, ThemeMode mode) {
    Prefs.instance.themeMode = mode.name;
    context.findAncestorStateOfType<_AduroAppState>()!._apply(mode);
  }

  /// Called wherever the user changes language; rebuilds the whole tree so
  /// every S.* string re-resolves.
  static void setLanguage(BuildContext context, String code) {
    Prefs.instance.language = code;
    Tts.instance.warmUp(code); // pre-load the new language's voice
    context.findAncestorStateOfType<_AduroAppState>()!._rebuild();
  }

  @override
  State<AduroApp> createState() => _AduroAppState();
}

class _AduroAppState extends State<AduroApp> {
  ThemeMode _mode = ThemeMode.values
      .firstWhere((m) => m.name == Prefs.instance.themeMode,
          orElse: () => ThemeMode.system);

  void _apply(ThemeMode mode) => setState(() => _mode = mode);

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aduro Guard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: _mode,
      navigatorObservers: [routeObserver],
      home: Prefs.instance.onboarded
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
