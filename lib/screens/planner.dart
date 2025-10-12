import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/screens/sessions.dart';
import 'package:offline_fitness_app/ui/design.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _start = DateTime.now();
  int _weeks = 4;

  final Map<int, int?> _weekdayMap = {1:null,2:null,3:null,4:null,5:null,6:null,7:null};

  List<Map<String, dynamic>> _workouts = [];
  List<Map<String, dynamic>> _upcoming = [];
  bool _loading = true;
  String? _error; // 👈 NEU

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final ws = await DB.instance.getWorkouts();
      final up = await DB.instance.upcomingSchedule(days: 21);
      if (!mounted) return;
      setState(() { _workouts = ws; _upcoming = up; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Fehler beim Laden: $e'; });
    }
  }

  Future<void> _quickCreateWorkout() async {
    final id = await DB.instance.insertWorkout('Ganzkörper');
    setState(() => _workouts.insert(0, {'id': id, 'name': 'Ganzkörper'}));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('„Ganzkörper“ angelegt.')));
  }

  Future<void> _pickStartDate() async {
    final init = DateTime(_start.year, _start.month, _start.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365*3)),
      helpText: 'Startdatum wählen',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme,
          dialogBackgroundColor: Theme.of(ctx).colorScheme.surface,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _generate() async {
    final mapping = Map<int, int?>.from(_weekdayMap);
    final hasAny = mapping.values.any((v) => v != null);
    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wähle mindestens einen Wochentag + Workout.')));
      return;
    }
    await DB.instance.generateSchedule(startDate: _start, weeks: _weeks, weekdayToWorkoutId: mapping);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan gespeichert.')));
  }

  String _weekdayLabel(int wd) {
    const names = {1:'Mo',2:'Di',3:'Mi',4:'Do',5:'Fr',6:'Sa',7:'So'};
    return names[wd]!;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('EEE, dd.MM.yyyy', 'de_DE');

    if (_loading) {
      return const AppScaffold(
        appBar: AppBar(title: Text('🗓️ Wochen-Planer')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('🗓️ Wochen-Planer')),
        body: Center(child: Text(_error!, textAlign: TextAlign.center)),
      );
    }

    final noWorkouts = _workouts.isEmpty;

    return AppScaffold(
      appBar: AppBar(title: const Text('🗓️ Wochen-Planer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          if (noWorkouts)
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Noch keine Workouts angelegt'),
                subtitle: const Text('Lege zuerst Workouts im Tab „Workouts“ an – oder erstelle eines hier.'),
                trailing: ElevatedButton(onPressed: _quickCreateWorkout, child: const Text('Schnell-Workout')),
              ),
            ),

          // Parameter
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Plan-Parameter', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text('Start: ${DateFormat('dd.MM.yyyy').format(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _weeks,
                      decoration: const InputDecoration(labelText: 'Wochen'),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: [1,2,3,4,6,8,12].map((w) => DropdownMenuItem(value: w, child: Text('$w'))).toList(),
                      onChanged: (v) => setState(() => _weeks = v ?? 4),
                    ),
                  ),
                ]),
              ]),
            ),
          ),

          const SizedBox(height: 8),

          // Wochenmuster
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Wochentage → Workout', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...List.generate(7, (i) {
                  final wd = i + 1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(width: 32, child: Text(_weekdayLabel(wd))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _weekdayMap[wd],
                            isExpanded: true,
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            decoration: const InputDecoration(labelText: 'Workout'),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(value: null, child: Text('— kein —')),
                              ..._workouts.map((w) => DropdownMenuItem<int?>(value: w['id'] as int, child: Text(w['name'] ?? '')))
                            ],
                            onChanged: (v) => setState(() => _weekdayMap[wd] = v),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: (_workouts.isEmpty) ? null : _generate,
                  icon: const Icon(Icons.save),
                  label: const Text('Plan erzeugen & speichern'),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 12),
          const Text('Nächste 3 Wochen', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),

          if (_upcoming.isEmpty)
            const Card(child: ListTile(title: Text('Kein Plan vorhanden.'))),

          if (_upcoming.isNotEmpty)
            ..._upcoming.map((row) {
              final date = row['date'] as String;
              final p = date.split('-');
              final day = DateFormat('yyyy-MM-dd').parse(date); // robust
              final name = (row['workout_name'] ?? 'Workout') as String;
              final workoutId = row['workout_id'] as int;
              return Card(
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(df.format(day)),
                  trailing: OutlinedButton(
                    child: const Text('Starten'),
                    onPressed: () async {
                      final sessionId = await DB.instance.startSession(workoutId: workoutId);
                      if (!mounted) return;
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SessionScreen(sessionId: sessionId, workoutId: workoutId, workoutName: name),
                      ));
                    },
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
