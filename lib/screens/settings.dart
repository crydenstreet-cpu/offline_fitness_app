import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeController controller;
  const SettingsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const _SectionHeader('Darstellung'),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: controller.mode,
                  onChanged: (v) => controller.setMode(v!),
                  title: const Text('System'),
                  subtitle: const Text('Automatisch Hell/Dunkel je nach Geräte-Einstellung'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: controller.mode,
                  onChanged: (v) => controller.setMode(v!),
                  title: const Text('Hell'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: controller.mode,
                  onChanged: (v) => controller.setMode(v!),
                  title: const Text('Dunkel'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const _SectionHeader('Info'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Offline Fitness App'),
              subtitle: const Text('Theme-Umschaltung gespeichert auf diesem Gerät'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
