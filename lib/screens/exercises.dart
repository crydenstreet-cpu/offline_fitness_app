import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
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
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('🏋️‍♂️ Neue Übung anlegen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: groupCtrl, decoration: const InputDecoration(labelText: 'Muskelgruppe')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Beschreibung')),
              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Einheit (z. B. kg)')),
              const SizedBox(height: 10),
              TextField(
                controller: setsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Standard-Sätze'),
              ),
              TextField(
                controller: repsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Standard-Wiederholungen'),
              ),
            ],
          ),
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
        'muscle_group': groupCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
        'default_sets': int.tryParse(setsCtrl.text.trim()) ?? 3,
        'default_reps': int.tryParse(repsCtrl.text.trim()) ?? 10,
      });
      _reload();
    }
  }

  Future<void> _deleteExercise(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Löschen?'),
        content: const Text('Diese Übung wirklich löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm == true) {
      await DB.instance.deleteExercise(id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏋️ Übungen'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExerciseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Übung'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _exercisesFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) return const Center(child: Text('Noch keine Übungen angelegt.'));
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final e = list[i];
              return Card(
                child: ListTile(
                  title: Text(e['name'] ?? ''),
                  subtitle: Text(
                    'Muskelgruppe: ${e['muscle_group'] ?? '-'}\n'
                    'Sätze: ${e['default_sets'] ?? 3} • Wiederholungen: ${e['default_reps'] ?? 10}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
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
