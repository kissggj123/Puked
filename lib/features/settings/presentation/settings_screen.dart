import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:package_info_plus/package_info_plus.dart';
// 🟢 1. 引入 path_provider 用于获取 iPhone 永久文件目录
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:puked/services/update_service.dart';
import 'package:puked/features/auth/providers/auth_provider.dart';
import 'package:puked/features/auth/presentation/login_screen.dart';
import 'package:puked/features/recording/presentation/vehicle_info_screen.dart';
import 'package:puked/services/pocketbase_service.dart';
import 'package:puked/common/utils/i18n.dart';
import 'package:puked/common/widgets/brand_logo.dart';
import '../providers/settings_provider.dart';

// 版本信息 Provider
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // 🟢 2. 核心方法：将图片永久保存到 iPhone 文档目录
  Future<String?> _saveToPermanentStorage(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // 使用时间戳防止文件名冲突
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final savedPath = p.join(directory.path, fileName);
      
      // 复制文件到永久目录
      await File(sourcePath).copy(savedPath);
      return savedPath;
    } catch (e) {
      debugPrint('Error saving avatar locally: $e');
      return null;
    }
  }

  // 裁剪图片逻辑
  Future<void> _cropImage(BuildContext context, WidgetRef ref, String sourcePath) async {
    try {
      final i18n = ref.read(i18nProvider);
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        // 锁定 1:1 正方形
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: i18n.t('edit_avatar') ?? 'Edit Avatar',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: i18n.t('edit_avatar') ?? 'Edit Avatar',
            aspectRatioLockEnabled: true, // 强制正方形
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        // 🟢 3. 先保存到文档目录，再更新 Provider
        // 这样即使 iOS 清理了 tmp 目录，头像也不会丢
        final permanentPath = await _saveToPermanentStorage(croppedFile.path);
        
        if (permanentPath != null) {
          ref.read(settingsProvider.notifier).setAvatarPath(permanentPath);
        }
      }
    } catch (e) {
      debugPrint('Crop error: $e');
    }
  }

  // 头像选择弹窗逻辑
  Future<void> _showAvatarPicker(BuildContext context, WidgetRef ref) async {
    final i18n = ref.read(i18nProvider);
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(i18n.t('pick_from_gallery')),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 90,
                  );
                  if (image != null && context.mounted) {
                    _cropImage(context, ref, image.path);
                  }
                } catch (e) {
                  debugPrint('Pick image error: $e');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(i18n.t('take_photo')),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 90,
                  );
                  if (photo != null && context.mounted) {
                    _cropImage(context, ref, photo.path);
                  }
                } catch (e) {
                   debugPrint('Take photo error: $e');
                }
              },
            ),
            if (ref.read(settingsProvider).avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  i18n.t('reset_avatar') ?? 'Reset Avatar',
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(settingsProvider.notifier).setAvatarPath(null);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // 修改昵称对话框
  Future<void> _showNicknameDialog(BuildContext context, WidgetRef ref) async {
    final i18n = ref.read(i18nProvider);
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(text: settings.nickname);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i18n.t('set_nickname') ?? 'Set Nickname'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: i18n.t('nickname_hint') ?? 'Enter custom nickname',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: controller.clear,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setNickname(null);
              Navigator.pop(ctx);
            },
            child: Text(
              i18n.t('reset') ?? 'Reset',
              style: const TextStyle(color: Colors.red),
            ),
          ),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setNickname(controller.text);
              Navigator.pop(ctx);
            },
            child: Text(i18n.t('save')),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImage(String? localPath, String? cloudUrl) {
    if (localPath != null && File(localPath).existsSync()) {
      return FileImage(File(localPath));
    }
    if (cloudUrl != null && cloudUrl.isNotEmpty) {
      return NetworkImage(cloudUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authProvider).isAuthenticated) {
        ref.read(authProvider.notifier).refreshUserFromServer();
      }
    });

    final settings = ref.watch(settingsProvider);
    final auth = ref.watch(authProvider);
    final i18n = ref.watch(i18nProvider);
    final packageInfo = ref.watch(packageInfoProvider);
    final cloudAvatarUrl = ref.watch(pbServiceProvider).currentAvatarUrl;

    // 判断是否显示编辑笔：如果没有本地头像 且 没有云端头像，才显示笔
    final bool hasAvatar = (settings.avatarPath != null && File(settings.avatarPath!).existsSync()) || 
                           (cloudAvatarUrl != null && cloudAvatarUrl.isNotEmpty);

    // 名字显示逻辑：优先显示本地昵称，其次显示云端名字，最后显示默认
    final displayName = settings.nickname ?? auth.user?.getStringValue('name') ?? i18n.t('user');

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.t('settings')),
      ),
      body: SafeArea(
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
                  // 头像区域
                  leading: GestureDetector(
                    onTap: () => _showAvatarPicker(context, ref),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: _getAvatarImage(settings.avatarPath, cloudAvatarUrl),
                          child: _getAvatarImage(settings.avatarPath, cloudAvatarUrl) == null
                              ? Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimaryContainer)
                              : null,
                        ),
                        if (!hasAvatar)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 8, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 名字区域
                  title: GestureDetector(
                    onTap: () => _showNicknameDialog(context, ref),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.edit_note, 
                          size: 16, 
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                      if (auth.user?.getBoolValue('verified') == false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: GestureDetector(
                            onTap: () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .refreshUserFromServer();

                              if (ref
                                      .read(authProvider)
                                      .user
                                      ?.getBoolValue('verified') ==
                                  true) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(i18n.t('verification_success')),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                return;
                              }

                              await ref
                                  .read(authProvider.notifier)
                                  .requestVerification();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(i18n.t('verification_sent')),
                                      backgroundColor: Colors.green),
                                );
                              }
                            },
                            child: Text(
                              i18n.t('not_verified'),
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
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

              // 账号关联的智驾设置 (保留原始云端同步逻辑)
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

              // 自动打标敏感度
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
                  i18n.t('current_version'),
                  style: const TextStyle(),
                ),
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
                  '由 CanguroMIO 修改呈现',
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
  }

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
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: current == level
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () => ref.read(settingsProvider.notifier).setSensitivity(level),
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

  Widget _buildVerificationBadge(
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
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