import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'package:intl/intl.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _entriesFuture = DB.instance.getJournal();
    setState(() {});
  }

  Future<void> _newEntryDialog() async {
    final mood = ValueNotifier<int>(3);
    final energy = ValueNotifier<int>(3);
    final sleep = ValueNotifier<int>(3);
    final textCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('📝 Neuer Tagebucheintrag'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sliderRow('Stimmung', mood),
              const SizedBox(height: 6),
              _sliderRow('Energie', energy),
              const SizedBox(height: 6),
              _sliderRow('Schlaf', sleep),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notizen',
                  border: OutlineInputBorder(),
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

    if (saved == true) {
      await DB.instance.insertJournal({
        'date': DateTime.now().toIso8601String(),
        'mood': mood.value,
        'energy': energy.value,
        'sleep': sleep.value,
        'text': textCtrl.text.trim(),
      });
      _reload();
    }
  }

  Widget _sliderRow(String label, ValueNotifier<int> value) {
    return ValueListenableBuilder<int>(
      valueListenable: value,
      builder: (context, v, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $v/5'),
          Slider(
            value: v.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$v',
            onChanged: (nv) => value.value = nv.round(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('📖 Tagebuch'),
        backgroundColor: Colors.black,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newEntryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Eintrag'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snap.data!;
          if (entries.isEmpty) {
            return const Center(child: Text('Noch keine Tagebucheinträge.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              final date = e['date'] != null ? fmt.format(DateTime.parse(e['date'])) : '-';
              return Card(
                child: ListTile(
                  title: Text(date),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('😄 Stimmung: ${e['mood'] ?? '-'}  | ⚡ Energie: ${e['energy'] ?? '-'}  | 💤 Schlaf: ${e['sleep'] ?? '-'}'),
                      if ((e['text'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(e['text'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                  ),
                  onTap: () => _showEntryDetail(e),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEntryDetail(Map<String, dynamic> e) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(fmt.format(DateTime.parse(e['date']))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('😄 Stimmung: ${e['mood'] ?? '-'}'),
            Text('⚡ Energie: ${e['energy'] ?? '-'}'),
            Text('💤 Schlaf: ${e['sleep'] ?? '-'}'),
            const SizedBox(height: 8),
            Text(e['text'] ?? '-', style: const TextStyle(fontSize: 15)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Schließen')),
        ],
      ),
    );
  }
}
