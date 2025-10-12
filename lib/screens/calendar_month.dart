import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/screens/sessions.dart';
import 'package:offline_fitness_app/ui/design.dart';

class CalendarMonthScreen extends StatefulWidget {
  const CalendarMonthScreen({super.key});
  @override
  State<CalendarMonthScreen> createState() => _CalendarMonthScreenState();
}

class _CalendarMonthScreenState extends State<CalendarMonthScreen> {
  late DateTime _month; // 1. des Monats
  List<Map<String, dynamic>> _workouts = [];
  Map<String, Map<String, dynamic>> _scheduleByYmd = {};
  bool _loading = true;
  String? _error; // 👈 NEU

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final from = _month;
      final to = DateTime(_month.year, _month.month + 1, 0);
      final ws = await DB.instance.getWorkouts();
      final sch = await DB.instance.getScheduleBetween(from, to);
      final map = <String, Map<String, dynamic>>{};
      for (final row in sch) {
        map[row['date'] as String] = row;
      }
      if (!mounted) return;
      setState(() {
        _workouts = ws;
        _scheduleByYmd = map;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Fehler beim Laden: $e'; });
    }
  }

  void _prevMonth() { setState(() => _month = DateTime(_month.year, _month.month - 1, 1)); _load(); }
  void _nextMonth() { setState(() => _month = DateTime(_month.year, _month.month + 1, 1)); _load(); }
  void _goToday() { final n = DateTime.now(); setState(() => _month = DateTime(n.year, n.month, 1)); _load(); }

  Future<void> _editDay(DateTime day) async {
    final ymd = _ymd(day);
    int? selected = _scheduleByYmd[ymd]?['workout_id'] as int?;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left:16, right:16, top:12, bottom:16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 4, width: 40, margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              Text(DateFormat('EEEE, dd.MM.yyyy', 'de_DE').format(day), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: selected,
                isExpanded: true,
                dropdownColor: Theme.of(ctx).colorScheme.surface,
                decoration: const InputDecoration(labelText: 'Workout zuweisen'),
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(value: null, child: Text('— kein —')),
                  ..._workouts.map((w) => DropdownMenuItem<int?>(value: w['id'] as int, child: Text(w['name'] ?? '')))
                ],
                onChanged: (v) => selected = v,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern'))),
                ],
              ),
              const SizedBox(height: 6),
              if (_scheduleByYmd[ymd] != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async { await DB.instance.deleteSchedule(ymd); if (!mounted) return; Navigator.pop(ctx, true); },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Zuweisung entfernen'),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      if (selected == null) {
        await DB.instance.deleteSchedule(ymd);
      } else {
        await DB.instance.upsertSchedule(ymd, selected!);
      }
      await _load();
    }
  }

  Future<void> _startFromDay(DateTime day) async {
    final ymd = _ymd(day);
    final row = _scheduleByYmd[ymd];
    if (row == null) return;
    final workoutId = row['workout_id'] as int;
    final name = (row['workout_name'] ?? 'Workout') as String;
    final sessionId = await DB.instance.startSession(workoutId: workoutId);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SessionScreen(sessionId: sessionId, workoutId: workoutId, workoutName: name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat('LLLL yyyy', 'de_DE').format(_month);

    if (_loading) {
      return const AppScaffold(
        appBar: AppBar(title: Text('📆 Kalender')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return AppScaffold(
        appBar: AppBar(title: const Text('📆 Kalender')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: Text('📆 $monthTitle'),
        actions: [
          IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
          IconButton(onPressed: _goToday,   icon: const Icon(Icons.today)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            _WeekdayHeader(),
            const SizedBox(height: 6),
            Expanded(child: MonthGrid(
              month: _month,
              scheduleByYmd: _scheduleByYmd,
              onEditDay: _editDay,
              onStartDay: _startFromDay,
            )),
          ],
        ),
      ),
    );
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

// ... (Rest der Datei mit _WeekdayHeader und _MonthGrid unverändert) ...
