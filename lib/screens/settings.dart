import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../main.dart' show AduroApp;
import '../services/gemma.dart';
import '../services/languages.dart';
import '../services/prefs.dart';
import '../services/registry.dart';
import '../services/strings.dart';
import '../services/voices.dart';
import '../theme/tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _language = Prefs.instance.language;
  String _themeMode = Prefs.instance.themeMode;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final registry = Registry.instance;
    return Scaffold(
      appBar: AppBar(title: Text(S.settings)),
      body: ListView(
        padding: const EdgeInsets.all(T.s5),
        children: [
          Text(S.language, style: T.h3),
          const SizedBox(height: T.s3),
          _Card(
            child: Column(
              children: [
                for (final (i, l) in langs.indexed) ...[
                  if (i > 0) const Divider(),
                  _RadioRow(
                    label: l.endonym,
                    caption: l.early ? S.earlySupport : null,
                    selected: _language == l.code,
                    onTap: () => _setLanguage(l.code),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: T.s8),
          Text(S.appearance, style: T.h3),
          const SizedBox(height: T.s3),
          _Card(
            child: Column(
              children: [
                _RadioRow(
                  label: S.matchPhone,
                  selected: _themeMode == 'system',
                  onTap: () => _setThemeMode('system'),
                ),
                const Divider(),
                _RadioRow(
                  label: S.light,
                  selected: _themeMode == 'light',
                  onTap: () => _setThemeMode('light'),
                ),
                const Divider(),
                _RadioRow(
                  label: S.dark,
                  selected: _themeMode == 'dark',
                  onTap: () => _setThemeMode('dark'),
                ),
              ],
            ),
          ),
          const SizedBox(height: T.s8),
          Text(S.offlineBrain, style: T.h3),
          const SizedBox(height: T.s1),
          Text(S.offlineBrainBlurb,
              style: T.small.copyWith(color: c.inkMuted)),
          const SizedBox(height: T.s3),
          for (final m in modelOptions) ...[
            _ModelCard(option: m),
            const SizedBox(height: T.s3),
          ],
          const SizedBox(height: T.s5),
          Text(S.voices, style: T.h3),
          const SizedBox(height: T.s1),
          Text(S.voicesBlurb, style: T.small.copyWith(color: c.inkMuted)),
          const SizedBox(height: T.s3),
          for (final l in langs.where((l) => l.mmsCode != null)) ...[
            _VoiceCard(lang: l),
            const SizedBox(height: T.s3),
          ],
          const SizedBox(height: T.s5),
          Text(S.about, style: T.h3),
          const SizedBox(height: T.s3),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (registry.isLoaded) ...[
                  Text(
                    S.snapshotLine(
                        registry.productCount, registry.snapshotDate),
                    style: T.bodyStrong.copyWith(color: c.ink),
                  ),
                  const SizedBox(height: T.s2),
                  Text(registry.sources,
                      style: T.small.copyWith(color: c.inkMuted)),
                  const SizedBox(height: T.s2),
                  Text(registry.registerNote,
                      style: T.small.copyWith(color: c.inkMuted)),
                  const SizedBox(height: T.s4),
                ],
                Text(S.disclaimer,
                    style: T.small.copyWith(color: c.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setLanguage(String v) {
    setState(() => _language = v);
    AduroApp.setLanguage(context, v); // whole UI follows
  }

  void _setThemeMode(String v) {
    setState(() => _themeMode = v);
    AduroApp.setThemeMode(
        context, ThemeMode.values.firstWhere((m) => m.name == v));
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(T.rMd),
        border: Border.all(color: c.hairline),
      ),
      padding: const EdgeInsets.all(T.s4),
      child: child,
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final String? caption;
  final bool selected;
  final VoidCallback onTap;

  const _RadioRow({
    required this.label,
    this.caption,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: T.s2),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(label, style: T.body.copyWith(color: c.ink)),
                  if (caption != null) ...[
                    const SizedBox(width: T.s2),
                    Text(caption!,
                        style: T.caption.copyWith(color: c.inkFaint)),
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
      ),
    );
  }
}

/// One offline voice: install state, download with progress, remove.
class _VoiceCard extends StatefulWidget {
  final Lang lang;

  const _VoiceCard({required this.lang});

  @override
  State<_VoiceCard> createState() => _VoiceCardState();
}

class _VoiceCardState extends State<_VoiceCard> {
  bool? _installed;
  int _progress = -1;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final installed = await Voices.instance.isInstalled(widget.lang.mmsCode!);
    if (mounted) setState(() => _installed = installed);
  }

  Future<void> _download() async {
    setState(() => _progress = 0);
    try {
      await for (final p in Voices.instance.download(widget.lang.mmsCode!)) {
        if (!mounted) return;
        setState(() => _progress = p);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.downloadStopped)));
      }
    } finally {
      if (mounted) {
        setState(() => _progress = -1);
        _check();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final downloading = _progress >= 0;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(S.voiceName(widget.lang.endonym),
                      style: T.bodyStrong.copyWith(color: c.ink))),
              if (_installed == true)
                Icon(Icons.check_circle_outline,
                    size: 18, color: c.successAccent)
              else
                Text('115 MB', style: T.caption.copyWith(color: c.inkMuted)),
            ],
          ),
          const SizedBox(height: T.s1),
          Text(S.voiceBlurb(widget.lang.endonym),
              style: T.small.copyWith(color: c.inkMuted)),
          const SizedBox(height: T.s3),
          if (downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(T.rSm),
              child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 6),
            ),
            const SizedBox(height: T.s2),
            Text(S.downloading(_progress),
                style: T.caption.copyWith(color: c.inkMuted)),
          ] else if (_installed == true)
            Row(
              children: [
                Text(S.installed, style: T.small.copyWith(color: c.inkMuted)),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await Voices.instance.delete(widget.lang.mmsCode!);
                    _check();
                  },
                  style: TextButton.styleFrom(foregroundColor: c.dangerAccent),
                  child: Text(S.remove),
                ),
              ],
            )
          else
            FilledButton(
              onPressed: _download,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: T.s5)),
              child: Text(S.download),
            ),
        ],
      ),
    );
  }
}

/// One model: install state, download with live progress, import, delete.
class _ModelCard extends StatefulWidget {
  final ModelOption option;

  const _ModelCard({required this.option});

  @override
  State<_ModelCard> createState() => _ModelCardState();
}

class _ModelCardState extends State<_ModelCard> {
  bool? _installed;
  int _progress = -1; // -1 = not downloading

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final installed = await Gemma.instance.isInstalled(widget.option);
    if (mounted) setState(() => _installed = installed);
  }

  Future<void> _download() async {
    setState(() => _progress = 0);
    try {
      await for (final p in Gemma.instance.download(widget.option)) {
        if (!mounted) return;
        setState(() => _progress = p);
      }
      Prefs.instance.modelFile = widget.option.fileName;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.downloadStopped)));
      }
    } finally {
      if (mounted) {
        setState(() => _progress = -1);
        _check();
      }
    }
  }

  Future<void> _import() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Gemma model', extensions: ['litertlm'])
    ]);
    if (file == null) return;
    setState(() => _progress = 0);
    try {
      await Gemma.instance.importFile(file.path);
      Prefs.instance.modelFile = widget.option.fileName;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.importFailed)));
      }
    } finally {
      if (mounted) {
        setState(() => _progress = -1);
        _check();
      }
    }
  }

  Future<void> _delete() async {
    await Gemma.instance.delete(widget.option);
    _check();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final m = widget.option;
    final downloading = _progress >= 0;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      Text(m.displayName, style: T.bodyStrong.copyWith(color: c.ink))),
              if (_installed == true)
                Icon(Icons.check_circle_outline,
                    size: 18, color: c.successAccent)
              else
                Text(m.sizeLabel, style: T.caption.copyWith(color: c.inkMuted)),
            ],
          ),
          const SizedBox(height: T.s1),
          Text(m.blurb, style: T.small.copyWith(color: c.inkMuted)),
          const SizedBox(height: T.s3),
          if (downloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(T.rSm),
              child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 6),
            ),
            const SizedBox(height: T.s2),
            Text(S.downloading(_progress),
                style: T.caption.copyWith(color: c.inkMuted)),
          ] else if (_installed == true)
            Row(
              children: [
                Text(S.installed, style: T.small.copyWith(color: c.inkMuted)),
                const Spacer(),
                TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: c.dangerAccent),
                  child: Text(S.remove),
                ),
              ],
            )
          else
            Row(
              children: [
                FilledButton(
                  onPressed: _download,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding:
                          const EdgeInsets.symmetric(horizontal: T.s5)),
                  child: Text(S.download),
                ),
                const SizedBox(width: T.s3),
                OutlinedButton(
                  onPressed: _import,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding:
                          const EdgeInsets.symmetric(horizontal: T.s4)),
                  child: Text(S.importFile),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
