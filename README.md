# 可乐杯物理模拟器 (Cola Cup Physics Simulator)

一个基于 Flutter Web 的实时加速度可视化应用，模拟可乐杯在车辆运动中的物理反应。

## 功能特性

### 核心功能
- **实时可乐杯模拟**: 100% 装满的可乐杯，根据实时加速度数据动态显示液体倾斜和撒出效果
- **物理计算引擎**: 基于真实物理公式计算撒出百分比 (0-100%)
- **实时数据显示**: 显示横向/纵向加速度、G 值、撒出百分比
- **灵敏度调节**: 支持 0.1x - 2.0x 灵敏度调节
### 行程回放

- 历史回放动): 回放已保存的行程数据s.
- 播放控制etry播放/暂停/停止、进度条拖拽、帧步进rea.
- 速度调节erts支持a0.5xg/u1i0xo(n2b0x 播放速度
- 同步显示遥测: 回放屏同步界面 乐杯）的和加速度数据驶反馈。

### Web 优化

- CEtrtrelo浏览器优化ntsi针对kCnen t/EiuTZ优化，支持c3sHzm传感器采样hts.
- 安卓车机优化tion自动检测车机环境，降低采样率至e" Hz>保证流畅cts.

* **PWA 支持**: 车安装为桌面应用物支持离线访问迹漂移。
  - 响应式设计速修:停适配手机、平板、车机屏幕里程”。

## 技术栈

- 框架飞点: FlCwysti3.24+\*\*
- 状态管理tiowRhvyreosm/h.
- 传感器HolnDen ceMw stayAPIv(Wsb)ion.

* **物理引擎**: 自定义物理计算引擎
  - 部署动态:速Doc er +kNginx
    图旋转。

## 快\*开始面乱转。

### 本地开发

````bash
# 克隆项目
git clone <eEpt(url>**
cd aocu-trmucZrtn

#g安装依赖
flustovepub hht

#g运行pW ds应用
fludecrdrida(slchpompd.
```报。

### 构建发布

```bAhh
#c构建 Wlbe自用**
flucthr buihonwabe--n eiaesd:

# 使用 D c( tv部署
 sckir co>prcreupvhsp--bmilders.
````

作误报。

## 部署指南锐捕捉。

详细部署说明请参考 [DEPLOY.md](DEPLOY.md)

### 快 部署到 Dtpyrsn服务传态。

```btSh**
# 1. 安装gDt tte
ctbttopnrupdx,m
sudo tphar omih/  y*daok* . 'waegkcc- tmteow
的偏差。
# 2. 克隆项目
git rFonln<tu*ehiod>ays.
 micela-foma  e athm.

#性3.t启动服务高刷屏。
d限cker*c sa eaeu,r-dk--buwhr

#b    **智能降采样**。在入库存储时将 100Hz 原始数据降频至 **20Hz**，在保留波形峰值特征的同时节省 80% 存储空间。
```
```

## 使用说明

### 实时模拟
1. 打开应用，点击"开始模拟"
2. 授权传感器权限 (需要 HTTPS)
3. 移动设备查看可乐杯实时反应
4. 调节灵敏度以获得最佳体验

### 行程回放
1. 进入"历史记录"页面
2. 点击行程卡片上的播放按钮
3. 使用控制按钮播放/暂停/调节进度

## 浏览器兼容性

| 浏览器 | 版本要求 |
|--------|----------|
| Chrome | 90+ |
| Edge | 90+ |
| Safari | 14+ (iOS 14+) |
| Firefox | 88+ |

**注意**: 传感器功能需要 HTTPS 环境

## 项目结构

```
lib/
├── common/
│   └── widgets/
│       └── cola_cup.dart          # 可乐杯可视化组件
├── features/
│   ├── cola_simulator/
│   │   ├── domain/
│   │   │   └── physics_engine.dart # 物理计算引擎
│   │   ├── presentation/
│   │   │   └── cola_simulator_screen.dart
│   │   └── providers/
│   │       └── cola_simulator_provider.dart
│   ├── history/
│   │   └── presentation/
│   │       └── history_screen.dart
│   ├── main/
│   │   └── presentation/
│   │       └── main_screen.dart
│   ├── recording/
│   │   └── providers/
│   │       └── sensor_provider.dart # 传感器提供者
│   ├── replay/
│   │   └── presentation/
│   │       └── trip_replay_screen.dart
│   └── settings/
├── services/
│   └── web_sensor_service.dart     # Web 传感器服务
└── main.dart
```

## 物理引擎原理

### 倾斜计算
- 基于加速度向量计算液面倾斜角度
- 最大倾斜角度: 45度
- 灵敏度系数: 0.1 - 2.0

### 撒出计算
```
撒出量 = (超出阈值加速度 / 最大加速度)² × 撒出速率 × 时间
```
- 开始撒出阈值: 3 m/s²
- 最大撒出阈值: 15 m/s²

## 配置选项

### 灵敏度设置
- **低 (0.1-0.5)**: 适合平稳驾驶环境
- **中 (0.5-1.0)**: 默认设置，适合一般使用
- **高 (1.0-2.0)**: 适合激烈驾驶或测试

### 车机模式
应用自动检测车机环境并优化:
- 降低传感器采样率至 20Hz
- 简化动画效果
- 适配横屏显示

## 安全提示

1. **驾驶安全**: 请勿在驾驶时操作应用
2. **传感器权限**: 应用需要加速度传感器权限
3. **HTTPS 要求**: 传感器 API 需要安全上下文

## 更新日志

### v2.2.0 (2024)
- 新增可乐杯物理模拟器
- 新增行程回放功能
- 新增 Web 传感器支持
- 移除 Arena 页面
- 优化车机显示

## 许可证

MIT License

## 致谢

- Flutter Team
- Riverpod
- 所有贡献者
