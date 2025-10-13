import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class PlanListScreen extends StatefulWidget {
  const PlanListScreen({super.key});
  @override
  State<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends State<PlanListScreen> {
  bool _loading = true;
  final List<_DayEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final items = await DB.instance.upcomingSchedule(days: 30); // in DB vorhanden
    final List<_DayEntry> out = [];

    for (final it in items) {
      final ymd = it['date'] as String;
      final workoutName = (it['workout_name'] ?? '-') as String;
      final workoutId = it['workout_id'] as int;

      // Übungen inkl. geplanter Sätze/Reps holen
      final exs = await DB.instance.getExercisesOfWorkout(workoutId);
      final lines = <String>[];
      for (final e in exs) {
        final sets = e['planned_sets'] ?? e['default_sets'];
        final name = (e['name'] ?? '') as String;
        if (sets != null) {
          final reps = e['planned_reps'] ?? e['default_reps'];
          lines.add(reps != null ? '${sets}x$reps  $name' : '${sets}x $name');

        } else {
          lines.add(name);
        }
      }

      out.add(_DayEntry(
        date: DateTime.parse('${ymd}T00:00:00'),
        title: workoutName,
        lines: lines,
      ));
    }

    setState(() {
      _entries
        ..clear()
        ..addAll(out);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Kein Training geplant.\n\nLege im Planer Workouts für die nächsten Tage fest.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    final dayHeaderFmt = DateFormat('EEE', 'de_DE'); // Mo, Di, ...
    final dayNumFmt = DateFormat('d');
    final monthFmt = DateFormat('MMM yyyy', 'de_DE');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: _entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final e = _entries[i];
          final isToday = _isSameDay(e.date, DateTime.now());
          final theme = Theme.of(context);
          final prim = theme.colorScheme.primary;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linke Datumsspalte
              SizedBox(
                width: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dayHeaderFmt.format(e.date).toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                          letterSpacing: 0.5,
                        )),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dayNumFmt.format(e.date),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          monthFmt.format(e.date),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Rechte "Karte" mit leichtem 3D-Look und farbigem Akzent
              Expanded(
                child: _PlanCard(
                  title: e.title,
                  lines: e.lines,
                  highlight: isToday ? prim : null, // heute akzentuieren
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayEntry {
  final DateTime date;
  final String title;
  final List<String> lines;
  _DayEntry({required this.date, required this.title, required this.lines});
}

/// Karte im Stil des Screenshots: runde Ecken, kräftiger Schatten,
/// rechts farbiger Akzent-Border; Farben kommen aus dem aktuellen Theme.
class _PlanCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Color? highlight;

  const _PlanCard({
    super.key,
    required this.title,
    required this.lines,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final borderColor = highlight ?? theme.dividerColor.withOpacity(0.0);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          // „kräftiger“ 3D-Schatten
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border(
          right: BorderSide(
            color: borderColor,
            width: 5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 6),
            ...lines.take(8).map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    t,
                    style: theme.textTheme.bodyMedium,
                  ),
                )),
            if (lines.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${lines.length - 8} weitere …',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
