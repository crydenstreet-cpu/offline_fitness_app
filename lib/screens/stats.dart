// lib/screens/stats.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../ui/design.dart';

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
    return AppScaffold(
      appBar: AppBar(title: const Text('📈 Progress & PRs')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final exercises = snap.data!;
          if (exercises.isEmpty) return const Center(child: Text('Noch keine Übungen angelegt.'));

          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // --- Globaler 7d Vergleich (Volumen) ---
              FutureBuilder<List<Map<String, dynamic>>>(
                future: DB.instance.volumeByDayAll(days: 28),
                builder: (context, s) {
                  if (!s.hasData) return const SizedBox.shrink();
                  final data = s.data!;
                  double last7 = 0, prev7 = 0;
                  // data ist ASC sortiert (per Helper) => wir summieren die letzten 7 und die 7 davor.
                  final vols = data.map((r) => (r['volume'] as num?)?.toDouble() ?? 0).toList();
                  if (vols.isNotEmpty) {
                    final end = vols.length;
                    final aStart = (end - 7).clamp(0, end);
                    final bStart = (end - 14).clamp(0, end);
                    last7 = vols.sublist(aStart, end).fold(0.0, (p, v) => p + v);
                    prev7 = vols.sublist(bStart, aStart).fold(0.0, (p, v) => p + v);
                  }
                  final diff = last7 - prev7;
                  final pct = prev7 == 0 ? 100.0 : (diff / prev7 * 100);
                  final sign = diff >= 0 ? '+' : '–';
                  return AppCard(
                    child: ListTile(
                      title: const Text('Letzte 7 Tage (Volumen)'),
                      subtitle: Text('Aktuell: ${last7.toStringAsFixed(0)}  •  Vorher: ${prev7.toStringAsFixed(0)}'),
                      trailing: Text('$sign${pct.abs().toStringAsFixed(1)} %', style: TextStyle(
                        color: diff>=0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w900,
                      )),
                    ),
                  );
                },
              ),

              // --- pro Übung: PR + Detail ---
              const SectionHeader('Übungen'),
              ...exercises.map((e) => FutureBuilder<Map<String, dynamic>?>(
                    future: DB.instance.progressForExercise(e['id'] as int),
                    builder: (context, progSnap) {
                      final p = progSnap.data;
                      final maxW = p?['max_weight'];
                      final vol  = p?['total_volume'];
                      final sets = p?['total_sets'];
                      return AppCard(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => _ExerciseDetail(exercise: e),
                        )),
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
                        ),
                      );
                    },
                  )),
            ],
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

class _ExerciseDetail extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const _ExerciseDetail({required this.exercise});

  @override
  State<_ExerciseDetail> createState() => _ExerciseDetailState();
}

class _ExerciseDetailState extends State<_ExerciseDetail> {
  Map<String, dynamic>? _best;
  List<Map<String, dynamic>> _perDayRW = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final id = widget.exercise['id'] as int;
    final best = await DB.instance.bestSetForExercise(id);
    final perDayRW = await DB.instance.repsAndWeightPerDayForExercise(id, limitDays: 28);
    setState(() { _best = best; _perDayRW = perDayRW; });
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.exercise['unit'] ?? 'kg';
    final df = DateFormat('dd.MM.yyyy');

    // Vergleich Ø-Reps & Max-Gewicht 7d vs. 7d davor
    double lastAvg = 0, prevAvg = 0, lastMax = 0, prevMax = 0;
    if (_perDayRW.isNotEmpty) {
      final daysAsc = List<Map<String, dynamic>>.from(_perDayRW.reversed); // ASC
      final end = daysAsc.length;
      final aStart = (end - 7).clamp(0, end);
      final bStart = (end - 14).clamp(0, end);
      final a = daysAsc.sublist(aStart, end);
      final b = daysAsc.sublist(bStart, aStart);
      if (a.isNotEmpty) {
        lastAvg = a.map((m) => (m['avg_reps'] as num?)?.toDouble() ?? 0).fold(0.0, (p, v) => p + v) / a.length;
        lastMax = a.map((m) => (m['max_weight'] as num?)?.toDouble() ?? 0).fold(0.0, (p, v) => p > v ? p : v);
      }
      if (b.isNotEmpty) {
        prevAvg = b.map((m) => (m['avg_reps'] as num?)?.toDouble() ?? 0).fold(0.0, (p, v) => p + v) / b.length;
        prevMax = b.map((m) => (m['max_weight'] as num?)?.toDouble() ?? 0).fold(0.0, (p, v) => p > v ? p : v);
      }
    }
    double _pct(double a, double b) => b == 0 ? 100.0 : ((a - b) / b * 100);

    return AppScaffold(
      appBar: AppBar(title: Text('Progress: ${widget.exercise['name']}')),
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
                        : '${(_best!['weight'] as num).toStringAsFixed(0)} $unit  ×  ${_best!['reps']}  (${_best!['started_at'] != null ? df.format(DateTime.parse(_best!['started_at'])) : '-'})'),
                  ]),
                ),
              ],
            ),
          ),
          const SectionHeader('Übung – 7-Tage Vergleich'),
          AppCard(
            child: Column(
              children: [
                _compRow('Ø Wiederholungen', lastAvg, prevAvg, 'x'),
                const SizedBox(height: 6),
                _compRow('Max-Gewicht', lastMax, prevMax, unit.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compRow(String label, double cur, double prev, String unit) {
    final diff = cur - prev;
    final pct = prev == 0 ? 100.0 : (diff / prev * 100);
    final sign = diff >= 0 ? '+' : '–';
    final color = diff >= 0 ? Colors.green : Colors.red;
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
        Text('${cur.toStringAsFixed(1)} $unit'),
        const SizedBox(width: 12),
        Text('$sign${pct.abs().toStringAsFixed(1)} %', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
