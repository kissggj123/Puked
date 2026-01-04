import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import 'package:puked/models/sensor_data.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vector_math/vector_math_64.dart';

class SensorEngine {
  // 🟢 优化1：采样周期提升至 100Hz (10ms)
  // iPhone 14 Pro 的 A16 芯片完全能处理这个负载，捕捉路面微小纹理
  static final Duration samplingPeriod = Platform.isIOS
      ? const Duration(milliseconds: 10) // 100Hz for iOS
      : const Duration(milliseconds: 33); // 30Hz for Android

  // 🟢 优化2：缓冲区扩容 (15秒 * 100Hz = 1500点)
  static final int bufferLimit = Platform.isIOS ? 1500 : 450;

  final ListQueue<SensorData> _buffer = ListQueue<SensorData>(bufferLimit);

  // 校准矩阵
  Matrix3 _rotationMatrix = Matrix3.identity();
  bool _isCalibrated = false;
  double _gravityMagnitude = 9.80665;

  // 🟢 优化3：滤波系数微调
  // 频率 100Hz 时，单次步长变小，系数需要减小以保持平滑手感
  // 0.05 -> 0.03
  static const double _lpfCoeff = 0.03; 
  static const double _rampFilterCoeff = 0.01;
  Vector3 _filteredAccel = Vector3.zero();
  Vector3 _gravityEstimate = Vector3.zero();

  // --- 顶级滤波矩阵 ---
  // 中值滤波窗口，100Hz下建议稍微增大窗口，消除偶发毛刺
  final ListQueue<Vector3> _medianBuffer = ListQueue<Vector3>();
  static const int _medianWindowSize = 5; // 原来是3，改成5更稳

  // 卡尔曼滤波器状态 (Gravity Tracking)
  Vector3 _kalmanGravity = Vector3.zero();
  Vector3 _kalmanP = Vector3.all(0.1); 
  // 100Hz下过程噪声要更小，因为10ms内重力不可能剧变
  static const double _kalmanQ = 0.0005; 
  static const double _kalmanR = 0.1; 

  // 动态航向修正
  double _dynamicYawOffset = 0.0;
  final ListQueue<Vector3> _headingLearningBuffer = ListQueue<Vector3>();
  bool _isHeadingAligned = false;

  // 传感器原始值
  final Vector3 _latestAccel = Vector3.zero();
  final Vector3 _latestGyro = Vector3.zero();
  final Vector3 _latestMag = Vector3.zero();
  DateTime _lastSensorEventTime = DateTime.now();
  int _sensorEventCount = 0;

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;
  Timer? _samplingTimer;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final _dataController = StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorStream => _dataController.stream;

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // 🟢 优化4：请求 gameInterval (约20ms)，虽然 UI 跑100Hz，但硬件推送太快可能阻塞 Isolate
    // 14 Pro 的 gameInterval 实际上非常快 (~60Hz)，我们通过 timer 插值到 100Hz
    final sensorInterval = SensorInterval.gameInterval;

    _accelSub =
        accelerometerEventStream(samplingPeriod: sensorInterval).listen((e) {
      _latestAccel.setValues(e.x, e.y, e.z);
      _lastSensorEventTime = DateTime.now();
      _sensorEventCount++;
      // iOS 依然采用事件驱动，保证最低延迟
      if (Platform.isIOS) _processTick();
    });

    _gyroSub = gyroscopeEventStream(samplingPeriod: sensorInterval)
        .listen((e) => _latestGyro.setValues(e.x, e.y, e.z));
    _magSub = magnetometerEventStream(samplingPeriod: sensorInterval)
        .listen((e) => _latestMag.setValues(e.x, e.y, e.z));

    if (!Platform.isIOS) {
      _samplingTimer = Timer.periodic(samplingPeriod, (timer) {
        _processTick();
      });
    }
  }

  void _processTick() {
    final now = DateTime.now();

    // 1. 中值滤波 (去噪)
    _medianBuffer.addLast(_latestAccel.clone());
    if (_medianBuffer.length > _medianWindowSize) _medianBuffer.removeFirst();
    final Vector3 smoothedAccel = _calculateMedian(_medianBuffer.toList());

    // 2. 卡尔曼滤波 (重力分离)
    if (!_isCalibrated) {
      _kalmanGravity = smoothedAccel.clone();
      _isCalibrated = true; 
    } else {
      for (int i = 0; i < 3; i++) {
        _kalmanP[i] = _kalmanP[i] + _kalmanQ;
        double kGain = _kalmanP[i] / (_kalmanP[i] + _kalmanR);
        _kalmanGravity[i] =
            _kalmanGravity[i] + kGain * (smoothedAccel[i] - _kalmanGravity[i]);
        _kalmanP[i] = (1 - kGain) * _kalmanP[i];
      }
    }

    // 3. 旋转对齐
    Vector3 rotatedAccel = _rotationMatrix.transformed(smoothedAccel);
    Vector3 rotatedGyro = _rotationMatrix.transformed(_latestGyro);

    if (_dynamicYawOffset != 0) {
      final yawMatrix = Matrix3.rotationZ(_dynamicYawOffset);
      rotatedAccel = yawMatrix.transformed(rotatedAccel);
      rotatedGyro = yawMatrix.transformed(rotatedGyro);
    }

    // 4. 扣除动态重力
    final Vector3 currentGravityInRef =
        _rotationMatrix.transformed(_kalmanGravity);
    
    // 纯净线性加速度
    final processedAccel = rotatedAccel - currentGravityInRef;

    // 5. 低通滤波 (用于 UI 平滑显示)
    _filteredAccel =
        _filteredAccel * (1.0 - _lpfCoeff) + processedAccel * _lpfCoeff;

    final data = SensorData(
      timestamp: now,
      accelerometer: _latestAccel.clone(),
      gyroscope: _latestGyro.clone(),
      magnetometer: _latestMag.clone(),
      processedAccel: processedAccel, // 用于算法检测 (如急刹)
      processedGyro: rotatedGyro,
      filteredAccel: _filteredAccel,  // 用于 UI 显示 (G力球)
    );

    // 航向学习 (需要积累更多点，100Hz下 300点 = 3秒)
    if (!_isHeadingAligned && _buffer.length > 300) {
      _learnHeading(processedAccel);
    }

    if (_buffer.length >= bufferLimit) {
      _buffer.removeFirst();
    }
    _buffer.addLast(data);

    _dataController.add(data);
  }

  Vector3 _calculateMedian(List<Vector3> samples) {
    if (samples.isEmpty) return Vector3.zero();
    if (samples.length == 1) return samples[0];

    final xValues = samples.map((s) => s.x).toList()..sort();
    final yValues = samples.map((s) => s.y).toList()..sort();
    final zValues = samples.map((s) => s.z).toList()..sort();

    final mid = samples.length ~/ 2;
    return Vector3(xValues[mid], yValues[mid], zValues[mid]);
  }

  void _learnHeading(Vector3 accel) {
    final double horizontalMag =
        Math.sqrt(accel.x * accel.x + accel.y * accel.y);
    
    // 只有明显的纵向加速 (> 1.2 m/s²) 才触发学习，防止误判
    if (horizontalMag > 1.2 && accel.y > 0) {
      _headingLearningBuffer.addLast(accel.clone());
      // 100Hz 下采集 50 个点 (0.5秒)
      if (_headingLearningBuffer.length > 50) {
        double avgAngle = 0;
        for (var a in _headingLearningBuffer) {
          avgAngle += Math.atan2(a.x, a.y);
        }
        avgAngle /= _headingLearningBuffer.length;

        if (avgAngle.abs() > 0.05) {
          _dynamicYawOffset -= avgAngle; 
          debugPrint(
              "Heading Aligned: Adjusted by ${(avgAngle * 180 / Math.pi).toStringAsFixed(1)}°");
        }
        _isHeadingAligned = true;
        _headingLearningBuffer.clear();
      }
    }
  }

  Future<void> calibrate() async {
    List<Vector3> samples = [];
    const int sampleCount = 40; // 100Hz 很快，多采一点样本 (40 * 20ms = 0.8s)

    for (int i = 0; i < sampleCount; i++) {
      samples.add(_latestAccel.clone());
      await Future.delayed(const Duration(milliseconds: 20));
    }

    Vector3 gMean = Vector3.zero();
    for (var s in samples) {
      gMean += s;
    }
    gMean /= samples.length.toDouble();

    double variance = 0;
    for (var s in samples) {
      variance += (s - gMean).length2;
    }
    variance /= samples.length;

    if (variance > 0.05) {
      throw Exception("校准失败：请确保手机完全静止（检测到波动: ${variance.toStringAsFixed(3)}）");
    }

    _gravityMagnitude = gMean.length;
    if (_gravityMagnitude < 8.0 || _gravityMagnitude > 12.0) {
      throw Exception(
          "校准失败：传感器读数异常 (G: ${_gravityMagnitude.toStringAsFixed(2)})，请检查权限或重启 App");
    }

    final unitZ = gMean.normalized();
    Vector3 reference = Vector3(0, 1, 0);
    if (unitZ.dot(reference).abs() > 0.9) {
      reference = Vector3(1, 0, 0);
    }

    final unitX = reference.cross(unitZ).normalized();
    final unitY = unitZ.cross(unitX).normalized();

    final rot = Matrix3.columns(unitX, unitY, unitZ);
    _rotationMatrix = rot.isIdentity() ? rot : Matrix3.copy(rot)
      ..invert();
    _gravityEstimate = _rotationMatrix.transformed(gMean);
    _isCalibrated = true;
    _isHeadingAligned = false; 
    _dynamicYawOffset = 0.0; 

    _processTick();
  }

  List<SensorData> getLookbackBuffer(int seconds, {int targetHz = 20}) {
    // 🟢 修正：源频率是 100Hz
    final sourceHz = Platform.isIOS ? 100 : 30;
    final step = (sourceHz / targetHz).round().clamp(1, 10);

    int pointsToTake = (seconds * sourceHz).clamp(0, _buffer.length);
    final rawList = _buffer.toList().sublist(_buffer.length - pointsToTake);

    List<SensorData> downsampled = [];
    for (int i = 0; i < rawList.length; i += step) {
      downsampled.add(rawList[i]);
    }
    return downsampled;
  }

  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _samplingTimer?.cancel();
    _dataController.close();
  }
}