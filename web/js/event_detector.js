/**
 * 事件检测模块
 * 检测急加速、急减速、急转弯、颠簸等驾驶事件
 */

const EventDetector = {
  // 事件阈值
  thresholds: {
    hardAcceleration: 3.0,    // 急加速阈值 (m/s²)
    hardBraking: -3.5,        // 急减速阈值 (m/s²)
    hardTurn: 2.5,            // 急转弯阈值 (m/s²)
    bump: 4.0,                // 颠簸阈值 (m/s²)
    collision: 8.0            // 碰撞阈值 (m/s²)
  },

  // 事件记录
  events: [],
  lastEventTime: 0,
  eventCooldown: 1000,        // 事件冷却时间 (ms)

  // 平滑驾驶评分
  smoothScore: 100,
  scoreDecay: {
    hardAcceleration: 5,
    hardBraking: 6,
    hardTurn: 4,
    bump: 2,
    collision: 20
  },

  /**
   * 检测事件
   */
  detect(totalAccel, sensorData) {
    const now = Date.now();
    
    // 检查冷却时间
    if (now - this.lastEventTime < this.eventCooldown) return;

    const longitudinal = sensorData.longitudinalAccel;
    const lateral = sensorData.lateralAccel;
    const vertical = sensorData.verticalAccel;

    let detectedEvent = null;

    // 检测碰撞
    if (totalAccel > this.thresholds.collision) {
      detectedEvent = {
        type: 'collision',
        severity: 'severe',
        timestamp: now,
        value: totalAccel,
        description: '检测到碰撞'
      };
    }
    // 检测急加速
    else if (longitudinal > this.thresholds.hardAcceleration) {
      detectedEvent = {
        type: 'hardAcceleration',
        severity: 'moderate',
        timestamp: now,
        value: longitudinal,
        description: '急加速'
      };
    }
    // 检测急减速
    else if (longitudinal < this.thresholds.hardBraking) {
      detectedEvent = {
        type: 'hardBraking',
        severity: 'moderate',
        timestamp: now,
        value: longitudinal,
        description: '急刹车'
      };
    }
    // 检测急转弯
    else if (Math.abs(lateral) > this.thresholds.hardTurn) {
      detectedEvent = {
        type: 'hardTurn',
        severity: 'moderate',
        timestamp: now,
        value: lateral,
        description: '急转弯'
      };
    }
    // 检测颠簸
    else if (Math.abs(vertical) > this.thresholds.bump) {
      detectedEvent = {
        type: 'bump',
        severity: 'minor',
        timestamp: now,
        value: vertical,
        description: '颠簸'
      };
    }

    // 记录事件
    if (detectedEvent) {
      this.events.push(detectedEvent);
      this.lastEventTime = now;
      
      // 减少平滑评分
      this.smoothScore = Math.max(0, this.smoothScore - this.scoreDecay[detectedEvent.type]);
      
      console.log('[EventDetector] 检测到事件:', detectedEvent);
    }
  },

  /**
   * 重置检测器
   */
  reset() {
    this.events = [];
    this.smoothScore = 100;
    this.lastEventTime = 0;
  },

  /**
   * 获取事件统计
   */
  getStatistics() {
    const stats = {
      total: this.events.length,
      byType: {},
      bySeverity: {
        severe: 0,
        moderate: 0,
        minor: 0
      }
    };

    this.events.forEach(event => {
      // 按类型统计
      if (!stats.byType[event.type]) {
        stats.byType[event.type] = 0;
      }
      stats.byType[event.type]++;

      // 按严重程度统计
      stats.bySeverity[event.severity]++;
    });

    return stats;
  },

  /**
   * 获取平滑驾驶评分
   */
  getSmoothScore() {
    return this.smoothScore;
  },

  /**
   * 获取事件列表
   */
  getEvents() {
    return this.events;
  }
};

// 导出模块
window.EventDetector = EventDetector;
