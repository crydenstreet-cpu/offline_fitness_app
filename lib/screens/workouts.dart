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
  void initState() { super.initState(); _reload(); }
  void _reload() { _future = DB.instance.getWorkouts(); setState(() {}); }

  Future<void> _createWorkout() async {
    final c = TextEditingController();
    int? color;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Neues Workout'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: c, decoration: const InputDecoration(labelText: 'Workout-Name'), autofocus: true),
            const SizedBox(height: 12),
            _ColorPickerRow(
              selected: color,
              onPick: (v) => setStateDialog(() => color = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Anlegen')),
          ],
        ),
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await DB.instance.insertWorkout(c.text.trim(), color: color);
      _reload();
    }
  }

  Future<void> _editWorkout(Map<String, dynamic> w) async {
    final nameCtrl = TextEditingController(text: w['name']?.toString() ?? '');
    int? color = w['color'] as int?;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Workout bearbeiten'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            _ColorPickerRow(selected: color, onPick: (v) => setStateDialog(() => color = v)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Abbrechen')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Löschen', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Speichern')),
          ],
        ),
      ),
    );
    if (choice == 'save') {
      await DB.instance.updateWorkout(w['id'] as int, name: nameCtrl.text.trim(), color: color);
      _reload();
    } else if (choice == 'delete') {
      await DB.instance.deleteWorkout(w['id'] as int);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('💪 Workouts')),
      fab: FloatingActionButton.extended(onPressed: _createWorkout, icon: const Icon(Icons.add), label: const Text('Workout')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('Noch keine Workouts – lege dein erstes an!'));
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final w = items[i];
              final color = (w['color'] as int?) ?? 0xFFE53935; // fallback rot
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(color).withOpacity(0.18),
                    child: Icon(Icons.fitness_center, color: Color(color)),
                  ),
                  title: Text(w['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _editWorkout(w)),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => WorkoutDetailScreen(workout: w),
                    ));
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

// ==== Detail bleibt wie gehabt (Plan bearbeiten + Session starten) ====

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
  void initState() { super.initState(); _reload(); }
  void _reload() {
    _futureExercisesOfWorkout = DB.instance.getExercisesOfWorkout(widget.workout['id'] as int);
    _futureAllExercises = DB.instance.getExercises();
    setState(() {});
  }

  Future<void> _addExerciseToWorkout() async {
    final all = await _futureAllExercises;
    if (all.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erstelle zuerst Übungen im Tab „Übungen“.')));
      return;
    }
    int? selectedId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Übung hinzufügen'),
          content: DropdownButtonFormField<int>(
            value: selectedId,
            items: all.map((e) => DropdownMenuItem<int>(value: e['id'] as int, child: Text(e['name'] ?? ''))).toList(),
            onChanged: (v) => setStateDialog(() => selectedId = v),
            decoration: const InputDecoration(labelText: 'Übung'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            ElevatedButton(
              onPressed: selectedId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && selectedId != null) {
      await DB.instance.addExerciseToWorkout(widget.workout['id'] as int, selectedId!);
      _reload();
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
          TextField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Gewicht ($unit)')),
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
    final color = (w['color'] as int?) ?? 0xFFE53935;
    return AppScaffold(
      appBar: AppBar(
        title: Text('Workout: ${w['name']}'),
        actions: [IconButton(onPressed: _startTraining, icon: const Icon(Icons.play_arrow))],
      ),
      fab: FloatingActionButton.extended(onPressed: _addExerciseToWorkout, icon: const Icon(Icons.add), label: const Text('Übung')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureExercisesOfWorkout,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('Noch keine Übungen in diesem Workout.'));
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
                  leading: CircleAvatar(
                    backgroundColor: Color(color).withOpacity(0.18),
                    child: Icon(Icons.fitness_center, color: Color(color)),
                  ),
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

// --- kleine Farbwahl für Workouts ---
class _ColorPickerRow extends StatelessWidget {
  final int? selected;
  final ValueChanged<int?> onPick;
  const _ColorPickerRow({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = <int>[
      0xFFE53935, 0xFFFB8C00, 0xFFFDD835, 0xFF43A047,
      0xFF1E88E5, 0xFF8E24AA, 0xFF6D4C41, 0xFF546E7A,
    ];
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: [
        ...colors.map((c) => GestureDetector(
              onTap: () => onPick(c),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: Border.all(color: selected == c ? Colors.white : Colors.black12, width: 2),
                ),
              ),
            )),
        GestureDetector(
          onTap: () => onPick(null),
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: selected == null ? Colors.white : Colors.black12, width: 2),
            ),
            child: const Icon(Icons.block, size: 16),
          ),
        ),
      ],
    );
  }
}
