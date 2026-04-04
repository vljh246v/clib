import 'package:flutter/material.dart';
import 'package:clib/main.dart';
import 'package:clib/theme/design_tokens.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('테마')),
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
                  if (v != null) themeModeNotifier.value = v;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ThemeMode>(
                      secondary: Icon(Icons.phone_android,
                          color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('시스템 설정'),
                      subtitle: const Text('기기 설정에 따라 자동 전환'),
                      value: ThemeMode.system,
                    ),
                    Divider(height: 1, indent: Spacing.lg, color: theme.dividerColor),
                    RadioListTile<ThemeMode>(
                      secondary: Icon(Icons.dark_mode_outlined,
                          color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('다크 모드'),
                      value: ThemeMode.dark,
                    ),
                    Divider(height: 1, indent: Spacing.lg, color: theme.dividerColor),
                    RadioListTile<ThemeMode>(
                      secondary: Icon(Icons.light_mode_outlined,
                          color: theme.colorScheme.onSurfaceVariant),
                      title: const Text('라이트 모드'),
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
