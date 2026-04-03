import 'package:flutter/material.dart';
import 'package:clib/main.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('테마')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          return RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (v) {
              if (v != null) themeModeNotifier.value = v;
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('시스템 설정'),
                  subtitle: const Text('기기 설정에 따라 자동 전환'),
                  value: ThemeMode.system,
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<ThemeMode>(
                  title: const Text('다크 모드'),
                  value: ThemeMode.dark,
                ),
                const Divider(height: 1, indent: 16),
                RadioListTile<ThemeMode>(
                  title: const Text('라이트 모드'),
                  value: ThemeMode.light,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
