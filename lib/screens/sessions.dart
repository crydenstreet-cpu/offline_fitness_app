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
    final exs = await DB.instance.getExercisesOfWorkout(widget.workoutId); // enthält planned_* + exercise-Felder
    final sets = await DB.instance.getSetsOfSession(widget.sessionId);
    if (!mounted) return;
    setState(() {
      _workoutExercises = exs;
      _sets = sets;
    });
  }

  List<Map<String, dynamic>> _setsForExercise(int exerciseId) {
    return _sets
        .where((s) => (s['exercise_id'] as int) == exerciseId)
        .toList()
      ..sort((a, b) => (a['set_index'] as int).compareTo(b['set_index'] as int));
  }

  Future<void> _addSetDialog(Map<String, dynamic> ex) async {
    final exerciseId = ex['id'] as int;
    final unit = (ex['unit'] ?? 'kg').toString();

    // Prefill: geplantes Gewicht -> sonst letztes Gewicht -> 0
    final lastW = await DB.instance.lastWeightForExercise(exerciseId);
    final prefillReps = (ex['planned_reps'] ?? ex['default_reps'] ?? 10).toString();
    final prefillWeight =
        ((ex['planned_weight'] as num?)?.toDouble() ?? lastW ?? 0).toString();

    final repsCtrl = TextEditingController(text: prefillReps);
    final weightCtrl = TextEditingController(text: prefillWeight);

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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Gewicht ($unit)'),
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
    );

    if (saved == true) {
      final reps = int.tryParse(repsCtrl.text.trim()) ?? 0;
      final weight =
          double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

      final existing = _setsForExercise(exerciseId);
      final nextIndex =
          (existing.isEmpty ? 1 : ((existing.last['set_index'] as int) + 1));

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
                final startW = (e['planned_weight'] as num?)?.toDouble();

                return Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          e['name'] ?? '',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(_buildPlanText(
                            planSets, planReps, startW, unit)),
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
                            'Noch keine Sätze. Tippe auf „Satz“ – '
                            'Wiederholungen & Gewicht sind aus dem Plan oder deinem letzten Satz vorausgefüllt.',
                          ),
                        ),
                      if (exSets.isNotEmpty)
                        ...exSets.map(
                          (s) => _buildSetTile(
                            s,
                            unit: unit,
                            plannedStart: startW,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // --- UI Helfer -------------------------------------------------------------

  String _buildPlanText(Object? sets, Object? reps, double? startW, String unit) {
    final parts = <String>[];
    parts.add('${sets ?? '-'} Sätze × ${reps ?? '-'} Wdh');
    if (startW != null) parts.add('(Startgewicht: ${_fmt(startW)} $unit)');
    return 'Plan: ${parts.join(' ')}';
  }

  Widget _buildSetTile(
    Map<String, dynamic> s, {
    required String unit,
    double? plannedStart,
  }) {
    final idx = s['set_index'] as int? ?? 0;
    final reps = s['reps'] as int? ?? 0;
    final weight = (s['weight'] as num?)?.toDouble() ?? 0.0;

    final subtitle = [
      '${reps} × ${ _fmt(weight)} $unit',
      if (plannedStart != null) '(Startgewicht: ${_fmt(plannedStart)} $unit)',
    ].join('  ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.deepPurple, // lila
        child: Text(
          'S$idx',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(subtitle),
    );
  }

  String _fmt(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
    // z.B. 20 -> "20", 20.5 -> "20.5"
  }
}
