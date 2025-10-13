import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'theme/theme_controller.dart';
import 'screens/dashboard.dart';
import 'screens/plan_hub.dart';
import 'screens/workouts.dart';
import 'screens/exercises.dart';
import 'screens/stats.dart';
import 'screens/journal.dart';
import 'screens/settings.dart'; // neu

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');
  final themeController = await ThemeController.init();
  runApp(ChangeNotifierProvider.value(
    value: themeController,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Fitness App',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: theme.mode,
      home: const _NavWithDrawer(),
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
    DashboardScreen(),
    PlanHubScreen(),
    WorkoutsScreen(),
    ExercisesScreen(),
    StatsScreen(),
    JournalScreen(),
  ];

  String get _title {
    switch (_index) {
      case 0: return '🏁 Home';
      case 1: return '🗓️ Plan';
      case 2: return '💪 Workouts';
      case 3: return '📋 Übungen';
      case 4: return '📈 Stats';
      case 5: return '📔 Tagebuch';
      default: return 'App';
    }
  }

  void _go(int i) {
    setState(() => _index = i);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      drawer: _AppDrawer(selected: _index, onSelect: _go),
      body: SafeArea(child: _pages[_index]),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _AppDrawer({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final selColor = Theme.of(context).colorScheme.primary.withOpacity(0.12);

    Widget item({required IconData icon, required String label, required int idx}) {
      final isSel = selected == idx;
      return Material(
        color: isSel ? selColor : Colors.transparent,
        child: ListTile(
          leading: Icon(icon),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () {
            Navigator.pop(context);
            onSelect(idx);
          },
        ),
      );
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: const Text('Offline Fitness App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              subtitle: const Text('Alles an einem Ort'),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Divider(),
            item(icon: Icons.home, label: 'Home', idx: 0),
            item(icon: Icons.event_note, label: 'Plan', idx: 1),
            item(icon: Icons.fitness_center, label: 'Workouts', idx: 2),
            item(icon: Icons.list_alt, label: 'Übungen', idx: 3),
            item(icon: Icons.bar_chart, label: 'Stats', idx: 4),
            item(icon: Icons.book, label: 'Tagebuch', idx: 5),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Einstellungen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
