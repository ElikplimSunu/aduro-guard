import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/scan.dart';

/// Scan history, persisted in its own db file (separate from the replaceable
/// register snapshot).
class History {
  History._();
  static final instance = History._();

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    _db = await openDatabase(
      '${dir.path}/history.db',
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE scans(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          at TEXT NOT NULL,
          image_path TEXT,
          extraction TEXT NOT NULL,
          verdict_status TEXT NOT NULL,
          verdict_summary TEXT,
          counseling TEXT,
          language TEXT
        )'''),
    );
    return _db!;
  }

  Future<int> add(ScanRecord r) async {
    final db = await _open();
    return db.insert('scans', {
      'at': r.at.toIso8601String(),
      'image_path': r.imagePath,
      'extraction': jsonEncode(r.extraction.toJson()),
      'verdict_status': r.verdictStatus,
      'verdict_summary': r.verdictSummary,
      'counseling': r.counseling,
      'language': r.language,
    });
  }

  Future<void> updateCounseling(int id, String counseling) async {
    final db = await _open();
    await db.update('scans', {'counseling': counseling},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ScanRecord>> recent({int limit = 50}) async {
    final db = await _open();
    final rows =
        await db.query('scans', orderBy: 'at DESC', limit: limit);
    return rows
        .map((r) => ScanRecord(
              id: r['id'] as int,
              at: DateTime.parse(r['at'] as String),
              imagePath: (r['image_path'] ?? '') as String,
              extraction: Extraction.fromJson(
                  jsonDecode(r['extraction'] as String)
                      as Map<String, Object?>),
              verdictStatus: r['verdict_status'] as String,
              verdictSummary: (r['verdict_summary'] ?? '') as String,
              counseling: (r['counseling'] ?? '') as String,
              language: (r['language'] ?? 'en') as String,
            ))
        .toList();
  }

  Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('scans', where: 'id = ?', whereArgs: [id]);
  }
}
