import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../ui/design.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>?> _nextPlannedFuture;
  late Future<Map<String, dynamic>?> _lastSessionFuture;
  late Future<double?> _avgMoodFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _nextPlannedFuture = DB.instance.nextPlannedWorkout();
    _lastSessionFuture = DB.instance.lastSessionSummary();
    _avgMoodFuture = DB.instance.averageMoodLast7Days();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('🏁 Home')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // Nächster Termin
          FutureBuilder<Map<String, dynamic>?>(
            future: _nextPlannedFuture,
            builder: (context, snap) {
              final row = snap.data;
              final title = row?['workout_name'] ?? '—';
              final dateStr = row?['date'] as String?;
              String sub = 'Kein Termin geplant';
              if (dateStr != null && dateStr.length >= 10) {
                final parts = dateStr.split('-');
                final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                sub = DateFormat('EEE, dd.MM.yyyy', 'de_DE').format(d);
              }
              return _cardTile(
                context,
                leading: const Icon(Icons.event_available),
                title: 'Nächster Termin',
                subtitle: '$title\n$sub',
              );
            },
          ),

          const SizedBox(height: 10),

          // Letzte Session
          FutureBuilder<Map<String, dynamic>?>(
            future: _lastSessionFuture,
            builder: (context, snap) {
              final row = snap.data;
              String when = '—';
              int sets = 0;
              double volume = 0;
              if (row != null) {
                final iso = row['started_at'] as String?;
                if (iso != null) when = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(iso));
                sets = (row['sets_count'] as num?)?.toInt() ?? 0;
                volume = (row['total_volume'] as num?)?.toDouble() ?? 0.0;
              }
              return _cardTile(
                context,
                leading: const Icon(Icons.fitness_center),
                title: 'Letzte Session',
                subtitle: 'Zeit: $when\nSätze: $sets   •   Volumen: ${_short(volume)}',
              );
            },
          ),

          const SizedBox(height: 10),

          // Stimmung (7 Tage)
          FutureBuilder<double?>(
            future: _avgMoodFuture,
            builder: (context, snap) {
              final v = snap.data;
              final label = v == null ? '—' : v.toStringAsFixed(1);
              return _cardTile(
                context,
                leading: const Icon(Icons.emoji_emotions),
                title: 'Stimmung (Ø 7 Tage)',
                subtitle: label,
              );
            },
          ),
        ],
      ),
    );
  }

  // Kleiner Helfer für hübsche Karten
  Widget _cardTile(
    BuildContext context, {
    required Widget leading,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leading,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle),
          ),
        ),
      ),
    );
  }

  String _short(double n) {
    if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
    if (n >= 1e3) return '${(n / 1e3).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }
}
