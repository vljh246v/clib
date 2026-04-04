import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/main.dart';
import 'package:clib/services/database_service.dart';
import 'package:clib/theme/design_tokens.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l.theme)),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          return Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: Radii.borderLg,
                boxShadow: AppShadows.card(isDark),
              ),
              child: RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (v) {
                  if (v != null) {
                    themeModeNotifier.value = v;
                    DatabaseService.saveThemeMode(v);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ThemeMode>(
                      secondary: Icon(Icons.phone_android,
                          color: theme.colorScheme.onSurfaceVariant),
                      title: Text(l.systemSettings),
                      subtitle: Text(l.systemSettingsSubtitle),
                      value: ThemeMode.system,
                    ),
                    Divider(height: 1, indent: Spacing.lg, color: theme.dividerColor),
                    RadioListTile<ThemeMode>(
                      secondary: Icon(Icons.dark_mode_outlined,
                          color: theme.colorScheme.onSurfaceVariant),
                      title: Text(l.darkMode),
                      value: ThemeMode.dark,
                    ),
                    Divider(height: 1, indent: Spacing.lg, color: theme.dividerColor),
                    RadioListTile<ThemeMode>(
                      secondary: Icon(Icons.light_mode_outlined,
                          color: theme.colorScheme.onSurfaceVariant),
                      title: Text(l.lightMode),
                      value: ThemeMode.light,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
