// lib/screens/workouts.dart
import 'package:flutter/material.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';
import 'package:offline_fitness_app/screens/sessions.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DB.instance.getWorkouts();
    setState(() {});
  }

  // ============================
  // Workout ERSTELLEN (mit Farbe + Sofort-Planen in Kalender)
  // ============================
  Future<void> _createWorkout() async {
    final nameCtrl = TextEditingController();
    int? pickedColor;

    // Neu: Sofort im Kalender planen
    bool planNow = false;
    DateTime startDate = DateTime.now();
    int weeks = 4;
    final Set<int> selectedWeekdays = {}; // 1=Mo … 7=So

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Neues Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Workout-Name'),
                ),
                const SizedBox(height: 12),

                // Farbe
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Farbe (optional)',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorChoices.map((c) {
                    final selected = pickedColor == c.value;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => pickedColor = c.value),
                      child: CircleAvatar(
                        radius: selected ? 18 : 16,
                        backgroundColor: c,
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Sofort im Kalender einplanen
                SwitchListTile(
                  title: const Text('Sofort im Kalender einplanen'),
                  value: planNow,
                  onChanged: (v) => setStateDialog(() => planNow = v),
                ),

                if (planNow) ...[
                  const SizedBox(height: 8),

                  // Startdatum
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Startdatum'),
                    subtitle: Text(
                      '${startDate.year.toString().padLeft(4, '0')}-'
                      '${startDate.month.toString().padLeft(2, '0')}-'
                      '${startDate.day.toString().padLeft(2, '0')}',
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setStateDialog(() => startDate =
                            DateTime(picked.year, picked.month, picked.day));
                      }
                    },
                  ),

                  // Wochenanzahl
                  Row(
                    children: [
                      const Text('Wochen:'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: weeks,
                        onChanged: (v) => setStateDialog(() => weeks = v ?? 4),
                        items: const [1, 2, 3, 4, 6, 8, 12]
                            .map((w) =>
                                DropdownMenuItem<int>(value: w, child: Text('$w')))
                            .toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Wochentage',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 6),

                  // Mo..So Auswahl
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _weekdayChip(selectedWeekdays, 1, 'Mo',
                          onChanged: () => setStateDialog(() {})),
                      _weekdayChip(selectedWeekdays, 2, 'Di',
                          onChanged: () => setStateDialog(() {})),
                      _weekdayChip(selectedWeekdays, 3, 'Mi',
                          onChanged: () => setStateDialog(() {})),
                      _weekdayChip(selectedWeekdays, 4, 'Do',
                          onChanged: () => setStateDialog(() {})),
                      _weekdayChip(selectedWeekdays, 5, 'Fr',
                          onChanged: () => setStateDialog(() {})),
                      _weekdayChip(selectedWeekdays, 6, 'Sa',
                          onChanged: () => setStateDialog(() {})),
                      _weekdayChip(selectedWeekdays, 7, 'So',
                          onChanged: () => setStateDialog(() {})),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (planNow && selectedWeekdays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Bitte mindestens einen Wochentag auswählen.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Anlegen'),
            ),
          ],
        ),
      ),
    );

    final name = nameCtrl.text.trim();
    if (ok == true && name.isNotEmpty) {
      // 1) Workout speichern (inkl. optionaler Farbe)
      final workoutId = await DB.instance.insertWorkout(name, color: pickedColor);

      // 2) Optional im Kalender einplanen
      if (planNow && selectedWeekdays.isNotEmpty) {
        final map = <int, int?>{};
        for (var wd = 1; wd <= 7; wd++) {
          map[wd] = selectedWeekdays.contains(wd) ? workoutId : null;
        }
        await DB.instance.generateSchedule(
          startDate: startDate,
          weeks: weeks,
          weekdayToWorkoutId: map,
        );
      }

      // 3) Liste aktualisieren
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout angelegt${(planNow && selectedWeekdays.isNotEmpty) ? ' und eingeplant' : ''}.',
            ),
          ),
        );
      }
    }
  }

  // Kleiner Helper für die Wochentags-Chips
  Widget _weekdayChip(Set<int> selected, int weekday, String label,
      {required VoidCallback onChanged}) {
    final isSel = selected.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) {
        if (isSel) {
          selected.remove(weekday);
        } else {
          selected.add(weekday);
        }
        onChanged();
      },
    );
  }

  // ============================
  // Workout bearbeiten (Name + Farbe)
  // ============================
  Future<void> _editWorkoutDialog(Map<String, dynamic> workout) async {
    final nameCtrl = TextEditingController(text: workout['name']?.toString() ?? '');
    int? pickedColor = workout['color'] as int?;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Workout bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Farbe',
                    style: Theme.of(context).textTheme.labelMedium),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorChoices.map((c) {
                  final selected = pickedColor == c.value;
                  return GestureDetector(
                    onTap: () => setStateDialog(() => pickedColor = c.value),
                    child: CircleAvatar(
                      radius: selected ? 18 : 16,
                      backgroundColor: c,
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      await DB.instance.updateWorkout(
        workout['id'] as int,
        name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        color: pickedColor,
      );
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('💪 Workouts')),
      fab: FloatingActionButton.extended(
        onPressed: _createWorkout,
        icon: const Icon(Icons.add),
        label: const Text('Workout'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Noch keine Workouts – lege dein erstes an!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final w = items[i];
              final color = w['color'] as int?;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color != null
                        ? Color(color)
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    w['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') {
                        await _editWorkoutDialog(w);
                      } else if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Workout löschen?'),
                            content: Text('„${w['name']}“ wirklich löschen?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Abbrechen'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Löschen'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await DB.instance.deleteWorkout(w['id'] as int);
                          _reload();
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                      PopupMenuItem(value: 'delete', child: Text('Löschen')),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutDetailScreen(workout: w),
                      ),
                    );
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WorkoutDetailScreen extends StatefulWidget {
  final Map<String, dynamic> workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late Future<List<Map<String, dynamic>>> _futureExercisesOfWorkout;
  late Future<List<Map<String, dynamic>>> _futureAllExercises;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureExercisesOfWorkout =
        DB.instance.getExercisesOfWorkout(widget.workout['id'] as int);
    _futureAllExercises = DB.instance.getExercises();
    setState(() {});
  }

  Future<void> _createExerciseInline() async {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'kg');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neue Übung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Einheit (z. B. kg, reps, s)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await DB.instance.insertExercise({
        'name': nameCtrl.text.trim(),
        'unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
      });
    }
  }

  Future<void> _addExerciseToWorkout() async {
    // 1) Alle Übungen holen (frisch)
    List<Map<String, dynamic>> all = await _futureAllExercises;

    // Falls noch keine existieren → Inline anlegen anbieten
    if (all.isEmpty) {
      await _createExerciseInline();
      all = await DB.instance.getExercises();
      if (all.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Übung vorhanden.')),
        );
        return;
      }
    }

    // 2) Auswahl-Dialog
    int? selectedId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Übung zum Workout hinzufügen'),
          content: SizedBox(
            width: 420,
            height: 360,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: all.map((e) {
                      final id = e['id'] as int;
                      return RadioListTile<int>(
                        value: id,
                        groupValue: selectedId,
                        title: Text(e['name']?.toString() ?? ''),
                        subtitle: Text('Einheit: ${e['unit'] ?? 'kg'}'),
                        onChanged: (v) => setStateDialog(() => selectedId = v),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Neue Übung anlegen'),
                        onPressed: () async {
                          await _createExerciseInline();
                          // Liste aktualisieren & UI im Dialog neu zeichnen
                          all = await DB.instance.getExercises();
                          if (!mounted) return;
                          setStateDialog(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Hinzufügen'),
                        onPressed: selectedId == null
                            ? null
                            : () => Navigator.pop(ctx, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true && selectedId != null) {
      await DB.instance.addExerciseToWorkout(
        widget.workout['id'] as int,
        selectedId!, // <-- WICHTIG: non-null
      );
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Übung zum Workout hinzugefügt.')),
        );
      }
    }
  }

  Future<void> _editPlanDialog(Map<String, dynamic> row) async {
    final linkId = row['link_id'] as int;
    final unit   = (row['unit'] ?? 'kg').toString();
    final setsCtrl   = TextEditingController(text: (row['planned_sets'] ?? row['default_sets'] ?? 3).toString());
    final repsCtrl   = TextEditingController(text: (row['planned_reps'] ?? row['default_reps'] ?? 10).toString());
    final weightCtrl = TextEditingController(text: (row['planned_weight'] ?? '').toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Plan bearbeiten – ${row['name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: TextField(controller: setsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sätze'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: repsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wdh.'))),
          ]),
          const SizedBox(height: 8),
          TextField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Gewicht ($unit)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
        ],
      ),
    );

    if (saved == true) {
      final sets   = int.tryParse(setsCtrl.text.trim());
      final reps   = int.tryParse(repsCtrl.text.trim());
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
      await DB.instance.updateWorkoutExercisePlan(
        linkId: linkId, plannedSets: sets, plannedReps: reps, plannedWeight: weight,
      );
      _reload();
    }
  }

  Future<void> _startTraining() async {
    final exercises = await DB.instance.getExercisesOfWorkout(widget.workout['id'] as int);
    if (exercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Füge zuerst Übungen hinzu.')));
      return;
    }
    final sessionId = await DB.instance.startSession(workoutId: widget.workout['id'] as int);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SessionScreen(
        sessionId: sessionId,
        workoutId: widget.workout['id'] as int,
        workoutName: widget.workout['name'] as String,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    final color = w['color'] as int?;
    return AppScaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(radius: 10, backgroundColor: color != null ? Color(color) : Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Workout: ${w['name']}'),
          ],
        ),
        actions: [
          IconButton(onPressed: _addExerciseToWorkout, icon: const Icon(Icons.add)),
          IconButton(
            onPressed: () async {
              // Edit vom Detail aus – nutze Dialog aus der Liste
              await context.findAncestorStateOfType<_WorkoutsScreenState>()?._editWorkoutDialog(w);
              setState(() {});
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(onPressed: _startTraining, icon: const Icon(Icons.play_arrow)),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureExercisesOfWorkout,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Noch keine Übungen in diesem Workout.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              final unit = (e['unit'] ?? 'kg').toString();
              final planSets = e['planned_sets'] ?? e['default_sets'];
              final planReps = e['planned_reps'] ?? e['default_reps'];
              final planWeight = e['planned_weight'];

              return Card(
                child: ListTile(
                  title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    'Plan: ${planSets ?? '-'}×${planReps ?? '-'}'
                    '${planWeight != null ? ' @ ${_fmt(planWeight)} $unit' : ''}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editPlanDialog(e),
                    tooltip: 'Plan bearbeiten',
                  ),
                ),
              );
            },
          );
        },
      ),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Training starten'),
            onPressed: _startTraining,
          ),
        ),
      ),
    );
  }

  String _fmt(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }
}

final List<Color> _colorChoices = [
  const Color(0xFFE53935), // rot
  const Color(0xFFEF6C00), // orange
  const Color(0xFFFDD835), // gelb
  const Color(0xFF43A047), // grün
  const Color(0xFF1E88E5), // blau
  const Color(0xFF6A1B9A), // lila
  const Color(0xFF8D6E63), // braun
  const Color(0xFF546E7A), // blau-grau
];
