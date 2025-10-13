import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

/// Einfache Tagesliste: zeigt, was für das gewählte Datum geplant ist.
/// Wird vom Monatskalender aus geöffnet.
class PlanListScreen extends StatelessWidget {
  final DateTime date;
  const PlanListScreen({super.key, required this.date});

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
