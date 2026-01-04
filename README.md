# Changelog (Personal Fork)

> This is a **personal modified fork**.
> Changes are tailored for local usage and experimentation and may diverge from upstream behavior.

> 本项目为 **个人魔改版本**，包含针对本地使用与实验性的改动，可能与原仓库存在较大差异。

---

## [2.1.0-canguroMIO] - 2026-01-04

### 🚀 Core Mechanics | 核心机制

*   **GPS + Inertial Fusion (Kalman Filter)**
    Implemented a professional-grade **Physics-Enhanced PV Model** (Position-Velocity) Kalman Filter.
    *   **Dead Reckoning**: Uses `speed` and `heading` from the A16 chip to predict trajectory during signal loss (tunnels).
    *   **ZUPT (Zero Velocity Update)**: Forces position lock when speed < 0.4m/s, eliminating "ghost mileage" at red lights.
    *   **Adaptive Noise**: Dynamically adjusts trust between GPS and Inertial sensors based on `speedAccuracy` (L5 GPS feature).
    **引入专业级 GPS + 惯性导航融合算法 (卡尔曼滤波)**。
    *   **航位推算**: 利用 A16 芯片的速度与航向数据，在信号丢失（如隧道）时惯性预测轨迹。
    *   **零速修正 (ZUPT)**: 低速状态下强制锁定坐标，彻底消除红绿灯停车时的“幽灵里程”漂移。
    *   **自适应抗噪**: 根据 L5 双频 GPS 的精度动态调整信任权重，拒绝信号飞点。

*   **100Hz Sensor Engine (100Hz 传感器引擎)**
    Upgraded `SensorEngine` sampling rate from 60Hz to **100Hz (10ms)** to fully utilize iPhone 14 Pro hardware.
    *   Added **Median Filter (Window=9)** and **Noise Gate (0.03G)** to eliminate road vibration noise while capturing micro-jerks.
    **传感器采样率提升至 100Hz (10ms)**，榨干 iPhone 14 Pro 性能。
    *   增加 **中值滤波** 与 **噪音门限**，有效过滤路面碎石震动，同时精准捕捉微小顿挫。

### 🎨 UI/UX | 界面与体验

*   **"Course Up" Navigation Mode（车头朝上模式）**
    Map now rotates smoothly to align with the vehicle's heading when speed > 3km/h. Locks rotation when stationary to prevent jitter.
    **地图随动旋转**：行驶速度 > 3km/h 时地图自动旋转保持车头朝上（导航视角）；静止时锁定角度防止乱转。

*   **Pro Telemetry Dashboard（专业遥测仪表盘）**
    Redesigned the top HUD into a unified frosted-glass panel containing:
    *   **G-Force Ball** with Compass Ring.
    *   **Real-time G-Values** (Long/Lat/Vert) with progress bars and dynamic colors.
    *   **Waveform Chart** (powered by `fl_chart`) visualizing 100Hz data.
    *   **Precision Data**: Speed, Altitude, Heading, and 5-decimal Coordinates.
    **重构 HUD 仪表盘**：采用磨砂玻璃拟态设计，整合 **G力球**、**实时三轴 G 值**、**100Hz 波形图** 以及 **精密经纬度/海拔** 数据。

*   **Floating Control Dock（悬浮控制台）**
    Replaced bulky bottom buttons with a minimalist, horizontal scrolling **Neon-style Pill Dock**.
    底部控制栏升级为 **霓虹风格胶囊悬浮坞**，支持横向滚动，视觉更通透。

*   **In-App Overlay Notifications（应用内胶囊通知）**
    Replaced system dialogs with elegant top-screen overlay capsules for event triggers (e.g., Rapid Accel), auto-dismissing in 2.5s.
    事件触发时不再弹出系统框，改为屏幕顶部优雅的 **胶囊浮窗提醒**，2.5秒后自动消失，不打断驾驶体验。

### 🛠 Technical | 技术调整

*   **Dependency Updates**
    Added `fl_chart` for high-performance waveform rendering and `flutter_secure_storage` for persistent local data.
    新增 `fl_chart` 用于高性能图表渲染；引入 `flutter_secure_storage` 增强本地数据持久化。

*   **Code Architecture**
    Decoupled UI rendering (RecordingScreen) from algorithm logic (RecordingProvider), ensuring 120Hz UI smoothness even with heavy math calculations.
    **架构解耦**：将 UI 渲染与算法逻辑分离，确保在进行高频卡尔曼滤波计算时，UI 依然保持 120Hz 满帧运行。
