import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clib/blocs/auth/auth_cubit.dart';
import 'package:clib/blocs/auth/auth_state.dart';
import 'package:clib/blocs/theme/theme_cubit.dart';
import 'package:clib/l10n/app_localizations.dart';
import 'package:clib/screens/label_management_screen.dart';
import 'package:clib/screens/onboarding_screen.dart';
import 'package:clib/screens/theme_settings_screen.dart';
import 'package:clib/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:clib/theme/design_tokens.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onShowGuide;

  const SettingsScreen({super.key, this.onShowGuide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    final themeMode = context.watch<ThemeCubit>().state;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Text(
          l.settings,
          style: theme.textTheme.displaySmall,
        ),
        const SizedBox(height: Spacing.xxl),
        // 계정 섹션
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            // 첫 authStateChanges 이벤트 수신 전에는 로그인/로그아웃 분기 보류
            if (!state.isInitialized) {
              return const SizedBox.shrink();
            }
            return _AccountSection(
              user: state.user,
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
                subtitle: _themeModeLabel(themeMode, l),
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
                onTap: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingScreen(isGuideMode: true)),
                  ).then((completed) {
                    if (completed == true) {
                      onShowGuide?.call();
                    }
                  });
                },
              ),
              Divider(
                  height: 1,
                  indent: 56,
                  color: theme.dividerColor),
              _buildItem(
                context,
                theme: theme,
                icon: Icons.shield_outlined,
                iconColor: theme.colorScheme.onSurfaceVariant,
                title: l.privacyPolicy,
                subtitle: l.privacyPolicySubtitle,
                onTap: () => launchUrl(
                    Uri.parse('https://vljh246v.github.io/clib-support/')),
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
          onTap: () => _handleSignIn(
            context,
            () => context.read<AuthCubit>().signInWithGoogle(),
          ),
          icon: Icons.g_mobiledata_rounded,
          label: l.signInWithGoogle,
          theme: theme,
        ),
        const SizedBox(height: Spacing.sm),
        _SignInButton(
          onTap: () => _handleSignIn(
            context,
            () => context.read<AuthCubit>().signInWithApple(),
          ),
          icon: Icons.apple_rounded,
          label: l.signInWithApple,
          theme: theme,
        ),
        const SizedBox(height: Spacing.md),
        Center(
          child: GestureDetector(
            onTap: () => launchUrl(
                Uri.parse('https://vljh246v.github.io/clib-support/')),
            child: Text.rich(
              TextSpan(
                text: l.loginPolicyAgreement.split(l.privacyPolicy).first,
                children: [
                  TextSpan(
                    text: l.privacyPolicy,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: l.loginPolicyAgreement.split(l.privacyPolicy).last,
                  ),
                ],
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoggedIn(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
                  user!.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              backgroundColor:
                  theme.colorScheme.secondary.withValues(alpha: 0.1),
              child: user!.photoURL == null
                  ? Icon(Icons.person,
                      size: 20, color: theme.colorScheme.secondary)
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
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _handleDeleteAccount(context),
            child: Text(l.deleteAccount,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                )),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignIn(
    BuildContext context,
    Future<void> Function() signInMethod,
  ) async {
    try {
      await signInMethod();
    } catch (e, st) {
      logError('로그인 실패: $e', e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.loginFailed}: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteAccountConfirm),
        content: Text(l.deleteAccountDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteAccount,
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await context.read<AuthCubit>().deleteAccount();
    } catch (e) {
      logError('계정 삭제 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().signOut();
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
