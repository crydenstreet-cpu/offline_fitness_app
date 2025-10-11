import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';
import '../ui/design.dart';
import '../ui/components.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<List<Map<String, dynamic>>> _exercisesFuture;

  @override
  void initState() { super.initState(); _reload(); }
  void _reload() { _exercisesFuture = DB.instance.getExercises(); setState(() {}); }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('📈 Progress & PRs')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final exercises = snap.data!;
          if (exercises.isEmpty) return const Center(child: Text('Noch keine Übungen angelegt.'));
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
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
                  return AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text([
                          if (maxW != null) 'PR: ${_fmtNum(maxW)} ${e['unit'] ?? 'kg'}',
                          if (vol  != null) 'Volumen: ${_fmtNum(vol)}',
                          if (sets != null) 'Sätze: $sets',
                        ].join('  •  ')),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => ExerciseProgressDetail(exercise: e))),
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
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final id = widget.exercise['id'] as int;
    final best = await DB.instance.bestSetForExercise(id);
    final recent = await DB.instance.recentSetsForExercise(id, limit: 12);
    final perDay = await DB.instance.volumePerDayForExercise(id, limitDays: 30);
    setState(() { _best = best; _recent = recent; _perDay = perDay; });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final unit = e['unit'] ?? 'kg';
    final dateFmt = DateFormat('dd.MM.yyyy');

    return AppScaffold(
      appBar: AppBar(title: Text('Progress: ${e['name']}')),
      body: ListView(
        children: [
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Personal Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text(_best == null
                        ? '–'
                        : '${_num(_best!['weight'])} $unit  ×  ${_best!['reps']}  (${_best!['started_at'] != null ? dateFmt.format(DateTime.parse(_best!['started_at'])) : '-'})'),
                  ]),
                ),
              ],
            ),
          ),

          const SectionHeader('Volumen (letzte 30 Tage)'),
          if (_perDay.isEmpty)
            const AppCard(child: Text('Keine Daten.'))
          else
            AppCard(child: SizedBox(height: 220, child: _volumeLineChart())),

          const SectionHeader('Satzanzahl pro Tag'),
          if (_perDay.isEmpty)
            const AppCard(child: Text('Keine Daten.'))
          else
            AppCard(child: SizedBox(height: 220, child: _setsBarChart())),

          const SectionHeader('Letzte Sätze'),
          if (_recent.isEmpty)
            const AppCard(child: Text('Keine Daten.'))
          else
            AppCard(
              child: Column(
                children: _recent.map((s) {
                  final when = s['started_at'] != null ? dateFmt.format(DateTime.parse(s['started_at'])) : '-';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: AppColors.surface2, child: Text('${s['set_index']}')),
                    title: Text('${s['reps']} × ${_num(s['weight'])} $unit'),
                    subtitle: Text(when),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // charts
  Widget _volumeLineChart() {
    final daysAsc = List<Map<String, dynamic>>.from(_perDay.reversed);
    final spots = <FlSpot>[];
    for (var i = 0; i < daysAsc.length; i++) {
      final y = (daysAsc[i]['day_volume'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), y));
    }
    return LineChart(
      LineChartData(
        minX: 0, maxX: (spots.length - 1).toDouble(), minY: 0,
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true))],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, interval: (spots.length / 4).clamp(1, 7).toDouble(),
            getTitlesWidget: (value, meta) {
              final idx = value.round();
              if (idx < 0 || idx >= daysAsc.length) return const SizedBox.shrink();
              final d = (daysAsc[idx]['day'] as String);
              final label = d.length >= 10 ? d.substring(5, 10) : d;
              return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 10)));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 40,
            getTitlesWidget: (v, m) => Text(_shortNumber(v), style: const TextStyle(fontSize: 10)),
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true), borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _setsBarChart() {
    final daysAsc = List<Map<String, dynamic>>.from(_perDay.reversed);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < daysAsc.length; i++) {
      final count = (daysAsc[i]['sets_count'] as num?)?.toDouble() ?? 0.0;
      groups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: count, width: 10)]));
    }
    return BarChart(
      BarChartData(
        barGroups: groups,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, interval: (groups.length / 4).clamp(1, 7).toDouble(),
            getTitlesWidget: (value, meta) {
              final idx = value.round();
              if (idx < 0 || idx >= daysAsc.length) return const SizedBox.shrink();
              final d = (daysAsc[idx]['day'] as String);
              final label = d.length >= 10 ? d.substring(5, 10) : d;
              return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 10)));
            },
          )),
        ),
      ),
    );
  }

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
