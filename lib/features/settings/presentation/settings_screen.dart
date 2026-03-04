import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:puked/services/update_service.dart';
import 'package:puked/features/auth/providers/auth_provider.dart';
import 'package:puked/features/auth/presentation/login_screen.dart';
import 'package:puked/features/recording/presentation/vehicle_info_screen.dart';
import 'package:puked/services/pocketbase_service.dart';
import 'package:puked/common/utils/i18n.dart';
import 'package:puked/common/widgets/brand_logo.dart';
import 'package:puked/features/settings/presentation/changelog_screen.dart';
import '../providers/settings_provider.dart';

// 版本信息 Provider
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(authProvider.notifier).refreshUserFromServer();
      }
    });

    final settings = r
         ef.watch(settingsProvider);
    final auth = ref.watch(authProvider);
nal i18n = ref.watch(i18nProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final cloudAvatarUrl = ref.watch(pbServiceProvider).currentAvatarUrl;

    // 名字显示逻辑：优先显示本地昵称，其次显示云端名字，最后显示默认
    final displayName = settings.nickname ?? auth.user?.getStringValue('name') ?? i18n.t('user');

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('settings')),
      ),
      body: SafeArea(
    
   
   ,
  
        left: true,
        right: true,
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ListView(
            children: [
              _buildSectionHeader(context, i18n.t('account')),
              if (!auth.isAuthenticated)
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(i18n.t('login')),
                  subtitle: Text(i18n.t('login_to_sync')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showAuthPage(context);
                  },
                )
              else
                ListTile(
                  // 头像区域 (Web 平台简化)
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: cloudAvatarUrl != null && cloudAvatarUrl.isNotEmpty
                        ? NetworkImage(cloudAvatarUrl)
                : null,
                    child: cloudAvatarUrl == null || cloudAvatarUrl.isEmpty
                        ? Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer)
                        : null,
                  ),
                  // 名字区域
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (auth.isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA500),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.user?.getStringValue('email') ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (auth.isSuperUser)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "SuperUser / Admin",
                            style: TextStyle(
                             fontSize: 9,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await Future.wait([
                        ref.read(authProvider.notifier).logout(),
                        ref
                            .read(settingsProvider.notifier)
                            .clearVehicleSettings(),
                      ]);
                    },
                    child: Text(i18n.t('logout'),
                        style: const TextStyle(color: Colors.red)),
                  ),
                ),

              const Divider(),

              // 账号关联的智驾设置
              if (auth.isAuthenticated) ...[
                _buildSectionHeader(context, i18n.t('my_car')),
                ListTile(
                  leading: BrandLogo(
                    brandName: settings.brand,
                    showBackground: true,
                  ),
                  title: Row(
                    children: [
                      Text(
                        settings.brand ?? i18n.t('my_car'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      _buildVerificationBadge(context, auth, i18n),
                    ],
                  ),
                  subtitle: Text(
                    [
                      if (settings.carModel != null &&
                          settings.carModel!.isNotEmpty)
                        settings.carModel,
                      if (settings.softwareVersion != null &&
                          settings.softwareVersion!.isNotEmpty)
                        settings.softwareVersion,
                    ].join(' • ').isEmpty
                        ? i18n.t('model_hint')
                        : [
                            if (settings.carModel != null &&
                                settings.carModel!.isNotEmpty)
                              settings.carModel,
                            if (settings.softwareVersion != null &&
                                settings.softwareVersion!.isNotEmpty)
                              settings.softwareVersion,
                          ].join(' • '),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VehicleInfoScreen(
                          isSettingsMode: true,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
              ],

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
                trailing: 
       settings.themeMode == ThemeMode.
           light
 ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => ref
                    .re
       ad(settingsProvider.n
       otifier)
       
                    .setThemeMode(ThemeMode.light),
              ),
              ListTil        title: Text(i18n.t('the          trailing: settings.themeMode == ThemeMode.dark
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

                            ,
                          
              const Divider(),
                            
                           ,
                          

                             
                                    
                                   ,
                                  
                                 
              // 自动打标敏感度
                                  
                                 
                                    ,
                                  ,
                                
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
                                  ,
                                
                context,
                ref,
                i18n.t('sensitivity_medium'),
                'Accel > 2.4m/s², Brake > 2.8m/s²',
                SensitivityLevel.medium,
                settings.sensitivity,
              ),
              _buildSensitivityTile(
                context,
                                  
                                 
                                 ,
                                
                ref,
                i18n.t('sensitivity_high'),
                'Accel > 1.8m/s², Brake > 2.1m/s²',
                SensitivityLevel.high,
                settings.sensitivity,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  i18n.t('sensitivity_tip'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),

              const Divider(),

              // 关于与更新
              _buildSectionHeader(context, i18n.t('about')),
              ListTile(
                title: Text(
                  i18n.t('current_version'
                            ),,
                          
                  style: const TextStyle(),
                ),
                trailing: packageInfo.when(
                  data: (info) => Text(
                    'v${info.version}',
                    style: con TextStyle(col
                             or: Colors.g,
                            rey),
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
              ListTile(
                title: Text(
                  i18n.t('check_update'),
                  style: const TextStyle(),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  UpdateService.checkUpdate(context, showNoUpdate: true);
                },
              ),

              // Footer
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '可乐杯物理模拟器 v3.0.0',
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
        ),
      ),
    );
  }

  void _showAuthPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
                                        ,
                                      

  Widget _buildSensitivityTile(
      BuildContext context,
      WidgetRef ref,
      String title,
      String subtitle,
      SensitivityLevel level,
      SensitivityLevel current) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(),
      ),
      subtitle: Text(
        style: TextStyle(,
                                  
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: current == level
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () => ref.read(settgsProvider.notifier).setSensitivity(level),
    );,
                              
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

                      
  Widget _buildVerificionBadge(,
                    
      BuildContext context, AuthState auth, dynamic i18n) {
    final status = auth.user?.getStringValue('audit_status') ?? '';

    Color bgColor;
    String text;

    switch (status) {
      case 'approved':
        bgColor = Colors.green.shade600;
        text = i18n.t('approved');
        break;
      case 'pending':
        bgColor = Colors.orange.shade600;
        text = i18n.t('pending');
        break;
      case 'rejected':
        bgColor = Colors.red.shade600;
        text = i18n.t('rejected');
        break;
      default:
        bgColor = Colors.grey.shade500;
        text = i18n.t('unverified');
    }

    return Container(
      padding: const E    dgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecor    ation(
        color: bgColor,    
        borderRadius:     BorderRadius.circular(4),
      ),    
      child: Text(    
        text,    
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

                           
                  
                 ,
                
                    ,
                  ,
  
   
   ,
  
