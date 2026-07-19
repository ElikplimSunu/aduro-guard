import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../main.dart' show AduroApp;
import '../services/gemma.dart';
import '../services/languages.dart';
import '../services/prefs.dart';
import '../services/strings.dart';
import '../theme/tokens.dart';
import '../widgets/motion.dart';
import 'home.dart';

/// First run: pick a language (each option labelled in its own language),
/// set up the offline brain, go. Never shown again once completed.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
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
          _error = S.downloadStoppedRetryImport;
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
          _error = S.importFailed;
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
          child: AnimatedSwitcher(
            duration: M.swap,
            switchInCurve: M.curve,
            switchOutCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _step == 0 ? _welcome() : _brain(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() {
    final c = context.c;
    final selected = Prefs.instance.language;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: T.s8),
        Entrance(
            child: Text('Aduro Guard',
                style: T.display.copyWith(color: c.ink))),
        const SizedBox(height: T.s3),
        Entrance(
          index: 1,
          child: Text(
            S.welcomeBlurb,
            style: T.body.copyWith(color: c.inkMuted, height: 1.6),
          ),
        ),
        const SizedBox(height: T.s8),
        Entrance(index: 2, child: Text(S.chooseLanguage, style: T.h3)),
        const SizedBox(height: T.s3),
        Expanded(
          child: ListView(
            children: [
              for (final (i, l) in langs.indexed) ...[
                Entrance(
                  index: 3 + i,
                  child: _LangCard(
                    title: l.endonym,
                    subtitle: l.nativeLine,
                    selected: selected == l.code,
                    onTap: () {
                      // The whole UI flips to the chosen language immediately.
                      AduroApp.setLanguage(context, l.code);
                    },
                  ),
                ),
                const SizedBox(height: T.s3),
              ],
            ],
          ),
        ),
        const SizedBox(height: T.s2),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: Text(S.continueLabel),
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
        Text(S.setupBrainTitle, style: T.h1.copyWith(color: c.ink)),
        const SizedBox(height: T.s3),
        Text(
          S.setupBrainBlurb(e2b.sizeLabel),
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
          Text(S.downloadingModel(e2b.displayName, _progress),
              style: T.small.copyWith(color: c.inkMuted)),
        ] else ...[
          if (_error.isNotEmpty) ...[
            Text(_error, style: T.body.copyWith(color: c.dangerText)),
            const SizedBox(height: T.s4),
          ],
          FilledButton(
              onPressed: _download,
              child: Text(S.downloadSize(e2b.sizeLabel))),
          const SizedBox(height: T.s3),
          OutlinedButton(
              onPressed: _import, child: Text(S.alreadyHaveFile)),
          const SizedBox(height: T.s4),
          Text(
            S.e4bNote(e4b.sizeLabel),
            style: T.caption.copyWith(color: c.inkMuted),
            textAlign: TextAlign.center,
          ),
        ],
        const Spacer(),
        if (!downloading)
          Center(
            child: TextButton(
              onPressed: _finish,
              child: Text(S.setUpLater),
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
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Pressable(
        child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rMd),
        child: AnimatedContainer(
          duration: M.swap,
          curve: M.curve,
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
              ExcludeSemantics(
                child: FadeSwap(
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    key: ValueKey(selected),
                    size: 20,
                    color: selected ? c.brandAccent : c.inkFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
