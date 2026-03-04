import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puked/models/sensor_data.dart';
import 'package:puked/features/recording/providers/sensor_provider.dart';
import 'package:puked/features/cola_simulator/domain/physics_engine.dart';

/// 可乐杯模拟器状态
class ColaSimulatorState {
  final bool isRunning;
  final bool hasPermission;
  final bool isCalibrated;
  final double lateralAccel;
  final double longitudinalAccel;
  final double verticalAccel;
  final double spillPercentage;
  final double gForce;
  final double sensitivity;
  final String accelDescription;
  final String spillDescription;
  final DateTime? startTime;
  final Duration elapsedTime;

  const ColaSimulatorState({
    this.isRunning = false,
    this.hasPermission = false,
    this.isCalibrated = false,
    this.lateralAccel = 0.0,
    this.longitudinalAccel = 0.0,
    this.verticalAccel = 0.0,
    this.spillPercentage = 0.0,
    this.gForce = 0.0,
    this.sensitivity = 1.0,
    this.accelDescription = '平稳',
    this.spillDescription = '几乎没撒',
    this.startTime,
    this.elapsedTime = Duration.zero,
  });

  ColaSimulatorState copyWith({
    bool? isRunning,
    bool? hasPermission,
    bool? isCalibrated,
    double? lateralAccel,
    double? longitudinalAccel,
    double? verticalAccel,
    double? spillPercentage,
    double? gForce,
    double? sensitivity,
    String? accelDescription,
    String? spillDescription,
    DateTime? startTime,
    Duration? elapsedTime,
  }) {
    return ColaSimulatorState(
      isRunning: isRunning ?? this.isRunning,
      hasPermission: hasPermission ?? this.hasPermission,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      lateralAccel: lateralAccel ?? this.lateralAccel,
      longitudinalAccel: longitudinalAccel ?? this.longitudinalAccel,
      verticalAccel: verticalAccel ?? this.verticalAccel,
      spillPercentage: spillPercentage ?? this.spillPercentage,
      gForce: gForce ?? this.gForce,
      sensitivity: sensitivity ?? this.sensitivity,
      accelDescription: accelDescription ?? this.accelDescription,
      spillDescription: spillDescription ?? this.spillDescription,
      startTime: startTime ?? this.startTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
    );
  }
}

/// 可乐杯模拟器状态管理
class ColaSimulatorNotifier extends StateNotifier<ColaSimulatorState> {
  final Ref _ref;
  final ColaPhysicsEngine _physicsEngine;
  StreamSubscription? _sensorSubscription;
  Timer? _updateTimer;

  ColaSimulatorNotifier(this._ref)
      : _physicsEngine = ColaPhysicsEngine(),
        super(const ColaSimulatorState()) {
    _init();
  }

  void _init() {
    // 监听传感器数据
    _sensorSubscription = _ref.read(sensorStreamProvider.stream).listen(
      (sensorData) {
        _onSensorData(sensorData);
      },
      onError: (error) {
        debugPrint('Sensor stream error: $error');
      },
    );

    // 启动更新定时器
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateElapsedTime();
    });
  }

  void _onSensorData(SensorData data) {
    if (!state.isRunning) return;

    // 提取加速度数据 (已处理过的)
    final lateralAccel = data.processedAccel.x;
    final longitudinalAccel = data.processedAccel.y;
    final verticalAccel = data.processedAccel.z;

    // 更新物理引擎
    _physicsEngine.sensitivity = state.sensitivity;
    _physicsEngine.update(lateralAccel, longitudinalAccel);

    // 计算 G 值
    final gForce = _physicsEngine.calculateGForce(lateralAccel, longitudinalAccel);

    // 更新状态
    state = state.copyWith(
      lateralAccel: lateralAccel,
      longitudinalAccel: longitudinalAccel,
      verticalAccel: verticalAccel,
      spillPercentage: _physicsEngine.spillPercentage,
      gForce: gForce,
      accelDescription: _physicsEngine.getAccelLevelDescription(gForce),
      spillDescription: _physicsEngine.getSpillLevelDescription(_physicsEngine.spillPercentage),
    );
  }

  void _updateElapsedTime() {
    if (state.isRunning && state.startTime != null) {
      state = state.copyWith(
        elapsedTime: DateTime.now().difference(state.startTime!),
      );
    }
  }

  /// 请求传感器权限
  Future<bool> requestPermission() async {
    final controller = _ref.read(sensorServiceControllerProvider);
    final granted = await controller.requestPermission();

    if (granted) {
      // 启动传感器服务
      controller.start();
    }

    state = state.copyWith(hasPermission: granted);
    return granted;
  }

  /// 开始模拟
  void startSimulation() {
    if (!state.hasPermission) {
      requestPermission().then((granted) {
        if (granted) {
          _start();
        }
      });
    } else {
      _start();
    }
  }

  void _start() {
    _physicsEngine.reset();
    _ref.read(sensorServiceControllerProvider).start();

    state = state.copyWith(
      isRunning: true,
      startTime: DateTime.now(),
      elapsedTime: Duration.zero,
      spillPercentage: 0.0,
    );
  }

  /// 停止模拟
  void stopSimulation() {
    _ref.read(sensorServiceControllerProvider).stop();

    state = state.copyWith(
      isRunning: false,
    );
  }

  /// 重置模拟
  void resetSimulation() {
    _physicsEngine.reset();

    state = state.copyWith(
      isRunning: false,
      lateralAccel: 0.0,
      longitudinalAccel: 0.0,
      verticalAccel: 0.0,
      spillPercentage: 0.0,
      gForce: 0.0,
      elapsedTime: Duration.zero,
      startTime: null,
      accelDescription: '平稳',
      spillDescription: '几乎没撒',
    );
  }

  /// 校准传感器
  Future<void> calibrate() async {
    final controller = _ref.read(sensorServiceControllerProvider);
    await controller.calibrate();

    state = state.copyWith(isCalibrated: true);
  }

  /// 设置灵敏度
  void setSensitivity(double value) {
    state = state.copyWith(sensitivity: value.clamp(0.1, 2.0));
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _updateTimer?.cancel();
    _ref.read(sensorServiceControllerProvider).stop();
    super.dispose();
  }
}

/// 可乐杯模拟器状态提供者
final colaSimulatorProvider = StateNotifierProvider<ColaSimulatorNotifier, ColaSimulatorState>((ref) {
  return ColaSimulatorNotifier(ref);
});

/// 加速度历史数据 (用于图表)
final accelHistoryProvider = StateProvider<List<AccelDataPoint>>((ref) => []);

/// 加速度数据点
class AccelDataPoint {
  final DateTime timestamp;
  final double lateral;
  final double longitudinal;
  final double vertical;

  AccelDataPoint({
    required this.timestamp,
    required this.lateral,
    required this.longitudinal,
    required this.vertical,
  });
}

/// 添加加速度数据到历史
final addAccelHistoryProvider = Provider<Function>((ref) {
  return (SensorData data) {
    final history = ref.read(accelHistoryProvider);
    final newPoint = AccelDataPoint(
      timestamp: data.timestamp,
      lateral: data.processedAccel.x,
      longitudinal: data.processedAccel.y,
      vertical: data.processedAccel.z,
    );

    final newHistory = [...history, newPoint];
    // 只保留最近 300 个点 (约 10 秒 @ 30Hz)
    if (newHistory.length > 300) {
      newHistory.removeAt(0);
    }

    ref.read(accelHistoryProvider.notifier).state = newHistory;
  };
});
