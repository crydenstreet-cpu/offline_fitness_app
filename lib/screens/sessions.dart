import 'package:flutter/material.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';

class SessionScreen extends StatefulWidget {
  final int sessionId;
  final int workoutId;
  final String workoutName;
  const SessionScreen({super.key, required this.sessionId, required this.workoutId, required this.workoutName});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<Map<String, dynamic>> _workoutExercises = [];
  List<Map<String, dynamic>> _sets = [];

  @override
  void initState() { super.initState(); _reload(); }
  Future<void> _reload() async {
    final exs = await DB.instance.getExercisesOfWorkout(widget.workoutId); // enthält planned_* + exercise-Felder
    final sets = await DB.instance.getSetsOfSession(widget.sessionId);
    setState(() { _workoutExercises = exs; _sets = sets; });
  }

  List<Map<String, dynamic>> _setsForExercise(int exerciseId) {
    return _sets.where((s) => (s['exercise_id'] as int) == exerciseId).toList()
      ..sort((a, b) => (a['set_index'] as int).compareTo(b['set_index'] as int));
  }

  Future<void> _addSetDialog(Map<String, dynamic> ex) async {
    final exerciseId = ex['id'] as int;
    final unit = (ex['unit'] ?? 'kg').toString();

    // Prefill aus Plan -> falls kein Gewicht geplant, nimm letztes verwendetes Gewicht
    final lastW = await DB.instance.lastWeightForExercise(exerciseId);
    final repsCtrl = TextEditingController(text: (ex['planned_reps'] ?? ex['default_reps'] ?? 10).toString());
    final weightCtrl = TextEditingController(
      text: ((ex['planned_weight'] as num?)?.toDouble() ?? lastW ?? 0).toString(),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Satz – ${ex['name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: repsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Wiederholungen')),
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
      final reps = int.tryParse(repsCtrl.text.trim()) ?? 0;
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
      final existing = _setsForExercise(exerciseId);
      final nextIndex = (existing.isEmpty ? 1 : ((existing.last['set_index'] as int) + 1));

      await DB.instance.insertSet(
        sessionId: widget.sessionId,
        exerciseId: exerciseId,
        setIndex: nextIndex,
        reps: reps,
        weight: weight,
      );
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('Training: ${widget.workoutName}')),
      body: _workoutExercises.isEmpty
          ? const Center(child: Text('Keine Übungen im Workout.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: _workoutExercises.length,
              itemBuilder: (context, i) {
                final e = _workoutExercises[i];
                final exSets = _setsForExercise(e['id'] as int);

                final unit = (e['unit'] ?? 'kg').toString();
                final planSets = e['planned_sets'] ?? e['default_sets'];
                final planReps = e['planned_reps'] ?? e['default_reps'];
                final planWeight = e['planned_weight'];

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(e['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        subtitle: Text(
                          'Plan: ${planSets ?? '-'}×${planReps ?? '-'}'
                          '${planWeight != null ? ' @ ${_fmt(planWeight)} $unit' : ''}',
                        ),
                        trailing: OutlinedButton.icon(
                          onPressed: () => _addSetDialog(e),
                          icon: const Icon(Icons.add),
                          label: const Text('Satz'),
                        ),
                      ),
                      const Divider(height: 1),
                      if (exSets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 12),
                          child: Text('Noch keine Sätze. '
                              'Tippe auf „Satz“, Werte sind aus dem Plan vorausgefüllt.'),
                        ),
                      if (exSets.isNotEmpty)
                        ...exSets.map((s) => ListTile(
                              leading: CircleAvatar(child: Text('${s['set_index']}')),
                              title: Text('${s['reps']} × ${_fmt(s['weight'])} $unit'),
                            )),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _fmt(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }
}
