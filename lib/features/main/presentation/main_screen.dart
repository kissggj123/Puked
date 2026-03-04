import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puked/features/cola_simulator/presentation/cola_simulator_screen.dart';
import 'package:puked/features/settings/presentation/settings_screen.dart';
import 'package:puked/common/utils/i18n.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ColaSimulatorScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.local_drink_outlined),
            selectedIcon: const Icon(Icons.local_drink),
            label: 'Cola Cup',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: i18n.t('settings'),
          ),
        ],
      ),
    );
  }
}
