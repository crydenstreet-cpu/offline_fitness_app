// lib/screens/settings.dart
import 'package:flutter/material.dart';
import 'package:offline_fitness_app/theme/theme_controller.dart';
import 'package:offline_fitness_app/ui/design.dart' as ui;

/// Fallback-Header direkt in dieser Datei,
/// damit es keine Abhängigkeit zu ui.SectionHeader gibt.
class SettingsSectionHeader extends StatelessWidget {
  final String text;
  const SettingsSectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.brightness == Brightness.light
        ? const Color(0xFF5E6676) // textLightMuted
        : const Color(0xFFB7BDCA); // textDarkMuted
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

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
          const SettingsSectionHeader('Darstellung'),
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
          const SettingsSectionHeader('Infos'),
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
