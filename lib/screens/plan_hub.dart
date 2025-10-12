// lib/screens/plan_hub.dart
import 'package:flutter/material.dart';
import 'calendar_month.dart';
import 'planner.dart';

class PlanHubScreen extends StatelessWidget {
  const PlanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🗓️ Plan'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kalender', icon: Icon(Icons.calendar_month)),
              Tab(text: 'Wochen-Planer', icon: Icon(Icons.view_week)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CalendarMonthScreen(),
            PlannerScreen(),
          ],
        ),
      ),
    );
  }
}
