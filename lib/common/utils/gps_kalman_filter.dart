import 'dart:math';

/// 🚀 融合加强版 GPS + 惯性导航滤波器 (Physics-Enhanced PV Model)
/// 结合了 卡尔曼滤波(KF) 的数值稳定性和 扩展卡尔曼(EKF) 的动力学约束(NHC)
/// 针对 iPhone 14 Pro 的 L5 GPS 和高频传感器特性进行了微调
class GpsInertialFilter {
  // --- 状态变量 (局部坐标系: 米) ---
  double _x = 0.0;
  double _y = 0.0;
  double _vx = 0.0; // 东向速度分量
  double _vy = 0.0; // 北向速度分量

  // --- 协方差矩阵 (不确定性) ---
  double _pPos = 10.0; 
  double _pVel = 1.0;

  // --- 参考系 ---
  double _refLat = 0.0;
  double _refLng = 0.0;
  double _cosRefLat = 0.0;
  bool _isInitialized = false;

  // --- 辅助状态 ---
  int _lastTimestamp = 0;
  double _lastValidHeading = 0.0;
  int _weakSignalCounter = 0;
  
  // 🟢 融合优化：平滑后的航向 (用于对抗电子罗盘抖动)
  double _smoothedHeading = 0.0;

  // --- 阈值配置 ---
  final double _minAccuracy = 0.5; 
  final double _stationarySpeedThres = 0.4; // 停车阈值
  final double _headingLockSpeedThres = 3.0; // 航向锁定阈值
  final double _maxPhysicalAccel = 10.0; // 物理加速度极限
  final double _gpsWeakThres = 20.0;
  final double _outlierSigma = 3.5; // 放宽一点飞点判定，避免误杀正常的高速变道

  void reset() {
    _isInitialized = false;
    _pPos = 10.0;
    _pVel = 1.0;
    _lastTimestamp = 0;
    _lastValidHeading = 0.0;
    _smoothedHeading = 0.0;
    _weakSignalCounter = 0;
  }

  List<double> process({
    required double lat,
    required double lng,
    required double accuracy,
    required double speed,
    required double heading,
    required int timestamp,
    double speedAccuracy = -1,
    double headingAccuracy = -1,
  }) {
    if (!_isInitialized) {
      _initialize(lat, lng, speed, heading, accuracy, timestamp);
      return [lat, lng];
    }

    double dt = (timestamp - _lastTimestamp) / 1000.0;
    if (dt <= 0) return _localToGlobal(_x, _y);
    if (dt > 2.0) dt = 2.0;

    // ==========================================
    // 🛑 1. 零速修正 (ZUPT)
    // ==========================================
    if (speed >= 0 && speed < _stationarySpeedThres) {
      _vx = 0.0;
      _vy = 0.0;
      _pPos = min(_pPos, accuracy * accuracy); // 收敛方差
      _lastTimestamp = timestamp;
      _weakSignalCounter = 0;
      return _localToGlobal(_x, _y);
    }

    // ==========================================
    // 🏎️ 2. 动力学预测 (Prediction w/ NHC)
    // ==========================================
    
    // --- 航向处理与平滑 ---
    double targetHeading = heading;
    bool isHeadingReliable = heading >= 0 && (headingAccuracy < 0 || headingAccuracy < 20.0);
    
    // 如果 iPhone 报告航向不准，或者速度太低（指南针容易受干扰），使用上一次的航向
    if (speed <= _headingLockSpeedThres || !isHeadingReliable) {
      targetHeading = _lastValidHeading;
    } else {
      _lastValidHeading = heading;
    }

    // 航向低通滤波：让车头转动更圆润，防止蛇形走位
    // 这里的 0.1 系数意味着我们让航向有一定惯性
    if ((targetHeading - _smoothedHeading).abs() > 180) {
       _smoothedHeading = targetHeading; // 处理 0/360 跳变，直接重置
    } else {
       _smoothedHeading = _smoothedHeading * 0.8 + targetHeading * 0.2;
    }

    double radHeading = _smoothedHeading * pi / 180.0;

    // --- 速度向量分解 (NHC 约束核心) ---
    // 强制认为速度方向 = 车头方向 (车辆不会横着漂移)
    double predVx = speed * sin(radHeading);
    double predVy = speed * cos(radHeading);

    // --- 动量融合 ---
    // 融合：上一时刻的滤波速度 (_vx) vs 当前观测速度 (predVx)
    // 动量因子：速度越快，惯性越大，越难改变方向 (0.9 vs 0.1)
    // 速度慢时，更灵敏 (0.5 vs 0.5)
    double momentumFactor = (speed / 30.0).clamp(0.5, 0.95);
    
    _vx = _vx * momentumFactor + predVx * (1 - momentumFactor);
    _vy = _vy * momentumFactor + predVy * (1 - momentumFactor);

    // 位置外推
    _x += _vx * dt;
    _y += _vy * dt;

    // 预测方差扩散
    double processNoise = 0.5 * _maxPhysicalAccel * dt * dt;
    _pPos += _pVel * dt * dt + processNoise;
    _pVel += processNoise;

    // ==========================================
    // 🛰️ 3. 测量更新 (Measurement Update)
    // ==========================================
    const double rEarth = 6371000.0;
    double measX = (lng - _refLng) * (pi / 180.0) * _cosRefLat * rEarth;
    double measY = (lat - _refLat) * (pi / 180.0) * rEarth;

    // --- 动态信任权重 (Adaptive R) ---
    double rMeasBase = max(accuracy, _minAccuracy);
    
    // L5 GPS 优化：如果速度精度极高，大幅增加对位置的信任
    if (speedAccuracy > 0 && speedAccuracy < 0.5) {
      rMeasBase *= 0.5; 
    }

    // 弱信号惩罚
    if (accuracy > _gpsWeakThres) {
      _weakSignalCounter++;
      // 信号弱时，R 值指数级暴增，强迫算法只信惯性
      rMeasBase *= pow(1.5, min(_weakSignalCounter, 10)); 
    } else {
      _weakSignalCounter = 0;
    }

    double rMeas = rMeasBase * rMeasBase;

    // --- 飞点剔除 (Innovation Check) ---
    double innovationX = measX - _x;
    double innovationY = measY - _y;
    double dist = sqrt(innovationX * innovationX + innovationY * innovationY);
    double gate = _outlierSigma * sqrt(_pPos + rMeas);

    if (dist > gate && dist > 15.0) {
      // 判定为飞点，只更新时间戳，保留预测位置
      _lastTimestamp = timestamp;
      return _localToGlobal(_x, _y);
    }

    // --- 卡尔曼更新 ---
    double k = _pPos / (_pPos + rMeas);
    
    _x += k * innovationX;
    _y += k * innovationY;
    
    // 更新后验方差
    _pPos = (1.0 - k) * _pPos;

    _lastTimestamp = timestamp;
    return _localToGlobal(_x, _y);
  }

  void _initialize(double lat, double lng, double speed, double heading, double accuracy, int timestamp) {
    _refLat = lat;
    _refLng = lng;
    _cosRefLat = cos(_refLat * pi / 180.0);
    _x = 0.0;
    _y = 0.0;
    
    if (speed > 0 && heading >= 0) {
      _lastValidHeading = heading;
      _smoothedHeading = heading;
      double rad = heading * pi / 180.0;
      _vx = speed * sin(rad);
      _vy = speed * cos(rad);
    } else {
      _vx = 0.0;
      _vy = 0.0;
    }
    
    _pPos = accuracy * accuracy;
    _pVel = 1.0; 
    _lastTimestamp = timestamp;
    _isInitialized = true;
  }

  List<double> _localToGlobal(double x, double y) {
    const double rEarth = 6371000.0;
    double newLat = _refLat + (y / rEarth) * (180.0 / pi);
    double newLng = _refLng + (x / (rEarth * _cosRefLat)) * (180.0 / pi);
    return [newLat, newLng];
  }
}