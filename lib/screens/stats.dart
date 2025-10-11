import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    // einfache Formatierung ohne Locale-Abhängigkeit
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

          // Letzte Sätze
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

          const SizedBox(height: 16),

          // Volumen pro Tag
          const Text('Volumen (letzte 30 Tage)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (_perDay.isEmpty)
            const Text('Keine Daten.'),
          if (_perDay.isNotEmpty)
            Column(
              children: _perDay.map((row) {
                final day = row['day'] ?? '';
                final vol = _num(row['day_volume']);
                final sets = row['sets_count'];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 18),
                  title: Text('$day – Volumen: $vol'),
                  subtitle: Text('Sätze: $sets'),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),
          // Hinweis auf Charts (optional später)
          const Text('Hinweis: Diagramme (Linien/Balken) können wir jederzeit mit fl_chart hinzufügen.',
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  String _num(Object? n) {
    if (n == null) return '-';
    final d = (n is num) ? n.toDouble() : double.tryParse('$n') ?? 0;
    return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
  }
}
