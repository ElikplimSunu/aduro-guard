// Builds assets/db/registry.db from the TSVs in tool/data/.
//
// Run from the project root:  dart run tool/build_db.dart
//
// Sources, in order of preference:
//   1. tool/data/register_live.tsv  — full FDA register export (if the
//      scraper has run successfully; see tool/scrape_register.py)
//   2. tool/data/products.tsv       — curated seed of real Ghanaian-market
//      products (FDA public alerts, Ghana EML generics, common brands)
// plus recalls.tsv and lookalikes.tsv.
//
// The app treats this file as a read-only snapshot; scan history lives in a
// separate database so snapshots can be replaced freely.

import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  sqfliteFfiInit();
  final dbFactory = databaseFactoryFfi;

  final outPath = '${Directory.current.path}/assets/db/registry.db';
  final outFile = File(outPath);
  outFile.parent.createSync(recursive: true);
  await dbFactory.deleteDatabase(outPath);

  final db = await dbFactory.openDatabase(outPath);
  await db.execute('''
    CREATE TABLE products(
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      generic TEXT,
      manufacturer TEXT,
      category TEXT,
      form TEXT,
      strength TEXT,
      reg_no TEXT,
      status TEXT,
      source TEXT
    )''');
  // ponytail: no FTS — snapshot is small and matching is fuzzy-in-Dart anyway;
  // revisit only if a full 30k register export makes in-memory search slow.
  await db.execute('''
    CREATE TABLE recalls(
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      manufacturer TEXT,
      type TEXT,
      reason TEXT,
      date TEXT,
      source_url TEXT
    )''');
  await db.execute('CREATE TABLE lookalikes(a TEXT, b TEXT, note TEXT)');
  await db.execute('CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT)');

  final seen = <String>{};
  var productCount = 0;
  Future<void> insertProduct(Map<String, String> r) async {
    final key =
        '${r['name']!.toLowerCase()}|${(r['manufacturer'] ?? '').toLowerCase()}';
    if (r['name']!.isEmpty || !seen.add(key)) return;
    productCount++;
    await db.insert('products', {
      'name': r['name'],
      'generic': r['generic'] ?? '',
      'manufacturer': r['manufacturer'] ?? '',
      'category': r['category'] ?? '',
      'form': r['form'] ?? '',
      'strength': r['strength'] ?? '',
      'reg_no': r['reg_no'] ?? '',
      'status': (r['status'] ?? 'active').toLowerCase(),
      'source': r['source'] ?? '',
    });
  }

  // Live register export, when available.
  final live = File('tool/data/register_live.tsv');
  var liveCount = 0;
  if (live.existsSync()) {
    for (final r in _readTsv(live)) {
      await insertProduct({
        'name': r['product_name'] ?? '',
        'manufacturer': r['manufacturer'] ?? '',
        'category': r['category'] ?? '',
        'status': r['status'] ?? 'active',
        'source': 'fda-register-export',
      });
      liveCount++;
    }
  }

  for (final r in _readTsv(File('tool/data/products.tsv'))) {
    await insertProduct(r);
  }

  var recallCount = 0;
  for (final r in _readTsv(File('tool/data/recalls.tsv'))) {
    await db.insert('recalls', {
      'name': r['name'],
      'manufacturer': r['manufacturer'] ?? '',
      'type': r['type'] ?? 'alert',
      'reason': r['reason'] ?? '',
      'date': r['date'] ?? '',
      'source_url': r['source_url'] ?? '',
    });
    recallCount++;
  }

  var lookalikeCount = 0;
  for (final r in _readTsv(File('tool/data/lookalikes.tsv'))) {
    await db.insert(
        'lookalikes', {'a': r['a'], 'b': r['b'], 'note': r['note'] ?? ''});
    lookalikeCount++;
  }

  final today = DateTime.now().toIso8601String().substring(0, 10);
  for (final e in {
    'schema_version': '1',
    'snapshot_date': today,
    'product_count': '$productCount',
    'live_export': liveCount > 0 ? 'yes' : 'no',
    'sources': liveCount > 0
        ? 'Ghana FDA public register export; FDA Ghana public alerts; WHO medical product alerts'
        : 'Curated snapshot: FDA Ghana public alerts, WHO alerts, Ghana EML generics, common registered brands',
    'register_note':
        'The Ghana FDA online register lists 30,000+ products; this offline snapshot is a subset.',
  }.entries) {
    await db.insert('meta', {'key': e.key, 'value': e.value});
  }

  // Self-check: the demo-critical lookups must hit.
  Future<int> probe(String q) async => (await db.rawQuery(
          'SELECT COUNT(*) c FROM products WHERE name LIKE ?', ['%$q%']))
      .first['c'] as int;
  final checks = <String, int>{
    'coartem': await probe('coartem'),
    'paracetamol': await probe('paracetamol'),
    'lonart': await probe('lonart'),
    'taabea': await probe('taabea'),
  };
  final recallProbe = (await db.rawQuery(
          "SELECT COUNT(*) c FROM recalls WHERE name LIKE '%Naturcold%'"))
      .first['c'] as int;
  await db.close();

  print('registry.db built: $productCount products '
      '(${liveCount > 0 ? "incl. live export" : "curated seed only"}), '
      '$recallCount recalls, $lookalikeCount lookalike pairs');
  print('fts probes: $checks  · recall probe (Naturcold): $recallProbe');
  final failed = checks.entries.where((e) => e.value == 0).toList();
  if (failed.isNotEmpty || recallProbe == 0) {
    stderr.writeln('SELF-CHECK FAILED: ${failed.map((e) => e.key).toList()}');
    exit(1);
  }
  print('self-check passed · ${outFile.lengthSync()} bytes');
}

Iterable<Map<String, String>> _readTsv(File f) sync* {
  final lines = f
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .toList(growable: false);
  if (lines.isEmpty) return;
  final header = lines.first.split('\t');
  for (final line in lines.skip(1)) {
    final cells = line.split('\t');
    yield {
      for (var i = 0; i < header.length; i++)
        header[i]: i < cells.length ? cells[i].trim() : '',
    };
  }
}
