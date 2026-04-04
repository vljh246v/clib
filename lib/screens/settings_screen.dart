import 'package:flutter/material.dart';
import 'package:clib/screens/label_management_screen.dart';
import 'package:clib/screens/theme_settings_screen.dart';
import 'package:clib/main.dart';
import 'package:clib/theme/design_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Text(
          '설정',
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
                title: '라벨 관리',
                subtitle: '라벨 추가, 수정, 삭제 및 알림 설정',
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
                title: '테마',
                subtitle: _themeModeLabel(themeModeNotifier.value),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ThemeSettingsScreen()),
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

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => '시스템 설정',
      ThemeMode.dark => '다크 모드',
      ThemeMode.light => '라이트 모드',
    };
  }
}
