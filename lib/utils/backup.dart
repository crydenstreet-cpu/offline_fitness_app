// lib/utils/backup.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../db/database_helper.dart';

class BackupService {
  /// Exportiert ALLE Tabellen in eine JSON-Datei im App-Documents-Ordner
  /// und teilt die Datei optional mit dem System-Share-Dialog.
  static Future<File> exportToJsonFile({bool alsoShare = true}) async {
    final db = await DB.instance.database;

    // alles holen
    final exercises = await db.query('exercises');
    final workouts = await db.query('workouts');
    final workoutExercises = await db.query('workout_exercises');
    final sessions = await db.query('sessions');
    final workoutSets = await db.query('workout_sets');
    final journal = await db.query('journal_entries');
    final schedule = await db.query('workout_schedule');

    final payload = {
      'meta': {
        'format': 'offline_fitness_backup',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
      },
      'tables': {
        'exercises': exercises,
        'workouts': workouts,
        'workout_exercises': workoutExercises,
        'sessions': sessions,
        'workout_sets': workoutSets,
        'journal_entries': journal,
        'workout_schedule': schedule,
      }
    };

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .replaceAll('.', '')
        .replaceAll('-', '');
    final file = File('${dir.path}/backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));

    if (alsoShare) {
      await Share.shareXFiles([XFile(file.path)], text: 'Offline Fitness – Backup');
    }
    return file;
  }

  /// Öffnet einen Dateiauswahldialog und importiert eine Backup-JSON.
  /// ACHTUNG: ersetzt den kompletten Datenbestand (sicher per Transaction).
  static Future<void> importFromPickedJson(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final file = File(path);
    final content = await file.readAsString();
    final decoded = jsonDecode(content);

    // Basic format check
    if (decoded is! Map || decoded['tables'] is! Map) {
      throw Exception('Ungültiges Backup-Format.');
    }

    final tables = decoded['tables'] as Map;

    final db = await DB.instance.database;
    await db.transaction((txn) async {
      // FK Check kurz aus – wir setzen IDs gezielt und Reihenfolge/Referenzen sind ok
      await txn.execute('PRAGMA foreign_keys = OFF');

      // 1) Alles löschen (Kinder → Eltern)
      await txn.delete('workout_sets');
      await txn.delete('journal_entries');
      await txn.delete('workout_schedule');
      await txn.delete('workout_exercises');
      await txn.delete('sessions');
      await txn.delete('workouts');
      await txn.delete('exercises');

      // 2) Reihenfolge: Eltern → Kinder
      Future<void> _insertAll(String table) async {
        final rows = (tables[table] as List?)?.cast<Map>() ?? const <Map>[];
        if (rows.isEmpty) return;
        final batch = txn.batch();
        for (final r in rows) {
          // Map<dynamic, dynamic> -> Map<String, Object?>
          final m = <String, Object?>{};
          r.forEach((k, v) => m['$k'] = v);
          batch.insert(table, m, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }

      await _insertAll('exercises');
      await _insertAll('workouts');
      await _insertAll('sessions');
      await _insertAll('workout_exercises');
      await _insertAll('workout_sets');
      await _insertAll('journal_entries');
      await _insertAll('workout_schedule');

      await txn.execute('PRAGMA foreign_keys = ON');
    });
  }
}
