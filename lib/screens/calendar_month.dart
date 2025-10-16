import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

/// Monatskalender mit Workout-Badges pro Tag – Design passend zu PlanHub.
/// Tap  = Tagesansicht öffnen
/// Long-Press = Workout für den Tag planen/ändern/löschen
class CalendarMonthScreen extends StatefulWidget {
  const CalendarMonthScreen({super.key});
  @override
  State<CalendarMonthScreen> createState() => _CalendarMonthScreenState();
}

class _CalendarMonthScreenState extends State<CalendarMonthScreen> {
  late DateTime _month; // 1. des aktuellen Monats
  Map<String, Map<String, dynamic>> _byDate = {}; // yyyy-MM-dd -> {date, workout_id, workout_name}
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _load();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);

    final firstDay = DateTime(_month.year, _month.month, 1);
    final lastDay  = DateTime(_month.year, _month.month + 1, 0);

    // Sichtbaren Bereich auf Mo–So Wochenraster erweitern
    final start = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final end   = lastDay.add(Duration(days: 7 - lastDay.weekday));

    final rows = await DB.instance.getScheduleBetween(start, end);
    final map = <String, Map<String, dynamic>>{};
    for (final r in rows) {
      map[r['date'] as String] = r;
    }
    setState(() {
      _byDate = map;
      _loading = false;
    });
  }

  void _prevMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
    _load();
  }

  void _nextMonth() {
    setState(() => _month = DateTime(_month.year, _month.month + 1, 1));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final monthLabel = DateFormat('MMMM yyyy', 'de_DE').format(_month);
    return Column(
      children: [
        // Kopfzeile (Monat + Pfeile)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Vorheriger Monat',
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthLabel,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Nächster Monat',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _weekdayHeader(context),
        Expanded(child: _monthGrid(context)),
      ],
    );
  }

  Widget _weekdayHeader(BuildContext context) {
    const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.secondary,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: List.generate(
          7,
          (i) => Expanded(child: Center(child: Text(names[i], style: style))),
        ),
      ),
    );
  }

  Widget _monthGrid(BuildContext context) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final lastDay  = DateTime(_month.year, _month.month + 1, 0);

    final start = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final end   = lastDay.add(Duration(days: 7 - lastDay.weekday));

    final days = <DateTime>[];
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (_, i) => _dayCell(context, days[i], days[i].month == _month.month),
    );
  }

  Widget _dayCell(BuildContext context, DateTime day, bool inMonth) {
    final ymd = _ymd(day);
    final scheduled = _byDate[ymd]; // {date, workout_id, workout_name}
    final isToday = _ymd(DateTime.now()) == ymd;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Tagesansicht (bekannter Flow)
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _PlanForDayScreen(date: day)),
          );
        },
        onLongPress: () async {
          // Direkt im Kalender planen/ändern/löschen
          final changed = await _pickWorkoutAndSaveForDate(context, day, scheduled);
          if (changed == true) {
            await _load();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Plan für ${DateFormat('dd.MM.yyyy').format(day)} aktualisiert.')),
              );
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: inMonth ? scheme.surface : scheme.surfaceVariant.withOpacity(0.35),
            border: Border.all(
              color: isToday ? scheme.primary : Colors.transparent,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  Theme.of(context).brightness == Brightness.light ? 0.08 : 0.28,
                ),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datum oben links
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isToday ? scheme.primary.withOpacity(0.14) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: inMonth ? scheme.onSurface : scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (scheduled != null)
                _workoutPill(context, scheduled['workout_name']?.toString() ?? 'Workout'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workoutPill(BuildContext context, String name) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.14),
          border: Border.all(color: scheme.primary),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }

  /// Workout für Datum wählen/speichern/löschen (BottomSheet).
  Future<bool> _pickWorkoutAndSaveForDate(
    BuildContext context,
    DateTime date,
    Map<String, dynamic>? current,
  ) async {
    final ymd = _ymd(date);
    final workouts = await DB.instance.getWorkouts();
    int? selected = current?['workout_id'] as int?;

    final chosenId = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Workout für $ymd wählen',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                if (workouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Noch keine Workouts vorhanden. Lege erst ein Workout an.'),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: workouts.map((w) {
                        final id = w['id'] as int;
                        return RadioListTile<int>(
                          value: id,
                          groupValue: selected,
                          title: Text(w['name'] ?? ''),
                          onChanged: (v) => selected = v,
                          secondary: const Icon(Icons.fitness_center),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (current != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Plan löschen'),
                          onPressed: () => Navigator.pop(ctx, -1),
                        ),
                      ),
                    if (current != null) const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Speichern'),
                        onPressed: (selected == null && current == null)
                            ? null
                            : () => Navigator.pop(ctx, selected),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    if (chosenId == null) return false;

    if (chosenId == -1) {
      await DB.instance.deleteSchedule(ymd);
      return true;
    } else {
      await DB.instance.upsertSchedule(ymd, chosenId);
      return true;
    }
  }
}

/// Kleine Tages-Detailansicht (beibehaltener Flow)
class _PlanForDayScreen extends StatelessWidget {
  final DateTime date;
  const _PlanForDayScreen({required this.date, super.key});

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ymd = _ymd(date);
    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('EEEE, d. MMMM', 'de_DE').format(date))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DB.instance.getScheduleBetween(date, date),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Kein Training geplant.'));
          }
          final row = items.first;
          return ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(row['workout_name']?.toString() ?? 'Workout'),
            subtitle: Text('Geplant für $ymd'),
          );
        },
      ),
    );
  }
}
