// lib/db/database_helper.dart
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
      version: 6, // ⬅️ v6: exercises.position + Fixes
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
            position INTEGER,                 -- ⬅️ v6
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
            motivation INTEGER,
            linked_session_id INTEGER,
            tags TEXT,
            FOREIGN KEY(linked_session_id) REFERENCES sessions(id) ON DELETE SET NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE workout_schedule(
            date TEXT PRIMARY KEY,
            workout_id INTEGER NOT NULL,
            note TEXT,
            FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE CASCADE
          );
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final cols = await db.rawQuery('PRAGMA table_info(exercises);');
          if (!cols.any((c) => (c['name'] as String?) == 'default_sets')) {
            await db.execute('ALTER TABLE exercises ADD COLUMN default_sets INTEGER DEFAULT 3;');
          }
          if (!cols.any((c) => (c['name'] as String?) == 'default_reps')) {
            await db.execute('ALTER TABLE exercises ADD COLUMN default_reps INTEGER DEFAULT 10;');
          }
        }
        if (oldVersion < 3) {
          final cols = await db.rawQuery('PRAGMA table_info(workout_exercises);');
          if (!cols.any((c) => (c['name'] as String?) == 'planned_sets')) {
            await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_sets INTEGER;');
          }
          if (!cols.any((c) => (c['name'] as String?) == 'planned_reps')) {
            await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_reps INTEGER;');
          }
          if (!cols.any((c) => (c['name'] as String?) == 'planned_weight')) {
            await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_weight REAL;');
          }
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS workout_schedule(
              date TEXT PRIMARY KEY,
              workout_id INTEGER NOT NULL,
              note TEXT,
              FOREIGN KEY(workout_id) REFERENCES workouts(id) ON DELETE CASCADE
            );
          ''');
        }
        if (oldVersion < 5) {
          final cols = await db.rawQuery('PRAGMA table_info(journal_entries);');
          if (!cols.any((c) => (c['name'] as String?) == 'motivation')) {
            await db.execute('ALTER TABLE journal_entries ADD COLUMN motivation INTEGER;');
          }
        }
        if (oldVersion < 6) {
          final cols = await db.rawQuery('PRAGMA table_info(exercises);');
          if (!cols.any((c) => (c['name'] as String?) == 'position')) {
            await db.execute('ALTER TABLE exercises ADD COLUMN position INTEGER;');
          }
        }
      },
    );
  }

  // -------- EXERCISES --------
  Future<int> insertExercise(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    return db.insert('exercises', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getExercises() async {
    final db = await database;
    // Sortierung: zuerst manuell (position), dann fallback auf id DESC
    return db.query('exercises', orderBy: 'COALESCE(position, 999999), id DESC');
  }

  Future<int> updateExercise(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update('exercises', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    return db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  /// ⬅️ Wird aus exercises.dart beim Drag&Drop-Reorder aufgerufen
  Future<void> updateExercisesOrder(List<int> idsInOrder) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < idsInOrder.length; i++) {
      batch.update('exercises', {'position': i + 1}, where: 'id = ?', whereArgs: [idsInOrder[i]]);
    }
    await batch.commit(noResult: true);
  }

  // -------- WORKOUTS --------
  Future<int> insertWorkout(String name) async {
    final db = await database;
    return db.insert('workouts', {
      'name': name,
      'created_at': DateTime.now().toIso8601String()
    });
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final db = await database;
    return db.query('workouts', orderBy: 'created_at DESC');
  }

  Future<int> addExerciseToWorkout(int workoutId, int exerciseId, {int? position}) async {
    final db = await database;
    final linkId = await db.insert('workout_exercises', {
      'workout_id': workoutId,
      'exercise_id': exerciseId,
      'position': position
    });
    final ex = (await db.query('exercises', where: 'id = ?', whereArgs: [exerciseId], limit: 1)).first;
    await db.update(
      'workout_exercises',
      {
        'planned_sets': ex['default_sets'],
        'planned_reps': ex['default_reps'],
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

  // -------- SESSIONS & SETS --------
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
    return db.query(
      'workout_sets',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'exercise_id ASC, set_index ASC',
    );
  }

  Future<Map<String, dynamic>?> lastSetForExerciseInSession(int sessionId, int exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'workout_sets',
      where: 'session_id = ? AND exercise_id = ?',
      whereArgs: [sessionId, exerciseId],
      orderBy: 'set_index DESC, id DESC',
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> updateSet(int id, {int? reps, double? weight, String? note}) async {
    final db = await database;
    final data = <String, Object?>{};
    if (reps != null) data['reps'] = reps;
    if (weight != null) data['weight'] = weight;
    if (note != null) data['note'] = note;
    if (data.isEmpty) return 0;
    return db.update('workout_sets', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSet(int id) async {
    final db = await database;
    return db.delete('workout_sets', where: 'id = ?', whereArgs: [id]);
  }

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

  // -------- JOURNAL --------
  Future<int> insertJournal(
    DateTime date,
    String note, {
    int mood = 3,
    int? energy,
    int? sleep,
    int? motivation,
    int? linkedSessionId,
    String? tags,
  }) async {
    final db = await database;
    return db.insert('journal_entries', {
      'date': _ymd(date),
      'text': note,
      'mood': mood,
      'energy': energy,
      'sleep': sleep,
      'motivation': motivation,
      'linked_session_id': linkedSessionId,
      'tags': tags,
    });
  }

  Future<int> updateJournal({
    required int id,
    DateTime? date,
    String? note,
    int? mood,
    int? energy,
    int? sleep,
    int? motivation,
    int? linkedSessionId,
    String? tags,
  }) async {
    final db = await database;
    final data = <String, Object?>{};
    if (date != null) data['date'] = _ymd(date);
    if (note != null) data['text'] = note;
    if (mood != null) data['mood'] = mood;
    if (energy != null) data['energy'] = energy;
    if (sleep != null) data['sleep'] = sleep;
    if (motivation != null) data['motivation'] = motivation;
    if (linkedSessionId != null) data['linked_session_id'] = linkedSessionId;
    if (tags != null) data['tags'] = tags;
    if (data.isEmpty) return 0;
    return db.update('journal_entries', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteJournal(int id) async {
    final db = await database;
    return db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getJournal({int limit = 200}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        id,
        date,
        text AS note,
        mood,
        energy,
        sleep,
        motivation,
        linked_session_id,
        tags
      FROM journal_entries
      ORDER BY date DESC, id DESC
      LIMIT ?
    ''', [limit]);
  }

  // -------- PROGRESS (pro Übung) --------
  Future<Map<String, dynamic>?> progressForExercise(int exerciseId) async {
    final db = await database;
    final res = await db.rawQuery(''
        'SELECT MAX(weight) AS max_weight, '
        '       SUM(weight * reps) AS total_volume, '
        '       COUNT(*) AS total_sets '
        'FROM workout_sets '
        'WHERE exercise_id = ?',
        [exerciseId]);
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
             SUM(ws.weight * reps) AS day_volume,
             COUNT(*) AS sets_count
      FROM workout_sets ws
      JOIN sessions s ON s.id = ws.session_id
      WHERE ws.exercise_id = ?
      GROUP BY day
      ORDER BY day DESC
      LIMIT ?
    ''', [exerciseId, limitDays]);
  }

  /// ⬅️ KORREKTE SIGNATUR (vorher fehlende Klammer) – Ø-Reps + Max-Weight pro Tag
  Future<List<Map<String, dynamic>>> repsAndWeightPerDayForExercise(
    int exerciseId, {int limitDays = 30}
  ) async {
    final db = await database;
    return db.rawQuery('''
      SELECT substr(s.started_at, 1, 10) AS day,
             AVG(ws.reps)   AS avg_reps,
             MAX(ws.weight) AS max_weight
      FROM workout_sets ws
      JOIN sessions s ON s.id = ws.session_id
      WHERE ws.exercise_id = ?
      GROUP BY day
      ORDER BY day DESC
      LIMIT ?
    ''', [exerciseId, limitDays]);
  }

  // -------- SCHEDULE --------
  Future<void> upsertSchedule(String ymd, int workoutId, {String? note}) async {
    final db = await database;
    await db.insert(
      'workout_schedule',
      {'date': ymd, 'workout_id': workoutId, 'note': note},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> generateSchedule({
    required DateTime startDate,
    required int weeks,
    required Map<int, int?> weekdayToWorkoutId,
  }) async {
    final db = await database;
    final batch = db.batch();
    DateTime start = DateTime(startDate.year, startDate.month, startDate.day);
    final totalDays = weeks * 7;
    for (int d = 0; d < totalDays; d++) {
      final day = start.add(Duration(days: d));
      final weekday = day.weekday; // 1..7
      final workoutId = weekdayToWorkoutId[weekday];
      if (workoutId != null) {
        final ymd = _ymd(day);
        batch.insert(
          'workout_schedule',
          {'date': ymd, 'workout_id': workoutId},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getScheduleBetween(DateTime from, DateTime to) async {
    final db = await database;
    final fromY = _ymd(from);
    final toY = _ymd(to);
    return db.rawQuery('''
      SELECT s.date, s.workout_id, w.name AS workout_name
      FROM workout_schedule s
      JOIN workouts w ON w.id = s.workout_id
      WHERE s.date >= ? AND s.date <= ?
      ORDER BY s.date ASC
    ''', [fromY, toY]);
  }

  Future<List<Map<String, dynamic>>> upcomingSchedule({int days = 21}) async {
    final today = DateTime.now();
    return getScheduleBetween(today, today.add(Duration(days: days)));
  }

  Future<int> deleteSchedule(String ymd) async {
    final db = await database;
    return db.delete('workout_schedule', where: 'date = ?', whereArgs: [ymd]);
  }

  // -------- DASHBOARD / STATS HELPERS --------
  Future<Map<String, dynamic>?> lastSessionSummary() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT s.id as session_id,
             s.started_at as started_at,
             COUNT(ws.id) as sets_count,
             COALESCE(SUM(ws.weight * ws.reps), 0) as total_volume
      FROM sessions s
      LEFT JOIN workout_sets ws ON ws.session_id = s.id
      ORDER BY s.started_at DESC
      LIMIT 1
    ''');
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<Map<String, dynamic>?> nextPlannedWorkout() async {
    final db = await database;
    final today = DateTime.now();
    final ymd = _ymd(DateTime(today.year, today.month, today.day));
    final rows = await db.rawQuery('''
      SELECT s.date, s.workout_id, w.name AS workout_name
      FROM workout_schedule s
      JOIN workouts w ON w.id = s.workout_id
      WHERE s.date >= ?
      ORDER BY s.date ASC
      LIMIT 1
    ''', [ymd]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<List<Map<String, dynamic>>> volumeByDayAll({int days = 14}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days - 1));
    final sinceIso = since.toIso8601String().substring(0, 10);
    return db.rawQuery('''
      SELECT substr(s.started_at, 1, 10) AS day,
             COALESCE(SUM(ws.weight * ws.reps), 0) AS volume
      FROM sessions s
      LEFT JOIN workout_sets ws ON ws.session_id = s.id
      WHERE substr(s.started_at,1,10) >= ?
      GROUP BY day
      ORDER BY day ASC
    ''', [sinceIso]);
  }

  Future<double?> averageMoodLast7Days() async {
    final db = await database;
    final since = DateTime.now().subtract(const Duration(days: 6));
    final rows = await db.rawQuery('''
      SELECT AVG(mood) as avg_mood
      FROM journal_entries
      WHERE date >= ?
    ''', [_ymd(since)]);
    if (rows.isEmpty) return null;
    final v = rows.first['avg_mood'];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

  Future<int> totalVolumeBetween(DateTime from, DateTime to) async {
    final db = await database;
    final fromIso = from.toIso8601String();
    final toIso = to.toIso8601String();
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(ws.weight * ws.reps),0) as vol
      FROM workout_sets ws
      JOIN sessions s ON s.id = ws.session_id
      WHERE s.started_at >= ? AND s.started_at < ?
    ''', [fromIso, toIso]);
    if (rows.isEmpty) return 0;
    final v = rows.first['vol'];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  // -------- Utils --------
  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
