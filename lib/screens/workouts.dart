import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'sessions.dart';

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

  Future<void> _createWorkout() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neues Workout'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Workout-Name')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('💪 Workouts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createWorkout,
        icon: const Icon(Icons.add),
        label: const Text('Workout'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('Noch keine Workouts – lege dein erstes an!'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final w = items[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  title: Text(w['name'] ?? ''),
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
  late Future<List<Map<String, dynamic>>> _futureAllExercises;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _futureExercisesOfWorkout = DB.instance.getExercisesOfWorkout(widget.workout['id'] as int);
    _futureAllExercises = DB.instance.getExercises();
    setState(() {});
  }

  Future<void> _addExerciseToWorkout() async {
    final all = await _futureAllExercises;
    if (all.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erstelle zuerst Übungen im Tab „Übungen“.')),
      );
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
            items: all
                .map((e) => DropdownMenuItem<int>(
                      value: e['id'] as int,
                      child: Text(e['name'] ?? ''),
                    ))
                .toList(),
            onChanged: (v) => setStateDialog(() => selectedId = v),
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

  Future<void> _startTraining() async {
    final exercises = await DB.instance.getExercisesOfWorkout(widget.workout['id'] as int);
    if (exercises.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Füge zuerst Übungen zu diesem Workout hinzu.')),
      );
      return;
    }
    final sessionId = await DB.instance.startSession(workoutId: widget.workout['id'] as int);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionScreen(
          sessionId: sessionId,
          workoutId: widget.workout['id'] as int,
          workoutName: widget.workout['name'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout: ${w['name']}'),
        actions: [IconButton(onPressed: _startTraining, icon: const Icon(Icons.play_arrow))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExerciseToWorkout,
        icon: const Icon(Icons.add),
        label: const Text('Übung hinzufügen'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureExercisesOfWorkout,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('Noch keine Übungen in diesem Workout.'));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: ListTile(
                  title: Text(e['name'] ?? ''),
                  subtitle: Text([e['muscle_group'], e['unit']].where((x) => (x ?? '').toString().isNotEmpty).join(' • ')),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _startTraining,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Training starten'),
          ),
        ),
      ),
    );
  }
}
