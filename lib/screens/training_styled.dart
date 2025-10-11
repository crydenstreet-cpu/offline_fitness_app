import 'package:flutter/material.dart';
import '../ui/design.dart';
import '../ui/components.dart';

class TrainingStyledScreen extends StatefulWidget {
  const TrainingStyledScreen({super.key});
  @override
  State<TrainingStyledScreen> createState() => _TrainingStyledScreenState();
}

class _TrainingStyledScreenState extends State<TrainingStyledScreen> {
  int rest = 90;
  int selectedChip = 1; // 60,90,180
  DateTime started = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dur = DateTime.now().difference(started);
    return AppScaffold(
      appBar: AppBar(title: const Text('Training')),
      body: ListView(
        children: [
          // Chip-Leiste (60/90/180) wie im 1. Screenshot
          SectionHeader('Pause'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                PillChip(label: '60s',  selected: selectedChip==0, onTap: ()=>setState((){selectedChip=0; rest=60;})),
                const SizedBox(width: 8),
                PillChip(label: '90s',  selected: selectedChip==1, onTap: ()=>setState((){selectedChip=1; rest=90;})),
                const SizedBox(width: 8),
                PillChip(label: '180s', selected: selectedChip==2, onTap: ()=>setState((){selectedChip=2; rest=180;})),
              ],
            ),
          ),

          // Metriken (Uhrzeit / Trainingszeit)
          Row(
            children: [
              MetricTile(title: 'Uhrzeit', value: _fmtTime(DateTime.now()), icon: Icons.schedule),
              MetricTile(title: 'Trainingszeit', value: _fmtDuration(dur), icon: Icons.timelapse),
            ],
          ),

          // Übungskarte mit "Bild" (Platzhalter) + Sets wie im 1. Screenshot
          SectionHeader('Beine'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titel + Mini-Bildplatzhalter
                Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text('🦵', style: TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Bulgarian Split Squat', style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert))
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),

                // Set-Liste (ESN-Stil: Sätze/Wdh. klar, checkbox)
                const SetRow(setNumber: 1, weight: '30 kg', reps: '12 Wdh.'),
                const SetRow(setNumber: 2, weight: '30 kg', reps: '12 Wdh.'),
                const SetRow(setNumber: 3, weight: '30 kg', reps: '12 Wdh.'),
              ],
            ),
          ),

          // Weitere Übung (Bankdrücken Beispiel)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Bankdrücken', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  trailing: Icon(Icons.more_vert),
                ),
                Divider(height: 1),
                SetRow(setNumber: 1, weight: '60 kg', reps: '10 Wdh.'),
                SetRow(setNumber: 2, weight: '60 kg', reps: '10 Wdh.'),
                SetRow(setNumber: 3, weight: '60 kg', reps: '8 Wdh.'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: (){}, child: const Text('Training beenden', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt){
    final h = dt.hour.toString().padLeft(2,'0');
    final m = dt.minute.toString().padLeft(2,'0');
    return '$h:$m Uhr';
    }
  String _fmtDuration(Duration d){
    final mm = d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final hh = d.inHours.toString().padLeft(2,'0');
    return '$hh:$mm Std';
  }
}
