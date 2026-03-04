import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:puked/features/settings/presentation/changelog_screen.dart';
import '../providers/settings_provider.dart';
import 'package:puked/common/utils/i18n.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final i18n = ref.watch(i18nProvider);
    final packageInfo = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('settings')),
      ),
      body: ListView(
        children: [
          // 全屏模式
          _buildSectionHeader(context, '显示设置'),
          SwitchListTile(
            title: const Text('全屏模式'),
            subtitle: const Text('隐藏浏览器地址栏和工具栏'),
            value: settings.fullscreenMode,
            onChanged: (value) async {
              ref.read(settingsProvider.notifier).setFullscreenMode(value);
              if (value) {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
              } else {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              }
            },
            secondary: Icon(
              settings.fullscreenMode ? Icons.fullscreen : Icons.fullscreen_exit,
            ),
          ),

          const Divider(),

          // 主题设置
          _buildSectionHeader(context, i18n.t('theme')),
          ListTile(
            title: Text(i18n.t('theme_auto')),
            trailing: settings.themeMode == ThemeMode.system
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .setThemeMode(ThemeMode.system),
          ),
          ListTile(
            title: Text(i18n.t('theme_light')),
            trailing: settings.themeMode == ThemeMode.light
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .setThemeMode(ThemeMode.light),
          ),
          ListTile(
            title: Text(i18n.t('theme_dark')),
            trailing: settings.themeMode == ThemeMode.dark
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .setThemeMode(ThemeMode.dark),
          ),

          const Divider(),

          // 语言设置
          _buildSectionHeader(context, i18n.t('language')),
          ListTile(
            title: Text(i18n.t('chinese')),
            trailing: settings.locale?.languageCode == 'zh'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .setLocale(const Locale('zh')),
          ),
          ListTile(
            title: Text(i18n.t('english')),
            trailing: settings.locale?.languageCode == 'en'
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () => ref
                .read(settingsProvider.notifier)
                .setLocale(const Locale('en')),
          ),

          const Divider(),

          // 灵敏度设置
          _buildSectionHeader(context, i18n.t('sensitivity')),
          _buildSensitivityTile(
            context,
            ref,
            i18n.t('sensitivity_low'),
            'Accel > 3.0m/s², Brake > 3.5m/s²',
            SensitivityLevel.low,
            settings.sensitivity,
          ),
          _buildSensitivityTile(
            context,
            ref,
            i18n.t('sensitivity_medium'),
            'Accel > 2.4m/s², Brake > 2.8m/s²',
            SensitivityLevel.medium,
            settings.sensitivity,
          ),
          _buildSensitivityTile(
            context,
            ref,
            i18n.t('sensitivity_high'),
            'Accel > 1.8m/s², Brake > 2.1m/s²',
            SensitivityLevel.high,
            settings.sensitivity,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              i18n.t('sensitivity_tip'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),

          const Divider(),

          // 关于
          _buildSectionHeader(context, i18n.t('about')),
          ListTile(
            title: Text(i18n.t('current_version')),
            trailing: packageInfo.when(
              data: (info) => Text(
                'v${info.version}',
                style: const TextStyle(color: Colors.grey),
              ),
              loading: () => const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Text(i18n.t('unknown')),
            ),
          ),
          ListTile(
            title: const Text('更新日志'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangelogScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Cola Cup Physics Simulator v3.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSensitivityTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    SensitivityLevel level,
    SensitivityLevel current,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing:
          current == level ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () =>
          ref.read(settingsProvider.notifier).setSensitivity(level),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
