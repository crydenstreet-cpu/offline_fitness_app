import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';

class WorkoutFormScreen extends StatefulWidget {
  final int? workoutId;
  final String? initialName;
  const WorkoutFormScreen({super.key, this.workoutId, this.initialName});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _planNow = false;
  DateTime _startDate = DateTime.now();
  int _weeks = 4;
  final Map<int, bool> _weekdayChecked = {1:false,2:false,3:false,4:false,5:false,6:false,7:false};

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initialName ?? '';
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('de'),
    );
    if (d != null) setState(() => _startDate = DateTime(d.year, d.month, d.day));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();

    if (widget.workoutId == null) {
      // Neu
      final id = await DB.instance.insertWorkout(name);
      if (_planNow) {
        final map = <int, int?>{};
        for (int wd = 1; wd <= 7; wd++) {
          map[wd] = _weekdayChecked[wd] == true ? id : null;
        }
        await DB.instance.generateSchedule(
          startDate: _startDate,
          weeks: _weeks,
          weekdayToWorkoutId: map,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      // Bearbeiten
      await DB.instance.updateWorkoutName(widget.workoutId!, name);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.workoutId != null;
    final df = DateFormat('dd.MM.yyyy', 'de_DE');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Workout bearbeiten' : 'Workout erstellen'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Workout-Name',
                hintText: 'z. B. Push, Pull, Beine …',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Bitte Namen eingeben' : null,
            ),
          ),
          const SizedBox(height: 20),

          if (!isEdit) ...[
            SwitchListTile(
              value: _planNow,
              onChanged: (v) => setState(() => _planNow = v),
              title: const Text('Direkt einplanen'),
              subtitle: const Text('Workouts automatisch in den Kalender setzen'),
            ),
            if (_planNow) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartDate,
                      icon: const Icon(Icons.event),
                      label: Text('Start: ${df.format(_startDate)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _weeks,
                      decoration: const InputDecoration(
                        labelText: 'Wochen',
                        border: OutlineInputBorder(),
                      ),
                      items: const [2,4,6,8,12]
                          .map((w) => DropdownMenuItem(value: w, child: Text('$w')))
                          .toList(),
                      onChanged: (v) => setState(() => _weeks = v ?? 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('An welchen Wochentagen?',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  _wdChip(1, 'Mo'),
                  _wdChip(2, 'Di'),
                  _wdChip(3, 'Mi'),
                  _wdChip(4, 'Do'),
                  _wdChip(5, 'Fr'),
                  _wdChip(6, 'Sa'),
                  _wdChip(7, 'So'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Die Planung läuft $_weeks Woche(n) ab ${df.format(_startDate)}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(isEdit ? 'Änderungen speichern' : 'Workout anlegen'),
          ),
        ],
      ),
    );
  }

  Widget _wdChip(int wd, String label) {
    final sel = _weekdayChecked[wd] == true;
    return FilterChip(
      selected: sel,
      label: Text(label),
      onSelected: (v) => setState(() => _weekdayChecked[wd] = v),
      showCheckmark: true,
    );
  }
}
