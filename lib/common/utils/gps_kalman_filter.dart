import 'dart:math';

/// 🚀 融合加强版 GPS + 惯性导航滤波器 (Physics-Enhanced PV Model)
/// 核心特性：
/// 1. ZUPT (零速修正): 停车时强制锁定坐标，消除静止漂移。
/// 2. NHC (非完整性约束): 强制轨迹跟随车头方向，消除转弯侧滑。
/// 3. Outlier Rejection (飞点剔除): 统计学过滤 20m+ 的异常跳变。
/// 4. Adaptive Noise (自适应抗噪): 根据精度动态调整 GPS 信任度。
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
  // 🟢 调高静止阈值：防止在家坐着时微小震动导致漂移
  final double _stationarySpeedThres = 1.2; // < 4.3 km/h 视为静止
  final double _headingLockSpeedThres = 3.0; // 航向锁定阈值
  final double _maxPhysicalAccel = 10.0; // 物理加速度极限
  final double _gpsWeakThres = 20.0; // 精度 > 20m 视为弱信号
  final double _outlierSigma = 3.5; // 飞点剔除强度

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
    // 1. 初始化
    if (!_isInitialized) {
      _initialize(lat, lng, speed, heading, accuracy, timestamp);
      return [lat, lng];
    }

    double dt = (timestamp - _lastTimestamp) / 1000.0;
    // 防止时间戳乱序或重复
    if (dt <= 0) return _localToGlobal(_x, _y);
    // 限制最大步长，防止断网重连后飞出地球
    if (dt > 2.0) dt = 2.0;

    // ==========================================
    // 🛑 1. 零速修正 (ZUPT) - 解决"在家坐着漂移"
    // ==========================================
    // 如果速度极低，或者 (速度低 且 精度差)，强制认为静止
    bool isStatic = speed >= 0 && speed < _stationarySpeedThres;
    if (speed < 2.0 && accuracy > 10.0) isStatic = true; // 室内/弱信号下的强力锁定

    if (isStatic) {
      _vx = 0.0;
      _vy = 0.0;
      // 保持位置不变 (Lock Position)
      _pPos = min(_pPos, accuracy * accuracy); 
      _lastTimestamp = timestamp;
      _weakSignalCounter = 0;
      // 直接返回上一帧坐标，不接受 GPS 的跳动
      return _localToGlobal(_x, _y);
    }

    // ==========================================
    // 🏎️ 2. 动力学预测 (Prediction w/ NHC)
    // ==========================================
    
    // --- 航向处理与平滑 ---
    double targetHeading = heading;
    bool isHeadingReliable = heading >= 0 && (headingAccuracy < 0 || headingAccuracy < 20.0);
    
    // 如果 iPhone 报告航向不准，或者速度太低，使用上一次的航向
    if (speed <= _headingLockSpeedThres || !isHeadingReliable) {
      targetHeading = _lastValidHeading;
    } else {
      _lastValidHeading = heading;
    }

    // 航向低通滤波：让转弯圆润
    if ((targetHeading - _smoothedHeading).abs() > 180) {
       _smoothedHeading = targetHeading; // 处理 0/360 突变
    } else {
       _smoothedHeading = _smoothedHeading * 0.8 + targetHeading * 0.2;
    }

    double radHeading = _smoothedHeading * pi / 180.0;

    // --- 速度向量分解 (NHC 约束) ---
    // 强制认为速度方向 = 车头方向
    double predVx = speed * sin(radHeading);
    double predVy = speed * cos(radHeading);

    // --- 动量融合 ---
    // 高速时(惯性大)更信历史速度，低速时更信实时速度
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
    
    // iPhone 14 Pro L5 GPS 优化
    if (speedAccuracy > 0 && speedAccuracy < 0.5) {
      rMeasBase *= 0.5; // 精度极高时，缩小方差，紧跟 GPS
    }

    // 弱信号惩罚 (解决 20m 跳变)
    if (accuracy > _gpsWeakThres) {
      _weakSignalCounter++;
      // 信号越差，R值指数级暴增，强迫算法只信惯性
      rMeasBase *= pow(1.5, min(_weakSignalCounter, 10)); 
    } else {
      _weakSignalCounter = 0;
    }

    double rMeas = rMeasBase * rMeasBase;

    // --- 飞点剔除 (Innovation Check) ---
    double innovationX = measX - _x;
    double innovationY = measY - _y;
    double dist = sqrt(innovationX * innovationX + innovationY * innovationY);
    // 动态门限
    double gate = _outlierSigma * sqrt(_pPos + rMeas);

    // 如果偏差太大，判定为飞点
    if (dist > gate && dist > 15.0) {
      // 忽略此 GPS 点，只更新时间戳，返回预测位置
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