import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const ListTile(title: Text('Darstellung')),
          RadioListTile<ThemeMode>(
            title: const Text('System'),
            value: ThemeMode.system,
            groupValue: theme.mode,
            onChanged: (v) => theme.setMode(v ?? ThemeMode.system),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Hell'),
            value: ThemeMode.light,
            groupValue: theme.mode,
            onChanged: (v) => theme.setMode(v ?? ThemeMode.light),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dunkel'),
            value: ThemeMode.dark,
            groupValue: theme.mode,
            onChanged: (v) => theme.setMode(v ?? ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}
