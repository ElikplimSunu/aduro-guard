import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';
import 'verdict_engine.dart';

/// Loads the read-only register snapshot (assets/db/registry.db) and exposes
/// the verdict engine over it.
class Registry {
  Registry._();
  static final instance = Registry._();

  VerdictEngine? _engine;
  Map<String, String> _meta = const {};
  Future<void>? _loading;

  VerdictEngine get engine => _engine!;
  bool get isLoaded => _engine != null;
  String get snapshotDate => _meta['snapshot_date'] ?? '';
  int get productCount => int.tryParse(_meta['product_count'] ?? '') ?? 0;
  String get sources => _meta['sources'] ?? '';
  String get registerNote => _meta['register_note'] ?? '';

  /// Single-flight: concurrent callers share one load.
  Future<void> load() => _loading ??= _doLoad();

  Future<void> _doLoad() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/registry.db';

    // ponytail: snapshot is read-only and small — unconditionally refresh the
    // local copy from the bundled asset; history lives in a separate db file.
    final asset = await rootBundle.load('assets/db/registry.db');
    await File(path).writeAsBytes(asset.buffer.asUint8List(), flush: true);

    final db = await openDatabase(path, readOnly: true);
    try {
      _meta = {
        for (final r in await db.query('meta'))
          r['key'] as String: r['value'] as String,
      };
      _engine = VerdictEngine(
        products: (await db.query('products')).map(Product.fromRow).toList(),
        recalls: (await db.query('recalls')).map(Recall.fromRow).toList(),
        lookalikes:
            (await db.query('lookalikes')).map(Lookalike.fromRow).toList(),
      );
    } finally {
      await db.close();
    }
  }
}
