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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final from = _month;
    final to = DateTime(_month.year, _month.month + 1, 0);
    final ws = await DB.instance.getWorkouts();
    final sch = await DB.instance.getScheduleBetween(from, to);
    final map = <String, Map<String, dynamic>>{};
    for (final row in sch) {
      map[row['date'] as String] = row;
    }
    setState(() {
      _workouts = ws;
      _scheduleByYmd = map;
      _loading = false;
    });
  }

  void _prevMonth() { setState(() => _month = DateTime(_month.year, _month.month - 1, 1)); _load(); }
  void _nextMonth() { setState(() => _month = DateTime(_month.year, _month.month + 1, 1)); _load(); }
  void _goToday()   { final n = DateTime.now(); setState(() => _month = DateTime(n.year, n.month, 1)); _load(); }

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
                  ..._workouts.map((w) => DropdownMenuItem<int?>(
                    value: w['id'] as int,
                    child: Text(w['name'] ?? ''),
                  ))
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

    return AppScaffold(
      appBar: AppBar(
        title: Text('📆 $monthTitle'),
        actions: [
          IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
          IconButton(onPressed: _goToday,   icon: const Icon(Icons.today)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  const _WeekdayHeader(),
                  const SizedBox(height: 6),
                  Expanded(child: _MonthGrid(
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

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({super.key});
  @override
  Widget build(BuildContext context) {
    const labels = ['Mo','Di','Mi','Do','Fr','Sa','So'];
    return Row(
      children: labels.map((l) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(child: Text(l, style: const TextStyle(fontWeight: FontWeight.w700))),
        ),
      )).toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month; // 1st of month
  final Map<String, Map<String, dynamic>> scheduleByYmd;
  final Future<void> Function(DateTime day) onEditDay;
  final Future<void> Function(DateTime day) onStartDay;

  const _MonthGrid({
    super.key,
    required this.month,
    required this.scheduleByYmd,
    required this.onEditDay,
    required this.onStartDay,
  });

  @override
  Widget build(BuildContext context) {
    final first = month;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1; // 0..6 (Mo=1)
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    final today = DateTime.now();
    final isTodayMonth = (today.year == month.year && today.month == month.month);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6,
      ),
      itemCount: totalCells,
      itemBuilder: (context, idx) {
        final dayNum = idx - leading + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();

        final day = DateTime(month.year, month.month, dayNum);
        final ymd = _ymd(day);
        final planned = scheduleByYmd[ymd];
        final name = planned?['workout_name'] as String?;
        final hasPlan = planned != null;

        final isToday = isTodayMonth && (day.day == today.day);
        final border = isToday
          ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.2)
          : Border.all(color: Colors.white12);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onEditDay(day),
          onLongPress: hasPlan ? () => onStartDay(day) : null,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: border,
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$dayNum',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: hasPlan ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasPlan)
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        name ?? 'Workout',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text('—', style: TextStyle(fontSize: 12, color: Colors.white38)),
                    ),
                  ),
                if (hasPlan)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.play_arrow, size: 18, color: Theme.of(context).colorScheme.secondary),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
