import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';
import 'package:offline_fitness_app/ui/components.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Übersicht
  bool _loadingOverview = true;
  List<Map<String, dynamic>> _volDays = [];
  double? _avgMood;

  // Übungen
  late Future<List<Map<String, dynamic>>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _reloadOverview();
    _reloadExercises();
  }

  void _reloadExercises() {
    _exercisesFuture = DB.instance.getExercises();
    setState(() {});
  }

  Future<void> _reloadOverview() async {
    setState(() => _loadingOverview = true);
    final vols = await DB.instance.volumeByDayAll(days: 14);
    final mood = await DB.instance.averageMoodLast7Days();
    if (!mounted) return;
    setState(() {
      _volDays = vols;
      _avgMood = mood;
      _loadingOverview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('📊 Statistik'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: false,
          tabs: const [
            Tab(icon: Icon(Icons.insights), text: 'Übersicht'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Übungen'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _overviewTab(),
          _exercisesTab(),
        ],
      ),
    );
  }

  // ------------------------- TAB 1: ÜBERSICHT -------------------------
  Widget _overviewTab() {
    if (_loadingOverview) {
      return const Center(child: CircularProgressIndicator());
    }

    // Vergleich: letzte 7 Tage vs. vorherige 7 Tage
    final today = DateTime.now();
    final startThis = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    final startPrev = startThis.subtract(const Duration(days: 7));
    final endPrev = startThis.subtract(const Duration(days: 1)); // inkl. 7 volle Tage

    int sumBetween(DateTime a, DateTime b) {
      final fmt = DateFormat('yyyy-MM-dd');
      final aa = fmt.format(a);
      final bb = fmt.format(b);
      int s = 0;
      for (final r in _volDays) {
        final d = (r['day'] as String?) ?? '';
        if (d.compareTo(aa) >= 0 && d.compareTo(bb) <= 0) {
          final v = r['volume'];
          final iv = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
          s += iv;
        }
      }
      return s;
    }

    final volThis = sumBetween(startThis, today);
    final volPrev = sumBetween(startPrev, endPrev);
    final pct = (volPrev == 0) ? (volThis > 0 ? 100.0 : 0.0) : ((volThis - volPrev) / volPrev * 100.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // Kachel: Volumen-Vergleich
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.15),
                  child: Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Volumen-Vergleich', style: TextStyle(fontWeight: FontWeight.w800)),
                    Text('Diese 7 Tage: $volThis  •  Vorherige 7 Tage: $volPrev'),
                    const SizedBox(height: 4),
                    Text(
                      (pct >= 0 ? '▲ ' : '▼ ') + pct.toStringAsFixed(1) + ' %',
                      style: TextStyle(
                        color: pct >= 0 ? Colors.greenAccent : Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                )
              ],
            ),
          ),
        ),

        // Kachel: Stimmung der Woche
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.15),
              child: Icon(Icons.mood, color: Theme.of(context).colorScheme.primary),
            ),
            title: const Text('Ø Stimmung (letzte 7 Tage)', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(_avgMood == null ? '—' : _avgMood!.toStringAsFixed(1) + ' / 5'),
          ),
        ),

        const SizedBox(height: 8),

        // Chart: Volumen der letzten 14 Tage
        const Text('Volumen – letzte 14 Tage', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(height: 200, child: _BarChartVolume(data: _volDays)),
          ),
        ),
      ],
    );
  }

  // ------------------------- TAB 2: ÜBUNGEN -------------------------
  Widget _exercisesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
    );
  }

  String _fmtNum(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }
}

// ===================================================================
//                          EXERCISE DETAIL
// ===================================================================

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
    if (!mounted) return;
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
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Text('${s['set_index']}'),
                    ),
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
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true),
            barWidth: 3,
          )
        ],
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
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _setsBarChart() {
    final daysAsc = List<Map<String, dynamic>>.from(_perDay.reversed);
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < daysAsc.length; i++) {
      final count = (daysAsc[i]['sets_count'] as num?)?.toDouble() ?? 0.0;
      groups.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: count, width: 10, borderRadius: BorderRadius.circular(3))]));
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

// ===================================================================
//                 GLOBAL OVERVIEW BAR CHART WIDGET
// ===================================================================

class _BarChartVolume extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _BarChartVolume({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('Keine Daten'));
    final groups = <BarChartGroupData>[];
    int i = 0;
    double maxV = 0;
    for (final r in data) {
      final v = r['volume'];
      final val = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      if (val > maxV) maxV = val;
      groups.add(BarChartGroupData(
        x: i++,
        barRods: [BarChartRodData(toY: val, width: 12, borderRadius: BorderRadius.circular(4))],
      ));
    }
    return BarChart(BarChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 36,
          getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
        )),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, interval: (groups.length / 4).clamp(1, 7).toDouble(),
          getTitlesWidget: (value, meta) {
            final idx = value.round();
            if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
            final d = (data[idx]['day'] as String);
            final label = d.length >= 10 ? d.substring(5, 10) : d;
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(label, style: const TextStyle(fontSize: 10)),
            );
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      barGroups: groups,
      maxY: (maxV * 1.2).clamp(10, double.infinity),
    ));
  }
}
