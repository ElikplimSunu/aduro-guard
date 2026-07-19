import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/scan.dart';
import '../models/verdict.dart';
import '../services/gemma.dart';
import '../services/history.dart';
import '../services/registry.dart';
import '../theme/tokens.dart';
import '../widgets/counseling_section.dart';
import '../widgets/fact_row.dart';
import '../widgets/follow_up_section.dart';
import '../widgets/verdict_banner.dart';
import 'scan.dart';

enum _Stage { reading, checking, done, failed }

/// Runs the scan pipeline (Gemma reads, the engine decides) and shows the result.
class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const ResultScreen({super.key, required this.imageBytes});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  _Stage _stage = _Stage.reading;
  Extraction? _extraction;
  Verdict? _verdict;
  String _error = '';
  int? _historyId;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final extraction = await Gemma.instance.extract(widget.imageBytes);
      if (!mounted) return;
      setState(() {
        _extraction = extraction;
        _stage = _Stage.checking;
      });

      await Registry.instance.load();
      final verdict = Registry.instance.engine.evaluate(extraction);
      if (!mounted) return;

      if (verdict.status != VerdictStatus.unreadable) {
        final dir = await getApplicationDocumentsDirectory();
        final imagePath =
            '${dir.path}/scans/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(imagePath).create(recursive: true);
        await File(imagePath).writeAsBytes(widget.imageBytes);
        _historyId = await History.instance.add(ScanRecord(
          at: DateTime.now(),
          imagePath: imagePath,
          extraction: extraction,
          verdictStatus: verdict.status.name,
          verdictSummary: verdict.reasons.isEmpty ? '' : verdict.reasons.first,
        ));
      }
      if (!mounted) return;
      setState(() {
        _verdict = verdict;
        _stage = _Stage.done;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _error = e is StateError
            ? 'The offline model is not set up yet. Download it in Settings, then scan again.'
            : 'Something went wrong while checking. Try again.';
      });
    }
  }

  void _scanAgain() {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScanScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: switch (_stage) {
        _Stage.reading || _Stage.checking => _progressView(),
        _Stage.failed => _failedView(),
        _Stage.done => _verdict!.status == VerdictStatus.unreadable
            ? _unreadableView()
            : _resultView(),
      },
    );
  }

  Widget _progressView() {
    final c = context.c;
    final label = _stage == _Stage.reading
        ? 'Reading the pack…'
        : 'Checking the register…';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(T.rMd),
            child: Image.memory(widget.imageBytes,
                width: 160, height: 160, fit: BoxFit.cover, cacheWidth: 480),
          ),
          const SizedBox(height: T.s6),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: T.s4),
          Text(label, style: T.bodyStrong.copyWith(color: c.ink)),
          const SizedBox(height: T.s2),
          Text('Everything runs on this phone. No internet needed.',
              style: T.small.copyWith(color: c.inkMuted)),
        ],
      ),
    );
  }

  Widget _failedView() {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(T.s6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: c.inkFaint),
            const SizedBox(height: T.s4),
            Text(_error,
                style: T.body.copyWith(color: c.ink),
                textAlign: TextAlign.center),
            const SizedBox(height: T.s6),
            FilledButton(onPressed: _scanAgain, child: const Text('Scan again')),
          ],
        ),
      ),
    );
  }

  Widget _unreadableView() {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.all(T.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerdictBanner(verdict: _verdict!),
          const SizedBox(height: T.s5),
          Text('Tips for a clear read', style: T.h3),
          const SizedBox(height: T.s3),
          Text(
            '• Move to brighter light. Daylight works best.\n'
            '• Fill the frame with the front of the pack.\n'
            '• Hold still until the photo is sharp.',
            style: T.body.copyWith(color: c.inkMuted, height: 1.7),
          ),
          const Spacer(),
          FilledButton(onPressed: _scanAgain, child: const Text('Try again')),
          const SizedBox(height: T.s4),
        ],
      ),
    );
  }

  Widget _resultView() {
    final c = context.c;
    final e = _extraction!;
    final v = _verdict!;
    return ListView(
      padding: const EdgeInsets.all(T.s5),
      children: [
        VerdictBanner(verdict: v),
        const SizedBox(height: T.s6),
        Text('What the pack says', style: T.h3),
        const SizedBox(height: T.s3),
        Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(T.rMd),
            border: Border.all(color: c.hairline),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: T.s4, vertical: T.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    FactRow(label: 'Product', value: e.productName),
                    FactRow(label: 'Made by', value: e.manufacturer),
                    FactRow(label: 'Batch', value: e.batchNumber),
                    FactRow(label: 'Expiry', value: e.expiryRaw),
                    if (e.regNo.isNotEmpty)
                      FactRow(label: 'FDA number', value: e.regNo),
                  ],
                ),
              ),
              const SizedBox(width: T.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(T.rSm),
                child: Image.memory(widget.imageBytes,
                    width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 192),
              ),
            ],
          ),
        ),
        const SizedBox(height: T.s6),
        CounselingSection(extraction: e, verdict: v, historyId: _historyId),
        const SizedBox(height: T.s6),
        FollowUpSection(extraction: e, verdict: v),
        const SizedBox(height: T.s8),
        OutlinedButton(
            onPressed: _scanAgain, child: const Text('Scan another medicine')),
        const SizedBox(height: T.s4),
      ],
    );
  }
}
