import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class SessionScreen extends StatefulWidget {
  final int sessionId;
  final int workoutId;
  final String workoutName;
  const SessionScreen({
    super.key,
    required this.sessionId,
    required this.workoutId,
    required this.workoutName,
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<Map<String, dynamic>> _workoutExercises = [];
  List<Map<String, dynamic>> _sets = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final exs = await DB.instance.getExercisesOfWorkout(widget.workoutId);
    final sets = await DB.instance.getSetsOfSession(widget.sessionId);
    setState(() {
      _workoutExercises = exs;
      _sets = sets;
    });
  }

  List<Map<String, dynamic>> _setsForExercise(int exerciseId) {
    return _sets.where((s) => (s['exercise_id'] as int) == exerciseId).toList()
      ..sort((a, b) => (a['set_index'] as int).compareTo(b['set_index'] as int));
  }

  Future<void> _addSetDialog(int exerciseId) async {
    final repsCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Satz hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wiederholungen'),
            ),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Gewicht'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
        ],
      ),
    );

    if (saved == true) {
      final reps = int.tryParse(repsCtrl.text.trim()) ?? 0;
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

      // set_index = (existierende Sätze dieser Übung) + 1
      final existing = _setsForExercise(exerciseId);
      final nextIndex = (existing.isEmpty ? 0 : (existing.last['set_index'] as int)) + 1;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Training: ${widget.workoutName}'),
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: _workoutExercises.isEmpty
          ? const Center(child: Text('Keine Übungen im Workout.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: _workoutExercises.length,
              itemBuilder: (context, i) {
                final e = _workoutExercises[i];
                final exSets = _setsForExercise(e['id'] as int);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        if (exSets.isEmpty)
                          const Text('Noch keine Sätze.'),
                        if (exSets.isNotEmpty)
                          ...exSets.map(
                            (s) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(child: Text('${s['set_index']}')),
                              title: Text('${s['reps']} x ${s['weight']}'),
                              subtitle: s['note'] != null ? Text('${s['note']}') : null,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _addSetDialog(e['id'] as int),
                            icon: const Icon(Icons.add),
                            label: const Text('Satz hinzufügen'),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
