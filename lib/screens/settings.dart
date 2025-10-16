// lib/screens/settings.dart
import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../ui/design.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('⚙️ Einstellungen')),
      body: ListView(
        children: [
          const SectionHeader('Darstellung'),
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

          const SectionHeader('Infos'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: const Text('App-Design'),
              subtitle: const Text('Grau/Schwarz/Rot, Material 3, Gradient-Background'),
              trailing: const Icon(Icons.color_lens),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
