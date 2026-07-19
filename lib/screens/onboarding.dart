import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../services/gemma.dart';
import '../services/prefs.dart';
import '../theme/tokens.dart';
import 'home.dart';

/// First run: pick a language, set up the offline brain, go.
/// Never shown again once completed.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  String _language = 'en';
  int _progress = -1;
  String _error = '';

  Future<void> _download() async {
    setState(() {
      _progress = 0;
      _error = '';
    });
    try {
      await for (final p in Gemma.instance.download(e2b)) {
        if (!mounted) return;
        setState(() => _progress = p);
      }
      Prefs.instance.modelFile = e2b.fileName;
      _finish();
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = -1;
          _error =
              'The download stopped. Check your connection and try again, or import the file if you already have it.';
        });
      }
    }
  }

  Future<void> _import() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Gemma model', extensions: ['litertlm'])
    ]);
    if (file == null) return;
    setState(() {
      _progress = 0;
      _error = '';
    });
    try {
      await Gemma.instance.importFile(file.path);
      Prefs.instance.modelFile = e2b.fileName;
      _finish();
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = -1;
          _error = 'That file could not be imported.';
        });
      }
    }
  }

  void _finish() {
    Prefs.instance.onboarded = true;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(T.s6),
          child: _step == 0 ? _welcome() : _brain(),
        ),
      ),
    );
  }

  Widget _welcome() {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: T.s12),
        Text('Aduro Guard', style: T.display.copyWith(color: c.ink)),
        const SizedBox(height: T.s3),
        Text(
          'Point your camera at any medicine pack. It gets checked against the Ghana FDA register, right here on your phone, no internet needed.',
          style: T.body.copyWith(color: c.inkMuted, height: 1.6),
        ),
        const SizedBox(height: T.s10),
        Text('Choose your language', style: T.h3),
        const SizedBox(height: T.s3),
        _LangCard(
          title: 'English',
          selected: _language == 'en',
          onTap: () => setState(() => _language = 'en'),
        ),
        const SizedBox(height: T.s3),
        _LangCard(
          title: 'Twi',
          subtitle: 'Nsɛm no bɛba Twi kasa mu',
          selected: _language == 'tw',
          onTap: () => setState(() => _language = 'tw'),
        ),
        const SizedBox(height: T.s3),
        Text(
          'Ewe, Dagbani and Hausa are in Settings.',
          style: T.caption.copyWith(color: context.c.inkMuted),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () {
            Prefs.instance.language = _language;
            setState(() => _step = 1);
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _brain() {
    final c = context.c;
    final downloading = _progress >= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: T.s12),
        Text('Set up the offline brain', style: T.h1.copyWith(color: c.ink)),
        const SizedBox(height: T.s3),
        Text(
          'Aduro Guard reads packs with Gemma 4, a model that lives on your phone. One download of ${e2b.sizeLabel}, best on Wi-Fi, and every scan after that works with no signal at all.',
          style: T.body.copyWith(color: c.inkMuted, height: 1.6),
        ),
        const SizedBox(height: T.s8),
        if (downloading) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(T.rSm),
            child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress / 100, minHeight: 8),
          ),
          const SizedBox(height: T.s3),
          Text('Downloading ${e2b.displayName} · $_progress%',
              style: T.small.copyWith(color: c.inkMuted)),
        ] else ...[
          if (_error.isNotEmpty) ...[
            Text(_error, style: T.body.copyWith(color: c.dangerText)),
            const SizedBox(height: T.s4),
          ],
          FilledButton(
              onPressed: _download,
              child: Text('Download · ${e2b.sizeLabel}')),
          const SizedBox(height: T.s3),
          OutlinedButton(
              onPressed: _import,
              child: const Text('I already have the file')),
          const SizedBox(height: T.s4),
          Text(
            'This is the version sized for everyday phones. A stronger ${e4b.sizeLabel} version for 8 GB phones lives in Settings whenever you want it.',
            style: T.caption.copyWith(color: c.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        if (!downloading)
          Center(
            child: TextButton(
              onPressed: _finish,
              child: const Text('Set up later'),
            ),
          ),
      ],
    );
  }
}

class _LangCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangCard({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(T.rMd),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(T.rMd),
          border: Border.all(
            color: selected ? c.brandAccent : c.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(T.s4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: T.bodyStrong.copyWith(color: c.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: T.small.copyWith(color: c.inkMuted)),
                  ],
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? c.brandAccent : c.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}
