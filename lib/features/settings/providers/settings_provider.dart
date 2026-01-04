import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🟢 用于存昵称(防卸载丢失)
import 'package:puked/features/auth/providers/auth_provider.dart';
import 'package:puked/services/pocketbase_service.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

enum SensitivityLevel { low, medium, high }

class SettingsState {
  final ThemeMode themeMode;
  final Locale? locale;
  final SensitivityLevel sensitivity;
  final String? brand;
  final String? carModel;
  final String? softwareVersion;
  final String? avatarPath; // 🟢 本地头像路径 (纯本地)
  final String? nickname;   // 🟢 本地昵称 (纯本地)

  SettingsState({
    required this.themeMode,
    this.locale,
    this.sensitivity = SensitivityLevel.high,
    this.brand,
    this.carModel,
    this.softwareVersion,
    this.avatarPath,
    this.nickname,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    SensitivityLevel? sensitivity,
    String? brand,
    String? carModel,
    String? softwareVersion,
    String? avatarPath,
    String? nickname,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      sensitivity: sensitivity ?? this.sensitivity,
      brand: brand ?? this.brand,
      carModel: carModel ?? this.carModel,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      avatarPath: avatarPath ?? this.avatarPath,
      nickname: nickname ?? this.nickname,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  // 🟢 安全存储，用于保存昵称，卸载重装后可能找回
  final _secureStorage = const FlutterSecureStorage();

  SettingsNotifier(this._ref)
      : super(SettingsState(themeMode: ThemeMode.system)) {
    _loadSettings();

    // 🔵 保持原始逻辑：监听登录状态，同步车辆信息
    _ref.listen(authProvider, (previous, next) {
      if (previous?.isAuthenticated == false && next.isAuthenticated) {
        _loadSettings();
      }
    });
  }

  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale_code';
  static const _sensitivityKey = 'sensitivity_level';
  static const _brandKey = 'default_brand';
  static const _carModelKey = 'default_car_model';
  static const _softwareVersionKey = 'default_software_version';
  static const _avatarPathKey = 'local_avatar_path';
  static const _nicknameKey = 'local_nickname';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values[themeIndex];

    final localeCode = prefs.getString(_localeKey);
    Locale? locale;
    if (localeCode != null) {
      locale = Locale(localeCode);
    }

    final sensitivityIndex =
        prefs.getInt(_sensitivityKey) ?? SensitivityLevel.high.index;
    final sensitivity = SensitivityLevel.values[sensitivityIndex];

    String? brand = prefs.getString(_brandKey);
    String? carModel = prefs.getString(_carModelKey);
    String? softwareVersion = prefs.getString(_softwareVersionKey);

    // 🟢 加载本地头像 (纯本地逻辑)
    String? avatarPath = prefs.getString(_avatarPathKey);
    // 检查文件是否存在，防止重装后路径残留导致报错
    if (avatarPath != null && !File(avatarPath).existsSync()) {
      avatarPath = null; 
    }

    // 🟢 加载本地昵称 (优先从 SecureStorage 加载，增加持久性)
    String? nickname = await _secureStorage.read(key: _nicknameKey);
    if (nickname == null) {
      nickname = prefs.getString(_nicknameKey);
    }

    // 🔵 保持原始逻辑：如果已登录，优先从云端覆盖车辆信息
    // 注意：这里【不】覆盖 avatarPath 和 nickname，严格遵守你的“本地优先”需求
    final auth = _ref.read(authProvider);
    if (auth.isAuthenticated) {
      brand = auth.user?.getStringValue('brand').isEmpty == false
          ? auth.user?.getStringValue('brand')
          : brand;
      carModel = auth.user?.getStringValue('car_model').isEmpty == false
          ? auth.user?.getStringValue('car_model')
          : carModel;
      softwareVersion =
          auth.user?.getStringValue('software_version').isEmpty == false
              ? auth.user?.getStringValue('software_version')
              : softwareVersion;
    }

    state = SettingsState(
      themeMode: themeMode,
      locale: locale,
      sensitivity: sensitivity,
      brand: brand,
      carModel: carModel,
      softwareVersion: softwareVersion,
      avatarPath: avatarPath, // 🟢
      nickname: nickname,     // 🟢
    );
  }

  // 🟢 纯本地头像设置
  Future<void> setAvatarPath(String? path) async {
    // 1. 如果有旧头像且不同，删除旧文件以节省空间
    final oldPath = state.avatarPath;
    if (oldPath != null && path != null && oldPath != path) {
      final oldFile = File(oldPath);
      if (await oldFile.exists()) {
        try {
          await oldFile.delete();
        } catch (e) {
          debugPrint('Failed to delete old avatar: $e');
        }
      }
    }

    // 2. 更新状态
    state = state.copyWith(avatarPath: path);

    // 3. 保存路径到本地 Prefs
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_avatarPathKey, path);
    } else {
      await prefs.remove(_avatarPathKey);
    }
    
    // ❌ 绝对不调用 PocketBase 上传
  }

  // 🟢 纯本地昵称设置
  Future<void> setNickname(String? name) async {
    final validName = (name != null && name.trim().isEmpty) ? null : name?.trim();

    state = state.copyWith(nickname: validName);

    final prefs = await SharedPreferences.getInstance();
    
    if (validName != null) {
      await prefs.setString(_nicknameKey, validName);
      // 同时写入 Keychain，增加卸载保留概率
      await _secureStorage.write(key: _nicknameKey, value: validName);
    } else {
      await prefs.remove(_nicknameKey);
      await _secureStorage.delete(key: _nicknameKey);
    }
    // ❌ 绝对不调用 PocketBase 更新 name
  }

  // 🔵 保持原始逻辑：同步车辆信息到云端
  Future<void> _syncToPocketBase() async {
    final auth = _ref.read(authProvider);
    if (!auth.isAuthenticated) return;

    try {
      final pb = _ref.read(pbServiceProvider).pb;
      await pb.collection('users').update(auth.user!.id, body: {
        'brand': state.brand ?? '',
        'car_model': state.carModel ?? '',
        'software_version': state.softwareVersion ?? '',
      });
      // 更新本地 auth 状态
      await _ref.read(authProvider.notifier).refreshUserFromServer();
    } catch (e) {
      debugPrint('Failed to sync vehicle settings to PocketBase: $e');
    }
  }

  Future<void> setSensitivity(SensitivityLevel level) async {
    state = state.copyWith(sensitivity: level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sensitivityKey, level.index);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setLocale(Locale? locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }

  // 🔵 保持原始逻辑：车辆信息依旧同步云端
  Future<void> setVehicleInfo(
      {String? brand, String? model, String? version}) async {
    state = state.copyWith(
      brand: brand,
      carModel: model,
      softwareVersion: version,
    );

    final prefs = await SharedPreferences.getInstance();
    if (brand != null) await prefs.setString(_brandKey, brand);
    if (model != null) await prefs.setString(_carModelKey, model);
    if (version != null) await prefs.setString(_softwareVersionKey, version);

    await _syncToPocketBase(); // 这里保留同步
  }

  Future<void> clearVehicleSettings() async {
    state = state.copyWith(
      brand: null,
      carModel: null,
      softwareVersion: null,
      // 🟢 退出登录时，保留本地头像和昵称，因为它们是“设备级”偏好，和账号无关
      avatarPath: state.avatarPath, 
      nickname: state.nickname, 
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_brandKey);
    await prefs.remove(_carModelKey);
    await prefs.remove(_softwareVersionKey);
  }

  @Deprecated('Use setVehicleInfo instead')
  Future<void> setBrand(String? brand) async {
    await setVehicleInfo(brand: brand);
  }

  @Deprecated('Use setVehicleInfo instead')
  Future<void> setCarModel(String? model) async {
    await setVehicleInfo(model: model);
  }
}