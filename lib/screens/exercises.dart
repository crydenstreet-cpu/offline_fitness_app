import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../ui/design.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _reorderMode = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await DB.instance.getExercises();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _addOrEditDialog({Map<String, dynamic>? exercise}) async {
    final isEdit = exercise != null;

    final nameCtrl = TextEditingController(text: exercise?['name'] ?? '');
    final groupCtrl = TextEditingController(text: exercise?['muscle_group'] ?? '');
    final unitCtrl = TextEditingController(text: exercise?['unit'] ?? 'kg');
    final setsCtrl = TextEditingController(text: '${exercise?['default_sets'] ?? 3}');
    final repsCtrl = TextEditingController(text: '${exercise?['default_reps'] ?? 10}');
    final descCtrl = TextEditingController(text: exercise?['description'] ?? '');

    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Übung bearbeiten' : 'Neue Übung'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name*'),
                  autofocus: true,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Bitte Namen angeben' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: groupCtrl,
                  decoration: const InputDecoration(labelText: 'Muskelgruppe (optional)'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: 'Einheit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: setsCtrl,
                        decoration: const InputDecoration(labelText: 'Standard-Sätze'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Zahl > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: repsCtrl,
                        decoration: const InputDecoration(labelText: 'Standard-Wdh'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Zahl > 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Beschreibung / Hinweise'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = <String, Object?>{
                'name': nameCtrl.text.trim(),
                'muscle_group': groupCtrl.text.trim().isEmpty ? null : groupCtrl.text.trim(),
                'unit': unitCtrl.text.trim().isEmpty ? 'kg' : unitCtrl.text.trim(),
                'default_sets': int.parse(setsCtrl.text.trim()),
                'default_reps': int.parse(repsCtrl.text.trim()),
                'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              };
              if (isEdit) {
                await DB.instance.updateExercise(exercise!['id'] as int, data);
              } else {
                await DB.instance.insertExercise(data);
              }
              if (context.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (saved == true) _reload();
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Übung löschen?'),
        content: Text('„$name“ wird gelöscht.\n'
            'Verknüpfungen in Workouts werden durch den DB-FK mit gelöscht.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Löschen'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DB.instance.deleteExercise(id);
      _reload();
    }
  }

  // ---- REORDER ----
  Future<void> _persistOrder() async {
    final ids = _items.map<int>((e) => e['id'] as int).toList();
    await DB.instance.updateExercisesOrder(ids);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('📋 Übungen'),
        actions: [
          IconButton(
            tooltip: _reorderMode ? 'Sortieren beenden' : 'Sortieren',
            icon: Icon(_reorderMode ? Icons.check : Icons.reorder),
            onPressed: () async {
              if (_reorderMode) {
                await _persistOrder();
              }
              setState(() => _reorderMode = !_reorderMode);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.list_alt, size: 40),
                        const SizedBox(height: 12),
                        const Text('Noch keine Übungen angelegt.'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _addOrEditDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Übung erstellen'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: _reorderMode
                      ? _buildReorderList()
                      : _buildNormalList(),
                ),
      fab: _reorderMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _addOrEditDialog,
              icon: const Icon(Icons.add),
              label: const Text('Übung'),
            ),
    );
  }

  Widget _buildNormalList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final e = _items[i];
        final id = e['id'] as int;
        final unit = (e['unit'] ?? 'kg').toString();

        return Dismissible(
          key: ValueKey('ex_$id'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            await _confirmDelete(id, e['name'] ?? '');
            return false;
          },
          child: AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                e['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text([
                  if ((e['muscle_group'] ?? '').toString().isNotEmpty) '${e['muscle_group']}',
                  'Std.-Sätze: ${e['default_sets'] ?? '-'}',
                  'Std.-Wdh: ${e['default_reps'] ?? '-'}',
                  'Einheit: $unit',
                ].join('  •  ')),
              ),
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(
                    tooltip: 'Bearbeiten',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _addOrEditDialog(exercise: e),
                  ),
                  IconButton(
                    tooltip: 'Löschen',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(id, e['name'] ?? ''),
                  ),
                ],
              ),
              onTap: () => _addOrEditDialog(exercise: e),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReorderList() {
    // ReorderableListView benötigt eine Liste von Widgets mit Keys
    return ReorderableListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      proxyDecorator: (child, index, animation) {
        // leichte Vergrößerung beim Ziehen
        return Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.02,
            child: child,
          ),
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
      },
      children: [
        for (final e in _items)
          AppCard(
            key: ValueKey('ex_re_${e['id']}'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.drag_indicator),
              title: Text(e['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: (e['muscle_group'] != null && (e['muscle_group'] as String).isNotEmpty)
                  ? Text('${e['muscle_group']}')
                  : null,
              trailing: const Icon(Icons.reorder),
            ),
          ),
      ],
    );
  }
}
