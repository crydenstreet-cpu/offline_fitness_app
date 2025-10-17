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
  void initState() { super.initState(); _reload(); }
  void _reload() { _future = DB.instance.getWorkouts(); setState(() {}); }

  Future<void> _createWorkout() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neues Workout'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Workout-Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anlegen')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await DB.instance.insertWorkout(c.text.trim());
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
              return Card(
                child: ListTile(
                  title: Text(w['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: w)),
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

  @override
  void initState() { super.initState(); _reload(); }
  void _reload() {
    _futureExercisesOfWorkout = DB.instance.getExercisesOfWorkout(widget.workout['id'] as int);
    setState(() {});
  }

  Future<void> _addExerciseToWorkout() async {
    // ⬅️ WICHTIG: IMMER FRISCH AUS DB LADEN (nicht aus einem alten Future)
    final allExercises = await DB.instance.getExercises();

    // Möglichkeit, direkt eine neue Übung anzulegen
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

    int? selectedId;
    final result = await showModalBottomSheet<Object?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 12, right: 12,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Übung hinzufügen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (allExercises.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Noch keine Übungen vorhanden. Lege zuerst eine Übung an.'),
                  )
                else
                  StatefulBuilder(
                    builder: (ctx, setStateSheet) => DropdownButtonFormField<int>(
                      value: selectedId,
                      items: allExercises
                          .map((e) => DropdownMenuItem<int>(
                                value: e['id'] as int,
                                child: Text(e['name'] ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setStateSheet(() => selectedId = v),
                      decoration: const InputDecoration(labelText: 'Übung auswählen'),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.fitness_center),
                        label: const Text('Übung anlegen'),
                        onPressed: () async {
                          Navigator.pop(ctx, 'create');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Hinzufügen'),
                        onPressed: selectedId == null ? null : () => Navigator.pop(ctx, selectedId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (result == 'create') {
      await _createExerciseInline();
      // Danach direkt nochmal den Add-Flow öffnen
      await _addExerciseToWorkout();
      return;
    }

    if (result is int) {
      await DB.instance.addExerciseToWorkout(widget.workout['id'] as int, result);
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Übung zum Workout hinzugefügt.')));
    }
  }

  Future<void> _editPlanDialog(Map<String, dynamic> row) async {
    final linkId = row['link_id'] as int;
    final unit   = (row['unit'] ?? 'kg').toString();
    final setsCtrl = TextEditingController(text: (row['planned_sets'] ?? row['default_sets'] ?? 3).toString());
    final repsCtrl = TextEditingController(text: (row['planned_reps'] ?? row['default_reps'] ?? 10).toString());
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
          TextField(
            controller: weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Gewicht ($unit)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
        ],
      ),
    );

    if (saved == true) {
      final sets = int.tryParse(setsCtrl.text.trim());
      final reps = int.tryParse(repsCtrl.text.trim());
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
      await DB.instance.updateWorkoutExercisePlan(
        linkId: linkId,
        plannedSets: sets,
        plannedReps: reps,
        plannedWeight: weight,
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
    return AppScaffold(
      appBar: AppBar(
        title: Text('Workout: ${w['name']}'),
        actions: [IconButton(onPressed: _startTraining, icon: const Icon(Icons.play_arrow))],
      ),
      fab: FloatingActionButton.extended(
        onPressed: _addExerciseToWorkout,
        icon: const Icon(Icons.add),
        label: const Text('Übung'),
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
