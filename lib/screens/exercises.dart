import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});
  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DB.instance.getExercises();
    setState(() {});
  }

  Future<void> _createOrEdit({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(text: existing?['name'] ?? '');
    final mg   = TextEditingController(text: existing?['muscle_group'] ?? '');
    final desc = TextEditingController(text: existing?['description'] ?? '');
    String unit = existing?['unit'] ?? 'kg';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(existing == null ? 'Übung anlegen' : 'Übung bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: mg, decoration: const InputDecoration(labelText: 'Muskelgruppe (optional)')),
                TextField(controller: desc, decoration: const InputDecoration(labelText: 'Beschreibung (optional)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: unit,
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                    DropdownMenuItem(value: 'reps', child: Text('nur Wdh.')),
                    DropdownMenuItem(value: 'sec', child: Text('Sekunden')),
                  ],
                  onChanged: (v) => unit = v ?? 'kg',
                  decoration: const InputDecoration(labelText: 'Einheit'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Speichern')),
          ],
        );
      },
    );

    if (saved != true) return;
    if (name.text.trim().isEmpty) return;

    if (existing == null) {
      await DB.instance.insertExercise({
        'name': name.text.trim(),
        'muscle_group': mg.text.trim().isEmpty ? null : mg.text.trim(),
        'description': desc.text.trim().isEmpty ? null : desc.text.trim(),
        'unit': unit
      });
    } else {
      await DB.instance.updateExercise(existing['id'], {
        'name': name.text.trim(),
        'muscle_group': mg.text.trim().isEmpty ? null : mg.text.trim(),
        'description': desc.text.trim().isEmpty ? null : desc.text.trim(),
        'unit': unit
      });
    }
    _reload();
  }

  Future<void> _delete(int id) async {
    await DB.instance.deleteExercise(id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Übungen'),
        backgroundColor: Colors.black,
        actions: [ IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)) ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Übung hinzufügen'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Noch keine Übungen – lege deine erste an!'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = items[i];
              return Dismissible(
                key: ValueKey(e['id']),
                background: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.delete)),
                secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete)),
                onDismissed: (_) => _delete(e['id'] as int),
                child: ListTile(
                  title: Text(e['name'] ?? ''),
                  subtitle: Text([e['muscle_group'], e['unit']].where((x) => (x ?? '').toString().isNotEmpty).join(' • ')),
                  trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _createOrEdit(existing: e)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
