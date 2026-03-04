
import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:puked/models/sensor_data.dart';

/// Web 平台传感器服务
/// 封装 DeviceMotion API 和 DeviceOrientation API
/// 提供统一的传感器数据流
class WebSensorService {
  static final WebSensorService _instance = WebSensorService._internal();
  factory WebSensorService() => _instance;
  WebSensorService._internal();

  // 采样率配置
  static const int _webSampleRate = 30; // Web 平台 30Hz
  static const Duration _sampleInterval = Duration(milliseconds: 33); // ~30Hz

  // 数据流控制器
  final _dataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorStream => _dataController.stream;

  // 权限状态
  bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  // 运行状态
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  // 最新传感器数据
  final Vector3 _latestAccel = Vector3.zero();
  final Vector3 _latestGyro = Vector3.zero();
  DateTime _lastUpdate = DateTime.now();

  // 定时器
  Timer? _sampleTimer;

  // 校准相关
  Matrix3 _rotationMatrix = Matrix3.identity();
  bool _isCalibrated = false;
  Vector3 _gravityEstimate = Vector3(0, 0, 9.8);

  /// 请求传感器权限
  /// iOS 13+ 需要用户交互后请求权限
  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;

    try {
      // 检查是否支持 DeviceMotionEvent
      if (js_util.hasProperty(html.window, 'DeviceMotionEvent')) {
        // iOS 13+ 需要请求权限
        if (js_util.hasProperty(
          js_util.getProperty(html.window, 'DeviceMotionEvent'),
          'requestPermission',
        )) {
          final promise = js_util.callMethod(
            js_util.getProperty(html.window, 'DeviceMotionEvent'),
            'requestPermission',
            [],
          );
          final result = await js_util.promiseToFuture(promise);
          _hasPermission = result == 'granted';
        } else {
          // 其他浏览器默认有权限
          _hasPermission = true;
        }
      }

      debugPrint('Web sensor permission: $_hasPermission');
      return _hasPermission;
    } catch (e) {
      debugPrint('Error requesting sensor permission: $e');
      // 某些浏览器可能不支持权限 API，尝试直接访问
      _hasPermission = true;
      return _hasPermission;
    }
  }

  /// 开始传感器监听
  void start() {
    if (_isRunning) return;
    if (!kIsWeb) {
      debugPrint('WebSensorService only works on web platform');
      return;
    }

    _isRunning = true;

    // 监听 device motion 事件
    html.window.addEventListener('devicemotion', _onDeviceMotion);

    // 启动定时采样
    _sampleTimer = Timer.periodic(_sampleInterval, (_) {
      _processSample();
    });

    debugPrint('WebSensorService started');
  }

  /// 停止传感器监听
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _sampleTimer?.cancel();
    _sampleTimer = null;

    html.window.removeEventListener('devicemotion', _onDeviceMotion);

    debugPrint('WebSensorService stopped');
  }

  /// 处理 device motion 事件
  void _onDeviceMotion(html.Event event) {
    try {
      final motionEvent = event as html.DeviceMotionEvent;

      // 获取加速度（包含重力）
      final acceleration = motionEvent.accelerationIncludingGravity;
      if (acceleration != null) {
        // Web 坐标系: x 右, y 上, z 出屏幕
        // 转换为: x 横向(右), y 纵向(前), z 垂直(上)
        _latestAccel.setValues(
          acceleration.x ?? 0.0,
          acceleration.y ?? 0.0,
          acceleration.z ?? 0.0,
        );
      }

      // 获取旋转速率
      final rotationRate = motionEvent.rotationRate;
      if (rotationRate != null) {
        _latestGyro.setValues(
          (rotationRate.beta ?? 0.0) * math.pi / 180, // x 轴旋转 (度/秒 -> 弧度/秒)
          (rotationRate.gamma ?? 0.0) * math.pi / 180, // y 轴旋转
          (rotationRate.alpha ?? 0.0) * math.pi / 180, // z 轴旋转
        );
      }

      _lastUpdate = DateTime.now();
    } catch (e) {
      debugPrint('Error processing device motion: $e');
    }
  }

  /// 处理采样数据
  void _processSample() {
    if (!_isRunning) return;

    final now = DateTime.now();

    // 如果数据太旧，使用零值
    final dataAge = now.difference(_lastUpdate).inMilliseconds;
    if (dataAge > 500) {
      // 500ms 没有新数据，可能是权限问题
      debugPrint('Sensor data stale: ${dataAge}ms');
    }

    // 坐标系转换: Web -> 车辆坐标系
    // Web: x(右), y(上), z(出屏幕)
    // 车辆: x(横向右), y(纵向前), z(垂直上)
    // 注意: Web 的 y 轴向上，车辆坐标系 y 轴向前
    final vehicleAccel = Vector3(
      _latestAccel.x, // 横向加速度
      -_latestAccel.y, // 纵向加速度 (反转，因为 Web y 向上)
      _latestAccel.z, // 垂直加速度
    );

    // 应用校准矩阵
    final processedAccel = _isCalibrated
        ? _rotationMatrix.transformed(vehicleAccel)
        : vehicleAccel;

    // 扣除重力估计
    final linearAccel = processedAccel - _gravityEstimate;

    final sensorData = SensorData(
      timestamp: now,
      accelerometer: _latestAccel.clone(),
      gyroscope: _latestGyro.clone(),
      magnetometer: Vector3.zero(), // Web 不提供磁力计
      processedAccel: linearAccel,
      processedGyro: _latestGyro.clone(),
      filteredAccel: linearAccel, // Web 平台简化处理
    );

    _dataController.add(sensorData);
  }

  /// 校准传感器
  /// 采集一段时间的数据，计算重力方向并建立校准矩阵
  Future<void> calibrate() async {
    debugPrint('Starting sensor calibration...');

    final samples = <Vector3>[];
    const sampleCount = 30; // 30 个样本 (~1秒)

    // 采集样本
    for (int i = 0; i < sampleCount; i++) {
      samples.add(_latestAccel.clone());
      await Future.delayed(const Duration(milliseconds: 33));
    }

    if (samples.isEmpty) {
      throw Exception('校准失败：无法获取传感器数据');
    }

    // 计算平均重力向量
    Vector3 gravitySum = Vector3.zero();
    for (final sample in samples) {
      gravitySum += sample;
    }
    final gravityMean = gravitySum / samples.length.toDouble();

    // 检查数据稳定性
    double variance = 0;
    for (final sample in samples) {
      variance += (sample - gravityMean).length2;
    }
    variance /= samples.length;

    if (variance > 0.5) {
      throw Exception('校准失败：请保持设备静止');
    }

    // 建立坐标系
    // 重力方向为 -Z 轴
    final unitZ = (-gravityMean).normalized();

    // 选择参考向量
    Vector3 reference = Vector3(0, 1, 0);
    if (unitZ.dot(reference).abs() > 0.9) {
      reference = Vector3(1, 0, 0);
    }

    // 建立正交基
    final unitX = reference.cross(unitZ).normalized();
    final unitY = unitZ.cross(unitX).normalized();

    // 构建旋转矩阵
    _rotationMatrix = Matrix3.columns(unitX, unitY, unitZ);
    _rotationMatrix.invert();

    _gravityEstimate = gravityMean;
    _isCalibrated = true;

    debugPrint('Sensor calibration completed');
    debugPrint('Gravity: ${_gravityEstimate.storage}');
  }

  /// 重置校准
  void resetCalibration() {
    _rotationMatrix = Matrix3.identity();
    _isCalibrated = false;
    _gravityEstimate = Vector3(0, 0, 9.8);
    debugPrint('Sensor calibration reset');
  }

  /// 释放资源
  void dispose() {
    stop();
    _dataController.close();
  }
}

/// 全局传感器服务提供者
final webSensorService = WebSensorService();
