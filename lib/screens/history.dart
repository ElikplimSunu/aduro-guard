import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan.dart';
import '../services/history.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('All checks')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(T.s6),
                    child: Text('No checks yet.',
                        style: T.body.copyWith(color: T.neutral600)),
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

/// A saved check, re-opened. Shows what was decided at scan time —
/// no re-run, no model needed.
class HistoryDetailScreen extends StatelessWidget {
  final ScanRecord record;

  const HistoryDetailScreen({super.key, required this.record});

  static const _status = {
    'registered': ('In the register', T.success700, T.successSurface),
    'expired': ('Expired — do not take', T.danger700, T.dangerSurface),
    'recalled': ('Do not take this', T.danger700, T.dangerSurface),
    'caution': ('Check this carefully', T.warning700, T.warningSurface),
    'notFound': ('Not in the register snapshot', T.warning700, T.warningSurface),
  };

  @override
  Widget build(BuildContext context) {
    final e = record.extraction;
    final s = _status[record.verdictStatus] ??
        ('Checked', T.neutral700, T.neutral100);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved check'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 22),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: T.neutral0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(T.rLg)),
                  title: Text('Delete this check?', style: T.h3),
                  content: Text('This only removes the saved record.',
                      style: T.body),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep it')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                            foregroundColor: T.danger600),
                        child: const Text('Delete')),
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
              color: s.$3,
              borderRadius: BorderRadius.circular(T.rLg),
            ),
            padding: const EdgeInsets.all(T.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$1, style: T.h2.copyWith(color: s.$2)),
                if (record.verdictSummary.isNotEmpty) ...[
                  const SizedBox(height: T.s2),
                  Text(record.verdictSummary,
                      style: T.body.copyWith(color: T.neutral800)),
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
                  height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: T.s6),
          ],
          Text('What the pack said', style: T.h3),
          const SizedBox(height: T.s3),
          Container(
            decoration: BoxDecoration(
              color: T.neutral0,
              borderRadius: BorderRadius.circular(T.rMd),
              border: Border.all(color: T.neutral200),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: T.s4, vertical: T.s3),
            child: Column(
              children: [
                FactRow(label: 'Product', value: e.productName),
                FactRow(label: 'Made by', value: e.manufacturer),
                FactRow(label: 'Batch', value: e.batchNumber),
                FactRow(label: 'Expiry', value: e.expiryRaw),
              ],
            ),
          ),
          if (record.counseling.isNotEmpty) ...[
            const SizedBox(height: T.s6),
            Text('Guidance given', style: T.h3),
            const SizedBox(height: T.s3),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: T.neutral0,
                borderRadius: BorderRadius.circular(T.rMd),
                border: Border.all(color: T.neutral200),
              ),
              padding: const EdgeInsets.all(T.s4),
              child: Text(record.counseling,
                  style: T.body.copyWith(height: 1.6)),
            ),
          ],
          const SizedBox(height: T.s4),
          Text('Checked ${record.at.day}/${record.at.month}/${record.at.year}',
              style: T.caption),
        ],
      ),
    );
  }
}
