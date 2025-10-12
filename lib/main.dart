import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // Locale-Fix für DateFormat('…','de_DE')

import 'ui/design.dart'; // enthält buildLightTheme / buildDarkTheme / AppScaffold

// Screens
import 'screens/dashboard.dart';
import 'screens/workouts.dart';
import 'screens/exercises.dart';
import 'screens/stats.dart';
import 'screens/journal.dart';
import 'screens/planner.dart';
import 'screens/calendar_month.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ohne das crasht DateFormat('…', 'de_DE') in Release häufig.
  await initializeDateFormatting('de_DE');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Fitness App',
      // ⚡️ Sportlich-Modernes Theme mit Gradient + Dark/Light
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system, // folgt Geräteeinstellung
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
    DashboardScreen(),        // 🏁 Startseite
    WorkoutsScreen(),
    ExercisesScreen(),
    StatsScreen(),
    JournalScreen(),
    PlannerScreen(),
    CalendarMonthScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(child: _pages[_index]),
      bottom: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (v) => setState(() => _index = v),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Übungen'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistik'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tagebuch'),
          BottomNavigationBarItem(icon: Icon(Icons.view_week), label: 'Planer'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Kalender'),
        ],
      ),
    );
  }
}
