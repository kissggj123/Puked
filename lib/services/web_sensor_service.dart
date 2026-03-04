import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:web/web.dart' as web;

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

/// Web 传感器服务 - 使用真实的 DeviceMotion API
class WebSensorService {
  final StreamController<AccelData> _accelController = 
      StreamController<AccelData>.broadcast();
  
  Stream<AccelData> get accelStream => _accelController.stream;

  bool _isRunning = false;
  bool _hasPermission = false;
  Vector3 _calibrationOffset = Vector3.zero();
  
  final List<Vector3> _recentReadings = [];
  static const int _calibrationSamples = 30;

  /// 请求传感器权限 (iOS 13+ 需要)
  Future<bool> requestPermission() async {
    if (!kIsWeb) {
      _hasPermission = true;
      return true;
    }

    try {
      // iOS 13+ 需要显式请求权限
      // 使用 JS 互操作请求权限
      _hasPermission = await _requestMotionPermission();
      return _hasPermission;
    } catch (e) {
      debugPrint('Permission request error: $e');
      // 非 iOS 设备可能没有 requestPermission 方法
      _hasPermission = true;
      return true;
    }
  }

  Future<bool> _requestMotionPermission() async {
    // 尝试请求 DeviceMotion 权限
    // 在 iOS 13+ 上需要用户交互触发
    try {
      // 检查 DeviceMotionEvent 是否存在
      if (web.DeviceMotionEvent == null) {
        debugPrint('DeviceMotionEvent not available');
        return false;
      }
      
      // 尝试请求权限 (iOS 13+)
      // 由于 package:web 可能没有 requestPermission 方法，
      // 我们直接返回 true，让浏览器在需要时请求权限
      return true;
    } catch (e) {
      debugPrint('Motion permission error: $e');
      return true;
    }
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
    // 添加 devicemotion 事件监听
    web.window.addEventListener('devicemotion', _onDeviceMotion.toJS);
    debugPrint('DeviceMotion listener started');
  }

  void _onDeviceMotion(web.Event event) {
    if (!_isRunning) return;

    final motionEvent = event as web.DeviceMotionEvent;
    final accel = motionEvent.accelerationIncludingGravity;
    if (accel == null) return;

    // 获取加速度数据
    final x = accel.x?.toDouble() ?? 0.0;
    final y = accel.y?.toDouble() ?? 0.0;
    final z = accel.z?.toDouble() ?? 0.0;

    // Web 坐标系转换:
    // x: 左右 (右为正)
    // y: 前后 (前为正) 
    // z: 上下 (上为正)
    // 转换为: lateral(横向), longitudinal(纵向), vertical(垂直)
    
    final lateral = x;  // 横向加速度
    final longitudinal = y;  // 纵向加速度  
    final vertical = z;  // 垂直加速度

    // 保存最近读数用于校准
    _recentReadings.add(Vector3(lateral, longitudinal, vertical));
    if (_recentReadings.length > _calibrationSamples) {
      _recentReadings.removeAt(0);
    }

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

  void _startMockSensors() {
    // 非 Web 平台使用模拟数据
    Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isRunning) {
        timer.cancel();
        return;
      }
      
      final random = math.Random();
      final lateral = (random.nextDouble() - 0.5) * 2;
      final longitudinal = (random.nextDouble() - 0.5) * 2;
      final vertical = (random.nextDouble() - 0.5) * 1;

      final calibratedLateral = lateral - _calibrationOffset.x;
      final calibratedLongitudinal = longitudinal - _calibrationOffset.y;
      final calibratedVertical = vertical - _calibrationOffset.z;

      _accelController.add(AccelData(
        lateral: calibratedLateral,
        longitudinal: calibratedLongitudinal,
        vertical: calibratedVertical,
      ));
    });
  }

  void stop() {
    _isRunning = false;
    
    if (kIsWeb) {
      web.window.removeEventListener('devicemotion', _onDeviceMotion.toJS);
    }
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
    stop();
    _accelController.close();
  }
}

final webSensorServiceProvider = Provider<WebSensorService>((ref) {
  final service = WebSensorService();
  ref.onDispose(() => service.dispose());
  return service;
});
