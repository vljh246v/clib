import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/screens/label_management_screen.dart';
import 'package:clib/screens/onboarding_screen.dart';
import 'package:clib/screens/theme_settings_screen.dart';
import 'package:clib/main.dart';
import 'package:clib/theme/design_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Text(
          l.settings,
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: Spacing.xxl),
        // 그룹 컨테이너
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: Radii.borderLg,
            boxShadow: AppShadows.card(isDark),
          ),
          child: Column(
            children: [
              _buildItem(
                context,
                theme: theme,
                icon: Icons.label_outline,
                iconColor: theme.colorScheme.secondary,
                title: l.labelManagement,
                subtitle: l.labelManagementSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LabelManagementScreen()),
                ),
              ),
              Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor),
              _buildItem(
                context,
                theme: theme,
                icon: Icons.palette_outlined,
                iconColor: theme.colorScheme.primary,
                title: l.theme,
                subtitle: _themeModeLabel(themeModeNotifier.value, l),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ThemeSettingsScreen()),
                ),
              ),
              Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor),
              _buildItem(
                context,
                theme: theme,
                icon: Icons.help_outline_rounded,
                iconColor: theme.colorScheme.secondary,
                title: l.howToUse,
                subtitle: l.howToUseSubtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const OnboardingScreen(isGuideMode: true)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: Spacing.xs, horizontal: Spacing.lg),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: Radii.borderSm,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
      )),
      subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
      trailing: Icon(Icons.chevron_right,
          size: 18, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  String _themeModeLabel(ThemeMode mode, AppLocalizations l) {
    return switch (mode) {
      ThemeMode.system => l.systemSettings,
      ThemeMode.dark => l.darkMode,
      ThemeMode.light => l.lightMode,
    };
  }
}
