// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'ui/design.dart' as ui;
import 'theme/theme_switcher.dart';

import 'screens/dashboard.dart';
import 'screens/plan_hub.dart';
import 'screens/workouts.dart';
import 'screens/exercises.dart';
import 'screens/stats.dart';
import 'screens/journal.dart';
import 'screens/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');
  runApp(const RootApp());
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});
  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  bool _dark = false;
  void _setDark(bool v) => setState(() => _dark = v);

  @override
  Widget build(BuildContext context) {
    return ThemeSwitcher(
      setDark: _setDark,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Offline Fitness App',
        theme: ui.buildLightTheme(),
        darkTheme: ui.buildDarkTheme(),
        themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
        home: const _NavWithDrawer(),
      ),
    );
  }
}

class _NavWithDrawer extends StatefulWidget {
  const _NavWithDrawer({super.key});
  @override
  State<_NavWithDrawer> createState() => _NavWithDrawerState();
}

class _NavWithDrawerState extends State<_NavWithDrawer> {
  int _index = 0;

  final _pages = const <Widget>[
    DashboardScreen(),   // Home
    PlanHubScreen(),     // Plan (Monat & Heute)
    WorkoutsScreen(),    // Workouts
    ExercisesScreen(),   // Übungen
    StatsScreen(),       // Stats
    JournalScreen(),     // Tagebuch
    SettingsScreen(),    // Einstellungen
  ];

  String get _title {
    switch (_index) {
      case 0: return '🏁 Home';
      case 1: return '🗓️ Plan';
      case 2: return '💪 Workouts';
      case 3: return '📋 Übungen';
      case 4: return '📈 Stats';
      case 5: return '📔 Tagebuch';
      case 6: return '⚙️ Einstellungen';
      default: return 'App';
    }
  }

  void _go(int i) {
    setState(() => _index = i);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return ui.AppScaffold(
      appBar: AppBar(title: Text(_title)),
      drawer: _AppDrawer(selected: _index, onSelect: _go),
      body: _pages[_index],
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _AppDrawer({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget item({required IconData icon, required String label, required int idx}) {
      final isSel = selected == idx;
      return Material(
        color: isSel ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent,
        child: ListTile(
          leading: Icon(icon),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () { Navigator.pop(context); onSelect(idx); },
        ),
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text('Offline Fitness App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              subtitle: Text('Alles an einem Ort'),
            ),
            const Divider(),
            item(icon: Icons.home,           label: 'Home',          idx: 0),
            item(icon: Icons.event_note,     label: 'Plan',          idx: 1),
            item(icon: Icons.fitness_center, label: 'Workouts',      idx: 2),
            item(icon: Icons.list_alt,       label: 'Übungen',       idx: 3),
            item(icon: Icons.bar_chart,      label: 'Stats',         idx: 4),
            item(icon: Icons.book,           label: 'Tagebuch',      idx: 5),
            const Divider(),
            item(icon: Icons.settings,       label: 'Einstellungen', idx: 6),
          ],
        ),
      ),
    );
  }
}
