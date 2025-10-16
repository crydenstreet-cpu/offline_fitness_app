// lib/screens/calendar_month.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/design.dart' as ui;
import '../db/database_helper.dart';
import 'plan_list.dart';

/// Monatskalender mit Workout-Badges pro Tag (Pills).
/// Nutzt AppScaffold => Gradient + Dark/Light greifen überall.
class CalendarMonthScreen extends StatefulWidget {
  const CalendarMonthScreen({super.key});

  @override
  State<CalendarMonthScreen> createState() => _CalendarMonthScreenState();
}

class _CalendarMonthScreenState extends State<CalendarMonthScreen> {
  late DateTime _month; // 1. des aktuellen Monats
  Map<String, Map<String, dynamic>> _byDate = {}; // yyyy-MM-dd -> row
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
    final title = 'Kalender – ${monthLabel[0].toUpperCase()}${monthLabel.substring(1)}';

    return ui.AppScaffold(
      appBar: AppBar(
        title: Text(title),
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
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.secondary,
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
      padding: const EdgeInsets.all(10),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          // Spring zur Plan-Liste für diesen Tag
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => _PlanForDayScreen(date: day)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: inMonth ? scheme.surface : scheme.surface.withOpacity(0.65),
            border: Border.all(
              color: isToday ? scheme.primary : Colors.transparent,
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              // leichter 3D-Look wie im Rest
              BoxShadow(
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.10 : 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datum oben links als kleine Kapsel
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
                        fontWeight: FontWeight.w800,
                        color: inMonth ? scheme.onSurface : scheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (scheduled != null)
                _workoutPill(context, scheduled['workout_name'] as String),
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
          color: scheme.primary.withOpacity(0.12),
          border: Border.all(color: scheme.primary.withOpacity(0.85)),
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
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

/// Tages-Screen (Plan-Liste für das Datum) – bleibt im bekannten Flow.
class _PlanForDayScreen extends StatelessWidget {
  final DateTime date;
  const _PlanForDayScreen({required this.date, super.key});

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, d. MMMM', 'de_DE').format(date);
    final title = '${label[0].toUpperCase()}${label.substring(1)}';

    return ui.AppScaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(child: PlanListScreen(date: DateTime(date.year, date.month, date.day))),
        ],
      ),
    );
  }
}
