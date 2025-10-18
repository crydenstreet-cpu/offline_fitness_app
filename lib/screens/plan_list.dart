// lib/screens/plan_list.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../ui/design.dart';
import 'sessions.dart';

class PlanListScreen extends StatefulWidget {
  final DateTime date;
  const PlanListScreen({super.key, required this.date});

  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  Map<String, dynamic>? _planned;
  bool _loading = true;

  String get _ymd =>
      '${widget.date.year.toString().padLeft(4,'0')}'
      '-${widget.date.month.toString().padLeft(2,'0')}'
      '-${widget.date.day.toString().padLeft(2,'0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await DB.instance.getScheduleBetween(widget.date, widget.date);
    if (!mounted) return;
    setState(() {
      _planned = rows.isNotEmpty ? rows.first : null; // {date, workout_id, workout_name, color?}
      _loading = false;
    });
  }

  Future<void> _startWorkoutFromPlanned() async {
    if (_planned == null) return;
    final workoutId = _planned!['workout_id'] as int;
    final workoutName = (_planned!['workout_name'] ?? 'Workout') as String;

    final sessionId = await DB.instance.startSession(workoutId: workoutId);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionScreen(
          sessionId: sessionId,
          workoutId: workoutId,
          workoutName: workoutName,
        ),
      ),
    );
  }

  Future<void> _onTapRow() async {
    // Kein Plan → direkt Plan-Dialog
    if (_planned == null) {
      await _pickWorkoutAndSave();
      return;
    }

    // Plan vorhanden → Aktions-Sheet
    final name = (_planned!['workout_name'] ?? 'Workout') as String;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_available),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(DateFormat('EEE, dd.MM.yyyy', 'de_DE').format(widget.date)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Workout starten'),
              onTap: () => Navigator.pop(ctx, 'start'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text('Plan ändern'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Plan löschen'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'start') {
      await _startWorkoutFromPlanned();
    } else if (action == 'edit') {
      await _pickWorkoutAndSave();
    } else if (action == 'delete') {
      await DB.instance.deleteSchedule(_ymd);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Plan gelöscht.')));
    }
  }

  Future<void> _pickWorkoutAndSave() async {
    final workouts = await DB.instance.getWorkouts();
    if (!mounted) return;

    int? selected = _planned?['workout_id'] as int?;

    final chosenId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Workout für den Tag wählen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (workouts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Noch keine Workouts vorhanden.'),
              ),
            if (workouts.isNotEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: workouts.map((w) {
                    final id = w['id'] as int;
                    return RadioListTile<int>(
                      value: id,
                      groupValue: selected,
                      title: Text(w['name'] ?? ''),
                      secondary: const Icon(Icons.fitness_center),
                      onChanged: (v) => selected = v,
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 8),
            Row(children: [
              if (_planned != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, -1),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Plan löschen'),
                  ),
                ),
              if (_planned != null) const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (selected == null && _planned == null)
                      ? null
                      : () => Navigator.pop(ctx, selected),
                  icon: const Icon(Icons.save),
                  label: const Text('Speichern'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );

    if (chosenId == null) return;

    if (chosenId == -1) {
      await DB.instance.deleteSchedule(_ymd);
    } else {
      await DB.instance.upsertSchedule(_ymd, chosenId);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final headline = DateFormat('EEEE, d. MMMM', 'de_DE').format(widget.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kopf mit Planen/Ändern-Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.icon(
                onPressed: _pickWorkoutAndSave,
                icon: const Icon(Icons.edit_calendar),
                label: Text(_planned == null ? 'Planen' : 'Ändern'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_planned == null)
                  AppCard(
                    onTap: _onTapRow,
                    child: const ListTile(
                      leading: Icon(Icons.event_busy),
                      title: Text('Kein Training geplant'),
                      subtitle: Text('Tippe, um ein Workout zuzuweisen.'),
                    ),
                  ),
                if (_planned != null)
                  AppCard(
                    onTap: _onTapRow, // ← öffnet Aktionssheet
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(
                        _planned!['workout_name'] ?? 'Workout',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('Geplant für $_ymd'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
