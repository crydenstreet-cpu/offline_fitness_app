import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';
import 'package:offline_fitness_app/ui/components.dart';

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
  bool _loading = true;

  /// Übungen des Workouts inkl. Plan-Feldern (planned_sets, planned_reps, planned_weight)
  List<Map<String, dynamic>> _workoutExercises = [];

  /// Alle Sätze dieser Session (wir gruppieren im UI pro Übung)
  List<Map<String, dynamic>> _sets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final exs = await DB.instance.getExercisesOfWorkout(widget.workoutId);
    final sets = await DB.instance.getSetsOfSession(widget.sessionId);
    setState(() {
      _workoutExercises = exs;
      _sets = sets;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> _setsForExercise(int exerciseId) {
    return _sets.where((s) => s['exercise_id'] == exerciseId).toList()
      ..sort((a, b) {
        final ai = (a['set_index'] as int?) ?? 0;
        final bi = (b['set_index'] as int?) ?? 0;
        return ai.compareTo(bi);
      });
  }

  Future<void> _addSetDialog(Map<String, dynamic> ex) async {
    final exerciseId = ex['id'] as int;

    // 1) Letzten Satz in DIESER Session holen (Auto-Vorbelegung)
    final last = await DB.instance.lastSetForExerciseInSession(widget.sessionId, exerciseId);

    // 2) Fallbacks: geplante Werte oder letzte Gewichte aus der Historie
    final plannedReps = (ex['planned_reps'] as int?) ?? (ex['default_reps'] as int?) ?? 10;
    final plannedWeight = (ex['planned_weight'] as num?)?.toDouble();
    final historicLastWeight = await DB.instance.lastWeightForExercise(exerciseId);

    final initReps = (last?['reps'] as int?) ?? plannedReps;
    final initWeight = (last?['weight'] as num?)?.toDouble() ??
        plannedWeight ??
        (historicLastWeight ?? 10.0);

    // nächster Satzindex
    final existing = _setsForExercise(exerciseId);
    final nextIndex = (existing.isEmpty ? 1 : ((existing.last['set_index'] as int?) ?? existing.length) + 1);

    final repsCtrl = TextEditingController(text: '$initReps');
    final weightCtrl = TextEditingController(text: initWeight.toStringAsFixed(1));

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottomKeyboard = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomKeyboard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Text(ex['name'] ?? 'Übung', style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('Satz #$nextIndex', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Wiederholungen',
                        hintText: 'z. B. 10',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Gewicht (${ex['unit'] ?? 'kg'})',
                        hintText: 'z. B. 50.0',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      final reps = int.tryParse(repsCtrl.text.trim());
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
      if (reps == null || weight == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte gültige Zahlen eingeben.')),
        );
        return;
      }
      await DB.instance.insertSet(
        sessionId: widget.sessionId,
        exerciseId: exerciseId,
        setIndex: nextIndex,
        reps: reps,
        weight: weight,
      );
      await _load();
    }
  }

  Future<void> _editSetDialog(Map<String, dynamic> setRow, Map<String, dynamic> ex) async {
    final repsCtrl = TextEditingController(text: '${setRow['reps']}');
    final weightCtrl = TextEditingController(
      text: ((setRow['weight'] as num?)?.toDouble() ?? 0).toStringAsFixed(1),
    );

    final changed = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final bottomKeyboard = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomKeyboard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4, width: 40, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Text(ex['name'] ?? 'Übung', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Satz #${setRow['set_index']}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Wiederholungen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: 'Gewicht (${ex['unit'] ?? 'kg'})'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'delete'),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Löschen'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, 'save'),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (changed == 'delete') {
      await DB.instance.deleteSet(setRow['id'] as int);
      await _load();
      return;
    }
    if (changed == 'save') {
      final reps = int.tryParse(repsCtrl.text.trim());
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
      if (reps == null || weight == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte gültige Zahlen eingeben.')),
        );
        return;
      }
      await DB.instance.updateSet(
        setRow['id'] as int,
        reps: reps,
        weight: weight,
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy, HH:mm');

    return AppScaffold(
      appBar: AppBar(title: Text('Training: ${widget.workoutName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                // Kopf-Karte mit Zeit + kleiner Zusammenfassung
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Aktive Session',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                            Text(fmt.format(DateTime.now()),
                                style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Liste der Übungen
                ..._workoutExercises.map((ex) {
                  final int exerciseId = ex['id'] as int;
                  final unit = ex['unit'] ?? 'kg';

                  final plannedSets = ex['planned_sets'] as int?;
                  final plannedReps = ex['planned_reps'] as int?;
                  final plannedWeight = (ex['planned_weight'] as num?)?.toDouble();

                  final sets = _setsForExercise(exerciseId);

                  return AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titel + Plan-Zeile
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ex['name'] ?? 'Übung',
                                style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _addSetDialog(ex),
                              icon: const Icon(Icons.add),
                              label: const Text('Satz'),
                            ),
                          ],
                        ),
                        if (plannedSets != null || plannedReps != null || plannedWeight != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _planLine(plannedSets, plannedReps, plannedWeight, unit),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),

                        // vorhandene Sätze
                        if (sets.isEmpty)
                          const Text('Noch keine Sätze.', style: TextStyle(color: Colors.white54))
                        else
                          Column(
                            children: sets.map((s) {
                              final reps = s['reps'] as int?;
                              final weight = (s['weight'] as num?)?.toDouble();
                              final idx = s['set_index'] as int?;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.surface2,
                                  child: Text('${idx ?? 0}'),
                                ),
                                title: Text('${reps ?? '-'} × ${_num(weight)} $unit'),
                                subtitle: s['note'] != null && '${s['note']}'.isNotEmpty
                                    ? Text('${s['note']}', maxLines: 2, overflow: TextOverflow.ellipsis)
                                    : null,
                                trailing: const Icon(Icons.edit_outlined),
                                onTap: () => _editSetDialog(s, ex),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _num(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    final asInt = d.truncateToDouble() == d;
    return asInt ? d.toStringAsFixed(0) : d.toStringAsFixed(1);
  }

  /// "Plan: 3 Sätze × 10 Wdh (Start: 10 kg)"
  String _planLine(int? sets, int? reps, double? weight, String unit) {
    final parts = <String>[];
    if (sets != null || reps != null) {
      final s = sets ?? 0;
      final r = reps ?? 0;
      parts.add('$s Sätze × $r Wdh');
    }
    if (weight != null) {
      parts.add('Start: ${_num(weight)} $unit');
    }
    if (parts.isEmpty) return 'Plan: –';
    return 'Plan: ${parts.join('  •  ')}';
  }
}
