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
      version: 4, // ⬅️ Schema v4 (inkl. workout_schedule)
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

        // ⬇️ NEU: Datum → Workout (YYYY-MM-DD)
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
        // v2: default_sets / default_reps
        if (oldVersion < 2) {
          final cols = await db.rawQuery('PRAGMA table_info(exercises);');
          if (!cols.any((c) => (c['name'] as String?) == 'default_sets')) {
            await db.execute('ALTER TABLE exercises ADD COLUMN default_sets INTEGER DEFAULT 3;');
          }
          if (!cols.any((c) => (c['name'] as String?) == 'default_reps')) {
            await db.execute('ALTER TABLE exercises ADD COLUMN default_reps INTEGER DEFAULT 10;');
          }
        }
        // v3: planned_* in workout_exercises
        if (oldVersion < 3) {
          final cols = await db.rawQuery('PRAGMA table_info(workout_exercises);');
          if (!cols.any((c) => (c['name'] as String?) == 'planned_sets'))   {
            await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_sets INTEGER;');
          }
          if (!cols.any((c) => (c['name'] as String?) == 'planned_reps'))   {
            await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_reps INTEGER;');
          }
          if (!cols.any((c) => (c['name'] as String?) == 'planned_weight')) {
            await db.execute('ALTER TABLE workout_exercises ADD COLUMN planned_weight REAL;');
          }
        }
        // v4: workout_schedule
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

  // ---------- SCHEDULE (NEU) ----------
  /// Einzelnen Tag planen/überschreiben (YYYY-MM-DD)
  Future<void> upsertSchedule(String ymd, int workoutId, {String? note}) async {
    final db = await database;
    await db.insert('workout_schedule', {
      'date': ymd, 'workout_id': workoutId, 'note': note
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Plan für mehrere Wochen erzeugen: mapping weekday(1=Mo..7=So) -> workoutId
  Future<void> generateSchedule({
    required DateTime startDate,
    required int weeks,
    required Map<int, int?> weekdayToWorkoutId,
  }) async {
    final db = await database;
    final batch = db.batch();
    // Start auf Tagesbeginn normalisieren
    DateTime start = DateTime(startDate.year, startDate.month, startDate.day);
    final totalDays = weeks * 7;
    for (int d = 0; d < totalDays; d++) {
      final day = start.add(Duration(days: d));
      final weekday = day.weekday; // 1..7 (Mo..So)
      final workoutId = weekdayToWorkoutId[weekday];
      if (workoutId != null) {
        final ymd = _ymd(day);
        batch.insert('workout_schedule', {
          'date': ymd,
          'workout_id': workoutId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    await batch.commit(noResult: true);
  }

  /// Plan in Datumsspanne holen (inkl.)
  Future<List<Map<String, dynamic>>> getScheduleBetween(DateTime from, DateTime to) async {
    final db = await database;
    final fromY = _ymd(from);
    final toY   = _ymd(to);
    return db.rawQuery('''
      SELECT s.date, s.workout_id, w.name AS workout_name
      FROM workout_schedule s
      JOIN workouts w ON w.id = s.workout_id
      WHERE s.date >= ? AND s.date <= ?
      ORDER BY s.date ASC
    ''', [fromY, toY]);
  }

  /// Nächste N geplante Tage ab heute
  Future<List<Map<String, dynamic>>> upcomingSchedule({int days = 21}) async {
    final today = DateTime.now();
    return getScheduleBetween(today, today.add(Duration(days: days)));
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  /// Zuweisung eines Datums entfernen
  Future<int> deleteSchedule(String ymd) async {
    final db = await database;
    return db.delete('workout_schedule', where: 'date = ?', whereArgs: [ymd]);
  }
}
