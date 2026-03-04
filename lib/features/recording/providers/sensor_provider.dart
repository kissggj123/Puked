
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puked/models/sensor_data.dart';
import 'package:puked/services/web_sensor_service.dart';
import 'package:puked/features/recording/domain/sensor_engine.dart';

/// 平台适配的传感器流提供者
/// 根据平台自动选择 WebSensorService 或原生 SensorEngine
final sensorStreamProvider = StreamProvider<SensorData>((ref) {
  if (kIsWeb) {
    // Web 平台使用 WebSensorService
    final webService = WebSensorService();

    // 确保在提供者销毁时清理资源
    ref.onDispose(() {
      webService.stop();
    });

    return webService.sensorStream;
  } else {
    // 移动端使用原生 SensorEngine
    final engine = SensorEngine();

    ref.onDispose(() {
      engine.dispose();
    });

    return engine.sensorStream;
  }
});

/// 传感器权限状态
final sensorPermissionProvider = StateProvider<bool>((ref) => false);

/// 请求传感器权限
final requestSensorPermissionProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) {
    final webService = WebSensorService();
    final granted = await webService.requestPermission();
    ref.read(sensorPermissionProvider.notifier).state = granted;
    return granted;
  } else {
    // 移动端默认有权限
    ref.read(sensorPermissionProvider.notifier).state = true;
    return true;
  }
});

/// 传感器校准状态
final sensorCalibrationProvider = StateProvider<bool>((ref) => false);

/// 执行传感器校准
final calibrateSensorProvider = FutureProvider<void>((ref) async {
  if (kIsWeb) {
    final webService = WebSensorService();
    await webService.calibrate();
    ref.read(sensorCalibrationProvider.notifier).state = true;
  } else {
    // 移动端校准逻辑在 SensorEngine 中处理
    ref.read(sensorCalibrationProvider.notifier).state = true;
  }
});

/// 传感器服务控制器
final sensorServiceControllerProvider = Provider<SensorServiceController>((ref) {
  return SensorServiceController(ref);
});

/// 传感器服务控制器类
class SensorServiceController {
  final Ref _ref;

  SensorServiceController(this._ref);

  /// 启动传感器服务
  void start() {
    if (kIsWeb) {
      WebSensorService().start();
    } else {
      // 移动端在 RecordingProvider 中启动
    }
  }

  /// 停止传感器服务
  void stop() {
    if (kIsWeb) {
      WebSensorService().stop();
    } else {
      // 移动端在 RecordingProvider 中停止
    }
  }

  /// 请求权限
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return await WebSensorService().requestPermission();
    }
    return true;
  }

  /// 校准
  Future<void> calibrate() async {
    if (kIsWeb) {
      await WebSensorService().calibrate();
    }
  }

  /// 重置校准
  void resetCalibration() {
    if (kIsWeb) {
      WebSensorService().resetCalibration();
    }
  }
}
