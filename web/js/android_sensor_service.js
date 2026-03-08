/**
 * Android 车机专用传感器服务
 * 针对 Chromium 浏览器优化，支持 HTTPS 传感器权限请求
 */

const AndroidSensorService = {
  // 传感器状态
  isAvailable: false,
  hasPermission: false,
  permissionGranted: false,
  
  // 传感器数据
  acceleration: { x: 0, y: 0, z: 0 },
  accelerationIncludingGravity: { x: 0, y: 0, z: 0 },
  rotationRate: { alpha: 0, beta: 0, gamma: 0 },
  orientation: { alpha: 0, beta: 0, gamma: 0 },
  
  // 校准参数（自适应）
  calibration: {
    accelBias: { x: 0, y: 0, z: 0 },
    gyroBias: { x: 0, y: 0, z: 0 },
    gravityAlignment: { x: 0, y: 0, z: 1 }
  },
  
  // 自适应统计
  stats: {
    accelSamples: [],
    gyroSamples: [],
    sampleCount: 0,
    isCalibrating: true
  },
  
  // 回调函数
  callbacks: [],
  
  // 检测 Android 车机环境
  isAndroidHeadUnit() {
    const ua = navigator.userAgent;
    return /Android/i.test(ua) && (/Car/i.test(ua) || /Auto/i.test(ua) || /Vehicle/i.test(ua));
  },
  
  // 检测 Chromium 浏览器
  isChromium() {
    return /Chrome/i.test(navigator.userAgent) && /Google Inc/i.test(navigator.vendor);
  },
  
  // 检测是否需要 HTTPS
  requiresHTTPS() {
    return window.location.protocol !== 'https:' && window.location.hostname !== 'localhost';
  },
  
  /**
   * 请求传感器权限（Android 13+ / Chromium）
   */
  async requestPermission() {
    console.log('[AndroidSensor] 请求传感器权限...');
    
    // 检查 API 支持
    if (typeof DeviceMotionEvent !== 'undefined' && typeof DeviceMotionEvent.requestPermission === 'function') {
      try {
        // Android 13+ 需要显式请求权限
        const permissionState = await DeviceMotionEvent.requestPermission();
        this.hasPermission = permissionState === 'granted';
        this.permissionGranted = this.hasPermission;
        
        if (this.hasPermission) {
          console.log('[AndroidSensor] 运动传感器权限已授予');
        } else {
          console.warn('[AndroidSensor] 运动传感器权限被拒绝');
        }
        
        // 同时请求方向传感器权限
        if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
          const orientPermission = await DeviceOrientationEvent.requestPermission();
          if (orientPermission === 'granted') {
            console.log('[AndroidSensor] 方向传感器权限已授予');
          }
        }
        
        return this.hasPermission;
      } catch (error) {
        console.error('[AndroidSensor] 权限请求失败:', error);
        this.hasPermission = false;
        return false;
      }
    } else {
      // 旧版浏览器，直接尝试监听
      console.log('[AndroidSensor] 使用传统传感器 API');
      this.hasPermission = true;
      this.permissionGranted = true;
      return true;
    }
  },
  
  /**
   * 初始化传感器
   */
  init(callback) {
    if (callback) {
      this.callbacks.push(callback);
    }
    
    // 检测环境
    const isAndroid = this.isAndroidHeadUnit();
    const isChromium = this.isChromium();
    const needsHTTPS = this.requiresHTTPS();
    
    console.log('[AndroidSensor] 环境检测:', {
      isAndroid,
      isChromium,
      needsHTTPS,
      isHTTPS: window.location.protocol === 'https:'
    });
    
    // HTTPS 检查
    if (needsHTTPS) {
      console.warn('[AndroidSensor] 传感器 API 需要 HTTPS 环境');
      // 不阻止，但提示用户
    }
    
    // 注册事件监听
    this.registerListeners();
    
    // 开始自适应校准
    this.startAdaptiveCalibration();
  },
  
  /**
   * 注册传感器监听器
   */
  registerListeners() {
    // 运动传感器（加速度）
    window.addEventListener('devicemotion', (event) => {
      this.acceleration.x = event.acceleration?.x || 0;
      this.acceleration.y = event.acceleration?.y || 0;
      this.acceleration.z = event.acceleration?.z || 0;
      
      this.accelerationIncludingGravity.x = event.accelerationIncludingGravity?.x || 0;
      this.accelerationIncludingGravity.y = event.accelerationIncludingGravity?.y || 0;
      this.accelerationIncludingGravity.z = event.accelerationIncludingGravity?.z || 0;
      
      // 应用校准
      const calibrated = this.calibrateAcceleration(this.acceleration);
      
      // 通知回调
      this.notifyCallbacks(calibrated);
      
      // 收集校准样本
      this.collectCalibrationSample(this.acceleration);
    }, true);
    
    // 方向传感器（角速度）
    window.addEventListener('deviceorientation', (event) => {
      this.rotationRate.alpha = event.alpha || 0;
      this.rotationRate.beta = event.beta || 0;
      this.rotationRate.gamma = event.gamma || 0;
      
      this.orientation.alpha = event.alpha || 0;
      this.orientation.beta = event.beta || 0;
      this.orientation.gamma = event.gamma || 0;
    }, true);
    
    this.isAvailable = true;
    console.log('[AndroidSensor] 传感器监听器已注册');
  },
  
  /**
   * 校准加速度（去除重力分量和偏置）
   */
  calibrateAcceleration(accel) {
    // 去除偏置
    const x = accel.x - this.calibration.accelBias.x;
    const y = accel.y - this.calibration.accelBias.y;
    const z = accel.z - this.calibration.accelBias.z;
    
    // 坐标转换（将设备坐标系转换到车辆坐标系）
    // 假设手机竖直放置，屏幕朝前
    const vehicleAccel = {
      lateral: -x,      // 横向加速度（左右）
      longitudinal: -z,  // 纵向加速度（前后）
      vertical: y        // 垂直加速度（上下）
    };
    
    return vehicleAccel;
  },
  
  /**
   * 收集校准样本
   */
  collectCalibrationSample(accel) {
    if (!this.stats.isCalibrating) return;
    
    this.stats.accelSamples.push(accel);
    this.stats.sampleCount++;
    
    // 每 100 个样本更新一次偏置估计
    if (this.stats.sampleCount % 100 === 0 && this.stats.sampleCount < 1000) {
      this.updateCalibration();
    }
    
    // 1000 个样本后完成校准
    if (this.stats.sampleCount >= 1000) {
      this.finishCalibration();
    }
  },
  
  /**
   * 更新校准参数
   */
  updateCalibration() {
    const samples = this.stats.accelSamples;
    const count = samples.length;
    
    if (count === 0) return;
    
    // 计算平均值作为偏置估计
    let sumX = 0, sumY = 0, sumZ = 0;
    samples.forEach(s => {
      sumX += s.x;
      sumY += s.y;
      sumZ += s.z;
    });
    
    this.calibration.accelBias.x = sumX / count;
    this.calibration.accelBias.y = sumY / count;
    this.calibration.accelBias.z = sumZ / count - 9.81; // 减去重力加速度
    
    console.log('[AndroidSensor] 校准参数更新:', this.calibration.accelBias);
  },
  
  /**
   * 完成校准
   */
  finishCalibration() {
    this.stats.isCalibrating = false;
    console.log('[AndroidSensor] 自适应校准完成');
  },
  
  /**
   * 开始自适应校准
   */
  startAdaptiveCalibration() {
    console.log('[AndroidSensor] 开始自适应校准...');
    this.stats.isCalibrating = true;
  },
  
  /**
   * 通知所有回调
   */
  notifyCallbacks(data) {
    this.callbacks.forEach(cb => {
      if (typeof cb === 'function') {
        cb(data);
      }
    });
  },
  
  /**
   * 获取传感器状态
   */
  getStatus() {
    return {
      isAvailable: this.isAvailable,
      hasPermission: this.hasPermission,
      isCalibrating: this.stats.isCalibrating,
      sampleCount: this.stats.sampleCount,
      isAndroid: this.isAndroidHeadUnit(),
      isChromium: this.isChromium()
    };
  },
  
  /**
   * 重置校准
   */
  resetCalibration() {
    this.stats.isCalibrating = true;
    this.stats.accelSamples = [];
    this.stats.gyroSamples = [];
    this.stats.sampleCount = 0;
    this.calibration.accelBias = { x: 0, y: 0, z: 0 };
    this.calibration.gyroBias = { x: 0, y: 0, z: 0 };
    console.log('[AndroidSensor] 校准已重置');
  }
};

// 导出模块
window.AndroidSensorService = AndroidSensorService;
