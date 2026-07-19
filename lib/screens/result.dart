import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:path_provider/path_provider.dart';

import '../models/scan.dart';
import '../models/verdict.dart';
import '../services/gemma.dart';
import '../services/history.dart';
import '../services/registry.dart';
import '../services/strings.dart';
import '../theme/tokens.dart';
import '../widgets/counseling_section.dart';
import '../widgets/fact_row.dart';
import '../widgets/motion.dart';
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
      // Screen readers hear the verdict the moment it lands.
      SemanticsService.sendAnnouncement(
          View.of(context), verdictHeadline(verdict.status), TextDirection.ltr);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _error = e is StateError ? S.modelNotSetUp : S.somethingWrong;
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
      appBar: AppBar(title: Text(S.resultTitle)),
      body: AnimatedSwitcher(
        duration: M.swap,
        switchInCurve: M.curve,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(_stage == _Stage.checking ? _Stage.reading : _stage),
          child: switch (_stage) {
            _Stage.reading || _Stage.checking => _progressView(),
            _Stage.failed => _failedView(),
            _Stage.done => _verdict!.status == VerdictStatus.unreadable
                ? _unreadableView()
                : _resultView(),
          },
        ),
      ),
    );
  }

  Widget _progressView() {
    final c = context.c;
    final label =
        _stage == _Stage.reading ? S.readingPack : S.checkingRegister;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Hero(
              tag: 'scan-shot',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(T.rMd),
                child: Image.memory(widget.imageBytes,
                    width: 160, height: 160, fit: BoxFit.cover,
                    cacheWidth: 480),
              ),
            ),
          ),
          const SizedBox(height: T.s6),
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: T.s4),
          FadeSwap(
            child: Text(label,
                key: ValueKey(label),
                style: T.bodyStrong.copyWith(color: c.ink)),
          ),
          const SizedBox(height: T.s2),
          Text(S.allOnPhone, style: T.small.copyWith(color: c.inkMuted)),
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
            FilledButton(onPressed: _scanAgain, child: Text(S.scanAgain)),
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
          Text(S.tipsTitle, style: T.h3),
          const SizedBox(height: T.s3),
          Text(S.tips, style: T.body.copyWith(color: c.inkMuted, height: 1.7)),
          const Spacer(),
          FilledButton(onPressed: _scanAgain, child: Text(S.tryAgain)),
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
        Entrance(child: VerdictBanner(verdict: v)),
        const SizedBox(height: T.s6),
        Entrance(index: 1, child: Text(S.whatPackSays, style: T.h3)),
        const SizedBox(height: T.s3),
        Entrance(
          index: 2,
          child: Container(
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
                    FactRow(label: S.product, value: e.productName),
                    FactRow(label: S.madeBy, value: e.manufacturer),
                    FactRow(label: S.batch, value: e.batchNumber),
                    FactRow(label: S.expiry, value: e.expiryRaw),
                    if (e.regNo.isNotEmpty)
                      FactRow(label: S.fdaNumber, value: e.regNo),
                  ],
                ),
              ),
              const SizedBox(width: T.s3),
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(T.rSm),
                  child: Image.memory(widget.imageBytes,
                      width: 64, height: 64, fit: BoxFit.cover,
                      cacheWidth: 192),
                ),
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: T.s6),
        Entrance(
            index: 3,
            child: CounselingSection(
                extraction: e, verdict: v, historyId: _historyId)),
        const SizedBox(height: T.s6),
        Entrance(
            index: 4, child: FollowUpSection(extraction: e, verdict: v)),
        const SizedBox(height: T.s8),
        Entrance(
            index: 5,
            child: OutlinedButton(
                onPressed: _scanAgain, child: Text(S.scanAnother))),
        const SizedBox(height: T.s4),
      ],
    );
  }
}
