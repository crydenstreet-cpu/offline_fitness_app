import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offline_fitness_app/db/database_helper.dart';
import 'package:offline_fitness_app/ui/design.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _df = DateFormat('EEE, dd.MM.yyyy', 'de_DE');
  bool _loading = true;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await DB.instance.getJournal(limit: 500);
    if (!mounted) return;
    setState(() {
      _entries = rows;
      _loading = false;
    });
  }

  Future<void> _newEntryDialog() async {
    DateTime date = DateTime.now();
    int mood = 3; // 1..5
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Neuer Eintrag'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateRow(
                label: 'Datum',
                date: date,
                onPick: (d) => date = d,
              ),
              const SizedBox(height: 8),
              _MoodRow(
                value: mood,
                onChanged: (v) => mood = v,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Notiz',
                  hintText: 'Wie war dein Training / dein Tag?',
                ),
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

    if (ok == true) {
      await DB.instance.insertJournal(date, ctrl.text.trim(), mood: mood);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eintrag gespeichert.')));
    }
  }

  Future<void> _editEntryDialog(Map<String, dynamic> row) async {
    DateTime date = DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();
    int mood = (row['mood'] as int?) ?? 3;
    final ctrl = TextEditingController(text: row['note'] as String? ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eintrag bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DateRow(label: 'Datum', date: date, onPick: (d) => date = d),
              const SizedBox(height: 8),
              _MoodRow(value: mood, onChanged: (v) => mood = v),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Notiz'),
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

    if (ok == true) {
      await DB.instance.updateJournal(
        id: row['id'] as int,
        date: date,
        note: ctrl.text.trim(),
        mood: mood,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eintrag aktualisiert.')));
    }
  }

  Future<void> _confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Das kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      await DB.instance.deleteJournal(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eintrag gelöscht.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('📓 Tagebuch')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('Noch keine Einträge.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: _entries.length,
                  itemBuilder: (ctx, i) {
                    final row = _entries[i];
                    final id = row['id'] as int;
                    final note = (row['note'] as String?) ?? '';
                    final mood = (row['mood'] as int?) ?? 3;
                    final date = DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();
                    return Dismissible(
                      key: ValueKey('journal_$id'),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline),
                      ),
                      confirmDismiss: (_) async {
                        await _confirmDelete(id);
                        return false; // wir löschen manuell nach Bestätigung
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(_df.format(date), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(note.isEmpty ? '—' : note),
                          leading: _MoodDot(mood: mood),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _editEntryDialog(row);
                              if (v == 'delete') _confirmDelete(id);
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Bearbeiten'))),
                              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Löschen'))),
                            ],
                          ),
                          onTap: () => _editEntryDialog(row),
                        ),
                      ),
                    );
                  },
                ),
      fab: FloatingActionButton.extended(
        onPressed: _newEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
      ),
    );
  }
}

/// Datumsauswahl-Zeile
class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;
  const _DateRow({required this.label, required this.date, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 3650)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: Theme.of(ctx).colorScheme,
                  dialogBackgroundColor: Theme.of(ctx).colorScheme.surface,
                ),
                child: child!,
              ),
            );
            if (picked != null) onPick(DateTime(picked.year, picked.month, picked.day));
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(DateFormat('dd.MM.yyyy').format(date)),
        ),
      ],
    );
  }
}

/// Stimmungsauswahl (1..5)
class _MoodRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _MoodRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = List<Widget>.generate(5, (i) {
      final v = i + 1;
      final selected = v == value;
      return ChoiceChip(
        label: Text('$v'),
        selected: selected,
        onSelected: (_) => onChanged(v),
      );
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Stimmung'),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: chips),
      ],
    );
  }
}

/// Kleiner farbiger Punkt je Stimmung
class _MoodDot extends StatelessWidget {
  final int mood;
  const _MoodDot({required this.mood});
  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.redAccent, Colors.deepOrange, Colors.amber, Colors.lightGreen, Colors.tealAccent,
    ];
    final c = colors[(mood.clamp(1, 5)) - 1];
    return CircleAvatar(radius: 10, backgroundColor: c);
  }
}
