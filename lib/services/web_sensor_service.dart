import 'dart:async';
import 'dart:js_interop';
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

  JSFunction? _motionListener;

  /// 请求传感器权限 (iOS 13+ 需要)
  Future<bool> requestPermission() async {
    if (!kIsWeb) {
      _hasPermission = true;
      return true;
    }

    try {
      _hasPermission = await _requestMotionPermission();
      return _hasPermission;
    } catch (e) {
      debugPrint('Permission request error: $e');
      _hasPermission = true;
      return true;
    }
  }

  Future<bool> _requestMotionPermission() async {
    try {
      // 检查 DeviceMotionEvent 是否存在
      if (web.DeviceMotionEvent == null) {
        debugPrint('DeviceMotionEvent not available');
        return false;
      }
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
    // 创建 JS 函数作为事件监听器
    _motionListener = ((web.Event event) {
      _handleDeviceMotion(event);
    }).toJS;

    web.window.addEventListener('devicemotion', _motionListener);
    debugPrint('DeviceMotion listener started');
  }

  void _handleDeviceMotion(web.Event event) {
    if (!_isRunning) return;

    final motionEvent = event as web.DeviceMotionEvent;
    final accel = motionEvent.accelerationIncludingGravity;
    if (accel == null) return;

    // 获取加速度数据
    final x = accel.x?.toDouble() ?? 0.0;
    final y = accel.y?.toDouble() ?? 0.0;
    final z = accel.z?.toDouble() ?? 0.0;

    // Web 坐标系转换
    final lateral = x;
    final longitudinal = y;
    final vertical = z;

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
    
    if (kIsWeb && _motionListener != null) {
      web.window.removeEventListener('devicemotion', _motionListener);
      _motionListener = null;
    }
  }

  Future<void> calibrate() async {
    if (_recentReadings.isEmpty) return;

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
