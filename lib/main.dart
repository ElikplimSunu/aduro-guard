import 'package:flutter/material.dart';
import 'screens/scan.dart';
import 'services/prefs.dart';
import 'services/registry.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

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
      home: const _ScaffoldPreview(),
    );
  }
}

/// Temporary placeholder while screens are built out.
class _ScaffoldPreview extends StatelessWidget {
  const _ScaffoldPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(T.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: T.s8),
              Text('Aduro Guard', style: T.display),
              const SizedBox(height: T.s2),
              Text('Check any medicine before you take it.',
                  style: T.body.copyWith(color: T.neutral600)),
              const SizedBox(height: T.s8),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScanScreen())),
                child: const Text('Scan a medicine'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
