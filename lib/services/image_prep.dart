import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Gemma's vision encoder center-crops to a square and resizes that crop to
/// 896x896 regardless of what's sent — so anything with a shorter edge above
/// this is pure wasted transfer/decode time, not extra accuracy.
const _kTargetShortEdge = 1024;
const _kJpegQuality = 88;

/// Downscales a captured/imported pack photo so its shorter edge is about
/// [_kTargetShortEdge]px before it's sent to [Gemma.extract], preserving
/// aspect ratio (the model's own center-crop-fill still applies downstream).
/// Falls back to the original bytes if decoding fails, so a resize bug never
/// blocks a scan. Intended to run off the UI thread via `compute(...)`.
Uint8List resizeForScan(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final shortEdge =
      decoded.width < decoded.height ? decoded.width : decoded.height;
  if (shortEdge <= _kTargetShortEdge) return bytes;
  final scale = _kTargetShortEdge / shortEdge;
  final resized = img.copyResize(
    decoded,
    width: (decoded.width * scale).round(),
    height: (decoded.height * scale).round(),
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: _kJpegQuality));
}
