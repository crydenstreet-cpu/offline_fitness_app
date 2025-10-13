// lib/screens/sessions.dart
import 'package:flutter/material.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';

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
    final exs = await DB.instance.getExercisesOfWorkout(widget.workoutId); // planned_* + exercise-Felder
    final sets = await DB.instance.getSetsOfSession(widget.sessionId);
    setState(() {
      _workoutExercises = exs;
      _sets = sets;
    });
  }

  List<Map<String, dynamic>> _setsForExercise(int exerciseId) {
    final list = _sets.where((s) => (s['exercise_id'] as int) == exerciseId).toList();
    list.sort((a, b) => (a['set_index'] as int).compareTo(b['set_index'] as int));
    return list;
  }

  // ---------- Satz anlegen ----------
  Future<void> _addSetDialog(Map<String, dynamic> ex) async {
    final exerciseId = ex['id'] as int;
    final unit = (ex['unit'] ?? 'kg').toString();

    // 1) letzter echter Satz in dieser Session
    final lastInThisSession = await DB.instance.lastSetForExerciseInSession(widget.sessionId, exerciseId);

    // 2) Historie (letztes Gewicht aller Sessions)
    final lastHistoricalW = await DB.instance.lastWeightForExercise(exerciseId);

    // 3) Plan-Defaults
    final planReps = ex['planned_reps'] ?? ex['default_reps'] ?? 10;
    final planWeight = (ex['planned_weight'] as num?)?.toDouble();

    // Vorbelegung: Session > Historie > Plan
    final prefillReps = (lastInThisSession?['reps'] as int?) ?? planReps;
    final prefillWeight = (lastInThisSession?['weight'] as num?)?.toDouble()
        ?? lastHistoricalW
        ?? planWeight
        ?? 0.0;

    final repsCtrl = TextEditingController(text: prefillReps.toString());
    final weightCtrl = TextEditingController(text: prefillWeight.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Satz – ${ex['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wiederholungen'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Gewicht ($unit)'),
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
      final reps = int.tryParse(repsCtrl.text.trim()) ?? prefillReps;
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')) ?? prefillWeight;

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

  // ---------- Satz bearbeiten ----------
  Future<void> _editSetDialog(Map<String, dynamic> setRow, Map<String, dynamic> ex) async {
    final unit = (ex['unit'] ?? 'kg').toString();
    final repsCtrl = TextEditingController(text: (setRow['reps'] ?? '').toString());
    final weightCtrl = TextEditingController(text: (setRow['weight'] ?? '').toString());
    final noteCtrl = TextEditingController(text: (setRow['note'] ?? '').toString());

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Satz ${setRow['set_index']} bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wiederholungen'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Gewicht ($unit)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Notiz (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Löschen'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Speichern')),
        ],
      ),
    );

    if (result == 'save') {
      final reps = int.tryParse(repsCtrl.text.trim());
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
      await DB.instance.updateSet(setRow['id'] as int, reps: reps, weight: weight, note: noteCtrl.text.trim());
      await _reload();
    } else if (result == 'delete') {
      await DB.instance.deleteSet(setRow['id'] as int);
      await _reload();
    }
  }

  // ---------- UI ----------
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
                final planWeight = (e['planned_weight'] as num?)?.toDouble();

                final planText = StringBuffer('Plan: ');
                planText.write('${planSets ?? '-'} Sätze × ${planReps ?? '-'} Wdh');
                if (planWeight != null) {
                  planText.write(' (Start: ${_fmt(planWeight)} $unit)');
                }

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kopf mit Plan-Info + +Satz-Button
                      ListTile(
                        title: Text(
                          e['name'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(planText.toString()),
                        trailing: OutlinedButton.icon(
                          onPressed: () => _addSetDialog(e),
                          icon: const Icon(Icons.add),
                          label: const Text('Satz'),
                        ),
                      ),
                      const Divider(height: 1),

                      if (exSets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          child: Text(
                            'Noch keine Sätze. Tippe auf „Satz“, Werte sind aus deinem letzten Satz (oder Plan) vorausgefüllt.',
                          ),
                        ),

                      if (exSets.isNotEmpty)
                        ...exSets.map((s) {
                          final idx = s['set_index'] as int;
                          final reps = s['reps'];
                          final weight = s['weight'];
                          final startPart = (planWeight != null) ? ' • Start: ${_fmt(planWeight)} $unit' : '';

                          return ListTile(
                            onLongPress: () => _editSetDialog(s, e),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.black,
                              child: Text('$idx'),
                            ),
                            title: Text('Satz $idx'),
                            subtitle: Text('${reps ?? '-'} Wdh – ${_fmt(weight)} $unit$startPart'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  await _editSetDialog(s, e);
                                } else if (v == 'delete') {
                                  await DB.instance.deleteSet(s['id'] as int);
                                  await _reload();
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'edit', child: Text('Bearbeiten')),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Löschen'),
                                ),
                              ],
                              icon: const Icon(Icons.more_vert),
                            ),
                          );
                        }),
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
