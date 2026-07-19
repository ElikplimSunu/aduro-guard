import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan.dart';
import '../services/history.dart';
import '../services/strings.dart';
import '../theme/tokens.dart';
import '../widgets/fact_row.dart';
import 'home.dart';

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

/// A saved check, re-opened. Shows what was decided at scan time.
/// No re-run, no model needed.
class HistoryDetailScreen extends StatelessWidget {
  final ScanRecord record;

  const HistoryDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final e = record.extraction;
    final (headline, fg, bg) = switch (record.verdictStatus) {
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
                if (record.verdictSummary.isNotEmpty) ...[
                  const SizedBox(height: T.s2),
                  Text(record.verdictSummary,
                      style: T.body.copyWith(color: c.ink)),
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
              ],
            ),
          ),
          if (record.counseling.isNotEmpty) ...[
            const SizedBox(height: T.s6),
            Text(S.guidanceGiven, style: T.h3),
            const SizedBox(height: T.s3),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(T.rMd),
                border: Border.all(color: c.hairline),
              ),
              padding: const EdgeInsets.all(T.s4),
              child: Text(record.counseling,
                  style: T.body.copyWith(height: 1.6, color: c.ink)),
            ),
          ],
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
