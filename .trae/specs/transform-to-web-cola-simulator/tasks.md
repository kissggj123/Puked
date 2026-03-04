# 任务列表

## 阶段一：项目清理与 Web 配置

- [ ] Task 1: 移除 Arena 页面及相关代码
  - [ ] SubTask 1.1: 删除 lib/features/arena/ 目录
  - [ ] SubTask 1.2: 从 main.dart 移除 arena_provider 导入和初始化
  - [ ] SubTask 1.3: 从 MainScreen 移除 Arena 导航项
  - [ ] SubTask 1.4: 清理 pubspec.yaml 中未使用的依赖

- [ ] Task 2: 配置 Flutter Web 支持
  - [ ] SubTask 2.1: 检查并启用 Flutter Web 支持 (flutter config --enable-web)
  - [ ] SubTask 2.2: 更新 web/index.html 添加传感器权限提示
  - [ ] SubTask 2.3: 更新 web/manifest.json 配置 PWA
  - [ ] SubTask 2.4: 配置 web 构建优化选项

## 阶段二：Web 传感器适配

- [ ] Task 3: 创建 Web 传感器服务
  - [ ] SubTask 3.1: 创建 lib/services/web_sensor_service.dart
  - [ ] SubTask 3.2: 实现 DeviceMotion API 封装
  - [ ] SubTask 3.3: 添加传感器权限请求逻辑
  - [ ] SubTask 3.4: 实现坐标系转换 (Web 到车辆坐标系)
  - [ ] SubTask 3.5: 创建平台适配层 (移动端 vs Web)

- [ ] Task 4: 修改传感器引擎支持 Web
  - [ ] SubTask 4.1: 修改 sensor_engine.dart 支持条件编译
  - [ ] SubTask 4.2: 为 Web 平台实现 30Hz 采样率
  - [ ] SubTask 4.3: 添加 Web 平台校准逻辑
  - [ ] SubTask 4.4: 测试 Web 传感器数据准确性

## 阶段三：可乐杯物理模拟器

- [ ] Task 5: 创建可乐杯可视化组件
  - [ ] SubTask 5.1: 创建 lib/common/widgets/cola_cup.dart
  - [ ] SubTask 5.2: 设计可乐杯 UI (杯子轮廓、液体、气泡)
  - [ ] SubTask 5.3: 实现液体倾斜动画 (基于加速度角度)
  - [ ] SubTask 5.4: 实现液体晃动效果
  - [ ] SubTask 5.5: 实现撒出粒子效果

- [ ] Task 6: 实现物理计算引擎
  - [ ] SubTask 6.1: 创建 lib/features/cola_simulator/domain/physics_engine.dart
  - [ ] SubTask 6.2: 实现加速度到倾斜角度的转换
  - [ ] SubTask 6.3: 实现撒出量计算公式
  - [ ] SubTask 6.4: 实现累积撒出量追踪
  - [ ] SubTask 6.5: 添加物理参数配置 (灵敏度、最大倾斜角)

- [ ] Task 7: 创建可乐杯模拟器页面
  - [ ] SubTask 7.1: 创建 lib/features/cola_simulator/presentation/cola_simulator_screen.dart
  - [ ] SubTask 7.2: 集成可乐杯组件和物理引擎
  - [ ] SubTask 7.3: 添加实时数据显示 (加速度、撒出百分比)
  - [ ] SubTask 7.4: 添加开始/重置按钮
  - [ ] SubTask 7.5: 添加灵敏度调节滑块

## 阶段四：行程回放功能

- [ ] Task 8: 创建行程回放页面
  - [ ] SubTask 8.1: 创建 lib/features/replay/presentation/trip_replay_screen.dart
  - [ ] SubTask 8.2: 实现行程数据加载逻辑
  - [ ] SubTask 8.3: 实现时间轴播放控制
  - [ ] SubTask 8.4: 集成可乐杯模拟器显示回放
  - [ ] SubTask 8.5: 添加加速度波形图显示

- [ ] Task 9: 实现回放控制组件
  - [ ] SubTask 9.1: 创建播放/暂停按钮组件
  - [ ] SubTask 9.2: 创建进度条拖拽组件
  - [ ] SubTask 9.3: 实现播放速度切换 (0.5x, 1x, 2x)
  - [ ] SubTask 9.4: 显示当前时间/总时长
  - [ ] SubTask 9.5: 添加帧步进控制 (前进/后退)

- [ ] Task 10: 修改历史记录页面
  - [ ] SubTask 10.1: 在历史记录列表添加"回放"按钮
  - [ ] SubTask 10.2: 实现点击跳转到回放页面
  - [ ] SubTask 10.3: 传递行程数据到回放页面

## 阶段五：Chromium 与车机优化

- [ ] Task 11: Chromium 浏览器优化
  - [ ] SubTask 11.1: 添加 HTTPS 传感器权限检测
  - [ ] SubTask 11.2: 优化 Canvas 渲染性能
  - [ ] SubTask 11.3: 添加触摸事件优化
  - [ ] SubTask 11.4: 测试 Chrome/Edge 兼容性

- [ ] Task 12: 安卓车机优化
  - [ ] SubTask 12.1: 检测车机环境并降低采样率至 20Hz
  - [ ] SubTask 12.2: 简化动画效果 (减少粒子数量)
  - [ ] SubTask 12.3: 适配车机横屏全屏模式
  - [ ] SubTask 12.4: 优化内存使用
  - [ ] SubTask 12.5: 添加车机专用 UI 布局

## 阶段六：部署配置

- [ ] Task 13: 创建 Debian 部署配置
  - [ ] SubTask 13.1: 创建 Nginx 配置文件
  - [ ] SubTask 13.2: 创建 Dockerfile
  - [ ] SubTask 13.3: 创建 docker-compose.yml
  - [ ] SubTask 13.4: 编写部署文档

- [ ] Task 14: 构建与发布
  - [ ] SubTask 14.1: 执行 flutter build web --release
  - [ ] SubTask 14.2: 验证构建输出
  - [ ] SubTask 14.3: 测试生产环境部署
  - [ ] SubTask 14.4: 优化构建体积 (tree shaking)

# Task Dependencies
- Task 2 依赖于 Task 1 完成
- Task 4 依赖于 Task 3 完成
- Task 6 依赖于 Task 5 完成
- Task 7 依赖于 Task 4 和 Task 6 完成
- Task 8 依赖于 Task 7 完成
- Task 10 依赖于 Task 8 完成
- Task 12 依赖于 Task 11 完成
- Task 14 依赖于 Task 13 完成
