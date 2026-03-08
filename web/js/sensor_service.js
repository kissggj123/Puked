/**
 * 传感器服务模块
 * 负责获取和处理设备传感器数据
 */

const SensorService = {
  isRunning: false,
  callback: null,
  calibrationOffset: { x: 0, y: 0, z: 0 },
  recentReadings: [],
  calibrationSamples: 30,

  /**
   * 初始化传感器
   */
  init(callback) {
    this.callback = callback;
    console.log('[SensorService] 初始化完成');
  },

  /**
   * 开始获取传感器数据
   */
  start() {
    if (this.isRunning) return;
    this.isRunning = true;

    // 检测是否支持 DeviceMotion
    if (typeof DeviceMotionEvent !== 'undefined') {
      // 请求权限（iOS 13+）
      this.requestPermission().then(granted => {
        if (granted) {
          window.addEventListener('devicemotion', (e) => this.handleMotion(e));
          console.log('[SensorService] DeviceMotion 已启动');
        } else {
          console.warn('[SensorService] 权限被拒绝，使用模拟数据');
          this.startSimulation();
        }
      });
    } else {
      console.warn('[SensorService] 不支持 DeviceMotion，使用模拟数据');
      this.startSimulation();
    }
  },

  /**
   * 请求权限（iOS 13+）
   */
  async requestPermission() {
    return new Promise((resolve) => {
      // 检查是否需要请求权限
      if (typeof DeviceMotionEvent.requestPermission === 'function') {
        DeviceMotionEvent.requestPermission()
          .then(response => {
            resolve(response === 'granted');
          })
          .catch(error => {
            console.error('[SensorService] 权限请求失败:', error);
            resolve(false);
          });
      } else {
        // 非 iOS 13+ 设备
        resolve(true);
      }
    });
  },

  /**
   * 处理 DeviceMotion 事件
   */
  handleMotion(event) {
    if (!this.isRunning || !this.callback) return;

    const accel = event.accelerationIncludingGravity;
    const rotationRate = event.rotationRate;

    if (!accel) return;

    // 获取加速度数据
    const x = accel.x || 0;
    const y = accel.y || 0;
    const z = accel.z || 0;

    // 应用校准偏移
    const calibratedX = x - this.calibrationOffset.x;
    const calibratedY = y - this.calibrationOffset.y;
    const calibratedZ = z - this.calibrationOffset.z;

    // 保存最近读数用于校准
    this.recentReadings.push({ x, y, z });
    if (this.recentReadings.length > this.calibrationSamples) {
      this.recentReadings.shift();
    }

    // 调用回调
    this.callback({
      lateral: calibratedX,
      longitudinal: calibratedY,
      vertical: calibratedZ,
      gyroX: rotationRate ? rotationRate.alpha || 0 : 0,
      gyroY: rotationRate ? rotationRate.beta || 0 : 0,
      gyroZ: rotationRate ? rotationRate.gamma || 0 : 0
    });
  },

  /**
   * 启动模拟数据（用于测试）
   */
  startSimulation() {
    const interval = setInterval(() => {
      if (!this.isRunning) {
        clearInterval(interval);
        return;
      }

      // 生成模拟数据
      const time = Date.now() / 1000;
      const data = {
        lateral: Math.sin(time) * 2 + (Math.random() - 0.5) * 0.5,
        longitudinal: Math.cos(time) * 2 + (Math.random() - 0.5) * 0.5,
        vertical: (Math.random() - 0.5) * 0.3,
        gyroX: (Math.random() - 0.5) * 0.1,
        gyroY: (Math.random() - 0.5) * 0.1,
        gyroZ: (Math.random() - 0.5) * 0.1
      };

      if (this.callback) {
        this.callback(data);
      }
    }, 50); // 20Hz

    console.log('[SensorService] 模拟数据已启动');
  },

  /**
   * 停止获取传感器数据
   */
  stop() {
    this.isRunning = false;
    window.removeEventListener('devicemotion', (e) => this.handleMotion(e));
    console.log('[SensorService] 已停止');
  },

  /**
   * 校准传感器
   */
  calibrate() {
    if (this.recentReadings.length === 0) {
      console.warn('[SensorService] 没有足够的读数进行校准');
      return;
    }

    // 计算平均值
    let sumX = 0, sumY = 0, sumZ = 0;
    this.recentReadings.forEach(r => {
      sumX += r.x;
      sumY += r.y;
      sumZ += r.z;
    });

    this.calibrationOffset = {
      x: sumX / this.recentReadings.length,
      y: sumY / this.recentReadings.length,
      z: sumZ / this.recentReadings.length
    };

    console.log('[SensorService] 校准完成:', this.calibrationOffset);
  },

  /**
   * 获取校准状态
   */
  getCalibrationStatus() {
    return {
      calibrated: this.calibrationOffset.x !== 0 || this.calibrationOffset.y !== 0 || this.calibrationOffset.z !== 0,
      offset: this.calibrationOffset,
      samples: this.recentReadings.length
    };
  }
};

// 导出模块
window.SensorService = SensorService;
