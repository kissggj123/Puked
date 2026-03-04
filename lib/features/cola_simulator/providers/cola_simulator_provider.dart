import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:puked/services/web_sensor_service.dart';

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
    this.accelDescription = 'Stable',
    this.spillDescription = 'Almost none',
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
  Timer? _updateTimer;
  StreamSubscription<AccelData>? _sensorSubscription;

  ColaSimulatorNotifier(this._ref)
      : _physicsEngine = ColaPhysicsEngine(),
        super(const ColaSimulatorState()) {
    _init();
  }

  void _init() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateElapsedTime();
    });
  }

  void _updateElapsedTime() {
    if (state.isRunning && state.startTime != null) {
      state = state.copyWith(
        elapsedTime: DateTime.now().difference(state.startTime!),
      );
    }
  }

  void _onSensorData(AccelData data) {
    if (!state.isRunning) return;

    _physicsEngine.sensitivity = state.sensitivity;
    _physicsEngine.update(data.lateral, data.longitudinal);

    final gForce =
        _physicsEngine.calculateGForce(data.lateral, data.longitudinal);

    state = state.copyWith(
      lateralAccel: data.lateral,
      longitudinalAccel: data.longitudinal,
      verticalAccel: data.vertical,
      spillPercentage: _physicsEngine.spillPercentage,
      gForce: gForce,
      accelDescription: _physicsEngine.getAccelLevelDescription(gForce),
      spillDescription: _physicsEngine
          .getSpillLevelDescription(_physicsEngine.spillPercentage),
    );
  }

  Future<bool> requestPermission() async {
    final service = _ref.read(webSensorServiceProvider);
    final granted = await service.requestPermission();
    state = state.copyWith(hasPermission: granted);
    return granted;
  }

  void startSimulation() {
    if (!state.hasPermission) {
      requestPermission().then((granted) {
        if (granted) _start();
      });
    } else {
      _start();
    }
  }

  void _start() {
    _physicsEngine.reset();
    final service = _ref.read(webSensorServiceProvider);
    service.start();

    _sensorSubscription = service.accelStream.listen(_onSensorData);

    state = state.copyWith(
      isRunning: true,
      startTime: DateTime.now(),
      elapsedTime: Duration.zero,
      spillPercentage: 0.0,
    );
  }

  void stopSimulation() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _ref.read(webSensorServiceProvider).stop();

    state = state.copyWith(isRunning: false);
  }

  void resetSimulation() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
    _ref.read(webSensorServiceProvider).stop();
    _physicsEngine.reset();

    state = const ColaSimulatorState();
  }

  Future<void> calibrate() async {
    await _ref.read(webSensorServiceProvider).calibrate();
    state = state.copyWith(isCalibrated: true);
  }

  void setSensitivity(double value) {
    state = state.copyWith(sensitivity: value.clamp(0.1, 2.0));
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _sensorSubscription?.cancel();
    _ref.read(webSensorServiceProvider).stop();
    super.dispose();
  }
}

final colaSimulatorProvider =
    StateNotifierProvider<ColaSimulatorNotifier, ColaSimulatorState>((ref) {
  return ColaSimulatorNotifier(ref);
});

/// 物理计算引擎
class ColaPhysicsEngine {
  static const double _gravity = 9.80665;
  static const double _maxSpillAccel = 15.0;
  static const double _spillThreshold = 3.0;

  double sensitivity;
  final double maxTiltAngle;
  final double spillRate;

  double _totalSpilled = 0.0;
  double _currentSpillPercentage = 0.0;
  DateTime _lastUpdate = DateTime.now();

  final List<_Vec2> _accelHistory = [];
  static const int _historySize = 5;

  ColaPhysicsEngine({
    this.sensitivity = 1.0,
    this.maxTiltAngle = math.pi / 4,
    this.spillRate = 0.5,
  });

  void reset() {
    _totalSpilled = 0.0;
    _currentSpillPercentage = 0.0;
    _accelHistory.clear();
    _lastUpdate = DateTime.now();
  }

  double get spillPercentage => _currentSpillPercentage.clamp(0.0, 1.0);

  double update(double lateralAccel, double longitudinalAccel) {
    final now = DateTime.now();
    final dt = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;

    _accelHistory.add(_Vec2(lateralAccel, longitudinalAccel));
    if (_accelHistory.length > _historySize) {
      _accelHistory.removeAt(0);
    }

    final smoothedAccel = _calculateSmoothedAcceleration();
    final accelMagnitude = smoothedAccel.length;
    final tiltAngle = _calculateTiltAngle(smoothedAccel);

    _calculateSpillage(accelMagnitude, dt);

    return tiltAngle;
  }

  _Vec2 _calculateSmoothedAcceleration() {
    if (_accelHistory.isEmpty) return _Vec2(0, 0);
    double sumX = 0, sumY = 0;
    for (final accel in _accelHistory) {
      sumX += accel.x;
      sumY += accel.y;
    }
    return _Vec2(sumX / _accelHistory.length, sumY / _accelHistory.length);
  }

  double _calculateTiltAngle(_Vec2 accel) {
    if (accel.length < 0.1) return 0.0;
    final accelAngle = math.atan2(accel.x, accel.y);
    final tiltMagnitude = (accel.length * sensitivity * 0.1).clamp(0.0, 1.0);
    return accelAngle * tiltMagnitude;
  }

  void _calculateSpillage(double accelMagnitude, double dt) {
    if (accelMagnitude < _spillThreshold) return;

    final excessAccel = accelMagnitude - _spillThreshold;
    final normalizedExcess =
        (excessAccel / (_maxSpillAccel - _spillThreshold)).clamp(0.0, 1.0);
    final instantSpill = math.pow(normalizedExcess, 2) * spillRate * dt * 0.1;

    _totalSpilled += instantSpill;
    _totalSpilled = _totalSpilled.clamp(0.0, 1.0);
    _currentSpillPercentage = _totalSpilled;
  }

  double calculateGForce(double lateralAccel, double longitudinalAccel) {
    final accelMagnitude = math.sqrt(
        lateralAccel * lateralAccel + longitudinalAccel * longitudinalAccel);
    return accelMagnitude / _gravity;
  }

  String getAccelLevelDescription(double gForce) {
    if (gForce < 0.1) return 'Stable';
    if (gForce < 0.3) return 'Slight shake';
    if (gForce < 0.5) return 'Noticeable shake';
    if (gForce < 0.8) return 'Strong shake';
    return 'Extreme shake';
  }

  String getSpillLevelDescription(double percentage) {
    if (percentage < 0.05) return 'Almost none';
    if (percentage < 0.2) return 'Small amount';
    if (percentage < 0.4) return 'Partial spill';
    if (percentage < 0.6) return 'Large spill';
    if (percentage < 0.8) return 'Almost empty';
    return 'Completely spilled';
  }
}

class _Vec2 {
  final double x;
  final double y;

  _Vec2(this.x, this.y);

  double get length => math.sqrt(x * x + y * y);
}
