/**
 * GPS 惯性导航滤波器（JS 移植版）
 * 功能：融合 GPS 和 IMU 数据，提供平滑的定位
 */

class GpsInertialFilter {
  constructor() {
    // --- 阈值配置 ---
    this._minAccuracy = 0.5;
    this._stationarySpeedThres = 1.2; // < 1.2 m/s 视为静止 (约 4.3 km/h)
    this._headingLockSpeedThres = 3.0; // 航向锁定阈值
    this._maxPhysicalAccel = 10.0; // 物理加速度极限
    this._gpsWeakThres = 20.0; // 精度 > 20m 视为弱信号
    this._outlierSigma = 3.5; // 飞点剔除强度

    this.reset();
  }

  reset() {
    // --- 状态变量 (局部坐标系：米) ---
    this._x = 0.0;
    this._y = 0.0;
    this._vx = 0.0; // 东向速度分量
    this._vy = 0.0; // 北向速度分量

    // --- 协方差矩阵 (不确定性) ---
    this._pPos = 10.0;
    this._pVel = 1.0;

    // --- 参考系 ---
    this._refLat = 0.0;
    this._refLng = 0.0;
    this._cosRefLat = 0.0;
    this._isInitialized = false;

    // --- 辅助状态 ---
    this._lastTimestamp = 0;
    this._lastValidHeading = 0.0;
    this._smoothedHeading = 0.0;
    this._weakSignalCounter = 0;
  }

  process(lat, lng, accuracy, speed, heading, timestamp, speedAccuracy = -1, headingAccuracy = -1) {
    // 1. 初始化
    if (!this._isInitialized) {
      this._initialize(lat, lng, speed, heading, accuracy, timestamp);
      return [lat, lng];
    }

    let dt = (timestamp - this._lastTimestamp) / 1000.0;
    // 防止时间戳乱序或重复
    if (dt <= 0) return this._localToGlobal(this._x, this._y);
    // 限制最大步长，防止断网重连后飞出地球
    if (dt > 2.0) dt = 2.0;

    // ==========================================
    // 🛑 1. 零速修正 (ZUPT) - 解决"在家坐着漂移"
    // ==========================================
    // 如果速度极低，或者 (速度低 且 精度差)，强制认为静止
    let isStatic = speed >= 0 && speed < this._stationarySpeedThres;
    if (speed < 2.0 && accuracy > 10.0) isStatic = true; // 室内/弱信号下的强力锁定

    if (isStatic) {
      this._vx = 0.0;
      this._vy = 0.0;
      // 保持位置不变 (Lock Position)
      this._pPos = Math.min(this._pPos, accuracy * accuracy);
      this._lastTimestamp = timestamp;
      this._weakSignalCounter = 0;
      // 直接返回上一帧坐标，不接受 GPS 的跳动
      return this._localToGlobal(this._x, this._y);
    }

    // ==========================================
    // 🏎️ 2. 动力学预测 (Prediction w/ NHC)
    // ==========================================

    // --- 航向处理与平滑 ---
    let targetHeading = heading;
    let isHeadingReliable = heading >= 0 && (headingAccuracy < 0 || headingAccuracy < 20.0);

    // 如果航向不准，或者速度太低，使用上一次的航向
    if (speed <= this._headingLockSpeedThres || !isHeadingReliable) {
      targetHeading = this._lastValidHeading;
    } else {
      this._lastValidHeading = heading;
    }

    // 航向低通滤波：让转弯圆润
    if (Math.abs(targetHeading - this._smoothedHeading) > 180) {
      this._smoothedHeading = targetHeading; // 处理 0/360 突变
    } else {
      this._smoothedHeading = this._smoothedHeading * 0.8 + targetHeading * 0.2;
    }

    let radHeading = this._smoothedHeading * Math.PI / 180.0;

    // --- 速度向量分解 (NHC 约束) ---
    // 强制认为速度方向 = 车头方向
    let predVx = speed * Math.sin(radHeading);
    let predVy = speed * Math.cos(radHeading);

    // --- 动量融合 ---
    // 高速时 (惯性大) 更信历史速度，低速时更信实时速度
    let momentumFactor = Math.min(Math.max(speed / 30.0, 0.5), 0.95); // clamp(0.5, 0.95)

    this._vx = this._vx * momentumFactor + predVx * (1 - momentumFactor);
    this._vy = this._vy * momentumFactor + predVy * (1 - momentumFactor);

    // 位置外推
    this._x += this._vx * dt;
    this._y += this._vy * dt;

    // 预测方差扩散
    let processNoise = 0.5 * this._maxPhysicalAccel * dt * dt;
    this._pPos += this._pVel * dt * dt + processNoise;
    this._pVel += processNoise;

    // ==========================================
    // 🛰️ 3. 测量更新 (Measurement Update)
    // ==========================================
    const rEarth = 6371000.0;
    let measX = (lng - this._refLng) * (Math.PI / 180.0) * this._cosRefLat * rEarth;
    let measY = (lat - this._refLat) * (Math.PI / 180.0) * rEarth;

    // --- 动态信任权重 (Adaptive R) ---
    let rMeasBase = Math.max(accuracy, this._minAccuracy);

    // iPhone 14 Pro L5 GPS 优化 (High accuracy speed)
    if (speedAccuracy > 0 && speedAccuracy < 0.5) {
      rMeasBase *= 0.5; // 精度极高时，缩小方差，紧跟 GPS
    }

    // 弱信号惩罚 (解决 20m 跳变)
    if (accuracy > this._gpsWeakThres) {
      this._weakSignalCounter++;
      // 信号越差，R 值指数级暴增，强迫算法只信惯性
      rMeasBase *= Math.pow(1.5, Math.min(this._weakSignalCounter, 10));
    } else {
      this._weakSignalCounter = 0;
    }

    let rMeas = rMeasBase * rMeasBase;

    // --- 飞点剔除 (Innovation Check) ---
    let innovationX = measX - this._x;
    let innovationY = measY - this._y;
    let dist = Math.sqrt(innovationX * innovationX + innovationY * innovationY);
    // 动态门限
    let gate = this._outlierSigma * Math.sqrt(this._pPos + rMeas);

    // 如果偏差太大，判定为飞点
    if (dist > gate && dist > 15.0) {
      // 忽略此 GPS 点，只更新时间戳，返回预测位置
      this._lastTimestamp = timestamp;
      return this._localToGlobal(this._x, this._y);
    }

    // --- 卡尔曼更新 ---
    let k = this._pPos / (this._pPos + rMeas);

    this._x += k * innovationX;
    this._y += k * innovationY;

    // 更新后验方差
    this._pPos = (1.0 - k) * this._pPos;

    this._lastTimestamp = timestamp;
    return this._localToGlobal(this._x, this._y);
  }

  _initialize(lat, lng, speed, heading, accuracy, timestamp) {
    this._refLat = lat;
    this._refLng = lng;
    this._cosRefLat = Math.cos(this._refLat * Math.PI / 180.0);
    this._x = 0.0;
    this._y = 0.0;

    if (speed > 0 && heading >= 0) {
      this._lastValidHeading = heading;
      this._smoothedHeading = heading;
      let rad = heading * Math.PI / 180.0;
      this._vx = speed * Math.sin(rad);
      this._vy = speed * Math.cos(rad);
    } else {
      this._vx = 0.0;
      this._vy = 0.0;
    }

    this._pPos = accuracy * accuracy;
    this._pVel = 1.0;
    this._lastTimestamp = timestamp;
    this._isInitialized = true;
  }

  _localToGlobal(x, y) {
    const rEarth = 6371000.0;
    let newLat = this._refLat + (y / rEarth) * (180.0 / Math.PI);
    let newLng = this._refLng + (x / (rEarth * this._cosRefLat)) * (180.0 / Math.PI);
    return [newLat, newLng];
  }
}

// 导出类
window.GpsInertialFilter = GpsInertialFilter;
