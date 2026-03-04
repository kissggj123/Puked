
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';

/// 可乐杯物理引擎
/// 计算加速度对可乐液面的影响，包括倾斜角度和撒出量
class ColaPhysicsEngine {
  // 物理常量
  static const double _gravity = 9.80665; // 重力加速度 (m/s²)
  static const double _maxSpillAccel = 15.0; // 最大撒出加速度阈值 (m/s²)
  static const double _spillThreshold = 3.0; // 开始撒出的加速度阈值 (m/s²)

  // 配置参数
  double sensitivity; // 灵敏度 (0.0 - 2.0)
  final double maxTiltAngle; // 最大倾斜角度 (弧度)
  final double spillRate; // 撒出速率系数

  // 状态
  double _totalSpilled = 0.0; // 总撒出量 (0.0 - 1.0)
  double _currentSpillPercentage = 0.0; // 当前撒出百分比
  DateTime _lastUpdate = DateTime.now();

  // 历史数据 (用于平滑)
  final List<Vector2> _accelHistory = [];
  static const int _historySize = 5;

  ColaPhysicsEngine({
    this.sensitivity = 1.0,
    this.maxTiltAngle = math.pi / 4, // 45度
    this.spillRate = 0.5,
  });

  /// 重置物理状态
  void reset() {
    _totalSpilled = 0.0;
    _currentSpillPercentage = 0.0;
    _accelHistory.clear();
    _lastUpdate = DateTime.now();
  }

  /// 获取当前撒出百分比
  double get spillPercentage => _currentSpillPercentage.clamp(0.0, 1.0);

  /// 获取总撒出量
  double get totalSpilled => _totalSpilled.clamp(0.0, 1.0);

  /// 更新物理状态
  /// [lateralAccel]: 横向加速度 (m/s²)
  /// [longitudinalAccel]: 纵向加速度 (m/s²)
  /// 返回当前液面倾斜角度 (弧度)
  double update(double lateralAccel, double longitudinalAccel) {
    final now = DateTime.now();
    final dt = now.difference(_lastUpdate).inMilliseconds / 1000.0;
    _lastUpdate = now;

    // 添加到历史数据
    _accelHistory.add(Vector2(lateralAccel, longitudinalAccel));
    if (_accelHistory.length > _historySize) {
      _accelHistory.removeAt(0);
    }

    // 计算平滑后的加速度
    final smoothedAccel = _calculateSmoothedAcceleration();

    // 计算合成加速度大小
    final accelMagnitude = smoothedAccel.length;

    // 计算倾斜角度
    final tiltAngle = _calculateTiltAngle(smoothedAccel);

    // 计算撒出量
    _calculateSpillage(accelMagnitude, dt);

    return tiltAngle;
  }

  /// 计算平滑后的加速度
  Vector2 _calculateSmoothedAcceleration() {
    if (_accelHistory.isEmpty) return Vector2.zero();

    Vector2 sum = Vector2.zero();
    for (final accel in _accelHistory) {
      sum += accel;
    }
    return sum / _accelHistory.length.toDouble();
  }

  /// 计算液面倾斜角度
  /// 基于加速度方向，液面会倾向于与合成加速度垂直
  double _calculateTiltAngle(Vector2 accel) {
    if (accel.length < 0.1) return 0.0;

    // 计算合成加速度方向 (相对于垂直方向的角度)
    // atan2(x, y) 因为我们关心的是相对于纵向(y)的偏移
    final accelAngle = math.atan2(accel.x, accel.y);

    // 计算倾斜角度 (灵敏度调整)
    final rawTilt = accelAngle;
    final tiltMagnitude = (accel.length * sensitivity * 0.1).clamp(0.0, 1.0);

    // 应用最大倾斜限制
    return rawTilt * tiltMagnitude;
  }

  /// 计算撒出量
  void _calculateSpillage(double accelMagnitude, double dt) {
    // 如果加速度小于阈值，不撒出
    if (accelMagnitude < _spillThreshold) {
      return;
    }

    // 计算超出阈值的部分
    final excessAccel = accelMagnitude - _spillThreshold;

    // 计算本次撒出量
    // 公式: spill = (excessAccel / maxAccel) ^ 2 * spillRate * dt
    final normalizedExcess = (excessAccel / (_maxSpillAccel - _spillThreshold)).clamp(0.0, 1.0);
    final instantSpill = math.pow(normalizedExcess, 2) * spillRate * dt * 0.1;

    // 累积总撒出量
    _totalSpilled += instantSpill;
    _totalSpilled = _totalSpilled.clamp(0.0, 1.0);

    // 更新当前撒出百分比
    _currentSpillPercentage = _totalSpilled;
  }

  /// 计算液面倾斜的可视化参数
  /// 返回 [tiltX, tiltY] 用于 UI 渲染
  Vector2 calculateTiltVector(double lateralAccel, double longitudinalAccel) {
    // 应用灵敏度
    final adjustedLateral = lateralAccel * sensitivity;
    final adjustedLongitudinal = longitudinalAccel * sensitivity;

    // 计算倾斜向量
    // X: 横向倾斜 (左右)
    // Y: 纵向倾斜 (前后)
    final tiltX = (adjustedLateral / _gravity).clamp(-1.0, 1.0);
    final tiltY = (adjustedLongitudinal / _gravity).clamp(-1.0, 1.0);

    return Vector2(tiltX, tiltY);
  }

  /// 计算当前 G 值
  double calculateGForce(double lateralAccel, double longitudinalAccel) {
    final accelMagnitude = math.sqrt(
      lateralAccel * lateralAccel + longitudinalAccel * longitudinalAccel,
    );
    return accelMagnitude / _gravity;
  }

  /// 获取加速度等级描述
  String getAccelLevelDescription(double gForce) {
    if (gForce < 0.1) return '平稳';
    if (gForce < 0.3) return '轻微晃动';
    if (gForce < 0.5) return '明显晃动';
    if (gForce < 0.8) return '剧烈晃动';
    return '极度剧烈';
  }

  /// 获取撒出等级描述
  String getSpillLevelDescription(double percentage) {
    if (percentage < 0.05) return '几乎没撒';
    if (percentage < 0.2) return '少量撒出';
    if (percentage < 0.4) return '部分撒出';
    if (percentage < 0.6) return '大量撒出';
    if (percentage < 0.8) return '几乎撒完';
    return '完全撒完';
  }

  /// 获取颜色指示 (根据撒出量)
  int getSpillColorValue(double percentage) {
    // 从绿色 (0%) 到红色 (100%)
    if (percentage < 0.3) {
      // 绿色到黄色
      final t = percentage / 0.3;
      return _lerpColor(0xFF4CAF50, 0xFFFFC107, t);
    } else if (percentage < 0.7) {
      // 黄色到橙色
      final t = (percentage - 0.3) / 0.4;
      return _lerpColor(0xFFFFC107, 0xFFFF9800, t);
    } else {
      // 橙色到红色
      final t = (percentage - 0.7) / 0.3;
      return _lerpColor(0xFFFF9800, 0xFFF44336, t);
    }
  }

  /// 颜色插值
  int _lerpColor(int color1, int color2, double t) {
    final r1 = (color1 >> 16) & 0xFF;
    final g1 = (color1 >> 8) & 0xFF;
    final b1 = color1 & 0xFF;

    final r2 = (color2 >> 16) & 0xFF;
    final g2 = (color2 >> 8) & 0xFF;
    final b2 = color2 & 0xFF;

    final r = (r1 + (r2 - r1) * t).round();
    final g = (g1 + (g2 - g1) * t).round();
    final b = (b1 + (b2 - b1) * t).round();

    return (0xFF << 24) | (r << 16) | (g << 8) | b;
  }
}

/// 物理状态数据类
class PhysicsState {
  final double lateralAccel;
  final double longitudinalAccel;
  final double tiltAngle;
  final double spillPercentage;
  final double gForce;
  final String accelDescription;
  final String spillDescription;

  const PhysicsState({
    required this.lateralAccel,
    required this.longitudinalAccel,
    required this.tiltAngle,
    required this.spillPercentage,
    required this.gForce,
    required this.accelDescription,
    required this.spillDescription,
  });

  factory PhysicsState.zero() {
    return const PhysicsState(
      lateralAccel: 0.0,
      longitudinalAccel: 0.0,
      tiltAngle: 0.0,
      spillPercentage: 0.0,
      gForce: 0.0,
      accelDescription: '平稳',
      spillDescription: '几乎没撒',
    );
  }
}

/// 扩展 Vector2 操作
extension Vector2Extension on Vector2 {
  Vector2 operator /(double scalar) {
    return Vector2(x / scalar, y / scalar);
  }

  Vector2 operator +(Vector2 other) {
    return Vector2(x + other.x, y + other.y);
  }
}
