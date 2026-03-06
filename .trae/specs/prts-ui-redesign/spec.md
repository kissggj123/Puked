# 洒了么 - PRTS 终端风格 UI 重构

## Why
当前 web/index.html 使用标准的 Material Design 风格，缺乏独特视觉识别度。为提升用户体验和品牌记忆点，采用《明日方舟》PRTS 终端风格，打造科幻工业风的界面设计。

## What Changes
- **配色系统**：采用黑/灰/青/橙配色方案
  - 主背景：深灰黑色 (#1a1a1a, #2d2d2d)
  - 强调色：青色 (#00f0ff, #1976D2)
  - 警告色：橙色 (#ff9800, #ffc107)
  - 危险色：红色 (#f44336, #8b0000)
  - 文字：白色/浅灰色 (#ffffff, #cccccc)

- **设计风格**：
  - 切角设计：所有卡片、按钮采用 45 度切角或斜角边框
  - 工业风：网格背景、扫描线效果、数据化展示
  - 科技感：发光效果、渐变边框、动态粒子背景

- **组件重构**：
  - 按钮：切角矩形，带发光边框效果
  - 卡片：斜角边框 + 半透明背景
  - 进度条：分段式工业风格
  - 弹窗：切角设计 + 扫描线背景
  - 图标：线性科技图标

- **动效设计**：
  - 加载动画：环形扫描效果
  - 切换动画：数字化淡入淡出
  - 悬停效果：边框发光 + 背景高亮

## Impact
- **Affected specs**: web/index.html 完整重构
- **Affected code**: 
  - CSS 样式系统（完全重写）
  - Vue 组件模板（结构调整）
  - 交互逻辑（保持功能不变）

## ADDED Requirements

### Requirement: PRTS 视觉风格
The system SHALL provide 《明日方舟》PRTS 终端风格的视觉设计

#### Scenario: 用户打开网页
- **WHEN** 用户访问网页
- **THEN** 看到黑/灰/青/橙配色的科幻工业风界面
- **THEN** 所有 UI 元素采用切角设计
- **THEN** 背景包含网格/扫描线等科技元素

### Requirement: 响应式布局
The system SHALL maintain 完全响应式布局，适配移动端和桌面端

#### Scenario: 不同设备访问
- **WHEN** 用户在手机/平板/桌面访问
- **THEN** 界面自动适配屏幕尺寸
- **THEN** 保持 PRTS 风格一致性

### Requirement: 交互反馈
The system SHALL provide 科技感的交互反馈效果

#### Scenario: 用户交互
- **WHEN** 用户悬停按钮
- **THEN** 显示边框发光效果
- **WHEN** 用户点击按钮
- **THEN** 显示数字化按压效果
- **WHEN** 数据加载
- **THEN** 显示扫描式加载动画

## MODIFIED Requirements

### Requirement: 杯子可视化
[MODIFIED] 可乐杯可视化采用 PRTS 风格

- 杯体：线框图 + 青色/橙色渐变
- 液体：分段式能量条风格
- 撒出效果：粒子飞散 + 橙色警告色
- 背景：网格坐标纸风格

### Requirement: 数据展示
[MODIFIED] 加速度/G 值数据采用科技感展示方式

- 数字：等宽字体 + 发光效果
- 图表：折线图采用青色渐变
- 单位：小型化标注
- 背景：半透明深色面板

## REMOVED Requirements

### Requirement: Material Design 圆角卡片
**Reason**: 与 PRTS 工业风冲突，改用切角设计
**Migration**: 所有圆角改为 45 度切角或斜角

### Requirement: 标准 Material 配色
**Reason**: 缺乏品牌识别度
**Migration**: 全面采用黑/灰/青/橙配色系统
