import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

enum SensitivityLevel { low, medium, high }

class SettingsState {
  final ThemeMode themeMode;
  final Locale? locale;
  final SensitivityLevel sensitivity;
  final String? brand;
  final String? carModel;
  final String? softwareVersion;
  final bool fullscreenMode;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale,
    this.sensitivity = SensitivityLevel.high,
    this.brand,
    this.carModel,
    this.softwareVersion,
    this.fullscreenMode = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    SensitivityLevel? sensitivity,
    String? brand,
    String? carModel,
    String? softwareVersion,
    bool? fullscreenMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      sensitivity: sensitivity ?? this.sensitivity,
      brand: brand ?? this.brand,
      carModel: carModel ?? this.carModel,
      softwareVersion: softwareVersion ?? this.softwareVersion,
      fullscreenMode: fullscreenMode ?? this.fullscreenMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  static const _themeKey = 'themeMode';
  static const _localeKey = 'locale';
  static const _sensitivityKey = 'sensitivity';
  static const _brandKey = 'brand';
  static const _carModelKey = 'carModel';
  static const _softwareVersionKey = 'softwareVersion';
  static const _fullscreenKey = 'fullscreenMode';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    final themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.index == themeIndex,
      orElse: () => ThemeMode.system,
    );

    final localeCode = prefs.getString(_localeKey);
    final locale = localeCode != null ? Locale(localeCode) : null;

    final sensitivityIndex = prefs.getInt(_sensitivityKey) ?? 2;
    final sensitivity = SensitivityLevel.values[sensitivityIndex.clamp(0, 2)];

    final brand = prefs.getString(_brandKey);
    final carModel = prefs.getString(_carModelKey);
    final softwareVersion = prefs.getString(_softwareVersionKey);
    final fullscreenMode = prefs.getBool(_fullscreenKey) ?? false;

    state = SettingsState(
      themeMode: themeMode,
      locale: locale,
      sensitivity: sensitivity,
      brand: brand,
      carModel: carModel,
      softwareVersion: softwareVersion,
      fullscreenMode: fullscreenMode,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString(_localeKey, locale.languageCode);
    } else {
      await prefs.remove(_localeKey);
    }
    state = state.copyWith(locale: locale);
  }

  Future<void> setSensitivity(SensitivityLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sensitivityKey, level.index);
    state = state.copyWith(sensitivity: level);
  }

  Future<void> setVehicleInfo({
    String? brand,
    String? carModel,
    String? softwareVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (brand != null) await prefs.setString(_brandKey, brand);
    if (carModel != null) await prefs.setString(_carModelKey, carModel);
    if (softwareVersion != null) {
      await prefs.setString(_softwareVersionKey, softwareVersion);
    }
    state = state.copyWith(
      brand: brand ?? state.brand,
      carModel: carModel ?? state.carModel,
      softwareVersion: softwareVersion ?? state.softwareVersion,
    );
  }

  Future<void> setFullscreenMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fullscreenKey, enabled);
    state = state.copyWith(fullscreenMode: enabled);
  }

  Future<void> clearVehicleSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_brandKey);
    await prefs.remove(_carModelKey);
    await prefs.remove(_softwareVersionKey);
    state = state.copyWith(
      brand: null,
      carModel: null,
      softwareVersion: null,
    );
  }
}
