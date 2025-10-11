import 'package:flutter/material.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});
  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late Future<List<Map<String, dynamic>>> _exercisesFuture;

  @override
  void initState() { super.initState(); _reload(); }
  void _reload() { _exercisesFuture = DB.instance.getExercises(); setState(() {}); }

  Future<void> _addExerciseDialog() async {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'kg');
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🏋️‍♂️ Neue Übung'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'Muskelgruppe')),
            const SizedBox(height: 8),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Beschreibung')),
            const SizedBox(height: 8),
            TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Einheit (z. B. kg, sec)')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(
                controller: setsCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Standard-Sätze'),
              )),
              const SizedBox(width: 10),
              Expanded(child: TextField(
                controller: repsCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Standard-Wdh.'),
              )),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
        ],
      ),
    );

    if (saved == true) {
      await DB.instance.insertExercise({
        'name': nameCtrl.text.trim(),
        'muscle_group': groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim(),
        'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        'unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
        'default_sets': int.tryParse(setsCtrl.text.trim()) ?? 3,
        'default_reps': int.tryParse(repsCtrl.text.trim()) ?? 10,
      });
      _reload();
    }
  }

  Future<void> _deleteExercise(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen?'),
        content: const Text('Übung wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) { await DB.instance.deleteExercise(id); _reload(); }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('📋 Übungen')),
      fab: FloatingActionButton.extended(onPressed: _addExerciseDialog, icon: const Icon(Icons.add), label: const Text('Übung')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('Noch keine Übungen – lege deine erste an!'));
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final e = list[i];
              return Card(
                child: ListTile(
                  title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text([
                      if ((e['muscle_group'] ?? '').toString().isNotEmpty) 'Gruppe: ${e['muscle_group']}',
                      'Sätze: ${e['default_sets'] ?? 3}',
                      'Wdh: ${e['default_reps'] ?? 10}',
                    ].join(' • ')),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteExercise(e['id'] as int),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
