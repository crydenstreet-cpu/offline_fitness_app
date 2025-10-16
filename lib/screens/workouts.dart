import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../ui/design.dart';
import 'workout_form.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DB.instance.getWorkouts();
    setState(() {});
  }

  Future<void> _create() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutFormScreen()),
    );
    if (changed == true) _reload();
  }

  Future<void> _edit(Map<String, dynamic> w) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkoutFormScreen(
        workoutId: w['id'] as int,
        initialName: (w['name'] ?? '').toString(),
      )),
    );
    if (changed == true) _reload();
  }

  Future<void> _delete(Map<String, dynamic> w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Workout löschen?'),
        content: const Text(
          'Dieses Workout wird dauerhaft gelöscht. '
          'Verknüpfte Übungen und Kalender-Einträge werden ebenfalls entfernt.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete),
            label: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DB.instance.deleteWorkoutById(w['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('„${w['name']}“ gelöscht')),
        );
      }
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(onPressed: _create, icon: const Icon(Icons.add), tooltip: 'Neues Workout'),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Noch keine Workouts angelegt.'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      label: const Text('Workout erstellen'),
                    )
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final w = items[i];
              return AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fitness_center),
                  title: Text('${w['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('ID: ${w['id']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _edit(w);
                      if (value == 'delete') _delete(w);
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(
                        leading: Icon(Icons.edit), title: Text('Bearbeiten'),
                      )),
                      const PopupMenuItem(value: 'delete', child: ListTile(
                        leading: Icon(Icons.delete_outline), title: Text('Löschen'),
                      )),
                    ],
                  ),
                  onTap: () => _edit(w),
                ),
              );
            },
          );
        },
      ),
      fab: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
    );
  }
}
