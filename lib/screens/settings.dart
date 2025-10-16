// lib/screens/settings.dart
import 'package:flutter/material.dart';
import 'package:offline_fitness_app/theme/theme_controller.dart';
import 'package:offline_fitness_app/ui/design.dart' as ui;

class SettingsScreen extends StatelessWidget {
  final ThemeController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ui.AppScaffold(
      appBar: AppBar(title: const Text('⚙️ Einstellungen')),
      body: ListView(
        children: [
          // Abschnitt: Darstellung
          ui.SectionHeader('Darstellung'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: controller,
            builder: (context, mode, _) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.system,
                    groupValue: mode,
                    title: const Text('System'),
                    subtitle: const Text('Folgt der Geräte-Einstellung'),
                    onChanged: (m) => controller.setMode(m!),
                  ),
                  const Divider(height: 0),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: mode,
                    title: const Text('Hell'),
                    onChanged: (m) => controller.setMode(m!),
                  ),
                  const Divider(height: 0),
                  RadioListTile<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: mode,
                    title: const Text('Dunkel'),
                    onChanged: (m) => controller.setMode(m!),
                  ),
                ],
              ),
            ),
          ),

          // Abschnitt: Infos
          ui.SectionHeader('Infos'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const ListTile(
              title: Text('App-Design'),
              subtitle: Text('Grau/Schwarz/Rot, Material 3, Gradient-Background'),
              trailing: Icon(Icons.color_lens),
            ),
          ),
        ],
      ),
    );
  }
}
