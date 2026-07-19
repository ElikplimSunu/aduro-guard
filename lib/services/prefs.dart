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

  void _set(String key, Object? value) {
    _data[key] = value;
    _file?.writeAsStringSync(jsonEncode(_data), flush: true);
  }
}
