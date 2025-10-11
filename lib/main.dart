import 'package:flutter/material.dart';

import 'screens/workouts.dart';
import 'screens/exercises.dart';
import 'screens/stats.dart';
import 'screens/journal.dart';
import 'ui/design.dart';
import 'screens/training_styled.dart'; // optional, wenn du den Demo-Screen nutzen willst

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Fitness App',
      theme: buildAppTheme(), // neues Theme
      home: const _Nav(),     // <-- richtige Klasse + const
    );
  }
}

class _Nav extends StatefulWidget {
  const _Nav({super.key});
  @override
  State<_Nav> createState() => _NavState();
}

class _NavState extends State<_Nav> {
  int _index = 0;

  final List<Widget> _pages = const [
    _Stub('🏠 Dashboard'),
    WorkoutsScreen(),
    ExercisesScreen(),
    StatsScreen(),
    JournalScreen(),
    _Stub('⚙️ Einstellungen'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        selectedItemColor: const Color(0xFF00E0C6),
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Übungen'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tagebuch'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
      ),
      floatingActionButton: null,
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Optionaler Button, um den neuen Styled-Trainingsscreen schnell zu öffnen:
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const TrainingStyledScreen())),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Neues Training (Styled)'),
        ),
        const SizedBox(height: 12),
        const Text('Platzhalter – Inhalt folgt.'),
      ],
    );
  }
}
