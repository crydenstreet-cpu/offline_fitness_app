import 'package:flutter/material.dart';

import 'screens/workouts.dart';
import 'screens/exercises.dart';
import 'screens/stats.dart';
import 'screens/journal.dart';
import 'ui/design.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Fitness App',
      theme: buildAppTheme(),  // <- AMOLED + Purple
      home: const _Nav(),
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
    return AppScaffold(
      body: SafeArea(child: _pages[_index]),
      bottom: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Übungen'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tagebuch'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Einstellungen'),
        ],
      ),
    );
  }
}

class _Stub extends StatelessWidget {
  final String title;
  const _Stub(this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            title: const Text('Willkommen!'),
            subtitle: Text(
              'AMOLED-Theme aktiv. Wenn du irgendwo harte Farben siehst, sag mir die Datei/Zeile, dann räum ich es auf.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}
