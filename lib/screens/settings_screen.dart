import 'package:flutter/material.dart';
import 'package:clib/screens/label_management_screen.dart';
import 'package:clib/screens/theme_settings_screen.dart';
import 'package:clib/main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '설정',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _buildItem(
          context,
          icon: Icons.label_outline,
          title: '라벨 관리',
          subtitle: '라벨 추가, 수정, 삭제 및 알림 설정',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LabelManagementScreen()),
          ),
        ),
        const Divider(height: 1),
        _buildItem(
          context,
          icon: Icons.palette_outlined,
          title: '테마',
          subtitle: _themeModeLabel(themeModeNotifier.value),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
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
