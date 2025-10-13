import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final current = themeController.mode;

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Einstellungen')),
      body: ListView(
        children: [
          const ListTile(title: Text('Darstellung', style: TextStyle(fontWeight: FontWeight.bold))),
          RadioListTile<ThemeMode>(
            title: const Text('Systemstandard'),
            value: ThemeMode.system,
            groupValue: current,
            onChanged: themeController.setMode,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Hell'),
            value: ThemeMode.light,
            groupValue: current,
            onChanged: themeController.setMode,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dunkel'),
            value: ThemeMode.dark,
            groupValue: current,
            onChanged: themeController.setMode,
          ),
        ],
      ),
    );
  }
}
