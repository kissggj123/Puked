/**
 * 高德地图模块
 * 支持实时轨迹、卫星图 + 路网混合
 */

const MapModule = {
  map: null,
  marker: null,
  polyline: null,
  gpsPath: [],
  isInitialized: false,
  hasGPS: false,
  
  /**
   * 初始化地图
   */
  init(containerId = 'map') {
    const container = document.getElementById(containerId);
    if (!container) {
      console.error('[MapModule] 地图容器未找到:', containerId);
      return false;
    }
    
    // 检查 AMap 是否加载
    if (typeof AMap === 'undefined') {
      console.error('[MapModule] AMap 未加载，请检查高德地图 SDK');
      return false;
    }
    
    try {
      // 销毁旧地图（如果有）
      if (this.map) {
        try { this.map.destroy(); } catch (e) {}
        this.map = null;
        this.marker = null;
        this.polyline = null;
      }
      
      // 确保容器可见
      container.style.display = 'block';
      container.style.width = '100%';
      container.style.height = '100%';
      
      // 创建地图（卫星图 + 路网混合）
      this.map = new AMap.Map(containerId, {
        zoom: 16,
        viewMode: '3D',
        showLabel: true,
        // 自定义图层：卫星图 + 路网
        layers: [
          // 卫星底图
          new AMap.TileLayer({
            url: 'https://wprd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&style=6&x={x}&y={y}&z={z}',
            subdomains: ['1', '2', '3', '4'],
            maxZoom: 18,
            minZoom: 3,
            tileSize: 256
          }),
          // 透明路网
          new AMap.TileLayer({
            url: 'https://wprd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&style=8&x={x}&y={y}&z={z}',
            subdomains: ['1', '2', '3', '4'],
            maxZoom: 18,
            minZoom: 3,
            tileSize: 256,
            opacity: 1
          })
        ]
      });
      
      this.map.on('load', () => {
        console.log('[MapModule] 地图加载完成');
        this.isInitialized = true;
        
        // 尝试获取当前位置
        this.getCurrentPosition();
      });
      
      this.map.on('error', (e) => {
        console.error('[MapModule] 地图加载失败:', e);
      });
      
      console.log('[MapModule] 地图初始化成功');
      return true;
    } catch (err) {
      console.error('[MapModule] 初始化失败:', err);
      return false;
    }
  },
  
  /**
   * 获取当前位置
   */
  getCurrentPosition() {
    if (!navigator.geolocation) {
      console.warn('[MapModule] 浏览器不支持地理定位');
      return;
    }
    
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const lat = position.coords.latitude;
        const lng = position.coords.longitude;
        console.log('[MapModule] 获取到 GPS 位置:', lat, lng);
        this.hasGPS = true;
        this.updatePosition(lng, lat);
      },
      (error) => {
        console.warn('[MapModule] GPS 定位失败:', error.message);
        this.hasGPS = false;
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    );
  },
  
  /**
   * 更新位置
   */
  updatePosition(lng, lat) {
    if (!this.map || lng === 0 || lat === 0) return;
    
    // 更新地图中心
    this.map.setCenter([lng, lat]);
    
    // 创建或更新标记
    if (!this.marker) {
      this.marker = new AMap.Marker({
        position: [lng, lat],
        content: `
          <div style="
            width: 20px;
            height: 20px;
            background: #00f0ff;
            border-radius: 50%;
            border: 3px solid #fff;
            box-shadow: 0 0 10px rgba(0, 240, 255, 0.8);
            animation: pulse 1s infinite;
          "></div>
          <style>
            @keyframes pulse {
              0%, 100% { transform: scale(1); opacity: 1; }
              50% { transform: scale(1.2); opacity: 0.8; }
            }
          </style>
        `,
        offset: new AMap.Pixel(-10, -10)
      });
      this.map.add(this.marker);
    } else {
      this.marker.setPosition([lng, lat]);
    }
    
    // 添加轨迹点
    this.gpsPath.push({ lng, lat });
    
    // 更新轨迹线
    this.updatePolyline();
  },
  
  /**
   * 更新轨迹线
   */
  updatePolyline() {
    if (this.gpsPath.length < 2) return;
    
    const pathArray = this.gpsPath.map(p => [p.lng, p.lat]);
    
    if (this.polyline) {
      this.polyline.setPath(pathArray);
    } else {
      this.polyline = new AMap.Polyline({
        path: pathArray,
        strokeColor: '#00f0ff',
        strokeWeight: 3,
        strokeOpacity: 0.8,
        lineJoin: 'round'
      });
      this.map.add(this.polyline);
    }
  },
  
  /**
   * 清除轨迹
   */
  clearTrack() {
    this.gpsPath = [];
    if (this.polyline) {
      this.map.remove(this.polyline);
      this.polyline = null;
    }
  },
  
  /**
   * 销毁地图
   */
  destroy() {
    if (this.map) {
      try {
        this.map.destroy();
      } catch (e) {}
      this.map = null;
      this.marker = null;
      this.polyline = null;
      this.gpsPath = [];
      this.isInitialized = false;
    }
  },
  
  /**
   * 获取状态
   */
  getStatus() {
    return {
      isInitialized: this.isInitialized,
      hasGPS: this.hasGPS,
      pointCount: this.gpsPath.length
    };
  }
};

// 导出模块
window.MapModule = MapModule;
