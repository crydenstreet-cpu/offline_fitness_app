// lib/screens/journal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/database_helper.dart';
import '../ui/design.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = DB.instance.getJournal(limit: 200);
    setState(() {});
  }

  Future<void> _openNew() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: _JournalForm(),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _openEdit(Map<String, dynamic> row) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: _JournalForm(existing: row),
      ),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('📓 Tagebuch')),
      fab: FloatingActionButton.extended(
        onPressed: _openNew,
        icon: const Icon(Icons.add),
        label: const Text('Neuer Eintrag'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) return Center(child: Text('Fehler: ${snap.error}'));
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snap.data!;
          if (rows.isEmpty) {
            return const Center(child: Text('Noch keine Einträge. Starte mit „Neuer Eintrag“.'));
          }

          final df = DateFormat('EEE, dd.MM.yyyy', 'de_DE');
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final r = rows[i];
              final date = r['date'] as String?; // yyyy-MM-dd
              DateTime? day;
              try {
                if (date != null && date.length >= 10) {
                  final y = int.parse(date.substring(0, 4));
                  final m = int.parse(date.substring(5, 7));
                  final d = int.parse(date.substring(8, 10));
                  day = DateTime(y, m, d);
                }
              } catch (_) {}
              final title = day != null ? df.format(day) : (date ?? '');

              final note = (r['note'] ?? '') as String;
              final mood = (r['mood'] as int?) ?? 3;
              final energy = r['energy'] as int?;
              final sleep = r['sleep'] as int?;
              final motivation = r['motivation'] as int?;

              return AppCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openEdit(r),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kopfzeile
                        Row(
                          children: [
                            Expanded(
                              child: Text(title,
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note),
                              onPressed: () => _openEdit(r),
                              tooltip: 'Bearbeiten',
                            ),
                          ],
                        ),
                        // Chips/Badges
                        Wrap(
                          spacing: 8, runSpacing: 6,
                          children: [
                            _pill('Stimmung', _moodLabel(mood), Icons.emoji_emotions),
                            if (energy != null) _pill('Energie', '$energy/5', Icons.bolt),
                            if (sleep != null) _pill('Schlaf', '${sleep}h', Icons.bedtime),
                            if (motivation != null) _pill('Motivation', '$motivation/5', Icons.local_fire_department),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (note.isNotEmpty)
                          Text(note),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _pill(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text('$title: $value'),
        ],
      ),
    );
  }

  String _moodLabel(int mood) {
    switch (mood) {
      case 1: return '😖 1';
      case 2: return '☹️ 2';
      case 3: return '😐 3';
      case 4: return '🙂 4';
      case 5: return '😄 5';
      default: return '$mood';
    }
  }
}

/// Formular für Neu/Bearbeiten
class _JournalForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _JournalForm({this.existing});

  @override
  State<_JournalForm> createState() => _JournalFormState();
}

class _JournalFormState extends State<_JournalForm> {
  late DateTime _date;
  final _noteCtrl = TextEditingController();

  int _mood = 3;
  int? _energy;      // 1..5
  int? _sleepH;      // 0..12 (Stunden)
  int? _motivation;  // 1..5

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();

    final r = widget.existing;
    if (r != null) {
      // date: yyyy-MM-dd
      final date = r['date'] as String?;
      if (date != null && date.length >= 10) {
        try {
          final y = int.parse(date.substring(0, 4));
          final m = int.parse(date.substring(5, 7));
          final d = int.parse(date.substring(8, 10));
          _date = DateTime(y, m, d);
        } catch (_) {}
      }
      _noteCtrl.text = (r['note'] ?? '') as String;
      _mood = (r['mood'] as int?) ?? 3;
      _energy = r['energy'] as int?;
      _sleepH = r['sleep'] as int?;
      _motivation = r['motivation'] as int?;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      helpText: 'Datum wählen',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (widget.existing == null) {
      await DB.instance.insertJournal(
        _date,
        _noteCtrl.text.trim(),
        mood: _mood,
        energy: _energy,
        sleep: _sleepH,
        motivation: _motivation,
      );
    } else {
      await DB.instance.updateJournal(
        id: widget.existing!['id'] as int,
        date: _date,
        note: _noteCtrl.text.trim(),
        mood: _mood,
        energy: _energy,
        sleep: _sleepH,
        motivation: _motivation,
      );
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: const Text('Dieser Eintrag wird dauerhaft entfernt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      await DB.instance.deleteJournal(widget.existing!['id'] as int);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Griff
          Center(
            child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(isEdit ? 'Eintrag bearbeiten' : 'Neuer Eintrag',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          // Datum
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('dd.MM.yyyy', 'de_DE').format(_date)),
          ),

          const SizedBox(height: 12),

          // Mood
          const Text('Stimmung', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [1,2,3,4,5].map((v) {
              final label = switch (v) {
                1 => '😖',
                2 => '☹️',
                3 => '😐',
                4 => '🙂',
                5 => '😄',
                _ => '$v',
              };
              final selected = _mood == v;
              return ChoiceChip(
                label: Text('$label  $v'),
                selected: selected,
                onSelected: (_) => setState(() => _mood = v),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Energie
          const Text('Energie', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [1,2,3,4,5].map((v) {
              final selected = _energy == v;
              return ChoiceChip(
                avatar: const Icon(Icons.bolt, size: 16),
                label: Text('$v/5'),
                selected: selected,
                onSelected: (_) => setState(() => _energy = v),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Motivation
          const Text('Motivation', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [1,2,3,4,5].map((v) {
              final selected = _motivation == v;
              return ChoiceChip(
                avatar: const Icon(Icons.local_fire_department, size: 16),
                label: Text('$v/5'),
                selected: selected,
                onSelected: (_) => setState(() => _motivation = v),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Schlaf (Slider in Stunden)
          Row(
            children: [
              const Text('Schlaf (h)', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${_sleepH ?? 0} h'),
            ],
          ),
          Slider(
            value: (_sleepH ?? 0).toDouble(),
            min: 0, max: 12, divisions: 12,
            label: '${_sleepH ?? 0} h',
            onChanged: (v) => setState(() => _sleepH = v.round()),
          ),

          const SizedBox(height: 12),

          // Notiz
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notiz',
              hintText: 'Wie war dein Tag / Training?',
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              if (isEdit)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Löschen'),
                  ),
                ),
              if (isEdit) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isEdit ? 'Speichern' : 'Anlegen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
