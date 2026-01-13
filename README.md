# Changelog (Personal Fork)

> This is a **personal modified fork**.
> Changes are tailored for local usage and experimentation and may diverge from upstream behavior.

> 本项目为 **个人魔改版本**，包含针对本地使用与实验性的改动，可能与原仓库存在较大差异。

## [2.3.3-canguroMIO] - 2026-01-13

### 📱 iOS Integration & System | iOS 深度集成

*   **Dynamic Island & Live Activities (灵动岛与实时活动)**
    Deep integration with iOS native features to replace intrusive audio alerts.
    *   **Real-time Telemetry**: Displays current speed and trip distance on the Lock Screen and Dynamic Island compact area.
    *   **Visual Event Alerts**: Replaced legacy audio beeps with immersive Island expansions. Events like *Rapid Decel* or *Jerk* trigger immediate color-coded visual warnings (Red/Orange) on the Island, providing safer, glanceable feedback.
    **灵动岛与实时活动深度集成**。
    *   **实时遥测常驻**：在灵动岛和锁屏界面实时显示当前车速与行驶里程。
    *   **可视化告警系统**：移除传统音效，启用灵动岛视觉强提醒。当检测到急刹或顿挫时，灵动岛会弹出对应颜色（红/橙）的警告动画，提供更安全、低干扰的驾驶反馈。

### 🧠 Core Navigation & Fusion | 核心导航与融合

*   **Physics-Enhanced PV Model (物理增强型 PV 卡尔曼滤波)**
    A completely rewritten navigation filter optimized for iPhone 14 Pro's dual-frequency GPS.
    *   **NHC (Non-Holonomic Constraints)**: Enforces "no sideslip" physics, locking the velocity vector to the vehicle's heading to eliminate trajectory drift during turns.
    *   **ZUPT (Zero Velocity Update)**: Detects stationary states (<0.4m/s) and locks coordinates to prevent "ghost mileage" and drift at red lights.
    *   **Outlier Rejection**: Implements a 3-sigma statistical gate to reject "flying points" (>20m jumps) caused by multipath effects.
    **重写物理增强型 PV 导航模型**。
    *   **NHC (非完整性约束)**：引入车辆“不可横移”的物理约束，强制速度向量跟随车头，消除转弯时的轨迹漂移。
    *   **ZUPT (零速修正)**：精准识别停车状态 (<0.4m/s) 并强制锁定坐标，彻底根除红绿灯时的“幽灵里程”。
    *   **飞点剔除**：基于 3-Sigma 统计学门限，自动过滤因多路径效应导致的 GPS 瞬移（飞点）。

*   **Course-Up Logic with Hysteresis (带迟滞的航向跟随)**
    *   **Dynamic Rotation**: Map rotates to align with heading only when speed > 3km/h.
    *   **Heading Hold**: Locks the map angle when moving slowly or stationary to prevent disorientation.
    **带迟滞的航向跟随算法**。
    *   **动态旋转**：仅在速度 > 3km/h 时启动地图旋转。
    *   **航向锁**：低速蠕行或静止时自动锁定地图角度，防止因电子罗盘抖动导致的画面乱转。

### 🛡️ Event Detection Engine | 事件检测引擎

*   **Non-linear Z-Y Energy Inhibition (Z-Y 非线性能量互斥)**
    Calculates vertical (Z-axis) vibration energy density over a 200ms window. If high-energy bumps (e.g., speed bumps) are detected, longitudinal (Y-axis) sensitivity is dynamically suppressed.
    **Z-Y 非线性能量互斥**。实时计算 Z 轴在 200ms 窗口内的震动能量密度。当检测到减速带或井盖冲击时，呈非线性比例压制纵向灵敏度，完美过滤因颠簸导致的急刹车误报。

*   **Adaptive Physics Multiplier (自适应物理倍率)**
    Dynamic thresholding based on real-time speed:
    *   **Low Speed (<15km/h)**: +50% threshold to prevent "nodding" false positives.
    *   **High Speed (>80km/h)**: -20% threshold to increase sensitivity for high-speed maneuvers.
    **自适应物理倍率**。
    *   **低速保护**：低速下大幅提高触发门槛，防止起步/刹停时的“点头”动作误报。
    *   **高速灵敏**：高速下降低门槛，确保危险驾驶行为被敏锐捕捉。

### 📡 Signal Processing (DSP) | 信号处理

*   **100Hz Ultra-High Frequency (100Hz 极速采样)**
    Unlocks the full potential of the A16 Bionic chip by increasing sensor polling rate from 60Hz to **100Hz (10ms)**.
    **100Hz 极速采样**。解锁 A16 芯片潜能，将传感器轮询率提升至 10ms/次，捕捉毫秒级动态。

*   **VPAS (Virtual Phone Alignment System) (虚拟坐标对齐系统)**
    *   **Auto-Leveling**: Continuously tracks gravity vectors to build a rotation matrix, mathematically correcting the phone's mounting angle (Pitch/Roll).
    *   **Yaw Correction**: Learns the vehicle's forward direction during acceleration events to correct the phone's heading (Yaw) deviation.
    **VPAS 虚拟坐标对齐**。
    *   **自动调平**：实时追踪重力矢量构建旋转矩阵，在数学层面消除手机摆放角度（俯仰/横滚）的偏差。
    *   **偏航修正**：通过捕捉起步时的纵向加速度，自动学习并修正手机相对于车头的偏航角（Yaw）。

*   **Dual-Track Filtering Architecture (双轨滤波架构)**
    *   **UI Track**: Optimized for fluidity (`alpha=0.05`), ensuring the G-Ball animation is buttery smooth on ProMotion displays.
    *   **Logic Track**: Optimized for signal purity (`alpha=0.02` + Noise Gate), feeding noise-free data to the detection algorithm.
    **双轨滤波架构**。
    *   **UI 轨**：注重视觉流畅性，适配 ProMotion 高刷屏。
    *   **逻辑轨**：集成 **噪音门限 (Noise Gate)** 和强力低通滤波，为算法提供纯净数据。

### ⚙️ Data Engineering | 数据工程

*   **Smart Downsampling (智能降采样)**
    Decimates 100Hz raw data to **20Hz** for database storage, preserving waveform peaks while reducing storage usage by 80%.
    **智能降采样**。在入库存储时将 100Hz 原始数据降频至 **20Hz**，在保留波形峰值特征的同时节省 80% 存储空间。
