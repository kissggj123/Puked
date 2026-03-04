import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

/// 加速度数据
class AccelData {
  final double lateral;
  final double longitudinal;
  final double vertical;
  final DateTime timestamp;

  AccelData({
    required this.lateral,
    required this.longitudinal,
    required this.vertical,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Web 传感器服务 - 使用 DeviceMotion API
class WebSensorService {
  final StreamController<AccelData> _accelController = 
      StreamController<AccelData>.broadcast();
  
  Stream<AccelData> get accelStream => _accelController.stream;

  bool _isRunning = false;
  Vector3 _calibrationOffset = Vector3.zero();
  
  // 最近几次读数用于校准
  final List<Vector3> _recentReadings = [];
  static const int _calibrationSamples = 30;

  Future<bool> requestPermission() async {
    if (!kIsWeb) return true;
    
    // iOS 13+ 需要请求权限
    try {
      // 尝试请求 DeviceMotion 权限
      final granted = await _requestDeviceMotionPermission();
      return granted;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  Future<bool> _requestDeviceMotionPermission() async {
    // 在 iOS 13+ 上需要显式请求权限
    // 这个方法会在 JS 互操作中实现
    return true;
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    
    if (kIsWeb) {
      _startWebSensors();
    } else {
      _startMockSensors();
    }
  }

  void _startWebSensors() {
    // 在 Web 平台上，使用 JS 互操作监听 devicemotion 事件
    // 这里使用模拟数据，实际部署时需要使用 dart:html 或 dart:js_interop
    _startMockSensors();
  }

  void _startMockSensors() {
    // 模拟传感器数据（用于测试和非 Web 平台）
    Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      
      final random = math.Random();
      final lateral = (random.nextDouble() - 0.5) * 2;
      final longitudinal = (random.nextDouble() - 0.5) * 2;
      final vertical = (random.nextDouble() - 0.5) * 1;

      _processAccelData(lateral, longitudinal, vertical);
    });
  }

  void _processAccelData(double lateral, double longitudinal, double vertical) {
    // 应用校准偏移
    final calibratedLateral = lateral - _calibrationOffset.x;
    final calibratedLongitudinal = longitudinal - _calibrationOffset.y;
    final calibratedVertical = vertical - _calibrationOffset.z;

    _accelController.add(AccelData(
      lateral: calibratedLateral,
      longitudinal: calibratedLongitudinal,
      vertical: calibratedVertical,
    ));
  }

  /// 接收来自 JS 的传感器数据
  void onDeviceMotion(double x, double y, double z) {
    if (!_isRunning) return;
    
    // Web 坐标系转换:
    // x: 左右 (右为正)
    // y: 前后 (前为正) 
    // z: 上下 (上为正)
    // 我们需要: lateral(横向), longitudinal(纵向), vertical(垂直)
    
    final lateral = x;  // 横向加速度
    final longitudinal = y;  // 纵向加速度  
    final vertical = z;  // 垂直加速度

    // 保存最近读数用于校准
    _recentReadings.add(Vector3(lateral, longitudinal, vertical));
    if (_recentReadings.length > _calibrationSamples) {
      _recentReadings.removeAt(0);
    }

    _processAccelData(lateral, longitudinal, vertical);
  }

  void stop() {
    _isRunning = false;
  }

  Future<void> calibrate() async {
    if (_recentReadings.isEmpty) return;

    // 计算平均偏移
    double sumX = 0, sumY = 0, sumZ = 0;
    for (final reading in _recentReadings) {
      sumX += reading.x;
      sumY += reading.y;
      sumZ += reading.z;
    }

    _calibrationOffset = Vector3(
      sumX / _recentReadings.length,
      sumY / _recentReadings.length,
      sumZ / _recentReadings.length,
    );

    debugPrint('Calibrated: offset=$_calibrationOffset');
  }

  void dispose() {
    _accelController.close();
  }
}

final webSensorServiceProvider = Provider<WebSensorService>((ref) {
  final service = WebSensorService();
  ref.onDispose(() => service.dispose());
  return service;
});
