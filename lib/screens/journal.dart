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

  // ---------- CREATE ----------
  Future<void> _newEntrySheet() async {
    DateTime date = DateTime.now();
    int mood = 3; // 1..5
    final ctrl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return _JournalEditor(
          title: 'Neuer Eintrag',
          initialDate: date,
          initialMood: mood,
          initialText: '',
          onChanged: (d, m, t) {
            // wird durch StatefulBuilder dort verwaltet, hier nur am Ende interessant
            date = d; mood = m; ctrl.text = t;
          },
        );
      },
    );

    if (saved == true) {
      await DB.instance.insertJournal(date, ctrl.text.trim(), mood: mood);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Eintrag gespeichert.')));
    }
  }

  // ---------- EDIT ----------
  Future<void> _editEntrySheet(Map<String, dynamic> row) async {
    DateTime date = DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();
    int mood = (row['mood'] as int?)?.clamp(1, 5) ?? 3;
    final ctrl = TextEditingController(text: row['note'] as String? ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) {
        return _JournalEditor(
          title: 'Eintrag bearbeiten',
          initialDate: date,
          initialMood: mood,
          initialText: ctrl.text,
          onChanged: (d, m, t) {
            date = d; mood = m; ctrl.text = t;
          },
        );
      },
    );

    if (saved == true) {
      await DB.instance.updateJournal(
        id: row['id'] as int,
        date: date,
        note: ctrl.text.trim(),
        mood: mood,
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Eintrag aktualisiert.')));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Eintrag gelöscht.')));
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
                    final mood = (row['mood'] as int?)?.clamp(1, 5) ?? 3;
                    final date = DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();
                    return Dismissible(
                      key: ValueKey('journal_$id'),
                      background: _swipeBg(left: true),
                      secondaryBackground: _swipeBg(left: false),
                      confirmDismiss: (_) async {
                        await _confirmDelete(id);
                        return false; // wir löschen manuell
                      },
                      child: Card(
                        child: ListTile(
                          title: Text(_df.format(date),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(note.isEmpty ? '—' : note),
                          leading: _MoodDot(mood: mood),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _editEntrySheet(row);
                              if (v == 'delete') _confirmDelete(id);
                            },
                            itemBuilder: (ctx) => const [
                              PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Bearbeiten'))),
                              PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                      leading: Icon(Icons.delete_outline),
                                      title: Text('Löschen'))),
                            ],
                          ),
                          onTap: () => _editEntrySheet(row),
                        ),
                      ),
                    );
                  },
                ),
      fab: FloatingActionButton.extended(
        onPressed: _newEntrySheet,
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
      ),
    );
  }

  Widget _swipeBg({required bool left}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.only(left: left ? 20 : 0, right: left ? 0 : 20),
      child: const Icon(Icons.delete_outline),
    );
  }
}

/// ---------- Editor BottomSheet (stateful im Inneren) ----------
class _JournalEditor extends StatelessWidget {
  final String title;
  final DateTime initialDate;
  final int initialMood; // 1..5
  final String initialText;
  final void Function(DateTime date, int mood, String text) onChanged;

  const _JournalEditor({
    required this.title,
    required this.initialDate,
    required this.initialMood,
    required this.initialText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    DateTime date = initialDate;
    int mood = initialMood;
    final ctrl = TextEditingController(text: initialText);

    return StatefulBuilder(
      builder: (ctx, setSheetState) {
        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: date,
            firstDate: DateTime.now().subtract(const Duration(days: 3650)),
            lastDate: DateTime.now().add(const Duration(days: 3650)),
            builder: (c, child) => Theme(
              data: Theme.of(c).copyWith(
                colorScheme: Theme.of(c).colorScheme,
                dialogBackgroundColor: Theme.of(c).colorScheme.surface,
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            setSheetState(() => date = DateTime(picked.year, picked.month, picked.day));
          }
        }

        void changeMood(int v) {
          setSheetState(() => mood = v.clamp(1, 5));
        }

        onChanged(date, mood, ctrl.text);

        final bottomSafe = MediaQuery.of(ctx).viewPadding.bottom;
        final bottomKeyboard = MediaQuery.of(ctx).viewInsets.bottom;

        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: 16 + bottomSafe + bottomKeyboard,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    height: 4, width: 40, margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 10),

                // Datum
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(DateFormat('EEE, dd.MM.yyyy', 'de_DE').format(date))),
                    OutlinedButton(
                      onPressed: pickDate,
                      child: const Text('Datum ändern'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stimmung (1..5)
                const Text('Stimmung'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: List.generate(5, (i) {
                    final v = i + 1;
                    final selected = v == mood;
                    return ChoiceChip(
                      label: Text('$v'),
                      selected: selected,
                      onSelected: (_) => changeMood(v),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // Notiz
                TextField(
                  controller: ctrl,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Notiz',
                    hintText: 'Wie war dein Training / dein Tag?',
                  ),
                  onChanged: (_) => onChanged(date, mood, ctrl.text),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Abbrechen'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onChanged(date, mood, ctrl.text);
                          Navigator.pop(ctx, true);
                        },
                        child: const Text('Speichern'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      Colors.redAccent, Colors.deepOrange, Colors.amber,
      Colors.lightGreen, Colors.tealAccent,
    ];
    final c = colors[(mood.clamp(1, 5)) - 1];
    return CircleAvatar(radius: 10, backgroundColor: c);
  }
}
