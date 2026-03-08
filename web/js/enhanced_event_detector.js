/**
 * 增强型事件检测器
 * 自适应阈值、Jerk 检测、隧道场景优化
 */

const EnhancedEventDetector = {
  // 事件阈值（自适应）
  thresholds: {
    // 基础阈值（会根据驾驶风格自适应调整）
    hardAcceleration: { base: 2.5, current: 2.5, min: 1.5, max: 4.0 },
    hardBraking: { base: -3.0, current: -3.0, min: -4.5, max: -2.0 },
    hardTurn: { base: 2.0, current: 2.0, min: 1.2, max: 3.5 },
    bump: { base: 3.5, current: 3.5, min: 2.5, max: 6.0 },
    collision: { base: 7.0, current: 7.0, min: 5.0, max: 12.0 },
    
    // Jerk 阈值（加速度变化率）
    jerkLongitudinal: { base: 2.0, current: 2.0 },
    jerkLateral: { base: 1.5, current: 1.5 }
  },
  
  // 自适应统计
  adaptation: {
    accelHistory: [],
    jerkHistory: [],
    eventHistory: [],
    drivingStyle: 'normal', // 'gentle', 'normal', 'aggressive'
    sampleCount: 0,
    lastUpdateTime: 0
  },
  
  // Jerk 计算（加速度变化率）
  jerk: {
    longitudinal: 0,
    lateral: 0,
    vertical: 0
  },
  
  // 上次传感器数据
  lastData: null,
  lastTimestamp: 0,
  
  // 事件计数
  events: [],
  eventIdCounter: 0,
  
  // 隧道场景检测
  tunnelMode: {
    active: false,
    gpsLostTime: 0,
    lastKnownSpeed: 0,
    lastKnownAccel: 0,
    decayFactor: 0.98 // 速度衰减系数
  },
  
  /**
   * 检测事件
   */
  detect(sensorData, timestamp, gpsData = null) {
    const now = timestamp || Date.now();
    const dt = (now - this.lastTimestamp) / 1000; // 秒
    
    // 计算 Jerk（加速度变化率）
    if (this.lastData && dt > 0 && dt < 1.0) {
      this.jerk.longitudinal = (sensorData.longitudinalAccel - this.lastData.longitudinalAccel) / dt;
      this.jerk.lateral = (sensorData.lateralAccel - this.lastData.lateralAccel) / dt;
      this.jerk.vertical = (sensorData.verticalAccel - this.lastData.verticalAccel) / dt;
    }
    
    // 更新历史数据
    this.adaptation.accelHistory.push({
      longitudinal: sensorData.longitudinalAccel,
      lateral: sensorData.lateralAccel,
      vertical: sensorData.verticalAccel,
      timestamp: now
    });
    
    this.adaptation.jerkHistory.push({
      longitudinal: this.jerk.longitudinal,
      lateral: this.jerk.lateral,
      timestamp: now
    });
    
    // 限制历史数据长度
    if (this.adaptation.accelHistory.length > 1000) {
      this.adaptation.accelHistory.shift();
    }
    if (this.adaptation.jerkHistory.length > 1000) {
      this.adaptation.jerkHistory.shift();
    }
    
    // 检测各类事件
    const detectedEvents = [];
    
    // 1. 急加速检测
    if (sensorData.longitudinalAccel > this.thresholds.hardAcceleration.current) {
      detectedEvents.push(this.createEvent('hardAcceleration', sensorData.longitudinalAccel, now, gpsData));
    }
    
    // 2. 急减速检测
    if (sensorData.longitudinalAccel < this.thresholds.hardBraking.current) {
      detectedEvents.push(this.createEvent('hardBraking', sensorData.longitudinalAccel, now, gpsData));
    }
    
    // 3. 急转向检测
    if (Math.abs(sensorData.lateralAccel) > this.thresholds.hardTurn.current) {
      detectedEvents.push(this.createEvent('hardTurn', sensorData.lateralAccel, now, gpsData));
    }
    
    // 4. Jerk 检测（顿挫/摆动）
    if (Math.abs(this.jerk.longitudinal) > this.thresholds.jerkLongitudinal.current) {
      const type = this.jerk.longitudinal > 0 ? 'jerkAcceleration' : 'jerkBraking';
      detectedEvents.push(this.createEvent(type, this.jerk.longitudinal, now, gpsData, 'jerk'));
    }
    
    if (Math.abs(this.jerk.lateral) > this.thresholds.jerkLateral.current) {
      detectedEvents.push(this.createEvent('jerkTurn', this.jerk.lateral, now, gpsData, 'jerk'));
    }
    
    // 5. 颠簸检测（垂直加速度）
    if (sensorData.verticalAccel > this.thresholds.bump.current) {
      detectedEvents.push(this.createEvent('bump', sensorData.verticalAccel, now, gpsData));
    }
    
    // 6. 碰撞检测（极高加速度）
    const totalAccel = Math.sqrt(
      sensorData.longitudinalAccel ** 2 +
      sensorData.lateralAccel ** 2 +
      sensorData.verticalAccel ** 2
    );
    
    if (totalAccel > this.thresholds.collision.current) {
      detectedEvents.push(this.createEvent('collision', totalAccel, now, gpsData, 'severe'));
    }
    
    // 7. 隧道场景检测
    this.detectTunnelMode(gpsData, now);
    
    // 更新状态
    this.lastData = { ...sensorData };
    this.lastTimestamp = now;
    this.adaptation.sampleCount++;
    
    // 自适应调整阈值（每 100 个样本）
    if (this.adaptation.sampleCount % 100 === 0) {
      this.adaptThresholds();
    }
    
    // 保存事件
    detectedEvents.forEach(event => {
      this.events.push(event);
      this.adaptation.eventHistory.push(event);
    });
    
    // 限制事件历史长度
    if (this.adaptation.eventHistory.length > 100) {
      this.adaptation.eventHistory.shift();
    }
    
    return detectedEvents;
  },
  
  /**
   * 创建事件对象
   */
  createEvent(type, value, timestamp, gpsData, severityClass = null) {
    const eventId = ++this.eventIdCounter;
    
    // 确定严重等级
    let severity = 'light';
    let severityLevel = 1;
    let scorePenalty = 0.5;
    
    if (!severityClass) {
      // 根据超出阈值的程度判断严重等级
      const threshold = this.getThresholdForType(type);
      const ratio = Math.abs(value / threshold);
      
      if (ratio > 1.5) {
        severity = 'severe';
        severityLevel = 3;
        scorePenalty = 2.0;
      } else if (ratio > 1.2) {
        severity = 'moderate';
        severityLevel = 2;
        scorePenalty = 1.0;
      }
    } else if (severityClass === 'severe') {
      severity = 'severe';
      severityLevel = 3;
      scorePenalty = 3.0;
    }
    
    // 生成描述
    const desc = this.generateEventDescription(type, value, severity);
    
    return {
      id: eventId,
      type: type,
      value: value,
      severity: severity,
      severityClass: severityClass || severity,
      level: severityLevel,
      desc: desc,
      timestamp: timestamp,
      gpsData: gpsData ? { ...gpsData } : null,
      scorePenalty: scorePenalty
    };
  },
  
  /**
   * 获取事件类型的阈值
   */
  getThresholdForType(type) {
    const thresholdMap = {
      'hardAcceleration': this.thresholds.hardAcceleration.current,
      'hardBraking': Math.abs(this.thresholds.hardBraking.current),
      'hardTurn': this.thresholds.hardTurn.current,
      'bump': this.thresholds.bump.current,
      'collision': this.thresholds.collision.current,
      'jerkAcceleration': this.thresholds.jerkLongitudinal.current,
      'jerkBraking': this.thresholds.jerkLongitudinal.current,
      'jerkTurn': this.thresholds.jerkLateral.current
    };
    return thresholdMap[type] || 1.0;
  },
  
  /**
   * 生成事件描述
   */
  generateEventDescription(type, value, severity) {
    const descriptions = {
      'hardAcceleration': `急加速 ${value.toFixed(2)} m/s²`,
      'hardBraking': `急减速 ${value.toFixed(2)} m/s²`,
      'hardTurn': `急转向 ${value.toFixed(2)} m/s²`,
      'bump': `颠簸 ${value.toFixed(2)} m/s²`,
      'collision': `碰撞警告 ${value.toFixed(2)} m/s²`,
      'jerkAcceleration': `顿挫 ${(value * 9.8).toFixed(1)} G/s`,
      'jerkBraking': `顿挫 ${(value * 9.8).toFixed(1)} G/s`,
      'jerkTurn': `摆动 ${(value * 9.8).toFixed(1)} G/s`
    };
    return descriptions[type] || `${type} ${value.toFixed(2)}`;
  },
  
  /**
   * 自适应调整阈值
   */
  adaptThresholds() {
    const history = this.adaptation.eventHistory;
    if (history.length < 10) return;
    
    // 统计最近事件频率
    const recentEvents = history.slice(-100);
    const eventRate = recentEvents.length / 100; // 每 100 样本事件数
    
    // 判断驾驶风格
    if (eventRate > 0.3) {
      this.adaptation.drivingStyle = 'aggressive';
      // 提高阈值，减少误报
      this.adjustThreshold(0.1);
    } else if (eventRate < 0.05) {
      this.adaptation.drivingStyle = 'gentle';
      // 降低阈值，提高灵敏度
      this.adjustThreshold(-0.05);
    } else {
      this.adaptation.drivingStyle = 'normal';
    }
    
    console.log('[EventDetector] 驾驶风格:', this.adaptation.drivingStyle, '事件率:', eventRate.toFixed(2));
  },
  
  /**
   * 调整阈值
   */
  adjustThreshold(delta) {
    // 调整所有阈值
    for (const key in this.thresholds) {
      const threshold = this.thresholds[key];
      const newValue = threshold.current * (1 + delta);
      
      // 限制在最小/最大范围内
      threshold.current = Math.max(threshold.min, Math.min(threshold.max, newValue));
    }
    
    console.log('[EventDetector] 阈值调整:', {
      hardAcceleration: this.thresholds.hardAcceleration.current.toFixed(2),
      hardBraking: this.thresholds.hardBraking.current.toFixed(2),
      hardTurn: this.thresholds.hardTurn.current.toFixed(2)
    });
  },
  
  /**
   * 检测隧道模式
   */
  detectTunnelMode(gpsData, timestamp) {
    if (!gpsData) {
      // GPS 信号丢失
      if (!this.tunnelMode.active) {
        this.tunnelMode.active = true;
        this.tunnelMode.gpsLostTime = timestamp;
        console.log('[EventDetector] 进入隧道模式');
      }
    } else {
      // GPS 信号恢复
      if (this.tunnelMode.active) {
        this.tunnelMode.active = false;
        console.log('[EventDetector] 离开隧道');
      }
      this.tunnelMode.lastKnownSpeed = gpsData.speed || 0;
    }
    
    // 隧道中速度衰减模拟
    if (this.tunnelMode.active) {
      const timeInTunnel = (timestamp - this.tunnelMode.gpsLostTime) / 1000;
      // 假设缓慢减速
      this.tunnelMode.lastKnownSpeed *= Math.pow(this.tunnelMode.decayFactor, timeInTunnel / 10);
    }
  },
  
  /**
   * 获取隧道中的推算速度
   */
  getTunnelSpeed() {
    return this.tunnelMode.lastKnownSpeed;
  },
  
  /**
   * 获取事件统计
   */
  getStatistics() {
    const now = Date.now();
    const recentEvents = this.events.filter(e => now - e.timestamp < 60000); // 最近 1 分钟
    
    return {
      totalEvents: this.events.length,
      recentEvents: recentEvents.length,
      drivingStyle: this.adaptation.drivingStyle,
      sampleCount: this.adaptation.sampleCount,
      thresholds: {
        hardAcceleration: this.thresholds.hardAcceleration.current,
        hardBraking: this.thresholds.hardBraking.current,
        hardTurn: this.thresholds.hardTurn.current
      },
      inTunnel: this.tunnelMode.active
    };
  },
  
  /**
   * 重置检测器
   */
  reset() {
    this.events = [];
    this.eventIdCounter = 0;
    this.lastData = null;
    this.lastTimestamp = 0;
    this.adaptation.accelHistory = [];
    this.adaptation.jerkHistory = [];
    this.adaptation.eventHistory = [];
    this.adaptation.sampleCount = 0;
    this.tunnelMode.active = false;
    
    // 重置阈值为基准值
    for (const key in this.thresholds) {
      this.thresholds[key].current = this.thresholds[key].base;
    }
  },
  
  /**
   * 获取最近事件
   */
  getRecentEvents(count = 10) {
    return this.events.slice(-count).reverse();
  }
};

// 导出模块
window.EnhancedEventDetector = EnhancedEventDetector;
