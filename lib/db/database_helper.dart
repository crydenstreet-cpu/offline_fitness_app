import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DB {
  DB._();
  static final DB instance = DB._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_fitness.db');

    return openDatabase(
      path,
      version: 3, // ⬅️ Schema v3 (mit Plan-Feldern)
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE exercises(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            muscle_group TEXT,
            description TEXT,
            unit TEXT DEFAULT 'kg',
            default_sets INTEGER DEFAULT 3,
            default_reps INTEGER DEFAULT 10,
            created_at TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE workouts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE workout_exercises(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workout_id INTEGER NOT NULL,
            exercise_id INTEGER NOT NULL,
            position INTEGER,
            planned_sets INTEGER,
            planned_reps INTEGER,
            planned_weight REAL,
            FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE CASCADE,
            FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE sessions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            workout_id INTEGER,
            started_at TEXT,
            note TEXT,
            FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE SET NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE workout_sets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            exercise_id INTEGER NOT NULL,
            set_index INTEGER,
            reps INTEGER,
            weight REAL,
            note TEXT,
            FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE,
            FOREIGN KEY(exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
          );
        ''');
        await db.execute('CREATE INDEX idx_sets_ex   ON workout_sets(exercise_id);');
        await db.execute('CREATE INDEX idx_sets_sess ON workout_sets(session_id);');

        await db.execute('''
          CREATE TABLE journal_entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            text TEXT,
            mood INTEGER,
            energy INTEGER,
            sleep INTEGER,
            linked_session_id INTEGER,
            tags TEXT,
            FOREIGN KEY(linked_session_id) REFERENCES sessions(id) ON DELETE SET NULL
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v2 brachte default_sets/default_reps (falls von sehr alt)
        if (oldVersion < 2) {
          final cols = await db.rawQuery('PRAGMA table_info(exercises);');
          final hasSets = cols.any((c) => (c['name'] as String?) == 'default_sets');
          final hasReps = cols.any((c) => (c['name'] as String?) == 'default_reps');
          if (!hasSets) await db.execute('ALTER TABLE exercises ADD COLUMN default_sets INTEGER DEFAULT 3;');
          if (!hasReps) await db.execute('ALTER TABLE exercises ADD COLUMN default_reps INTEGER DEFAULT 10;');
        }
        // v3: Plan-Felder auf workout_exercises
        if (oldVersion < 3) {
          final cols = await db.rawQuery('PRAGMA table_info(workout_exercises);');
          bool hasPlSets   = cols.any((c) => (c['name'] as String?) == 'planned_sets');
          bool hasPlReps   = cols.any((c) => (c['name'] as String?) == 'planned_reps');
          bool hasPlWeight = cols.any((c) => (c['name'] as String?) == 'planned_weight');

          if (!hasPlSets)   await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_sets INTEGER;');
          if (!hasPlReps)   await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_reps INTEGER;');
          if (!hasPlWeight) await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_weight REAL;');
        }
      },
    );
  }

  // ---------- EXERCISES ----------
  Future<int> insertExercise(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    return db.insert('exercises', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    final db = await database;
    return db.query('exercises', orderBy: 'created_at DESC');
  }

  Future<int> updateExercise(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('exercises', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    return db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- WORKOUTS ----------
  Future<int> insertWorkout(String name) async {
    final db = await database;
    return db.insert('workouts', {'name': name, 'created_at': DateTime.now().toIso8601String()});
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await database;
    return db.query('workouts', orderBy: 'created_at DESC');
  }

  /// Fügt Übung ins Workout und übernimmt default_sets/default_reps als Plan.
  Future<int> addExerciseToWorkout(int workoutId, int exerciseId, {int? position}) async {
    final db = await database;
    final linkId = await db.insert('workout_exercises', {
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'position': position
    });

    // Defaults aus exercise übernehmen
    final ex = (await db.query('exercises', where: 'id = ?', whereArgs: [exerciseId], limit: 1)).first;
    await db.update(
      'workout_exercises',
      {
        'planned_sets': ex['default_sets'],
        'planned_reps': ex['default_reps'],
        // planned_weight bleibt zunächst NULL – User setzt es selbst
      },
      where: 'id = ?',
      whereArgs: [linkId],
    );
    return linkId;
  }

  Future<List<Map<String, dynamic>>> getExercisesOfWorkout(int workoutId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT we.id as link_id,
             we.planned_sets, we.planned_reps, we.planned_weight,
             e.*
      FROM workout_exercises we
      JOIN exercises e ON e.id = we.exercise_id
      WHERE we.workout_id = ?
      ORDER BY COALESCE(we.position, 999999), we.id
    ''', [workoutId]);
  }

  Future<int> updateWorkoutExercisePlan({
    required int linkId,
    int? plannedSets,
    int? plannedReps,
    double? plannedWeight,
  }) async {
    final db = await database;
    final data = <String, Object?>{};
    if (plannedSets != null) data['planned_sets'] = plannedSets;
    if (plannedReps != null) data['planned_reps'] = plannedReps;
    if (plannedWeight != null) data['planned_weight'] = plannedWeight;
    if (data.isEmpty) return 0;
    return db.update('workout_exercises', data, where: 'id = ?', whereArgs: [linkId]);
  }

  // ---------- SESSIONS & SETS ----------
  Future<int> startSession({int? workoutId, String? note}) async {
    final db = await database;
    return db.insert('sessions', {
      'workout_id': workoutId,
      'started_at': DateTime.now().toIso8601String(),
      'note': note
    });
  }

  Future<int> insertSet({
    required int sessionId,
    required int exerciseId,
    required int setIndex,
    required int reps,
    required double weight,
    String? note,
  }) async {
    final db = await database;
    return db.insert('workout_sets', {
      'session_id': sessionId,
      'exercise_id': exerciseId,
      'set_index': setIndex,
      'reps': reps,
      'weight': weight,
      'note': note
    });
  }

  Future<List<Map<String, dynamic>>> getSetsOfSession(int sessionId) async {
    final db = await database;
    return db.query('workout_sets',
        where: 'session_id = ?',
        whereArgs: [sessionId],
        orderBy: 'exercise_id ASC, set_index ASC');
  }

  /// Letztes verwendetes Gewicht für eine Übung (global)
  Future<double?> lastWeightForExercise(int exerciseId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT ws.weight
      FROM workout_sets ws
      JOIN sessions s ON s.id = ws.session_id
      WHERE ws.exercise_id = ?
      ORDER BY s.started_at DESC, ws.set_index DESC
      LIMIT 1
    ''', [exerciseId]);
    if (res.isEmpty) return null;
    final w = res.first['weight'];
    return (w is num) ? w.toDouble() : double.tryParse('$w');
  }

  // ---------- JOURNAL ----------
  Future<int> insertJournal(Map<String, dynamic> entry) async {
    final db = await database;
    entry['date'] ??= DateTime.now().toIso8601String();
    return db.insert('journal_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getJournal({String? fromIso, String? toIso}) async {
    final db = await database;
    var where = <String>[];
    var args = <dynamic>[];
    if (fromIso != null) { where.add('date >= ?'); args.add(fromIso); }
    if (toIso != null)   { where.add('date <  ?'); args.add(toIso);  }
    return db.query('journal_entries',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'date DESC');
  }

  // ---------- PROGRESS ----------
  Future<Map<String, dynamic>?> progressForExercise(int exerciseId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT MAX(weight) AS max_weight,
             SUM(weight * reps) AS total_volume,
             COUNT(*) AS total_sets
      FROM workout_sets
      WHERE exercise_id = ?
    ''', [exerciseId]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<Map<String, dynamic>?> bestSetForExercise(int exerciseId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT ws.weight, ws.reps, s.started_at
      FROM workout_sets ws
      JOIN sessions s ON s.id = ws.session_id
      WHERE ws.exercise_id = ?
      ORDER BY ws.weight DESC, ws.reps DESC
      LIMIT 1
    ''', [exerciseId]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<List<Map<String, dynamic>>> recentSetsForExercise(int exerciseId, {int limit = 10}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT ws.set_index, ws.reps, ws.weight, s.started_at
      FROM workout_sets ws
      JOIN sessions s ON s.id = ws.session_id
      WHERE ws.exercise_id = ?
      ORDER BY s.started_at DESC, ws.set_index DESC
      LIMIT ?
    ''', [exerciseId, limit]);
  }

  Future<List<Map<String, dynamic>>> volumePerDayForExercise(int exerciseId, {int limitDays = 30}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT substr(s.started_at, 1, 10) AS day,
             SUM(ws.weight * ws.reps) AS day_volume,
             COUNT(*) AS sets_count
      FROM workout_sets ws
      JOIN sessions s ON s.id = ws.session_id
      WHERE ws.exercise_id = ?
      GROUP BY day
      ORDER BY day DESC
      LIMIT ?
    ''', [exerciseId, limitDays]);
  }
}
