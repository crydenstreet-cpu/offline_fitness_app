import 'package:flutter/material.dart';
import 'calendar_month.dart';
import 'planner.dart';
import 'plan_list.dart';

/// Tab-Container für den Bereich "Plan":
/// - Kalender (deine bestehende Monatsansicht)
/// - Liste (optimierte, kartenartige Tagesliste)
class PlanHubScreen extends StatelessWidget {
  const PlanHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 1,
            child: SafeArea(
              bottom: false,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                tabs: const [
                  Tab(text: 'Kalender'),
                  Tab(text: 'Liste'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            CalendarMonthScreen(), // deine Kalenderübersicht
            PlanListScreen(),      // NEU: Listenansicht
          ],
        ),
      ),
    );
  }
}
