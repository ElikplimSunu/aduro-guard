import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../main.dart' show AduroApp;
import '../services/gemma.dart';
import '../services/prefs.dart';
import '../services/registry.dart';
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(T.s5),
        children: [
          Text('Language', style: T.h3),
          const SizedBox(height: T.s3),
          _Card(
            child: Column(
              children: [
                _RadioRow(
                  label: 'English',
                  selected: _language == 'en',
                  onTap: () => _setLanguage('en'),
                ),
                const Divider(),
                _RadioRow(
                  label: 'Twi',
                  selected: _language == 'tw',
                  onTap: () => _setLanguage('tw'),
                ),
              ],
            ),
          ),
          const SizedBox(height: T.s8),
          Text('Appearance', style: T.h3),
          const SizedBox(height: T.s3),
          _Card(
            child: Column(
              children: [
                _RadioRow(
                  label: 'Match the phone',
                  selected: _themeMode == 'system',
                  onTap: () => _setThemeMode('system'),
                ),
                const Divider(),
                _RadioRow(
                  label: 'Light',
                  selected: _themeMode == 'light',
                  onTap: () => _setThemeMode('light'),
                ),
                const Divider(),
                _RadioRow(
                  label: 'Dark',
                  selected: _themeMode == 'dark',
                  onTap: () => _setThemeMode('dark'),
                ),
              ],
            ),
          ),
          const SizedBox(height: T.s8),
          Text('Offline brain', style: T.h3),
          const SizedBox(height: T.s1),
          Text(
            'Gemma 4 runs entirely on this phone. Download once on Wi-Fi; scanning then needs no internet at all.',
            style: T.small.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: T.s3),
          for (final m in modelOptions) ...[
            _ModelCard(option: m),
            const SizedBox(height: T.s3),
          ],
          const SizedBox(height: T.s5),
          Text('About', style: T.h3),
          const SizedBox(height: T.s3),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (registry.isLoaded) ...[
                  Text(
                    'Register snapshot: ${registry.productCount} products · ${registry.snapshotDate}',
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
                Text(
                  'Aduro Guard is a verification aid, not medical advice. For any health decision, talk to a pharmacist, a clinic, or the FDA on 0551112224 (WhatsApp).',
                  style: T.small.copyWith(color: c.inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setLanguage(String v) {
    Prefs.instance.language = v;
    setState(() => _language = v);
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
  final bool selected;
  final VoidCallback onTap;

  const _RadioRow(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: T.s2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: T.body.copyWith(color: c.ink))),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('The download stopped. Check your connection and retry.')));
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('That file could not be imported.')));
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
            Text('Downloading… $_progress%',
                style: T.caption.copyWith(color: c.inkMuted)),
          ] else if (_installed == true)
            Row(
              children: [
                Text('Installed', style: T.small.copyWith(color: c.inkMuted)),
                const Spacer(),
                TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(foregroundColor: c.dangerAccent),
                  child: const Text('Remove'),
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
                  child: const Text('Download'),
                ),
                const SizedBox(width: T.s3),
                OutlinedButton(
                  onPressed: _import,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding:
                          const EdgeInsets.symmetric(horizontal: T.s4)),
                  child: const Text('Import file'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
