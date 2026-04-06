import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/screens/label_management_screen.dart';
import 'package:clib/screens/onboarding_screen.dart';
import 'package:clib/screens/theme_settings_screen.dart';
import 'package:clib/services/auth_service.dart';
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
        // 계정 섹션
        ValueListenableBuilder<User?>(
          valueListenable: authStateNotifier,
          builder: (context, user, _) {
            return _AccountSection(
              user: user,
              theme: theme,
              isDark: isDark,
              l: l,
            );
          },
        ),
        const SizedBox(height: Spacing.lg),
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

class _AccountSection extends StatelessWidget {
  final User? user;
  final ThemeData theme;
  final bool isDark;
  final AppLocalizations l;

  const _AccountSection({
    required this.user,
    required this.theme,
    required this.isDark,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: Radii.borderLg,
        boxShadow: AppShadows.card(isDark),
      ),
      padding: const EdgeInsets.all(Spacing.lg),
      child: user == null ? _buildLoggedOut(context) : _buildLoggedIn(context),
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: Radii.borderSm,
              ),
              child: Icon(Icons.person_outline,
                  size: 18, color: theme.colorScheme.secondary),
            ),
            const SizedBox(width: Spacing.md),
            Text(l.account, style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          l.loginSubtitle,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        _SignInButton(
          onTap: () => _handleSignIn(context, AuthService.signInWithGoogle),
          icon: Icons.g_mobiledata_rounded,
          label: l.signInWithGoogle,
          theme: theme,
        ),
        const SizedBox(height: Spacing.sm),
        _SignInButton(
          onTap: () => _handleSignIn(context, AuthService.signInWithApple),
          icon: Icons.apple_rounded,
          label: l.signInWithApple,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildLoggedIn(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage:
              user!.photoURL != null ? NetworkImage(user!.photoURL!) : null,
          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
          child: user!.photoURL == null
              ? Icon(Icons.person, size: 20, color: theme.colorScheme.secondary)
              : null,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user!.displayName ?? user!.email ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (user!.email != null)
                Text(
                  user!.email!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => _handleSignOut(context),
          child: Text(l.signOut,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _handleSignIn(
    BuildContext context,
    Future<dynamic> Function() signInMethod,
  ) async {
    try {
      await signInMethod();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.loginFailed)),
        );
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.signOutConfirm),
        content: Text(l.signOutDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.signOut,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService.signOut();
    }
  }
}

class _SignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final ThemeData theme;

  const _SignInButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(borderRadius: Radii.borderMd),
        ),
      ),
    );
  }
}
