import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _nextPlan;
  Map<String, dynamic>? _lastSession;
  double? _avgMood;
  List<Map<String, dynamic>> _volDays = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DB.instance;
    final nextPlan = await db.nextPlannedWorkout();
    final last = await db.lastSessionSummary();
    final mood = await db.averageMoodLast7Days();
    final vols = await db.volumeByDayAll(days: 14);
    if (!mounted) return;
    setState(() {
      _nextPlan = nextPlan;
      _lastSession = last;
      _avgMood = mood;
      _volDays = vols;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        appBar: AppBar(title: Text('🏁 Dashboard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Volumen-Vergleich: letzte 7 Tage vs. vorherige 7 Tage
    final today = DateTime.now();
    final startThis = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    final startPrev = startThis.subtract(const Duration(days: 7));
    final endPrev = startThis;

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
    final pct = (volPrev == 0) ? 100.0 : ((volThis - volPrev) / volPrev * 100.0);

    return AppScaffold(
      appBar: AppBar(title: const Text('🏁 Dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Nächster Termin
          _CardTile(
            icon: Icons.event_available,
            title: 'Nächster Termin',
            subtitle: _nextPlan == null
                ? 'Kein Termin geplant'
                : '${_nextPlan!['workout_name']} – ${_nextPlan!['date']}',
          ).animate().fadeIn(duration: 300.ms).move(begin: const Offset(0, 8)),

          // Letzte Session
          _CardTile(
            icon: Icons.history,
            title: 'Letzte Session',
            subtitle: _lastSession == null
                ? 'Noch keine Session'
                : '${DateFormat('dd.MM.yyyy – HH:mm').format(DateTime.parse(_lastSession!['started_at']))}\n'
                  'Sätze: ${_lastSession!['sets_count']}  •  Volumen: ${(_lastSession!['total_volume'] as num?)?.toInt() ?? 0}',
          ).animate().fadeIn(duration: 350.ms).move(begin: const Offset(0, 8)),

          // Stimmung der Woche
          _CardTile(
            icon: Icons.mood,
            title: 'Stimmung (Ø letzte 7 Tage)',
            subtitle: (_avgMood == null) ? '—' : _avgMood!.toStringAsFixed(1) + ' / 5',
          ).animate().fadeIn(duration: 400.ms).move(begin: const Offset(0, 8)),

          const SizedBox(height: 8),

          // Volumenvergleich + Sparkline
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Volumen-Vergleich', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Diese 7 Tage: $volThis   •   Vorherige 7 Tage: $volPrev'),
                  const SizedBox(height: 4),
                  Text(
                    (pct >= 0 ? '▲' : '▼') + ' ' + pct.toStringAsFixed(1) + ' %',
                    style: TextStyle(
                      color: pct >= 0 ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 140, child: _VolumeSparkline(data: _volDays)),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 450.ms).move(begin: const Offset(0, 8)),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _CardTile({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.15),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _VolumeSparkline extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _VolumeSparkline({required this.data});
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Keine Daten'));
    }
    final xs = <FlSpot>[];
    int i = 0;
    int maxV = 0;
    for (final r in data) {
      final v = r['volume'];
      final iv = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      xs.add(FlSpot(i.toDouble(), iv));
      if (iv > maxV) maxV = iv.toInt();
      i++;
    }
    return LineChart(LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          spots: xs,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: true, applyCutOffY: true),
          barWidth: 3,
        ),
      ],
      minY: 0,
    ));
  }
}
