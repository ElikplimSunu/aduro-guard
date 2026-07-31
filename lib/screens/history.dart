import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/scan.dart';
import '../models/verdict.dart';
import '../services/gemma.dart';
import '../services/history.dart';
import '../services/registry.dart';
import '../services/strings.dart';
import '../services/verdict_engine.dart';
import '../theme/tokens.dart';
import '../widgets/counseling_section.dart';
import '../widgets/fact_row.dart';
import '../widgets/follow_up_section.dart';
import '../widgets/verdict_banner.dart';
import 'home.dart';
import 'scan.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanRecord> _all = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final all = await History.instance.recent(limit: 200);
    if (!mounted) return;
    setState(() {
      _all = all;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: Text(S.allChecks)),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(T.s6),
                    child: Text(S.noChecksYet,
                        style: T.body.copyWith(color: c.inkMuted)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(T.s5),
                  itemCount: _all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: T.s2),
                  itemBuilder: (_, i) =>
                      ScanTile(record: _all[i], onChanged: _refresh),
                ),
    );
  }
}

/// A saved check, re-opened: the verdict as decided at scan time, plus the
/// live sections (counseling in any language, read-aloud, follow-up Q&A) and
/// the option to photograph more sides, which re-runs the check.
class HistoryDetailScreen extends StatefulWidget {
  final ScanRecord record;

  const HistoryDetailScreen({super.key, required this.record});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Extraction _e = widget.record.extraction;
  late String _status = widget.record.verdictStatus;
  late String _summary = widget.record.verdictSummary;
  Verdict? _fresh; // set once a new side re-runs the check
  int _updates = 0;
  bool _updating = false;

  /// The verdict handed to counseling and Q&A: the fresh one when a new
  /// side re-ran the check, else a shell rebuilt from the saved record.
  Verdict get _verdict =>
      _fresh ??
      Verdict(
        status: VerdictStatus.values.firstWhere((s) => s.name == _status,
            orElse: () => VerdictStatus.notFound),
        reasons: [if (_summary.isNotEmpty) _summary],
        expiryDate: VerdictEngine.parseExpiry(_e.expiryRaw),
      );

  Future<void> _addSide() async {
    final bytes = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => const ScanScreen(returnShot: true)));
    if (bytes == null || !mounted) return;
    setState(() => _updating = true);
    try {
      final second = await Gemma.instance.extract(bytes);
      if (!mounted) return;
      final merged = _e.merge(second);
      await Registry.instance.load();
      final verdict = Registry.instance.engine.evaluate(merged);
      final summary = verdict.reasons.isEmpty ? '' : verdict.reasons.first;
      if (widget.record.id != null) {
        await History.instance
            .updateResult(widget.record.id!, merged, verdict.status.name, summary);
      }
      if (!mounted) return;
      setState(() {
        _e = merged;
        _status = verdict.status.name;
        _summary = summary;
        _fresh = verdict;
        _updates++;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(S.sideFailed)));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  List<String> _missing() => [
        if (_e.expiryRaw.isEmpty) S.expiry,
        if (_e.batchNumber.isEmpty) S.batch,
        if (_e.manufacturer.isEmpty) S.madeBy,
        if (_e.regNo.isEmpty) S.fdaNumber,
      ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final record = widget.record;
    final e = _e;
    final (headline, fg, bg) = switch (_status) {
      'registered' => (S.vRegistered, c.successText, c.successSurface),
      'expired' => (S.vExpired, c.dangerText, c.dangerSurface),
      'recalled' => (S.vRecalled, c.dangerText, c.dangerSurface),
      'caution' => (S.vCaution, c.warningText, c.warningSurface),
      'notFound' => (S.vNotFound, c.warningText, c.warningSurface),
      _ => (S.vChecked, c.muteText, c.muteSurface),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(S.savedCheck),
        actions: [
          IconButton(
            tooltip: S.delete,
            icon: const Icon(Icons.delete_outline, size: 22),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(S.deleteCheckQ, style: T.h3),
                  content: Text(S.deleteBody, style: T.body),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(S.keepIt)),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: c.dangerAccent),
                        child: Text(S.delete)),
                  ],
                ),
              );
              if (confirmed == true && record.id != null) {
                await History.instance.delete(record.id!);
                if (record.imagePath.isNotEmpty) {
                  final f = File(record.imagePath);
                  if (f.existsSync()) f.deleteSync();
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(T.s5),
        children: [
          if (_fresh != null)
            VerdictBanner(verdict: _fresh!)
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(T.rLg),
              ),
              padding: const EdgeInsets.all(T.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: T.h2.copyWith(color: fg)),
                  if (_summary.isNotEmpty) ...[
                    const SizedBox(height: T.s2),
                    Text(_summary, style: T.body.copyWith(color: c.ink)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: T.s6),
          if (record.imagePath.isNotEmpty &&
              File(record.imagePath).existsSync()) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(T.rMd),
              child: Image.file(File(record.imagePath),
                  height: 180, fit: BoxFit.cover, cacheHeight: 540),
            ),
            const SizedBox(height: T.s6),
          ],
          Text(S.whatPackSaid, style: T.h3),
          const SizedBox(height: T.s3),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(T.rMd),
              border: Border.all(color: c.hairline),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: T.s4, vertical: T.s3),
            child: Column(
              children: [
                FactRow(label: S.product, value: e.productName),
                FactRow(label: S.madeBy, value: e.manufacturer),
                FactRow(label: S.batch, value: e.batchNumber),
                FactRow(label: S.expiry, value: e.expiryRaw),
                if (e.regNo.isNotEmpty)
                  FactRow(label: S.fdaNumber, value: e.regNo),
              ],
            ),
          ),
          if (_missing().isNotEmpty) ...[
            const SizedBox(height: T.s3),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(T.rMd),
                border: Border.all(color: c.hairline),
              ),
              padding: const EdgeInsets.all(T.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${S.notSeenOnPack} ${_missing().join(' · ')}',
                      style: T.small.copyWith(color: c.inkMuted)),
                  const SizedBox(height: T.s3),
                  if (_updating)
                    const LinearProgressIndicator(minHeight: 4)
                  else
                    OutlinedButton.icon(
                      onPressed: _addSide,
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding:
                              const EdgeInsets.symmetric(horizontal: T.s4)),
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(S.addAnotherSide),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: T.s6),
          CounselingSection(
            key: ValueKey('h-counsel$_updates'),
            extraction: e,
            verdict: _verdict,
            historyId: record.id,
            initialText: _updates == 0 ? record.counseling : null,
            initialLanguage: record.language,
          ),
          const SizedBox(height: T.s6),
          FollowUpSection(
              key: ValueKey('h-follow$_updates'),
              extraction: e,
              verdict: _verdict,
              historyId: record.id,
              initialTurns: record.qa),
          const SizedBox(height: T.s4),
          Text(
              S.checkedOn(
                  '${record.at.day}/${record.at.month}/${record.at.year}'),
              style: T.caption.copyWith(color: c.inkMuted)),
        ],
      ),
    );
  }
}
