import 'package:flutter/material.dart';
import 'package:novelverse/Theme/theme_controller.dart';
import 'package:provider/provider.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Chế độ tối (Dark Mode)'),
            value: controller.isDark,
            onChanged: (v) => context.read<ThemeController>().setDarkEnabled(v),
            secondary: const Icon(Icons.brightness_6),
          ),
          const Divider(height: 1),
          // Các mục cài đặt khác của bạn...
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Giới thiệu'),
            subtitle: const Text('Phiên bản 1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
