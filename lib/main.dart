import 'package:flutter/material.dart';

import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'services/prefs.dart';
import 'services/registry.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.instance.load();
  Registry.instance.load(); // warm the snapshot; screens await it again
  runApp(const AduroApp());
}

class AduroApp extends StatelessWidget {
  const AduroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aduro Guard',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Prefs.instance.onboarded
          ? const HomeScreen()
          : const OnboardingScreen(),
    );
  }
}
