# Flutter Web 可乐杯物理模拟器 改造规格

## Why
将现有的 Flutter 自动驾驶舒适度记录应用改造成一个基于 Web 的可乐杯物理模拟器。用户可以通过浏览器访问，实时查看加速度对可乐杯的影响，并回放历史行程数据。针对 Chromium 浏览器和安卓车机进行优化，确保流畅运行。

## What Changes

### 主要功能变更
- **移除 Arena 页面**: 删除原有的排行榜/竞技场功能
- **新增可乐杯模拟器**: 
  - 100% 装满的可乐杯可视化
  - 基于实时加速度的物理计算
  - 实时显示可乐撒出百分比
  - 动态动画效果
- **新增行程回放功能**: 
  - 单个行程的加速度数据回放
  - 从开始到结束的完整播放
  - 实时显示纵向和横向加速度值
- **Web 优化**:
  - 针对 Chromium 浏览器优化
  - 针对安卓车机优化权限和性能
  - 支持 Debian 服务器部署

### 技术变更
- 启用 Flutter Web 支持
- 替换移动端专用传感器库为 Web 兼容方案
- 优化构建配置用于 Web 部署
- 添加 PWA 支持

## Impact
- **移除功能**: Arena 页面及其相关 Provider
- **新增功能**: ColaSimulator 页面、TripReplay 页面
- **修改功能**: MainScreen 导航、RecordingScreen 传感器处理
- **配置文件**: pubspec.yaml、web/index.html、web/manifest.json

## ADDED Requirements

### Requirement: 可乐杯物理模拟器
The system SHALL provide a cola cup physics simulator that visualizes liquid spillage based on real-time acceleration data.

#### Scenario: 实时模拟
- **GIVEN** 用户已授权传感器权限
- **WHEN** 设备检测到纵向或横向加速度变化
- **THEN** 系统 SHALL:
  - 计算可乐液面倾斜角度
  - 根据加速度大小计算撒出百分比 (0-100%)
  - 实时更新可乐杯动画
  - 显示当前撒出百分比数值

#### Scenario: 物理计算
- **GIVEN** 实时加速度数据 (ax, ay, az in m/s²)
- **WHEN** 每秒更新传感器数据
- **THEN** 系统 SHALL:
  - 计算合成加速度向量
  - 应用物理公式: spillage = f(acceleration_magnitude, duration)
  - 考虑重力影响 (9.8 m/s²)
  - 累积计算总撒出量

### Requirement: 行程回放功能
The system SHALL provide trip replay functionality to visualize historical acceleration data.

#### Scenario: 回放单个行程
- **GIVEN** 用户选择一个历史行程
- **WHEN** 用户点击"回放"按钮
- **THEN** 系统 SHALL:
  - 加载该行程的所有传感器数据点
  - 按时间顺序播放加速度变化
  - 实时显示纵向加速度值 (Y轴)
  - 实时显示横向加速度值 (X轴)
  - 同步更新可乐杯动画
  - 提供播放/暂停/进度控制

#### Scenario: 回放控制
- **GIVEN** 行程回放进行中
- **WHEN** 用户操作控制按钮
- **THEN** 系统 SHALL 支持:
  - 播放/暂停切换
  - 进度条拖拽跳转
  - 播放速度调节 (0.5x, 1x, 2x)
  - 显示当前回放时间/总时长

### Requirement: Web 平台适配
The system SHALL be fully functional as a web application optimized for Chromium browsers and Android automotive systems.

#### Scenario: Chromium 浏览器兼容
- **GIVEN** 用户在 Chromium 浏览器中访问
- **WHEN** 页面加载完成
- **THEN** 系统 SHALL:
  - 正确请求传感器权限 (DeviceMotion API)
  - 以 30Hz 频率读取加速度数据
  - 渲染 60fps 动画
  - 支持触摸和鼠标交互

#### Scenario: 安卓车机优化
- **GIVEN** 应用在安卓车机系统运行
- **WHEN** 系统资源受限时
- **THEN** 系统 SHALL:
  - 降低传感器采样率至 20Hz
  - 简化动画效果保证流畅
  - 适配车机屏幕分辨率
  - 支持横屏全屏模式

## MODIFIED Requirements

### Requirement: 主页面导航
**原需求**: 包含 Recording、Arena、History、Settings 四个标签
**新需求**: 
- 移除 Arena 标签
- 保留 Recording、History、Settings 三个标签
- Recording 页面集成可乐杯模拟器

### Requirement: 传感器数据处理
**原需求**: 使用 sensors_plus 库，支持 iOS 100Hz / Android 30Hz
**新需求**:
- Web 平台使用 DeviceMotion API
- 统一采样率为 30Hz (Web/Android)
- 添加权限请求处理
- 适配 Web 坐标系 (可能需翻转轴)

## REMOVED Requirements

### Requirement: Arena 排行榜功能
**Reason**: 项目转型为纯物理模拟工具，不再需要云端排行榜功能
**Migration**: 
- 删除 ArenaScreen 及相关 Provider
- 保留云端数据同步服务供历史记录使用
- 移除品牌对比图表功能

## 部署需求

### Debian 服务器部署
- 构建为静态 Web 文件
- 支持 Nginx 或 Apache 部署
- 配置 HTTPS 以支持传感器 API
- 提供 Docker 部署方案

### 性能指标
- 首屏加载时间 < 3秒
- 动画帧率 >= 30fps
- 传感器延迟 < 100ms
- 内存占用 < 200MB
