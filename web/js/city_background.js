/**
 * 城市天台和高速公路背景
 * 使用 Canvas 绘制像素风格城市场景
 */

const CityBackground = {
  canvas: null,
  ctx: null,
  animationFrame: null,
  
  // 建筑数据
  buildings: [],
  cars: [],
  clouds: [],
  
  // 颜色方案
  colors: {
    sky: ['#1a1a2e', '#16213e', '#0f3460'],
    building: ['#2d2d44', '#3d3d5c', '#4a4a6a'],
    window: ['#ffd700', '#ffed4e', '#ffffff'],
    road: '#2d2d2d',
    car: ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4'],
    cloud: 'rgba(255, 255, 255, 0.1)'
  },
  
  /**
   * 初始化背景
   */
  init(containerId = 'three-container') {
    const container = document.getElementById(containerId);
    if (!container) return;
    
    // 创建 Canvas
    this.canvas = document.createElement('canvas');
    this.canvas.style.cssText = `
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: 0;
      pointer-events: none;
    `;
    
    container.appendChild(this.canvas);
    this.ctx = this.canvas.getContext('2d');
    
    // 调整大小
    this.resize();
    window.addEventListener('resize', () => this.resize());
    
    // 生成场景元素
    this.generateBuildings();
    this.generateCars();
    this.generateClouds();
    
    // 开始动画
    this.animate();
    
    console.log('[CityBackground] 城市背景已初始化');
  },
  
  /**
   * 调整大小
   */
  resize() {
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
  },
  
  /**
   * 生成建筑
   */
  generateBuildings() {
    this.buildings = [];
    const buildingCount = Math.floor(this.canvas.width / 60);
    
    for (let i = 0; i < buildingCount; i++) {
      const width = 40 + Math.random() * 40;
      const height = 100 + Math.random() * 200;
      const x = i * 60 + Math.random() * 20;
      const y = this.canvas.height - height;
      
      // 窗户
      const windows = [];
      const windowRows = Math.floor(height / 20);
      const windowCols = Math.floor(width / 15);
      
      for (let row = 0; row < windowRows; row++) {
        for (let col = 0; col < windowCols; col++) {
          if (Math.random() > 0.3) { // 70% 的窗户亮着
            windows.push({
              x: col * 15 + 5,
              y: row * 20 + 5,
              width: 8,
              height: 12,
              lit: Math.random() > 0.2
            });
          }
        }
      }
      
      this.buildings.push({ x, y, width, height, windows });
    }
  },
  
  /**
   * 生成汽车
   */
  generateCars() {
    this.cars = [];
    const carCount = 5 + Math.floor(Math.random() * 5);
    
    for (let i = 0; i < carCount; i++) {
      this.cars.push({
        x: Math.random() * this.canvas.width,
        y: this.canvas.height - 30 + Math.random() * 40,
        width: 30 + Math.random() * 20,
        height: 12,
        speed: 1 + Math.random() * 2,
        color: this.colors.car[Math.floor(Math.random() * this.colors.car.length)],
        direction: Math.random() > 0.5 ? 1 : -1
      });
    }
  },
  
  /**
   * 生成云
   */
  generateClouds() {
    this.clouds = [];
    const cloudCount = 3 + Math.floor(Math.random() * 3);
    
    for (let i = 0; i < cloudCount; i++) {
      this.clouds.push({
        x: Math.random() * this.canvas.width,
        y: 50 + Math.random() * 100,
        width: 100 + Math.random() * 150,
        height: 30 + Math.random() * 50,
        speed: 0.2 + Math.random() * 0.3
      });
    }
  },
  
  /**
   * 绘制天空渐变
   */
  drawSky() {
    const gradient = this.ctx.createLinearGradient(0, 0, 0, this.canvas.height);
    gradient.addColorStop(0, this.colors.sky[0]);
    gradient.addColorStop(0.5, this.colors.sky[1]);
    gradient.addColorStop(1, this.colors.sky[2]);
    this.ctx.fillStyle = gradient;
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
  },
  
  /**
   * 绘制云
   */
  drawClouds() {
    this.ctx.fillStyle = this.colors.cloud;
    this.clouds.forEach(cloud => {
      this.ctx.beginPath();
      this.ctx.ellipse(cloud.x, cloud.y, cloud.width / 2, cloud.height / 2, 0, 0, Math.PI * 2);
      this.ctx.ellipse(cloud.x + cloud.width * 0.3, cloud.y + 10, cloud.width * 0.4, cloud.height * 0.6, 0, 0, Math.PI * 2);
      this.ctx.ellipse(cloud.x - cloud.width * 0.3, cloud.y + 10, cloud.width * 0.4, cloud.height * 0.6, 0, 0, Math.PI * 2);
      this.ctx.fill();
    });
  },
  
  /**
   * 绘制建筑
   */
  drawBuildings() {
    this.buildings.forEach(building => {
      // 建筑主体
      this.ctx.fillStyle = this.colors.building[Math.floor(Math.random() * this.colors.building.length)];
      this.ctx.fillRect(building.x, building.y, building.width, building.height);
      
      // 窗户
      building.windows.forEach(win => {
        if (win.lit) {
          this.ctx.fillStyle = this.colors.window[Math.floor(Math.random() * this.colors.window.length)];
          this.ctx.fillRect(building.x + win.x, building.y + win.y, win.width, win.height);
        }
      });
      
      // 建筑轮廓
      this.ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
      this.ctx.lineWidth = 1;
      this.ctx.strokeRect(building.x, building.y, building.width, building.height);
    });
  },
  
  /**
   * 绘制道路
   */
  drawRoad() {
    const roadY = this.canvas.height - 20;
    
    // 路面
    this.ctx.fillStyle = this.colors.road;
    this.ctx.fillRect(0, roadY, this.canvas.width, 20);
    
    // 道路标线
    this.ctx.strokeStyle = '#ffffff';
    this.ctx.lineWidth = 2;
    this.ctx.setLineDash([20, 20]);
    this.ctx.beginPath();
    this.ctx.moveTo(0, roadY + 10);
    this.ctx.lineTo(this.canvas.width, roadY + 10);
    this.ctx.stroke();
    this.ctx.setLineDash([]);
  },
  
  /**
   * 绘制汽车
   */
  drawCars() {
    this.cars.forEach(car => {
      // 车身
      this.ctx.fillStyle = car.color;
      this.ctx.fillRect(car.x, car.y, car.width, car.height);
      
      // 车窗
      this.ctx.fillStyle = '#87CEEB';
      this.ctx.fillRect(car.x + car.width * 0.2, car.y + 2, car.width * 0.6, car.height * 0.5);
      
      // 车灯
      this.ctx.fillStyle = car.direction > 0 ? '#ffff00' : '#ff0000';
      if (car.direction > 0) {
        this.ctx.fillRect(car.x + car.width - 2, car.y + 3, 2, 3);
        this.ctx.fillRect(car.x + car.width - 2, car.y + car.height - 6, 2, 3);
      } else {
        this.ctx.fillRect(car.x, car.y + 3, 2, 3);
        this.ctx.fillRect(car.x, car.y + car.height - 6, 2, 3);
      }
      
      // 移动汽车
      car.x += car.speed * car.direction;
      if (car.x > this.canvas.width + 50) car.x = -50;
      if (car.x < -50) car.x = this.canvas.width + 50;
    });
  },
  
  /**
   * 动画循环
   */
  animate() {
    // 清空画布
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    
    // 绘制各层
    this.drawSky();
    this.drawClouds();
    this.drawBuildings();
    this.drawRoad();
    this.drawCars();
    
    // 更新云位置
    this.clouds.forEach(cloud => {
      cloud.x += cloud.speed;
      if (cloud.x > this.canvas.width + cloud.width) {
        cloud.x = -cloud.width;
      }
    });
    
    // 下一帧
    this.animationFrame = requestAnimationFrame(() => this.animate());
  },
  
  /**
   * 销毁背景
   */
  destroy() {
    if (this.animationFrame) {
      cancelAnimationFrame(this.animationFrame);
    }
    if (this.canvas && this.canvas.parentNode) {
      this.canvas.parentNode.removeChild(this.canvas);
    }
  }
};

// 导出模块
window.CityBackground = CityBackground;
