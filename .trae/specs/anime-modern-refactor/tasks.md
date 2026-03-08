# Tasks - 二次元现代化重构

- [ ] Task 1: 清理无用代码
  - [ ] SubTask 1.1: 移除隐私政策弹窗相关代码
  - [ ] SubTask 1.2: 移除云端上传功能代码
  - [ ] SubTask 1.3: 简化数据库操作相关代码
  - [ ] SubTask 1.4: 优化 IndexedDB 和 localStorage 代码
  - [ ] SubTask 1.5: 清理无用的 Vue 变量和函数

- [ ] Task 2: 创建二次元现代化 CSS 样式系统
  - [ ] SubTask 2.1: 定义二次元配色变量（粉色/紫色/青色）
  - [ ] SubTask 2.2: 创建玻璃拟态设计样式
  - [ ] SubTask 2.3: 实现渐变和阴影效果
  - [ ] SubTask 2.4: 创建流畅的动画过渡效果
  - [ ] SubTask 2.5: 优化响应式布局断点

- [ ] Task 3: 引入 Three.js 并实现 3D 基础场景
  - [ ] SubTask 3.1: 添加 Three.js CDN 引用
  - [ ] SubTask 3.2: 创建基础场景（Scene、Camera、Renderer）
  - [ ] SubTask 3.3: 实现基础光照（AmbientLight + DirectionalLight）
  - [ ] SubTask 3.4: 创建地面和背景
  - [ ] SubTask 3.5: 实现相机控制和场景管理

- [ ] Task 4: 实现多种液体/食物 3D 模型
  - [ ] SubTask 4.1: 创建杯子模型（CylinderGeometry）
  - [ ] SubTask 4.2: 创建碗模型（SphereGeometry 截断）
  - [ ] SubTask 4.3: 创建盘子模型（CylinderGeometry 扁平）
  - [ ] SubTask 4.4: 实现液体表面（使用 Shader 或顶点动画）
  - [ ] SubTask 4.5: 实现颗粒食物模型（米饭/面条粒子系统）
  - [ ] SubTask 4.6: 添加材质和纹理（透明、反射）

- [ ] Task 5: 实现食物/液体物理引擎
  - [ ] SubTask 5.1: 定义不同液体的物理属性（粘度、密度、表面张力）
  - [ ] SubTask 5.2: 实现低粘度液体物理（可乐/水）
  - [ ] SubTask 5.3: 实现中粘度液体物理（咖啡/牛奶）
  - [ ] SubTask 5.4: 实现高粘度液体物理（粥/汤）
  - [ ] SubTask 5.5: 实现颗粒食物物理（米饭/面条）
  - [ ] SubTask 5.6: 根据传感器数据计算晃动效果

- [ ] Task 6: 实现粒子撒出效果
  - [ ] SubTask 6.1: 创建粒子系统基础框架
  - [ ] SubTask 6.2: 实现液体粒子效果（小水滴）
  - [ ] SubTask 6.3: 实现颗粒粒子效果（米粒/面条）
  - [ ] SubTask 6.4: 优化粒子物理（重力、碰撞）
  - [ ] SubTask 6.5: 添加粒子消失效果

- [ ] Task 7: 实现 Three.js 性能优化
  - [ ] SubTask 7.1: 检测设备性能（GPU 信息）
  - [ ] SubTask 7.2: 实现 LOD（Level of Detail）系统
  - [ ] SubTask 7.3: 优化粒子系统（实例化渲染）
  - [ ] SubTask 7.4: 实现质量预设（高/中/低）
  - [ ] SubTask 7.5: 添加 FPS 监控和自动降级

- [ ] Task 8: 重构右上角菜单为侧边抽屉式
  - [ ] SubTask 8.1: 创建侧边抽屉菜单组件
  - [ ] SubTask 8.2: 添加滑出/滑入动画
  - [ ] SubTask 8.3: 实现背景半透明模糊效果
  - [ ] SubTask 8.4: 添加触摸手势支持
  - [ ] SubTask 8.5: 优化菜单项布局和样式

- [ ] Task 9: 优化历史记录功能
  - [ ] SubTask 9.1: 优化 IndexedDB 存储结构
  - [ ] SubTask 9.2: 实现历史记录列表展示
  - [ ] SubTask 9.3: 实现历史记录详情查看
  - [ ] SubTask 9.4: 实现轨迹回放功能
  - [ ] SubTask 9.5: 添加删除和清空功能
  - [ ] SubTask 9.6: 优化存储性能和空间管理

- [ ] Task 10: 创建更新日志页面
  - [ ] SubTask 10.1: 设计更新日志页面布局
  - [ ] SubTask 10.2: 实现 Markdown 解析功能
  - [ ] SubTask 10.3: 创建版本历史展示组件
  - [ ] SubTask 10.4: 优化日志格式化显示

- [ ] Task 11: 实现 Android 车机传感器支持
  - [ ] SubTask 11.1: 添加 Chromium 传感器权限检测
  - [ ] SubTask 11.2: 实现 DeviceOrientation API 支持
  - [ ] SubTask 11.3: 实现 DeviceMotion API 支持
  - [ ] SubTask 11.4: 创建传感器数据解析模块
  - [ ] SubTask 11.5: 优化车机模式下的 UI 适配

- [ ] Task 12: 优化全屏功能
  - [ ] SubTask 12.1: 实现 Fullscreen API 封装
  - [ ] SubTask 12.2: 添加全屏按钮和快捷键（ESC）
  - [ ] SubTask 12.3: 全屏模式下隐藏非必要 UI 元素
  - [ ] SubTask 12.4: 优化全屏模式下的 UI 布局
  - [ ] SubTask 12.5: 添加全屏状态指示器

- [ ] Task 13: 重构数据可视化组件
  - [ ] SubTask 13.1: 创建三轴加速度图表
  - [ ] SubTask 13.2: 重构 G 值环形进度条
  - [ ] SubTask 13.3: 实现 Canvas 轨迹绘制
  - [ ] SubTask 13.4: 优化数据展示动画
  - [ ] SubTask 13.5: 添加二次元风格的数据展示

- [ ] Task 14: 优化整体 UI/UX
  - [ ] SubTask 14.1: 优化按钮和交互元素
  - [ ] SubTask 14.2: 优化加载和状态指示器
  - [ ] SubTask 14.3: 优化错误处理和提示
  - [ ] SubTask 14.4: 优化触摸和手势反馈
  - [ ] SubTask 14.5: 优化性能和内存使用

- [ ] Task 15: 测试和验证
  - [ ] SubTask 15.1: 在不同设备上测试响应式布局
  - [ ] SubTask 15.2: 测试 Android 车机传感器功能
  - [ ] SubTask 15.3: 验证 Three.js 性能和画质
  - [ ] SubTask 15.4: 验证二次元 UI 样式一致性
  - [ ] SubTask 15.5: 验证菜单和历史记录功能
  - [ ] SubTask 15.6: 验证全屏功能
  - [ ] SubTask 15.7: 验证液体/食物切换功能
  - [ ] SubTask 15.8: 性能基准测试

# Task Dependencies
- Task 2 depends on Task 1
- Task 3 depends on Task 2
- Task 4 depends on Task 3
- Task 5 depends on Task 4
- Task 6 depends on Task 4, 5
- Task 7 depends on Task 3-6
- Task 8 depends on Task 2
- Task 9 depends on Task 1
- Task 10 depends on Task 2
- Task 11 depends on Task 2
- Task 12 depends on Task 2
- Task 13 depends on Task 2, 3
- Task 14 depends on Task 2-13
- Task 15 depends on Task 1-14
