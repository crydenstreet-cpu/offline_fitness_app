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

  // -------- Dialoge: Hinzufügen / Bearbeiten --------

  Future<void> _addSetDialog(Map<String, dynamic> ex) async {
    final exerciseId = ex['id'] as int;
    final unit = (ex['unit'] ?? 'kg').toString();

    // Auto-Pre-Fill: geplanter Wert > letzter Wert in dieser Session > letzter historischer Wert > 0
    final lastInSession = await DB.instance.lastSetForExerciseInSession(widget.sessionId, exerciseId);
    final lastHistorical = await DB.instance.lastWeightForExercise(exerciseId);

    final plannedReps = (ex['planned_reps'] ?? ex['default_reps'] ?? 10) as int;
    final plannedWeight = (ex['planned_weight'] as num?)?.toDouble();

    final repsCtrl = TextEditingController(
      text: (lastInSession != null
              ? (lastInSession['reps'] ?? plannedReps)
              : plannedReps)
          .toString(),
    );

    final weightCtrl = TextEditingController(
      text: (lastInSession != null
              ? ((lastInSession['weight'] as num?)?.toDouble() ?? plannedWeight ?? lastHistorical ?? 0)
              : (plannedWeight ?? lastHistorical ?? 0))
          .toString(),
    );

    final noteCtrl = TextEditingController(); // neu: Notiz

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SetDialog(
        title: 'Satz – ${ex['name']}',
        unit: unit,
        repsCtrl: repsCtrl,
        weightCtrl: weightCtrl,
        noteCtrl: noteCtrl,
      ),
    );

    if (saved == true) {
      final reps = int.tryParse(repsCtrl.text.trim()) ?? 0;
      final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
      final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();

      final existing = _setsForExercise(exerciseId);
      final nextIndex = (existing.isEmpty ? 1 : ((existing.last['set_index'] as int) + 1));

      await DB.instance.insertSet(
        sessionId: widget.sessionId,
        exerciseId: exerciseId,
        setIndex: nextIndex,
        reps: reps,
        weight: weight,
        note: note,
      );
      await _reload();
    }
  }

  Future<void> _editSetDialog(Map<String, dynamic> ex, Map<String, dynamic> setRow) async {
    final unit = (ex['unit'] ?? 'kg').toString();

    final repsCtrl = TextEditingController(text: '${setRow['reps'] ?? ''}');
    final weightCtrl = TextEditingController(text: '${setRow['weight'] ?? ''}');
    final noteCtrl = TextEditingController(text: (setRow['note'] ?? '').toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _SetDialog(
        title: 'Satz ${setRow['set_index']} – ${ex['name']}',
        unit: unit,
        repsCtrl: repsCtrl,
        weightCtrl: weightCtrl,
        noteCtrl: noteCtrl,
        showDelete: true,
        onDelete: () async {
          final ok = await _confirmDelete(ctx);
          if (ok == true) {
            await DB.instance.deleteSet(setRow['id'] as int);
            if (ctx.mounted) Navigator.pop(ctx, true); // Dialog schließen (als "gespeichert" interpretieren)
          }
        },
      ),
    );

    if (saved == true) {
      // Falls gelöscht wurde, _reload() ist schon erfolgt; hier nur noch bearbeiten.
      if (mounted) {
        final id = setRow['id'] as int;
        final reps = int.tryParse(repsCtrl.text.trim());
        final weight = double.tryParse(weightCtrl.text.trim().replaceAll(',', '.'));
        final note = noteCtrl.text.trim();

        await DB.instance.updateSet(
          id,
          reps: reps,
          weight: weight,
          note: note.isEmpty ? null : note,
        );
        await _reload();
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Satz löschen?'),
        content: const Text('Dieser Satz wird dauerhaft entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
  }

  // -------- UI --------

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
                          'Plan: ${planSets ?? '-'} Sätze × ${planReps ?? '-'} Wdh'
                          '${planWeight != null ? ' (Start: ${_fmt(planWeight)} $unit)' : ''}',
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
                              'Tippe auf „Satz“, Werte sind aus dem Plan/letzten Sätzen vorausgefüllt.'),
                        ),
                      if (exSets.isNotEmpty)
                        ...exSets.map((s) {
                          final idx = s['set_index'] as int? ?? 0;
                          final reps = s['reps'];
                          final weight = s['weight'];
                          final note = (s['note'] ?? '').toString();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              foregroundColor: AppColors.primary,
                              child: Text('$idx', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            title: Text('$reps × ${_fmt(weight)} $unit'),
                            subtitle: Text(
                              note.isEmpty ? 'Notiz hinzufügen' : note,
                              style: TextStyle(
                                fontStyle: note.isEmpty ? FontStyle.italic : FontStyle.normal,
                                color: note.isEmpty ? Theme.of(context).hintColor : null,
                              ),
                            ),
                            onTap: () => _editSetDialog(e, s),        // bearbeiten (inkl. Notiz)
                            onLongPress: () async {                    // löschen
                              final ok = await _confirmDelete(context);
                              if (ok == true) {
                                await DB.instance.deleteSet(s['id'] as int);
                                await _reload();
                              }
                            },
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

/// Gemeinsamer Dialog für Hinzufügen/Bearbeiten eines Satzes (inkl. Notiz)
class _SetDialog extends StatefulWidget {
  final String title;
  final String unit;
  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController noteCtrl;
  final bool showDelete;
  final Future<void> Function()? onDelete;

  const _SetDialog({
    required this.title,
    required this.unit,
    required this.repsCtrl,
    required this.weightCtrl,
    required this.noteCtrl,
    this.showDelete = false,
    this.onDelete,
  });

  @override
  State<_SetDialog> createState() => _SetDialogState();
}

class _SetDialogState extends State<_SetDialog> {
  // kleine Notiz-Schnellchips
  final _quickNotes = const [
    'Fiel leicht',
    'RPE 8',
    'Letzte Wdh grindy',
    'Technik: Rücken gerade',
    'Tempo langsamer',
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widget.repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Wiederholungen'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Gewicht (${widget.unit})'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: widget.noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notiz (optional)',
                hintText: 'z. B. RPE, Technik, Gefühl …',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickNotes.map((q) {
                  return ActionChip(
                    label: Text(q),
                    onPressed: () {
                      final t = widget.noteCtrl.text;
                      widget.noteCtrl.text = t.isEmpty ? q : '$t; $q';
                      widget.noteCtrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: widget.noteCtrl.text.length),
                      );
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.showDelete && widget.onDelete != null)
          TextButton.icon(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Löschen'),
          ),
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Speichern')),
      ],
    );
  }
}
