import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart' show routeObserver;
import '../models/scan.dart';
import '../services/history.dart';
import '../services/registry.dart';
import '../services/strings.dart';
import '../theme/tokens.dart';
import '../widgets/motion.dart';
import 'history.dart';
import 'scan.dart';
import 'settings.dart';

/// Home: one loud action (scan), recent checks, and the snapshot status line.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  List<ScanRecord> _recent = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) routeObserver.subscribe(this, route);
  }

  @override
  void didPopNext() => _refresh(); // returning from scan/result/settings

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    await Registry.instance.load();
    final recent = await History.instance.recent(limit: 4);
    if (!mounted) return;
    setState(() {
      _recent = recent;
      _loaded = true;
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final registry = Registry.instance;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(T.s5, T.s4, T.s5, T.s6),
          children: [
            Entrance(
              child: Row(
                children: [
                  Expanded(child: Text('Aduro Guard', style: T.h1)),
                  IconButton(
                    onPressed: () => _open(const SettingsScreen()),
                    tooltip: S.settings,
                    icon: const Icon(Icons.tune, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: T.s6),
            Entrance(
                index: 1,
                child: _ScanCard(onTap: () => _open(const ScanScreen()))),
            const SizedBox(height: T.s3),
            if (registry.isLoaded)
              Entrance(
                index: 2,
                child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: T.s1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(Icons.cloud_off_outlined,
                          size: 14, color: c.inkFaint),
                    ),
                    const SizedBox(width: T.s2),
                    Expanded(
                      child: Text(
                        S.worksOffline(
                            registry.productCount, registry.snapshotDate),
                        style: T.caption.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            const SizedBox(height: T.s8),
            if (_loaded && _recent.isNotEmpty) ...[
              Entrance(
                index: 3,
                child: Row(
                children: [
                  Expanded(child: Text(S.recentChecks, style: T.h3)),
                  TextButton(
                    onPressed: () => _open(const HistoryScreen()),
                    style: TextButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding:
                            const EdgeInsets.symmetric(horizontal: T.s2)),
                    child: Text(S.seeAll),
                  ),
                ],
              ),
              ),
              const SizedBox(height: T.s2),
              for (final (i, r) in _recent.indexed) ...[
                Entrance(
                    index: 4 + i,
                    child: ScanTile(record: r, onChanged: _refresh)),
                const SizedBox(height: T.s2),
              ],
            ] else if (_loaded) ...[
              Entrance(index: 3, child: Text(S.recentChecks, style: T.h3)),
              const SizedBox(height: T.s3),
              Entrance(
                index: 4,
                child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(T.rMd),
                  border: Border.all(color: c.hairline),
                ),
                padding: const EdgeInsets.all(T.s5),
                child: Text(
                  S.nothingChecked,
                  style: T.body.copyWith(color: c.inkMuted),
                ),
              ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The one gold moment on the screen. Deliberately identical in both themes.
class _ScanCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${S.scanAMedicine}. ${S.scanBlurb}',
      child: Pressable(
      child: Material(
      color: T.brand700,
      borderRadius: BorderRadius.circular(T.rLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(T.rLg),
        child: Padding(
          padding: const EdgeInsets.all(T.s5),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  decoration: BoxDecoration(
                    color: T.brand800,
                    borderRadius: BorderRadius.circular(T.rMd),
                  ),
                  padding: const EdgeInsets.all(T.s3),
                  child: const Icon(Icons.center_focus_strong_outlined,
                      color: T.brand200, size: 26),
                ),
              ),
              const SizedBox(width: T.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Text(S.scanAMedicine,
                          style: T.h3.copyWith(color: T.neutral0)),
                    ),
                    const SizedBox(height: 2),
                    ExcludeSemantics(
                      child: Text(S.scanBlurb,
                          style: T.small.copyWith(color: T.brand100)),
                    ),
                  ],
                ),
              ),
              const ExcludeSemantics(
                child:
                    Icon(Icons.arrow_forward, color: T.brand200, size: 20),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}

/// Shared history row: verdict-colored dot, product name, when.
class ScanTile extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback? onChanged;

  const ScanTile({super.key, required this.record, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dot = switch (record.verdictStatus) {
      'registered' => c.successAccent,
      'expired' || 'recalled' => c.dangerAccent,
      'caution' || 'notFound' => c.warningAccent,
      _ => c.inkFaint,
    };
    final name = record.extraction.productName.isEmpty
        ? S.unnamedPack
        : record.extraction.productName;
    final headline = switch (record.verdictStatus) {
      'registered' => S.vRegistered,
      'expired' => S.vExpired,
      'recalled' => S.vRecalled,
      'caution' => S.vCaution,
      'notFound' => S.vNotFound,
      _ => S.vChecked,
    };
    return Semantics(
      button: true,
      label: '$name. $headline. ${_when(record.at)}',
      child: Pressable(
      child: Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(T.rMd),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HistoryDetailScreen(record: record)));
          onChanged?.call();
        },
        borderRadius: BorderRadius.circular(T.rMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: c.hairline),
          ),
          padding: const EdgeInsets.all(T.s3),
          child: Row(
            children: [
              if (record.imagePath.isNotEmpty &&
                  File(record.imagePath).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(T.rSm),
                  child: Image.file(File(record.imagePath),
                      width: 44, height: 44, fit: BoxFit.cover,
                      cacheWidth: 132),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.surfaceDim,
                    borderRadius: BorderRadius.circular(T.rSm),
                  ),
                  child: Icon(Icons.medication_outlined,
                      color: c.inkFaint, size: 22),
                ),
              const SizedBox(width: T.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: T.bodyStrong.copyWith(color: c.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(_when(record.at),
                        style: T.caption.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              const SizedBox(width: T.s2),
              ExcludeSemantics(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: dot),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }

  static String _when(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return S.justNow;
    if (d.inHours < 1) return S.minAgo(d.inMinutes);
    if (d.inDays < 1) return S.hAgo(d.inHours);
    if (d.inDays == 1) return S.yesterday;
    return '${t.day}/${t.month}/${t.year}';
  }
}
