import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/image_prep.dart';
import '../services/strings.dart';
import '../theme/tokens.dart';
import '../widgets/motion.dart';
import 'photo_pick.dart';
import 'result.dart';

/// Camera capture with a confirm step. On desktop (no camera plugin support)
/// the screen offers photo picking only — same downstream flow.
///
/// With [returnShot] the confirmed photo pops back to the caller instead of
/// starting a new result: used to add another face of the same box.
class ScanScreen extends StatefulWidget {
  final bool returnShot;

  const ScanScreen({super.key, this.returnShot = false});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  static final bool _cameraSupported =
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  CameraController? _camera;
  String? _cameraError;
  Uint8List? _shot;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!_cameraSupported) return;
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _cameraError = S.cameraOff);
      return;
    }
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cams.first);
      final controller =
          CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } on CameraException catch (e) {
      setState(() => _cameraError =
          'The camera could not start (${e.code}). Pick a photo instead.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      cam.dispose();
      _camera = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final cam = _camera;
    if (cam == null || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await cam.takePicture();
      final raw = await file.readAsBytes();
      final bytes = await compute(resizeForScan, raw);
      if (mounted) setState(() => _shot = bytes);
    } on CameraException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(S.photoFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    Uint8List? raw;
    if (_cameraSupported) {
      // In-app grid over MediaStore: with "Select photos" access it shows
      // only the photos the user approved, not the whole gallery.
      raw = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(builder: (_) => const PhotoPickScreen()));
    } else {
      final result =
          await FilePicker.pickFiles(type: FileType.image);
      final path = result?.files.single.path;
      if (path != null) raw = await File(path).readAsBytes();
    }
    if (raw == null) return;
    final bytes = await compute(resizeForScan, raw);
    if (mounted) setState(() => _shot = bytes);
  }

  void _use() {
    if (widget.returnShot) {
      Navigator.of(context).pop(_shot);
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(imageBytes: _shot!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.neutral950,
      appBar: AppBar(
        backgroundColor: T.neutral950,
        foregroundColor: T.neutral0,
        title: Text(
            _shot != null
                ? S.useThisPhoto
                : widget.returnShot
                    ? S.addAnotherSide
                    : S.scanAMedicine,
            style: T.h3.copyWith(color: T.neutral0)),
        iconTheme: const IconThemeData(color: T.neutral0, size: 22),
      ),
      body: AnimatedSwitcher(
        duration: M.swap,
        switchInCurve: M.curve,
        switchOutCurve: Curves.easeOut,
        child: KeyedSubtree(
          key: ValueKey(_shot != null),
          child: _shot != null ? _confirmView() : _captureView(),
        ),
      ),
    );
  }

  Widget _captureView() {
    final cam = _camera;
    return Column(
      children: [
        Expanded(
          child: cam != null && cam.value.isInitialized
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(T.rSm),
                  child: CameraPreview(cam),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(T.s8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_cameraSupported && _cameraError == null)
                          const CircularProgressIndicator()
                        else ...[
                          const Icon(Icons.photo_camera_outlined,
                              size: 40, color: T.neutral400),
                          const SizedBox(height: T.s4),
                          Text(
                            _cameraError ?? S.noCamera,
                            style: T.body.copyWith(color: T.neutral300),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: T.s6, vertical: T.s5),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pick,
                  tooltip: S.pickFromPhotos,
                  icon: const Icon(Icons.photo_library_outlined,
                      color: T.neutral200, size: 26),
                ),
                Expanded(
                  child: Center(
                    child: _ShutterButton(
                      enabled:
                          cam != null && cam.value.isInitialized && !_busy,
                      onPressed: _capture,
                    ),
                  ),
                ),
                const SizedBox(width: 42), // balances the pick button
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmView() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(T.s4),
            child: Hero(
              // Distinct tag in add-a-side mode so it never flies against
              // the first photo's hero on the result page underneath.
              tag: widget.returnShot ? 'scan-shot-extra' : 'scan-shot',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(T.rMd),
                // cacheWidth: preview needs no full-res texture (and the
                // emulator's software GL can't paint one); Gemma still gets
                // the original bytes.
                child: Image.memory(_shot!,
                    fit: BoxFit.contain, cacheWidth: 1000),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(T.s6, 0, T.s6, T.s5),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _shot = null),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: T.neutral0,
                        side: const BorderSide(color: T.neutral600)),
                    child: Text(S.retake),
                  ),
                ),
                const SizedBox(width: T.s4),
                Expanded(
                  child: FilledButton(
                    onPressed: _use,
                    child: Text(S.checkIt),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ShutterButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: S.takePhoto,
      child: Pressable(
      enabled: enabled,
      child: GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: T.neutral0, width: 4),
          ),
          padding: const EdgeInsets.all(5),
          child: const DecoratedBox(
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: T.brand400),
          ),
        ),
      ),
      ),
      ),
    );
  }
}
