import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

/// Monatskalender mit Workout-Badges pro Tag.
/// Zeigt für jedes Datum den geplanten Workout-Namen als kleine „Pille“.
class CalendarMonthScreen extends StatefulWidget {
  const CalendarMonthScreen({super.key});

  @override
  State<CalendarMonthScreen> createState() => _CalendarMonthScreenState();
}

class _CalendarMonthScreenState extends State<CalendarMonthScreen> {
  late DateTime _month; // aktueller Monat (1. des Monats)
  Map<String, Map<String, dynamic>> _byDate = {}; // yyy-MM-dd -> row
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

    // Sichtbarer Bereich des Monats (inkl. Überhang der ersten/letzten Woche)
    final firstDayOfMonth = DateTime(_month.year, _month.month, 1);
    final lastDayOfMonth = DateTime(_month.year, _month.month + 1, 0);

    // auf Wochenraster ausdehnen: Montag = 1 … Sonntag = 7
    final start = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    final end = lastDayOfMonth.add(Duration(days: 7 - lastDayOfMonth.weekday));

    final rows = await DB.instance.getScheduleBetween(start, end);
    final map = <String, Map<String, dynamic>>{};
    for (final r in rows) {
      final d = r['date'] as String;
      map[d] = r;
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
    final monthLabel = DateFormat('MMMM yyyy', 'de_DE').format(_month);

    return Scaffold(
      appBar: AppBar(
        title: Text('Kalender – $monthLabel'),
        actions: [
          IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: _nextMonth, icon: const Icon(Icons.chevron_right)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _weekdayHeader(context),
                const Divider(height: 1),
                Expanded(child: _monthGrid(context)),
              ],
            ),
    );
  }

  Widget _weekdayHeader(BuildContext context) {
    // Mo–So
    final names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.secondary,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: List.generate(7, (i) {
          return Expanded(
            child: Center(child: Text(names[i], style: style)),
          );
        }),
      ),
    );
  }

  Widget _monthGrid(BuildContext context) {
    final firstDayOfMonth = DateTime(_month.year, _month.month, 1);
    final lastDayOfMonth = DateTime(_month.year, _month.month + 1, 0);

    final start = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    final end = lastDayOfMonth.add(Duration(days: 7 - lastDayOfMonth.weekday));

    final days = <DateTime>[];
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      days.add(d);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
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

    return InkWell(
      onTap: () {
        // Optional: zur Plan-Liste für diesen Tag springen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _PlanForDayScreen(date: day)),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: inMonth ? scheme.surface : scheme.surfaceVariant.withOpacity(0.4),
          border: Border.all(
            color: isToday ? scheme.primary : Colors.transparent,
            width: isToday ? 2 : 1,
          ),
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
                    color: isToday ? scheme.primary.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: inMonth ? scheme.onSurface : scheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (scheduled != null) _workoutPill(context, scheduled['workout_name'] as String),
          ],
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
          color: scheme.primary.withOpacity(0.15),
          border: Border.all(color: scheme.primary),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Kleiner Tages-Screen, zeigt den Plan für ein Datum (so bleibt der Flow gewohnt).
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
