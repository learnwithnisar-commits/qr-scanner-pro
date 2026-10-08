import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/history_service.dart';
import '../services/settings_service.dart';
import 'generator_screen.dart';
import 'history_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

/// Main shell with bottom navigation.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _titles = ['Scan', 'Create', 'History', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final history = context.watch<HistoryService>();

    final pages = [
      const ScannerScreen(),
      const GeneratorScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: _index == 0
          ? null
          : AppBar(
              title: Text(_titles[_index],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                if (_index == 3)
                  IconButton(
                    tooltip: 'Toggle theme',
                    icon: Icon(switch (settings.themeMode) {
                      'light' => Icons.light_mode_rounded,
                      'dark' => Icons.dark_mode_rounded,
                      _ => Icons.brightness_auto_rounded,
                    }),
                    onPressed: () {
                      final next = switch (settings.themeMode) {
                        'light' => 'dark',
                        'dark' => 'system',
                        _ => 'light',
                      };
                      settings.setThemeMode(next);
                    },
                  ),
              ],
            ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2_rounded),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: history.items.isNotEmpty,
              label: Text('${history.items.length}'),
              child: const Icon(Icons.history_outlined),
            ),
            selectedIcon: const Icon(Icons.history_rounded),
            label: 'History',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
