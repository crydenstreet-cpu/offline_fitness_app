import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<Map<String, dynamic>>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _exercisesFuture = DB.instance.getExercises();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📈 Progress & PRs'),
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final exercises = snap.data!;
          if (exercises.isEmpty) {
            return const Center(child: Text('Noch keine Übungen angelegt.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: exercises.length,
            itemBuilder: (context, i) {
              final e = exercises[i];
              return FutureBuilder<Map<String, dynamic>?>(
                future: DB.instance.progressForExercise(e['id'] as int),
                builder: (context, progSnap) {
                  final p = progSnap.data;
                  final maxW = p?['max_weight'];
                  final vol  = p?['total_volume'];
                  final sets = p?['total_sets'];
                  return ListTile(
                    title: Text(e['name'] ?? ''),
                    subtitle: Text([
                      if (maxW != null) 'PR: ${_fmtNum(maxW)} ${e['unit'] ?? 'kg'}',
                      if (vol  != null) 'Volumen: ${_fmtNum(vol)}',
                      if (sets != null) 'Sätze: $sets',
                    ].join('  •  ')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseProgressDetail(exercise: e),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _fmtNum(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }
}

class ExerciseProgressDetail extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const ExerciseProgressDetail({super.key, required this.exercise});

  @override
  State<ExerciseProgressDetail> createState() => _ExerciseProgressDetailState();
}

class _ExerciseProgressDetailState extends State<ExerciseProgressDetail> {
  Map<String, dynamic>? _best;
  List<Map<String, dynamic>> _recent = [];
  List<Map<String, dynamic>> _perDay = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.exercise['id'] as int;
    final best = await DB.instance.bestSetForExercise(id);
    final recent = await DB.instance.recentSetsForExercise(id, limit: 12);
    final perDay = await DB.instance.volumePerDayForExercise(id, limitDays: 30);
    setState(() {
      _best = best;
      _recent = recent;
      _perDay = perDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final unit = e['unit'] ?? 'kg';
    final dateFmt = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Progress: ${e['name']}'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PR-Karte
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          _best == null
                              ? '–'
                              : '${_num(_best!['weight'])} $unit  ×  ${_best!['reps']}  (${_best!['started_at'] != null ? dateFmt.format(DateTime.parse(_best!['started_at'])) : '-'})',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Volumen-Liniendiagramm (letzte 30 Tage)
          const Text('Volumen (letzte 30 Tage)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_perDay.isEmpty)
            const Text('Keine Daten.'),
          if (_perDay.isNotEmpty) _volumeLineChart(),

          const SizedBox(height: 16),

          // Sätze pro Tag (BarChart)
          const Text('Satzanzahl pro Tag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_perDay.isEmpty)
            const Text('Keine Daten.'),
          if (_perDay.isNotEmpty) _setsBarChart(),

          const SizedBox(height: 16),

          // Letzte Sätze (Liste)
          const Text('Letzte Sätze', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (_recent.isEmpty)
            const Text('Keine Daten.'),
          if (_recent.isNotEmpty)
            ..._recent.map((s) {
              final when = s['started_at'] != null ? dateFmt.format(DateTime.parse(s['started_at'])) : '-';
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${s['set_index']}')),
                title: Text('${s['reps']} × ${_num(s['weight'])} $unit'),
                subtitle: Text(when),
              );
            }),

          const SizedBox(height: 24),
          const Text(
            'Tipp: Zeiträume/Filter (7/30/90 Tage) können wir später ergänzen.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // ---------- Charts ----------

  /// Liniendiagramm: Tagesvolumen (x = Tagindex, y = Volumen)
  Widget _volumeLineChart() {
    // älteste zuerst für schöne x-Achse links->rechts
    final daysAsc = List<Map<String, dynamic>>.from(_perDay.reversed);
    final spots = <FlSpot>[];
    for (var i = 0; i < daysAsc.length; i++) {
      final y = (daysAsc[i]['day_volume'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), y));
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, applyCutOffY: true),
              // keine Farben explizit setzen → Standardfarben
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (spots.length / 4).clamp(1, 7).toDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  if (idx < 0 || idx >= daysAsc.length) return const SizedBox.shrink();
                  final d = daysAsc[idx]['day'] as String;
                  // nur MM-TT anzeigen
                  final label = d.length >= 10 ? d.substring(5, 10) : d;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  _shortNumber(value),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  /// Balkendiagramm: Sätze pro Tag
  Widget _setsBarChart() {
    final daysAsc = List<Map<String, dynamic>>.from(_perDay.reversed);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < daysAsc.length; i++) {
      final count = (daysAsc[i]['sets_count'] as num?)?.toDouble() ?? 0.0;
      groups.add(BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: count, width: 10)],
      ));
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (groups.length / 4).clamp(1, 7).toDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.round();
                  if (idx < 0 || idx >= daysAsc.length) return const SizedBox.shrink();
                  final d = daysAsc[idx]['day'] as String;
                  final label = d.length >= 10 ? d.substring(5, 10) : d;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Utils ----------

  String _num(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }

  String _shortNumber(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
