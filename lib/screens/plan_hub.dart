import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ui/design.dart';
import 'calendar_month.dart';
import 'plan_list.dart';

class PlanHubScreen extends StatefulWidget {
  const PlanHubScreen({super.key});
  @override
  State<PlanHubScreen> createState() => _PlanHubScreenState();
}

class _PlanHubScreenState extends State<PlanHubScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.calendar_month), text: 'Monat'),
            Tab(icon: Icon(Icons.today), text: 'Heute'),
          ],
        ),
      ),
      body: const DefaultTabController(
        length: 2,
        child: TabBarView(
          children: [
            CalendarMonthScreen(),
            _TodayPlanTab(),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanTab extends StatefulWidget {
  const _TodayPlanTab({super.key});
  @override
  State<_TodayPlanTab> createState() => _TodayPlanTabState();
}

class _TodayPlanTabState extends State<_TodayPlanTab> {
  DateTime _date = DateTime.now();
  DateTime get _ymd => DateTime(_date.year, _date.month, _date.day);
  void _shift(int days) => setState(() => _date = _ymd.add(Duration(days: days)));

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, d. MMMM', 'de_DE').format(_ymd);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(child: Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)))),
              IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: PlanListScreen(date: _ymd)),
      ],
    );
  }
}
