import 'package:flutter/material.dart';

import 'screens/calendar_month.dart';   // ⬅️ neu
import 'screens/planner.dart';
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
      theme: buildAppTheme(),
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
    CalendarMonthScreen(),   // 📆 Monatsansicht
    PlannerScreen(),         // 🗓️ Wochen-Generator
    WorkoutsScreen(),
    ExercisesScreen(),
    StatsScreen(),
    JournalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Kalender'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Planer'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Übungen'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tagebuch'),
        ],
      ),
    );
  }
}
