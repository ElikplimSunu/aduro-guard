import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// App settings, persisted as one small JSON file.
/// ponytail: JSON file over shared_preferences — path_provider is already here.
class Prefs {
  Prefs._();
  static final instance = Prefs._();

  Map<String, Object?> _data = {};
  File? _file;

  /// 'en' or 'tw'
  String get language => (_data['language'] ?? 'en') as String;
  set language(String v) => _set('language', v);

  bool get onboarded => (_data['onboarded'] ?? false) as bool;
  set onboarded(bool v) => _set('onboarded', v);

  /// Preferred model fileName; empty = default (E2B).
  String get modelFile => (_data['modelFile'] ?? '') as String;
  set modelFile(String v) => _set('modelFile', v);

  /// 'system' | 'light' | 'dark'
  String get themeMode => (_data['themeMode'] ?? 'system') as String;
  set themeMode(String v) => _set('themeMode', v);

  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/prefs.json');
    if (_file!.existsSync()) {
      try {
        _data = (jsonDecode(_file!.readAsStringSync()) as Map)
            .cast<String, Object?>();
      } catch (_) {
        _data = {};
      }
    }
  }

  Future<void> _flush = Future.value();

  void _set(String key, Object? value) {
    _data[key] = value;
    // _data is already updated above, so reads are consistent immediately;
    // the write to disk happens in the background. Writes are chained:
    // two overlapping writeAsString calls on one file can interleave and
    // corrupt it, and chaining also keeps last-set as last-written.
    final file = _file;
    if (file == null) return;
    final snapshot = jsonEncode(_data);
    _flush = _flush
        .catchError((_) {}) // a failed write must not stall the chain
        .then((_) => file.writeAsString(snapshot, flush: true));
  }
}
