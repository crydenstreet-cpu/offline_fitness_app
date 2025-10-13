import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'calendar_month.dart';
import 'plan_list.dart';

/// Tab-Container: Monat & Heute.
/// Fix: PlanListScreen bekommt jetzt immer ein Datum übergeben.
class PlanHubScreen extends StatefulWidget {
  const PlanHubScreen({super.key});

  @override
  State<PlanHubScreen> createState() => _PlanHubScreenState();
}

class _PlanHubScreenState extends State<PlanHubScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: 'Monat'),
              Tab(icon: Icon(Icons.today), text: 'Heute'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CalendarMonthScreen(),
            _TodayPlanTab(), // ⬅️ liefert PlanListScreen mit Datum
          ],
        ),
      ),
    );
  }
}

/// Einfache „Heute“-Ansicht mit Datum-Navigation (gestern/heute/morgen).
class _TodayPlanTab extends StatefulWidget {
  const _TodayPlanTab({super.key});

  @override
  State<_TodayPlanTab> createState() => _TodayPlanTabState();
}

class _TodayPlanTabState extends State<_TodayPlanTab> {
  DateTime _date = DateTime.now();

  DateTime get _ymd =>
      DateTime(_date.year, _date.month, _date.day); // normalisiert auf 00:00

  void _shift(int days) {
    setState(() => _date = _ymd.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, d. MMMM', 'de_DE').format(_ymd);

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
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
