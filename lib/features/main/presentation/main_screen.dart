import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puked/features/cola_simulator/presentation/cola_simulator_screen.dart';
import 'package:puked/features/history/presentation/history_screen.dart';
import 'package:puked/features/recording/presentation/recording_screen.dart';
import 'package:puked/features/settings/presentation/settings_screen.dart';
import 'package:puked/common/utils/i18n.dart';

/// 主页面
/// 包含四个标签页：行程记录、可乐杯、历史记录、设置
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  // 使用 IndexedStack 保持页面状态
  final List<Widget> _screens = const [
    RecordingScreen(),      // 行程记录页面
    ColaSimulatorScreen(),  // 可乐杯模拟器页面
    HistoryScreen(),        // 历史记录页面
    SettingsScreen(),       // 设置页面
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
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route),
            label: i18n.t('start_trip'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_drink_outlined),
            selectedIcon: const Icon(Icons.local_drink),
            label: '可乐杯',
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: i18n.t('history'),
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
