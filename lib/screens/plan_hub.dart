// lib/screens/plan_hub.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:offline_fitness_app/ui/design.dart' as ui;
import 'calendar_month.dart';
import 'plan_list.dart';

/// ---------------------------
/// PlanHubScreen – Tab-Container für Monat & Heute
/// mit AppScaffold (3D-Design, Gradient, Dark/Light)
/// ---------------------------
class PlanHubScreen extends StatefulWidget {
  const PlanHubScreen({super.key});

  @override
  State<PlanHubScreen> createState() => _PlanHubScreenState();
}

class _PlanHubScreenState extends State<PlanHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return ui.AppScaffold(
      appBar: AppBar(
        title: const Text('🗓️ Plan'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Monat'),
            Tab(icon: Icon(Icons.today), text: 'Heute'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          CalendarMonthScreen(),
          _TodayPlanTab(), // liefert PlanList + Datum-Navigation
        ],
      ),
    );
  }
}

/// ---------------------------
/// Heute-Ansicht – PlanListScreen(date)
/// mit Tagesnavigation (Gestern/Heute/Morgen)
/// ---------------------------
class _TodayPlanTab extends StatefulWidget {
  const _TodayPlanTab({super.key});

  @override
  State<_TodayPlanTab> createState() => _TodayPlanTabState();
}

class _TodayPlanTabState extends State<_TodayPlanTab> {
  DateTime _date = DateTime.now();

  DateTime get _ymd => DateTime(_date.year, _date.month, _date.day);

  void _shift(int days) => setState(() {
        _date = _ymd.add(Duration(days: days));
      });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, d. MMMM', 'de_DE').format(_ymd);
    final formatted = label[0].toUpperCase() + label.substring(1);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Gestern',
              ),
              Expanded(
                child: Center(
                  child: Text(
                    formatted,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Morgen',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: PlanListScreen(date: _ymd),
        ),
      ],
    );
  }
}
