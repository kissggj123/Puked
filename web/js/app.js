/**
 * 可乐模拟器 - 主应用入口
 * 二次元现代化版本
 */

// 应用状态
const AppState = {
  isRunning: false,
  currentPage: 'home',
  drawerOpen: false,
  showSidePanel: false,
  selectedSimulator: 'cola',
  qualitySetting: 'high',
  sensitivity: 1.0,
  viewMode: 'simple' // 'simple' or 'professional'
};

// 传感器数据
const SensorData = {
  lateralAccel: 0,
  longitudinalAccel: 0,
  verticalAccel: 0,
  gyroX: 0,
  gyroY: 0,
  gyroZ: 0
};

// 计算数据
const CalculatedData = {
  gForce: 0,
  spillPercentage: 0,
  smoothScore: 100,
  events: []
};

// 当前会话
const CurrentSession = {
  startTime: null,
  endTime: null,
  maxG: 0,
  avgG: 0,
  events: [],
  sensorData: [],
  gpsFilter: null,
  lastGpsPosition: null
};

// 历史记录
let HistoryRecords = [];

// Vue 应用实例
let app = null;

/**
 * 初始化 Vue 应用
 */
function initVueApp() {
  const { createApp, ref, reactive, onMounted, onUnmounted } = Vue;

  app = createApp({
    setup() {
      // 响应式状态
      const isRunning = ref(AppState.isRunning);
      const drawerOpen = ref(AppState.drawerOpen);
      const showSidePanel = ref(AppState.showSidePanel);
      const currentPage = ref(AppState.currentPage);
      const selectedSimulator = ref(AppState.selectedSimulator);
      const qualitySetting = ref(AppState.qualitySetting);
      const sensitivity = ref(AppState.sensitivity);
      const viewMode = ref(AppState.viewMode);

      // 传感器数据
      const sensorData = reactive(SensorData);
      const gForce = ref(CalculatedData.gForce);
      const spillPercentage = ref(CalculatedData.spillPercentage);
      const smoothScore = ref(CalculatedData.smoothScore);
      const events = ref(CalculatedData.events);
      const historyRecords = ref(HistoryRecords);

      // 专业仪表盘状态
      const accBallX = ref(0);
      const accBallY = ref(0);
      const duration = ref(0);
      const distance = ref(0);
      const speed = ref(0);
      const hasGPS = ref(false);

      // 配置选项
      const simulators = [
        { value: 'cola', label: '🥤 可乐' },
        { value: 'water', label: '💧 水' },
        { value: 'coffee', label: '☕ 咖啡' },
        { value: 'milk', label: '🥛 牛奶' },
        { value: 'juice', label: '🧃 果汁' },
        { value: 'rice', label: '🍚 米饭' },
        { value: 'noodles', label: '🍜 面条' },
        { value: 'soup', label: '🍲 汤' },
        { value: 'porridge', label: '🥣 粥' }
      ];

      const qualityLevels = [
        { value: 'low', label: '低' },
        { value: 'medium', label: '中' },
        { value: 'high', label: '高' }
      ];

      // 更新日志内容
      const changelog = ref(`
# 更新日志

## v2.0.0 - 二次元现代化重构
- 🎨 二次元配色系统（粉色/紫色/青色）
- ✨ 玻璃拟态设计（Glassmorphism）
- 🎮 Three.js 3D 可乐杯模拟
- 📱 侧边抽屉式菜单
- 🖥️ 优化全屏功能
- 🚀 清理冗余代码
- 📦 模块化代码架构

## v1.5.0 - 像素小兔子
- 🐰 像素风格小兔子定位图标
- 🗺️ 高德卫星图 + 路网混合
- 🎯 3D 视图模式

## v1.0.0 - PRTS 终端风格
- 🖥️ PRTS 终端风格 UI
- 🗺️ 高德地图集成
- 📊 实时传感器数据
      `);

      // 方法
      const toggleDrawer = () => {
        drawerOpen.value = !drawerOpen.value;
      };

      const toggleSidePanel = () => {
        showSidePanel.value = !showSidePanel.value;
      };

      const toggleFullscreen = async () => {
        if (!document.fullscreenElement) {
          try {
            await document.documentElement.requestFullscreen();
          } catch (e) {
            console.error('Fullscreen error:', e);
          }
        } else {
          await document.exitFullscreen();
        }
      };

      const showPage = (page) => {
        currentPage.value = page;
        drawerOpen.value = false;
        
        // 页面加载逻辑
        if (page === 'history') {
          loadHistoryFromUI();
        }
      };

      const startSimulation = () => {
        AppState.isRunning = true;
        isRunning.value = true;
        CurrentSession.startTime = new Date();
        CurrentSession.events = [];
        CurrentSession.sensorData = [];
        
        // 初始化传感器
        SensorService.init(handleSensorData);
        SensorService.start();
        
        // 启动 Three.js 动画
        ThreeEngine.startAnimation();
      };

      const stopSimulation = () => {
        AppState.isRunning = false;
        isRunning.value = false;
        
        // 停止传感器
        SensorService.stop();
        
        // 停止 Three.js 动画
        ThreeEngine.stopAnimation();
        
        // 保存历史记录
        if (CurrentSession.startTime) {
          saveHistory();
        }
      };

      const changeSimulator = (type) => {
        AppState.selectedSimulator = type;
        selectedSimulator.value = type;
        
        // 更新 Three.js 液体类型
        if (ThreeEngine.updateLiquidType) {
          ThreeEngine.updateLiquidType(type);
        }
      };

      const changeQuality = (quality) => {
        AppState.qualitySetting = quality;
        qualitySetting.value = quality;
        ThreeEngine.setQuality(quality);
      };

      const switchViewMode = () => {
        if (viewMode.value === 'simple') {
          viewMode.value = 'professional';
          currentPage.value = 'professional';
          // 初始化专业仪表盘
          setTimeout(() => {
            initProfessionalDashboard();
          }, 100);
        } else {
          viewMode.value = 'simple';
          currentPage.value = 'home';
        }
      };

      const initProfessionalDashboard = () => {
        // 初始化 GPS 滤波器
        if (!CurrentSession.gpsFilter) {
          CurrentSession.gpsFilter = new GpsInertialFilter();
        }
        
        // 初始化 Canvas 图表
        const longCanvas = document.querySelector('canvas[ref="longChart"]');
        const latCanvas = document.querySelector('canvas[ref="latChart"]');
        if (longCanvas || latCanvas) {
          ProfessionalDashboard.init(longCanvas, latCanvas);
        }
      };

      const calibrateSensors = () => {
        if (SensorService.calibrate) {
          SensorService.calibrate();
          alert('传感器校准完成！');
        }
      };

      // 工具函数
      const formatDate = (dateStr) => {
        const date = new Date(dateStr);
        return date.toLocaleString('zh-CN');
      };

      const formatDuration = (seconds) => {
        const mins = Math.floor(seconds / 60);
        const secs = Math.floor(seconds % 60);
        return `${mins}分${secs}秒`;
      };

      const getSimulatorName = (simulator) => {
        const sim = simulators.find(s => s.value === simulator);
        return sim ? sim.label : simulator;
      };

      const renderChangelog = () => {
        if (typeof marked !== 'undefined') {
          return marked.parse(changelog.value);
        }
        return changelog.value;
      };

      const viewHistoryDetail = (record) => {
        alert(`历史记录详情\n\n日期：${formatDate(record.date)}\n时长：${formatDuration(record.duration)}\n最大 G 值：${record.maxG.toFixed(2)}\n平均 G 值：${record.avgG.toFixed(2)}\n模拟器：${getSimulatorName(record.simulator)}\n事件数：${record.events}\n平稳得分：${record.smoothScore.toFixed(0)}`);
      };

      const formatEventType = (type) => {
        const typeMap = {
          'hardAcceleration': '急加速',
          'hardBraking': '急减速',
          'hardTurn': '急转向',
          'bump': '颠簸',
          'collision': '碰撞'
        };
        return typeMap[type] || type;
      };

      const formatTimeAgo = (timestamp) => {
        const now = Date.now();
        const diff = now - timestamp;
        const seconds = Math.floor(diff / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);

        if (hours > 0) return `${hours}小时前`;
        if (minutes > 0) return `${minutes}分钟前`;
        return '刚刚';
      };

      const formatTime = (seconds) => {
        return ProfessionalDashboard.formatTime(seconds);
      };

      // 计算属性 - 最近事件（只显示最近 10 条）
      const recentEvents = computed(() => {
        return events.value.slice(-10).reverse();
      });

      // 生命周期
      onMounted(async () => {
        // 等待 DOM 渲染
        await new Promise(resolve => setTimeout(resolve, 100));
        
        // 初始化 Three.js
        const container = document.getElementById('three-container');
        if (container && window.ThreeEngine) {
          ThreeEngine.init(container);
          ThreeEngine.startAnimation();
        }
        
        // 初始化 IndexedDB
        Storage.initDB();
        
        // 加载历史记录
        loadHistoryFromUI();
      });

      onUnmounted(() => {
        stopSimulation();
        ThreeEngine.dispose();
      });

      return {
        isRunning,
        drawerOpen,
        showSidePanel,
        currentPage,
        selectedSimulator,
        qualitySetting,
        sensitivity,
        viewMode,
        sensorData,
        gForce,
        spillPercentage,
        smoothScore,
        events,
        historyRecords,
        changelog,
        simulators,
        qualityLevels,
        accBallX,
        accBallY,
        duration,
        distance,
        speed,
        hasGPS,
        recentEvents,
        toggleDrawer,
        toggleSidePanel,
        toggleFullscreen,
        showPage,
        startSimulation,
        stopSimulation,
        changeSimulator,
        changeQuality,
        switchViewMode,
        calibrateSensors,
        formatDate,
        formatDuration,
        getSimulatorName,
        renderChangelog,
        viewHistoryDetail,
        formatEventType,
        formatTimeAgo,
        formatTime
      };
    }
  });

  return app;
}

/**
 * 处理传感器数据
 */
function handleSensorData(data) {
  SensorData.lateralAccel = data.lateral || 0;
  SensorData.longitudinalAccel = data.longitudinal || 0;
  SensorData.verticalAccel = data.vertical || 0;
  SensorData.gyroX = data.gyroX || 0;
  SensorData.gyroY = data.gyroY || 0;
  SensorData.gyroZ = data.gyroZ || 0;

  // 计算 G 值
  const totalAccel = Math.sqrt(
    SensorData.lateralAccel ** 2 +
    SensorData.longitudinalAccel ** 2 +
    SensorData.verticalAccel ** 2
  );
  CalculatedData.gForce = totalAccel / 9.80665;

  // 更新最大值
  if (CalculatedData.gForce > CurrentSession.maxG) {
    CurrentSession.maxG = CalculatedData.gForce;
  }

  // 计算撒出百分比
  const threshold = 5;
  if (totalAccel > threshold) {
    CalculatedData.spillPercentage = Math.min((totalAccel - threshold) / 10, 1);
  } else {
    CalculatedData.spillPercentage = 0;
  }

  // 事件检测
  EventDetector.detect(totalAccel, SensorData);

  // 保存传感器数据
  if (AppState.isRunning) {
    CurrentSession.sensorData.push({
      timestamp: Date.now(),
      ...SensorData
    });
  }

  // 更新 Three.js 液体效果
  ThreeEngine.updateLiquid(SensorData.lateralAccel, SensorData.longitudinalAccel);

  // 更新专业仪表盘
  if (AppState.viewMode === 'professional') {
    updateProfessionalDashboard(data);
  }

  // 更新 UI（如果 Vue 已初始化）
  if (app && app._instance) {
    app._instance.data.gForce.value = CalculatedData.gForce;
    app._instance.data.spillPercentage.value = CalculatedData.spillPercentage;
    app._instance.data.accBallX.value = ProfessionalDashboard.accBallX;
    app._instance.data.accBallY.value = ProfessionalDashboard.accBallY;
    app._instance.data.duration.value = ProfessionalDashboard.duration;
    app._instance.data.distance.value = ProfessionalDashboard.distance;
  }
}

/**
 * 更新专业仪表盘
 */
function updateProfessionalDashboard(sensorData) {
  // 更新仪表盘数据
  ProfessionalDashboard.update(sensorData, CurrentSession.lastGpsPosition);
  
  // 更新 UI 状态
  if (app && app._instance) {
    app._instance.data.duration.value = ProfessionalDashboard.duration;
    app._instance.data.distance.value = ProfessionalDashboard.distance;
  }
}

/**
 * 保存历史记录
 */
function saveHistory() {
  CurrentSession.endTime = new Date();
  
  const duration = CurrentSession.endTime - CurrentSession.startTime;
  const avgG = CurrentSession.sensorData.length > 0 ?
    CurrentSession.sensorData.reduce((sum, d) => {
      const accel = Math.sqrt(d.lateralAccel ** 2 + d.longitudinalAccel ** 2 + d.verticalAccel ** 2);
      return sum + accel / 9.80665;
    }, 0) / CurrentSession.sensorData.length : 0;

  const record = {
    id: Date.now(),
    date: CurrentSession.startTime.toISOString(),
    duration: duration / 1000,
    maxG: CurrentSession.maxG,
    avgG: avgG,
    simulator: AppState.selectedSimulator,
    events: CurrentSession.events.length,
    smoothScore: CalculatedData.smoothScore
  };

  HistoryRecords.unshift(record);
  Storage.saveHistory(record);

  // 更新 UI
  if (app && app._instance.data.historyRecords) {
    app._instance.data.historyRecords.value = HistoryRecords;
  }
}

/**
 * 加载历史记录
 */
function loadHistoryFromUI() {
  Storage.loadHistory().then(records => {
    HistoryRecords = records.sort((a, b) => new Date(b.date) - new Date(a.date));
    if (app && app._instance.data.historyRecords) {
      app._instance.data.historyRecords.value = HistoryRecords;
    }
  });
}

/**
 * 删除历史记录
 */
function deleteHistoryRecord(id) {
  Storage.deleteHistory(id).then(() => {
    HistoryRecords = HistoryRecords.filter(r => r.id !== id);
    if (app && app._instance.data.historyRecords) {
      app._instance.data.historyRecords.value = HistoryRecords;
    }
  });
}

/**
 * 清空历史记录
 */
function clearAllHistory() {
  if (confirm('确定要清空所有历史记录吗？')) {
    Storage.clearHistory().then(() => {
      HistoryRecords = [];
      if (app && app._instance.data.historyRecords) {
        app._instance.data.historyRecords.value = HistoryRecords;
      }
    });
  }
}

// 导出全局函数
window.deleteHistoryRecord = deleteHistoryRecord;
window.clearAllHistory = clearAllHistory;

/**
 * 初始化应用
 */
function initApp() {
  console.log('[App] 初始化应用...');
  
  // 应用像素猫主题
  if (window.PixelCatTheme) {
    PixelCatTheme.applyToPage();
  }
  
  // 创建 Vue 应用
  const vueApp = initVueApp();
  
  // 挂载应用
  vueApp.mount('#app');
  
  console.log('[App] 应用初始化完成');
}

// DOM 加载完成后初始化
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initApp);
} else {
  initApp();
}
