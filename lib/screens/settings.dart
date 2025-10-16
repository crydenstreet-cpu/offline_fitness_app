// lib/screens/settings.dart
import 'package:flutter/material.dart';
import '../ui/design.dart' as ui;
import '../utils/backup.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ui.AppScaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const ui.SectionHeader('Darstellung'),

          ui.AppCard(
            child: Row(
              children: [
                const Icon(Icons.brightness_6_rounded),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Theme (Hell/Dunkel)',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                SegmentedButton<Brightness>(
                  segments: const [
                    ButtonSegment(value: Brightness.light, label: Text('Hell')),
                    ButtonSegment(value: Brightness.dark, label: Text('Dunkel')),
                  ],
                  selected: {isDark ? Brightness.dark : Brightness.light},
                  onSelectionChanged: (sel) {
                    final wantDark = sel.first == Brightness.dark;
                    // Systemweite Theme-Umstellung via Inherited ThemeMode (einfachste Variante):
                    // => wir nutzen MaterialApp.themeMode über Navigator state
                    // Hier: wir triggern eine Route-Neuaufbau-Callback, den du in main.dart gesetzt hast.
                    _ThemeSwitcher.of(context)?.setDark(wantDark);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const ui.SectionHeader('Backup'),

          ui.AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daten-Backup', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                    'Exportiere alle lokalen Daten (Übungen, Workouts, Sätze, Journal, Plan) '
                    'als JSON-Datei. Beim Import wird der aktuelle Datenbestand ersetzt.'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ui.AppButton3D(
                        label: 'Backup exportieren',
                        icon: Icons.file_upload,
                        onPressed: () async {
                          try {
                            await BackupService.exportToJsonFile(alsoShare: true);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup exportiert.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Fehler beim Export: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ui.AppButton3D(
                        label: 'Backup importieren',
                        icon: Icons.file_download,
                        filled: false,
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Backup importieren'),
                              content: const Text(
                                  'Achtung: Der aktuelle Datenbestand wird ersetzt. '
                                  'Fortfahren?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Abbrechen'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Importieren'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;

                          try {
                            await BackupService.importFromPickedJson(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup importiert.')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Fehler beim Import: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const ui.SectionHeader('Infos'),
          ui.AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Offline Fitness App', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text('Alle Daten lokal. Backup/Restore möglich.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kleiner Inherited-Helper, damit Settings das Theme umschalten kann.
/// In main.dart registrieren wir ihn um MaterialApp.themeMode zu ändern.
class _ThemeSwitcher extends InheritedWidget {
  final void Function(bool dark) setDark;
  const _ThemeSwitcher({required this.setDark, required super.child, super.key});

  static _ThemeSwitcher? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ThemeSwitcher>();

  @override
  bool updateShouldNotify(covariant _ThemeSwitcher oldWidget) => false;
}
