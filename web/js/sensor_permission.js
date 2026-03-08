/**
 * 传感器权限管理模块
 * 支持 iOS/Android 权限请求和自动检测
 */

const SensorPermissionManager = {
  // 权限状态
  motionPermission: 'unknown', // 'granted', 'denied', 'prompt', 'unknown'
  orientationPermission: 'unknown',
  isIOS: false,
  isAndroid: false,
  
  // 算法版本
  algorithmVersion: '2.0.0',
  calibrationVersion: 'adaptive-v3',
  
  /**
   * 检测设备类型
   */
  detectDevice() {
    const ua = navigator.userAgent;
    this.isIOS = /iPhone|iPad|iPod/i.test(ua);
    this.isAndroid = /Android/i.test(ua);
    
    console.log('[SensorPermission] 设备检测:', {
      isIOS: this.isIOS,
      isAndroid: this.isAndroid,
      userAgent: ua.substring(0, 50) + '...'
    });
  },
  
  /**
   * 检测权限状态
   */
  async checkPermissionStatus() {
    this.detectDevice();
    
    // 检测运动传感器权限
    if (typeof DeviceMotionEvent === 'undefined') {
      this.motionPermission = 'denied';
      console.log('[SensorPermission] 不支持 DeviceMotionEvent');
      return;
    }
    
    // iOS 13+ 需要显式权限
    if (typeof DeviceMotionEvent.requestPermission === 'function') {
      this.motionPermission = 'prompt';
      console.log('[SensorPermission] iOS 13+, 需要用户授权');
    } else {
      // 旧版 iOS 或 Android
      this.motionPermission = 'granted';
      console.log('[SensorPermission] 不需要权限或已授予');
    }
    
    // 检测方向传感器权限
    if (typeof DeviceOrientationEvent !== 'undefined' && 
        typeof DeviceOrientationEvent.requestPermission === 'function') {
      this.orientationPermission = 'prompt';
    } else {
      this.orientationPermission = 'granted';
    }
  },
  
  /**
   * 请求传感器权限（自动）
   */
  async requestPermission() {
    console.log('[SensorPermission] 开始请求权限...');
    
    // 非 iOS 13+ 设备，不需要请求
    if (!this.isIOS || typeof DeviceMotionEvent.requestPermission !== 'function') {
      console.log('[SensorPermission] 非 iOS 13+ 设备，直接返回');
      this.motionPermission = 'granted';
      this.orientationPermission = 'granted';
      return true;
    }
    
    try {
      // 请求运动传感器权限
      const motionResult = await DeviceMotionEvent.requestPermission();
      console.log('[SensorPermission] 运动传感器权限:', motionResult);
      
      if (motionResult === 'granted') {
        this.motionPermission = 'granted';
        
        // 请求方向传感器权限
        if (typeof DeviceOrientationEvent.requestPermission === 'function') {
          try {
            const orientResult = await DeviceOrientationEvent.requestPermission();
            console.log('[SensorPermission] 方向传感器权限:', orientResult);
            this.orientationPermission = orientResult;
          } catch (e) {
            console.warn('[SensorPermission] 方向传感器权限请求失败:', e);
            this.orientationPermission = 'denied';
          }
        }
        
        console.log('[SensorPermission] ✅ 权限请求成功');
        return true;
      } else {
        this.motionPermission = 'denied';
        console.warn('[SensorPermission] ❌ 用户拒绝了权限');
        return false;
      }
    } catch (error) {
      console.error('[SensorPermission] ❌ 权限请求错误:', error);
      this.motionPermission = 'denied';
      return false;
    }
  },
  
  /**
   * 显示权限请求 UI
   */
  showPermissionDialog() {
    // 检查是否需要请求
    if (this.motionPermission === 'granted') {
      console.log('[SensorPermission] 权限已授予，无需请求');
      return;
    }
    
    // 创建权限请求对话框
    const dialog = document.createElement('div');
    dialog.className = 'sensor-permission-dialog';
    dialog.style.cssText = `
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: rgba(26, 26, 46, 0.95);
      backdrop-filter: blur(20px);
      border: 2px solid rgba(255, 107, 157, 0.5);
      border-radius: 16px;
      padding: 30px;
      z-index: 10000;
      max-width: 400px;
      text-align: center;
      box-shadow: 0 8px 32px rgba(255, 107, 157, 0.3);
    `;
    
    dialog.innerHTML = `
      <div style="font-size: 48px; margin-bottom: 16px;">📱</div>
      <h2 style="
        font-size: 20px;
        margin-bottom: 12px;
        background: linear-gradient(90deg, #ff6b9d, #c77dff);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
      ">需要传感器权限</h2>
      <p style="
        font-size: 14px;
        color: rgba(255, 255, 255, 0.7);
        margin-bottom: 24px;
        line-height: 1.6;
      ">
        为了提供准确的驾驶数据分析，<br>
        需要访问您的设备加速度和方向传感器。<br>
        <span style="font-size: 12px; opacity: 0.6;">
          算法版本：v${this.algorithmVersion}<br>
          校准版本：${this.calibrationVersion}
        </span>
      </p>
      <div style="display: flex; gap: 12px; justify-content: center;">
        <button class="btn-cancel" style="
          padding: 12px 24px;
          border: 1px solid rgba(255, 255, 255, 0.3);
          border-radius: 8px;
          background: transparent;
          color: rgba(255, 255, 255, 0.7);
          font-size: 14px;
          cursor: pointer;
        ">取消</button>
        <button class="btn-grant" style="
          padding: 12px 24px;
          border: none;
          border-radius: 8px;
          background: linear-gradient(135deg, #ff6b9d, #c77dff);
          color: white;
          font-size: 14px;
          cursor: pointer;
          box-shadow: 0 4px 16px rgba(255, 107, 157, 0.4);
        ">允许</button>
      </div>
    `;
    
    document.body.appendChild(dialog);
    
    // 绑定按钮事件
    dialog.querySelector('.btn-cancel').onclick = () => {
      dialog.remove();
      this.motionPermission = 'denied';
    };
    
    dialog.querySelector('.btn-grant').onclick = async () => {
      dialog.querySelector('.btn-grant').disabled = true;
      dialog.querySelector('.btn-grant').textContent = '请求中...';
      
      const granted = await this.requestPermission();
      
      if (granted) {
        dialog.remove();
        // 触发权限授予后的回调
        if (window.onSensorPermissionGranted) {
          window.onSensorPermissionGranted();
        }
      } else {
        dialog.querySelector('.btn-grant').disabled = false;
        dialog.querySelector('.btn-grant').textContent = '重试';
      }
    };
  },
  
  /**
   * 获取灵敏度配置（自动）
   */
  getAutoSensitivity() {
    // 根据设备类型和传感器精度自动配置
    if (this.isIOS) {
      return {
        base: 1.0,
        calibration: 'ios-optimized',
        version: this.algorithmVersion
      };
    } else if (this.isAndroid) {
      return {
        base: 1.2,
        calibration: 'android-optimized',
        version: this.algorithmVersion
      };
    } else {
      return {
        base: 1.0,
        calibration: 'generic',
        version: this.algorithmVersion
      };
    }
  },
  
  /**
   * 获取权限状态文本
   */
  getStatusText() {
    const statusMap = {
      granted: '已授权 ✅',
      denied: '已拒绝 ❌',
      prompt: '等待授权 ⏳',
      unknown: '检测中...'
    };
    return statusMap[this.motionPermission] || this.motionPermission;
  }
};

// 导出模块
window.SensorPermissionManager = SensorPermissionManager;
