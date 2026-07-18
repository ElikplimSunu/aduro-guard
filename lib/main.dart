import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

void main() {
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
              FilledButton(onPressed: () {}, child: const Text('Scan a medicine')),
            ],
          ),
        ),
      ),
    );
  }
}
