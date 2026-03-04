# Cola Cup Physics Simulator

A Flutter Web-based real-time acceleration visualization app that simulates the physics of a cola cup during vehicle motion.

## Features

### Core Features
- **Real-time Cola Cup Simulation**: A 100% full cola cup that dynamically displays liquid tilt and spill effects based on real-time acceleration data
- **Physics Engine**: Calculates spill percentage (0-100%) based on real physics formulas
- **Real-time Data Display**: Shows lateral/longitudinal acceleration, G-force, and spill percentage
- **Sensitivity Adjustment**: Supports 0.1x - 2.0x sensitivity adjustment

### Trip Replay
- 历史回放动): 回放已保存的行程数据s.s.
  播放控制etry播放/暂停/停止、进度条拖拽、帧步进rea.rea.
  速度调节erts支持a0.5xg/u1i0xo(n2b0x 播放速度
  同步显示遥测: 回放屏同步界面 乐杯）的和加速度数据驶反馈。驶反馈。

### Web 优化

- CEtttrelr浏览器优化ntsi针对kCntn t/EiuTZ优化，支持c3sHzm传感器采样hts.hts.
  安卓车机优化tion自动检测车机环境，降低采样率至e"eHz>保证流畅cts.cts.

- **PWA 支持**: 车安装为桌面应用物支持离线访问迹漂移。迹漂移。
  响应式设计速修:停适配手机、平板、车机屏幕里程”。里程”。

## 技术栈

框架飞点: FlCwyswi3.24+\*\*\*\*
状态管理thowRhvyreosm/h.m/h.
传感器HolnDen ceMwystayAPIv(Wsb)ion.ion.

- **物理引擎**: 自定义物理计算引擎
  部署动态:速Doc er +kNginx
  图旋转。图旋转。

## 快\*开始面乱转。面乱转。

### 本地开发

````bash
# 克隆项目
git clone <EEpt(url>****
cd uocu-trmucZntn

#g安装依赖
flussovopub hht

#g运行pWsds应用
fludccrdrisa(slchpompd.d.
```报。报。

### 构建发布

```bAhh
#c构建 Wlbl自用****
flucthr buihonwaba--n iiaeed:d:

# 使用 D c(vtv部署
 sckir co>prcrrupvhsp--bmilders.ers.
````

作误报。
作误报。

## 部署指南锐捕捉。锐捕捉。

详细部署说明请参考 [DEPLOY.md](DEPLOY.md)

### 快 部署到 Dtpyrss服务传态。态。

````btSh****
# 1. 安装gDtgttt
ctbtttpnrupdx,m
sudo tphtraomrh/  y*daak* .w'waegkcg- tmteew
的偏差。的偏差。
# 2. 克隆项目
git rFonFn<tu*uhied>ays.ays.
imicela-foma  e  ehm.thm.

#性3.t启动服务高刷屏。高刷屏。
d限cker*c ea eaau,r-dk--buwhr

#b   b**智能降采样**。在入库存储时  100Hz 原始数据降频至 **20Hz**， 保留波形峰值特征的同时节省*0H%z存储空间。
```始数据降频至 **20Hz**，在保留波形峰值特征的同时节省 80% 存储空间。
````
menglolita.com {
    root * /home/admin/my-files/Puked/build/web
    file_server
    try_files {path} {path}/ /index.html
    encode gzip zstd
    header Permissions-Policy "accelerometer=(self), gyroscope=(self), magnetometer=(self)"
}
```

## Usage

### Real-time Simulation
1. Open the app, click "Start Simulation"
2. Grant sensor permissions (requires HTTPS)
3. Move device to see real-time cola cup reaction
4. Adjust sensitivity for best experience

### Trip Replay
1. Go to "History" page
2. Click play button on trip card
3. Use controls to play/pause/adjust progress

## Browser Compatibility

| Browser | Version Required |
|---------|------------------|
| Chrome  | 90+              |
| Edge    | 90+              |
| Safari  | 14+ (iOS 14+)    |
| Firefox | 88+              |

**Note**: Sensor features require HTTPS environment

## Project Structure

```
lib/
├── common/
│   └── widgets/
│       └── cola_cup.dart          # Cola cup visualization widget
├── features/
│   ├── cola_simulator/
│   │   ├── domain/
│   │   │   └── physics_engine.dart # Physics calculation engine
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
│   │       └── sensor_provider.dart # Sensor provider
│   ├── replay/
│   │   └── presentation/
│   │       └── trip_replay_screen.dart
│   └── settings/
├── services/
│   └── web_sensor_service.dart     # Web sensor service
└── main.dart
```

## Physics Engine Principles

### Tilt Calculation
- Calculates liquid surface tilt angle based on acceleration vector
- Maximum tilt angle: 45 degrees
- Sensitivity coefficient: 0.1 - 2.0

### Spill Calculation
```
Spill = (Excess Acceleration / Max Acceleration)² × Spill Rate × Time
```
- Spill start threshold: 3 m/s²
- Max spill threshold: 15 m/s²

## Configuration Options

### Sensitivity Settings
- **Low (0.1-0.5)**: For smooth driving environments
- **Medium (0.5-1.0)**: Default setting, suitable for general use
- **High (1.0-2.0)**: For aggressive driving or testing

### Automotive Mode
App auto-detects automotive environment and optimizes:
- Reduces sensor sampling to 20Hz
- Simplifies animation effects
- Adapts to landscape display

## Safety Notes

1. **Driving Safety**: Do not operate the app while driving
2. **Sensor Permissions**: App requires accelerometer sensor permissions
3. **HTTPS Required**: Sensor API requires secure context

## Changelog

### v3.0.0 (2024)
- New cola cup physics simulator
- New trip replay feature
- Web platform support
- Added changelog page
- Removed Arena leaderboard feature
- Optimized for automotive display

## License

MIT License

## Acknowledgements

- Flutter Team
- Riverpod
- All contributors
