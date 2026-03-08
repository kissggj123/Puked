/**
 * 专业仪表盘模块
 * 包含：惯性球、加速度波形图、行驶统计、事件列表
 */

const ProfessionalDashboard = {
  // 加速度波形图数据
  longChartData: [],
  latChartData: [],
  maxChartPoints: 100,
  
  // 行驶统计
  startTime: 0,
  duration: 0,
  distance: 0,
  lastPosition: null,
  
  // 惯性球位置
  accBallX: 0,
  accBallY: 0,
  
  // Canvas 上下文
  longChartCtx: null,
  latChartCtx: null,
  
  /**
   * 初始化仪表盘
   */
  init(longCanvas, latCanvas) {
    if (longCanvas) {
      this.longChartCtx = longCanvas.getContext('2d');
      this.resizeCanvas(longCanvas);
    }
    if (latCanvas) {
      this.latChartCtx = latCanvas.getContext('2d');
      this.resizeCanvas(latCanvas);
    }
    
    // 窗口大小调整
    window.addEventListener('resize', () => {
      if (longCanvas) this.resizeCanvas(longCanvas);
      if (latCanvas) this.resizeCanvas(latCanvas);
    });
    
    console.log('[ProfessionalDashboard] 初始化完成');
  },
  
  /**
   * 调整 Canvas 大小
   */
  resizeCanvas(canvas) {
    const rect = canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    const ctx = canvas.getContext('2d');
    ctx.scale(dpr, dpr);
    return { width: rect.width, height: rect.height };
  },
  
  /**
   * 更新数据
   */
  update(sensorData, gpsData = null) {
    // 更新加速度波形图数据
    this.longChartData.push(sensorData.longitudinalAccel || 0);
    this.latChartData.push(sensorData.lateralAccel || 0);
    
    if (this.longChartData.length > this.maxChartPoints) {
      this.longChartData.shift();
      this.latChartData.shift();
    }
    
    // 更新惯性球位置
    this.accBallX = this.clampAccBall(-sensorData.lateralAccel || 0);
    this.accBallY = this.clampAccBall(sensorData.longitudinalAccel || 0);
    
    // 更新行驶统计
    if (this.startTime === 0) {
      this.startTime = Date.now();
    }
    this.duration = (Date.now() - this.startTime) / 1000;
    
    // 计算距离（如果有 GPS）
    if (gpsData && this.lastPosition) {
      const dist = this.calculateDistance(
        this.lastPosition.lat, this.lastPosition.lng,
        gpsData.lat, gpsData.lng
      );
      this.distance += dist;
    }
    if (gpsData) {
      this.lastPosition = { lat: gpsData.lat, lng: gpsData.lng };
    }
    
    // 绘制波形图
    this.drawChart(this.longChartCtx, this.longChartData, '#1976D2');
    this.drawChart(this.latChartCtx, this.latChartData, '#2196F3');
  },
  
  /**
   * 绘制波形图
   */
  drawChart(ctx, data, color) {
    if (!ctx) return;
    
    const size = this.resizeCanvas(ctx.canvas);
    const width = size.width;
    const height = size.height;
    
    ctx.clearRect(0, 0, width, height);
    
    if (data.length < 2) return;
    
    // 绘制背景
    ctx.fillStyle = color + '10'; // 10% 透明度
    ctx.fillRect(0, 0, width, height);
    
    // 绘制边框
    ctx.strokeStyle = color + '30'; // 30% 透明度
    ctx.lineWidth = 1;
    ctx.strokeRect(0.5, 0.5, width - 1, height - 1);
    
    // 绘制波形
    ctx.beginPath();
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    
    const step = width / (this.maxChartPoints - 1);
    const range = 20; // +/- 10 m/s²
    
    for (let i = 0; i < data.length; i++) {
      const x = i * step;
      const y = height / 2 - (data[i] / range) * (height / 2);
      
      if (i === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    
    ctx.stroke();
  },
  
  /**
   * 限制惯性球位置
   */
  clampAccBall(value) {
    const max = 40; // 最大偏移像素
    return Math.max(-max, Math.min(max, value * 4));
  },
  
  /**
   * 计算两点间距离（Haversine 公式）
   */
  calculateDistance(lat1, lng1, lat2, lng2) {
    const R = 6371000; // 地球半径（米）
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c / 1000; // 返回公里
  },
  
  /**
   * 重置统计
   */
  reset() {
    this.startTime = 0;
    this.duration = 0;
    this.distance = 0;
    this.lastPosition = null;
    this.longChartData = [];
    this.latChartData = [];
    this.accBallX = 0;
    this.accBallY = 0;
  },
  
  /**
   * 格式化时间
   */
  formatTime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }
    return `${m}:${s.toString().padStart(2, '0')}`;
  },
  
  /**
   * 获取实时速度（km/h）
   */
  getSpeed(gpsData) {
    if (!gpsData || !gpsData.speed) return 0;
    return gpsData.speed * 3.6; // m/s to km/h
  }
};

// 导出模块
window.ProfessionalDashboard = ProfessionalDashboard;
