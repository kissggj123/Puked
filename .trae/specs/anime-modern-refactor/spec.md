# 可乐模拟器 - 二次元现代化重构

## Why
当前 web/index.html 包含大量过时的隐私政策代码、冗余功能和陈旧的 UI 设计。需要清理无用代码，引入二次元风格的现代化 UI，使用 Three.js 实现华丽的 3D 效果，支持多种液体/食物模拟，实现专业的物理算法和惯导算法，优化事件判定，并支持 Android 车机传感器数据获取。

## What Changes
- **代码清理**：
  - 移除隐私政策弹窗及相关逻辑
  - 移除云端上传功能
  - 简化数据库相关代码
  - 优化 IndexedDB 和 localStorage 操作

- **UI 重构**：
  - 二次元风格配色（粉色/紫色/青色渐变）
  - 现代化玻璃拟态设计（Glassmorphism）
  - 流畅的动画过渡效果
  - 响应式布局优化
  - 高级渐变和阴影效果

- **Three.js 3D 效果**：
  - 3D 容器模型（杯子、碗、盘子等）
  - 动态液体/食物效果（基于传感器数据）
  - 粒子效果（撒出时的粒子系统）
  - 环境光遮蔽和阴影
  - 动态模糊和光晕效果

- **物理算法系统**：
  - **刚体动力学算法**
  - **流体动力学简化模型**
  - **粒子系统物理**
  - **碰撞检测和响应**
  - **摩擦力模型**
  - **表面张力模拟**

- **惯导算法系统**：
  - **姿态解算算法**（欧拉角、四元数）
  - **卡尔曼滤波**（传感器数据融合）
  - **互补滤波**（加速度计 + 陀螺仪）
  - **零速修正**（ZUPT - Zero Velocity Update）
  - **惯性导航解算**（位置、速度、姿态）
  - **重力补偿算法**
  - **坐标系转换**（世界坐标系 - 设备坐标系）

- **事件判定优化**：
  - **急加速/急减速判定**（基于加速度阈值和变化率）
  - **急转弯判定**（基于横向加速度和角速度）
  - **颠簸判定**（基于垂直加速度和频率分析）
  - **刹车判定**（基于纵向减速度）
  - **碰撞检测**（基于加速度峰值）
  - **平滑驾驶评分**（综合多种因素）

- **功能优化**：
  - 右上角菜单重构为侧边抽屉式
  - 添加更新日志页面
  - **保留并优化历史记录功能**
  - 简化设置选项
  - 优化传感器数据获取
  - **优化全屏功能（支持真正的全屏沉浸体验）**

- **新增功能**：
  - **多种液体/食物模拟（可乐、水、咖啡、米饭、汤等）**
  - **通过设置选项切换不同的模拟对象**
  - Android 车机传感器支持（通过 Chromium DeviceOrientation API）
  - 实时 G 值轨迹记录
  - 传感器数据可视化图表
  - 更新日志展示页面
  - Three.js 性能优化（LOD、实例化渲染）
  - **物理事件记录和分析**

## Impact
- **Affected specs**: web/index.html 完全重构
- **Affected code**: 
  - 删除隐私政策相关代码（约 200 行）
  - 删除云端功能代码（约 300 行）
  - 重写 CSS 样式系统
  - 重构 Vue 组件结构
  - 新增 Three.js 3D 渲染模块
  - 新增传感器服务模块
  - **新增物理引擎模块**
  - **新增惯导算法模块**
  - **新增事件判定算法模块**
  - 优化历史记录存储
  - 新增食物/液体物理引擎

## ADDED Requirements

### Requirement: 二次元现代化 UI 风格
The system SHALL provide 二次元风格的现代化界面设计

#### Scenario: 用户打开网页
- **WHEN** 用户访问网页
- **THEN** 看到粉色/紫色/青色渐变背景
- **THEN** 所有卡片采用玻璃拟态设计（半透明 + 模糊）
- **THEN** 按钮和图标有流畅的悬停动画
- **THEN** 整体风格年轻化和高级感

### Requirement: 多种液体/食物模拟
The system SHALL provide 多种液体和食物的物理模拟

#### Scenario: 用户切换模拟对象
- **WHEN** 用户打开设置页面
- **WHEN** 用户选择不同的模拟对象
- **THEN** 可选：可乐、水、咖啡、茶、果汁、牛奶
- **THEN** 可选：米饭、面条、汤、粥
- **THEN** 不同液体有不同的物理属性（粘度、表面张力、密度）
- **THEN** 不同食物有不同的颗粒效果
- **THEN** 实时切换到选中的 3D 模型

### Requirement: 食物/液体物理引擎
The system SHALL provide 针对不同液体/食物的物理特性模拟

#### Scenario: 不同液体/食物的物理表现
- **WHEN** 使用可乐/水（低粘度液体）
- **THEN** 流动性好，晃动幅度大，易撒出
- **WHEN** 使用咖啡/牛奶（中粘度液体）
- **THEN** 流动性适中，晃动幅度中等
- **WHEN** 使用粥/汤（高粘度液体）
- **THEN** 流动性差，晃动幅度小，不易撒出
- **WHEN** 使用米饭/面条（颗粒状食物）
- **THEN** 显示颗粒效果，散落时呈颗粒状

### Requirement: 刚体动力学算法
The system SHALL provide 刚体动力学计算能力

#### Scenario: 刚体运动计算
- **WHEN** 设备移动时
- **THEN** 计算线速度和角速度
- **THEN** 计算线加速度和角加速度
- **THEN** 应用牛顿运动定律
- **THEN** 计算惯性力

### Requirement: 流体动力学简化模型
The system SHALL provide 简化的流体动力学计算

#### Scenario: 液体晃动计算
- **WHEN** 设备加速/减速/转弯时
- **THEN** 计算液体表面倾斜角度
- **THEN** 计算液体晃动幅度和频率
- **THEN** 考虑粘度和表面张力影响
- **THEN** 计算液体溢出临界点

### Requirement: 姿态解算算法
The system SHALL provide 设备姿态解算能力

#### Scenario: 设备姿态计算
- **WHEN** 获取传感器数据时
- **THEN** 使用欧拉角或四元数表示姿态
- **THEN** 计算俯仰角（Pitch）
- **THEN** 计算横滚角（Roll）
- **THEN** 计算偏航角（Yaw）
- **THEN** 避免万向节锁问题（使用四元数）

### Requirement: 卡尔曼滤波算法
The system SHALL provide 传感器数据融合和滤波

#### Scenario: 传感器数据处理
- **WHEN** 获取加速度计和陀螺仪数据时
- **THEN** 使用卡尔曼滤波融合多传感器数据
- **THEN** 消除传感器噪声
- **THEN** 估计真实加速度和角速度
- **THEN** 自适应调整滤波参数

### Requirement: 互补滤波算法
The system SHALL provide 加速度计 + 陀螺仪数据融合

#### Scenario: 姿态融合计算
- **WHEN** 同时获取加速度计和陀螺仪数据
- **THEN** 使用互补滤波融合两种传感器
- **THEN** 短期使用陀螺仪（高频响应好）
- **THEN** 长期使用加速度计（无漂移）
- **THEN** 获得稳定准确的姿态

### Requirement: 惯性导航解算
The system SHALL provide 位置、速度、姿态解算

#### Scenario: 轨迹推算
- **WHEN** 设备移动时
- **THEN** 积分加速度得到速度
- **THEN** 积分速度得到位置
- **THEN** 应用零速修正（ZUPT）减少漂移
- **THEN** 重力补偿
- **THEN** 坐标系转换（世界坐标 - 设备坐标）

### Requirement: 事件判定算法
The system SHALL provide 驾驶事件检测和判定

#### Scenario: 驾驶事件检测
- **WHEN** 实时分析传感器数据时
- **THEN** 检测急加速（纵向加速度 > 阈值）
- **THEN** 检测急减速（纵向减速度 > 阈值）
- **THEN** 检测急转弯（横向加速度 > 阈值）
- **THEN** 检测颠簸（垂直加速度 + 频率分析）
- **THEN** 检测刹车（纵向减速度变化率）
- **THEN** 检测碰撞（加速度峰值检测）

### Requirement: 平滑驾驶评分算法
The system SHALL provide 综合驾驶质量评分

#### Scenario: 驾驶评分计算
- **WHEN** 一次行程结束或实时计算
- **THEN** 综合急加速/急减速次数
- **THEN** 综合急转弯次数
- **THEN** 综合颠簸程度
- **THEN** 考虑加速度平滑度
- **THEN** 给出 0-100 的评分
- **THEN** 提供改进建议

### Requirement: Three.js 3D 效果
The system SHALL provide 使用 Three.js 实现的华丽 3D 效果

#### Scenario: 用户查看 3D 模拟
- **WHEN** 用户打开模拟器页面
- **THEN** 看到 3D 渲染的容器和液体/食物
- **THEN** 液体/食物根据传感器数据实时倾斜/晃动
- **THEN** 撒出时显示粒子飞散效果
- **THEN** 支持动态光影和反射效果
- **THEN** 在不同配置设备上流畅运行（60fps）

### Requirement: Three.js 性能优化
The system SHALL provide 针对不同配置的 Three.js 性能优化

#### Scenario: 不同配置设备运行
- **WHEN** 用户在高端设备（独立显卡）
- **THEN** 启用高质量渲染（阴影、反射、抗锯齿、复杂粒子）
- **WHEN** 用户在中端设备（集成显卡）
- **THEN** 启用中等质量渲染（简化阴影、降低采样、中等粒子）
- **WHEN** 用户在低端设备（移动设备）
- **THEN** 启用低质量渲染（基础光照、减少粒子、简化模型）
- **THEN** 自动检测设备性能并调整渲染质量
- **THEN** 保持至少 30fps 的帧率

### Requirement: 优化全屏功能
The system SHALL provide 真正的全屏沉浸体验

#### Scenario: 用户进入全屏模式
- **WHEN** 用户点击全屏按钮
- **THEN** 使用 Fullscreen API 进入真正的全屏
- **THEN** 隐藏所有浏览器 UI（地址栏、工具栏等）
- **THEN** 隐藏网页中不必要的元素（菜单、按钮等）
- **THEN** 仅保留核心模拟区域和数据展示
- **THEN** 支持 ESC 键或手势退出全屏
- **THEN** 全屏状态下优化 UI 布局（最大化可视区域）

### Requirement: Android 车机传感器支持
The system SHALL provide 通过 Chromium 浏览器获取 Android 车机传感器数据

#### Scenario: 用户在 Android 车机上使用
- **WHEN** 用户使用 Android 车机上的 Chromium 浏览器
- **WHEN** 用户点击"开始模拟"
- **THEN** 请求 DeviceOrientation 和 DeviceMotion 权限
- **THEN** 实时获取加速度数据（X/Y/Z 轴）
- **THEN** 实时获取角速度数据（X/Y/Z 轴）
- **THEN** 计算并显示 G 值和轨迹
- **THEN** 数据更新频率至少 50Hz

### Requirement: 历史记录功能
The system SHALL provide 本地历史记录保存和查看功能

#### Scenario: 用户保存和查看历史
- **WHEN** 用户完成一次模拟
- **THEN** 可以选择保存到本地
- **THEN** 使用 IndexedDB 存储详细数据
- **WHEN** 用户查看历史记录
- **THEN** 显示历史模拟列表（时间、G 值、时长、使用的模拟对象、事件记录）
- **THEN** 可以点击回放轨迹
- **THEN** 可以查看物理事件统计
- **THEN** 支持删除和清空操作

### Requirement: 更新日志页面
The system SHALL provide 展示项目更新历史的页面

#### Scenario: 用户查看更新日志
- **WHEN** 用户点击右上角菜单
- **WHEN** 用户选择"更新日志"
- **THEN** 显示版本历史记录
- **THEN** 包含日期、版本号、更新内容
- **THEN** 支持 Markdown 格式渲染

### Requirement: 侧边抽屉式菜单
The system SHALL provide 现代化的侧边抽屉式导航菜单

#### Scenario: 用户打开菜单
- **WHEN** 用户点击右上角菜单按钮
- **THEN** 从右侧滑出抽屉式菜单
- **THEN** 背景半透明模糊
- **THEN** 包含：更新日志、设置、历史记录、关于等选项
- **THEN** 点击外部区域关闭

## MODIFIED Requirements

### Requirement: 右上角菜单
[MODIFIED] 重构为侧边抽屉式设计

- 原设计：简单的下拉菜单
- 新设计：右侧滑出的抽屉式菜单
- 添加动画过渡效果
- 优化触摸交互体验
- 新增历史记录入口

### Requirement: 传感器数据获取
[MODIFIED] 增强为支持 Android 车机传感器

- 原实现：仅支持手机传感器
- 新实现：支持 Android 车机 + 手机
- 添加设备类型检测
- 优化车机模式下的 UI 布局
- 支持加速度计和陀螺仪

### Requirement: 数据展示
[MODIFIED] 采用更直观的可视化方式

- 原实现：2D 图表
- 新实现：Three.js 3D 可视化 + 2D 数据面板
- 加速度：三轴实时图表
- G 值：环形进度条 + 数字显示
- 轨迹：Canvas 绘制运动轨迹
- 物理事件：时间轴展示
- 风格：二次元配色 + 玻璃拟态

### Requirement: 历史记录存储
[MODIFIED] 优化为 IndexedDB 高性能存储

- 原实现：简单的 localStorage
- 新实现：IndexedDB + localStorage 混合
- IndexedDB：存储详细轨迹数据、物理事件
- localStorage：存储摘要和设置
- 支持批量操作和事务

### Requirement: 设置页面
[MODIFIED] 增加模拟对象选择和算法配置

- 原设计：简单的灵敏度设置
- 新设计：完整的模拟设置
- 模拟对象选择（液体/食物类型）
- 质量预设（高/中/低）
- 全屏模式开关
- 灵敏度调节
- 传感器校准
- 算法参数配置（高级用户）

## REMOVED Requirements

### Requirement: 隐私政策弹窗
**Reason**: 项目改为个人开源项目，无需商业隐私政策
**Migration**: 完全移除相关代码和 UI

### Requirement: 云端上传功能
**Reason**: 功能冗余，用户不需要云端同步
**Migration**: 移除上传逻辑，保留本地存储
