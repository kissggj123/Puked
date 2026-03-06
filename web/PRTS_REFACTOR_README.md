# 《明日方舟》PRTS 终端风格 UI 重构完成

## 重构概述

已成功将 `/web/index.html` 重构为《明日方舟》PRTS 终端风格 UI，保持所有现有功能不变。

## 文件结构

- `index.html` - 主页面（已添加 PRTS CSS 引用）
- `prts_styles.css` - PRTS 风格样式表（新增）
- `index_backup.html` - 原始文件备份

## PRTS 风格特性

### 1. CSS 变量系统

```css
:root {
  --prt-black: #0a0a0a;      /* 深黑色背景 */
  --prt-dark: #1a1a1a;       /* 深色面板 */
  --prt-gray: #2d2d2d;       /* 灰色 */
  --prt-cyan: #00f0ff;       /* 青色（主色调） */
  --prt-blue: #1976D2;       /* 蓝色 */
  --prt-orange: #ff9800;     /* 橙色（能量条） */
  --prt-warning: #ffc107;    /* 警告色 */
  --prt-red: #f44336;        /* 红色（危险） */
  --prt-danger: #8b0000;     /* 深红色 */
  --prt-white: #ffffff;      /* 白色 */
  --prt-text: #cccccc;       /* 文本色 */
}
```

### 2. 全局样式效果

- **网格背景**：使用 CSS 渐变创建 30px 网格
- **扫描线动画**：全屏扫描线效果（8 秒循环）
- **等宽字体**：Roboto Mono 用于数字显示

### 3. 杯子可视化组件

- **线框图样式**：青色边框 + 发光效果
- **液体能量条**：分段式设计（每段 10%）
- **粒子效果**：橙色发光撒出动画

### 4. 按钮组件

- **切角矩形**：45 度切角（clip-path）
- **悬停发光**：box-shadow + border 高亮
- **按下状态**：transform: scale(0.98)
- **内部光效**：扫光动画

### 5. 卡片和面板

- **切角边框**：使用 clip-path
- **半透明背景**：rgba(26, 26, 26, 0.9)
- **渐变边框**：青色到蓝色渐变

### 6. 弹窗组件

- **切角容器**：大尺寸切角
- **扫描线背景**：垂直扫描动画
- **统一按钮样式**：PRTS 风格

### 7. 数据展示

- **等宽字体**：Roboto Mono
- **文字发光**：text-shadow 效果
- **青色渐变进度条**：动态填充
- **数字化时间**：大字号 + 发光

### 8. 加载动画

- **环形扫描**：双层旋转边框
- **校准能量填充**：脉冲动画

## 响应式布局

```css
@media (max-width: 768px) {
  /* 移动端优化切角尺寸 */
  --prt-chamfer-md: polygon(0 0, calc(100% - 6px) 0, ...);
}
```

## 性能优化

- 使用 `transform` 而非 `position` 进行动画
- `will-change` 提示浏览器优化
- CSS 动画使用 GPU 加速

## 浏览器兼容性

- 支持现代浏览器（Chrome, Safari, Firefox, Edge）
- 使用 vendor prefixes 确保 Safari 兼容性
- Fallback 配色方案

## 使用方法

1. 打开 `index.html` 即可体验 PRTS 风格 UI
2. 所有功能保持不变
3. 样式通过 `prts_styles.css` 独立管理

## 自定义

可以通过修改 `prts_styles.css` 中的 CSS 变量来调整配色方案：

```css
:root {
  --prt-cyan: #你的颜色;  /* 修改主色调 */
}
```

## 技术细节

- **切角效果**：使用 `clip-path: polygon()` 创建
- **扫描线**：使用伪元素 + linear-gradient + animation
- **发光效果**：使用 `box-shadow` 和 `text-shadow`
- **渐变边框**：使用 `border-image` 或伪元素

## 注意事项

- 不要删除 `index_backup.html`，除非确认新版本无问题
- `prts_styles.css` 需要与 `index.html` 在同一目录
- 部分动画可能需要设备性能支持

---

重构完成时间：2026-03-07
重构风格：《明日方舟》PRTS 终端
保持功能：100% 兼容原有功能
