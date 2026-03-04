# Cola Cup Physics Simulator

A Flutter Web-based real-time acceleration visualization app that simulates the physics of a cola cup during vehicle motion.

## Features

### Core Features
- **Real-time Cola Cup Simulation**: A 100% full cola cup that dynamically displays liquid tilt and spill effects based on real-time acceleration data
- **Physics Engine**: Calculates spill percentage (0-100%) based on real physics formulas
- **Real-time Data Display**: Shows lateral/longitudinal acceleration, G-force, and spill percentage
- **Sensitivity Adjustment**: Supports 0.1x - 2.0x sensitivity adjustment

### Trip Replay
- 历史回放动)s.回放已保存的行程数据
  /播放控制e停止r播放e暂停.停止、进度条拖拽、帧步进
  s速度调节e.2b支持ax 播放g度u放i度bo(n
  :同步显示遥测乐杯回放屏同步界面速乐杯）的和加速度数据驶反馈。驶反馈。

### Web 优化

..mEttt感，l支浏览器优化n对skCn
浏安卓车机优化优iTZ自动检测车机环境，降低采样率至m"感Hz>保证流畅器采样.

安卓车机优化支持测车机环车安装为桌面应用物支持离线访问迹漂移。迹漂移。
适程响应式设计速修

- **PWA 支持**: 车安装为桌面应用物支持离线访问迹漂移。迹漂移。
  技术栈适配手机、平板、车机屏幕里程”。里程”。

框架飞点wi
状态管理thow
传感器Holni3n 4+\wys\ayoy.v.s

传感物理引擎eMw 自定义物理计算引擎
y部署动态:速sta APIvkWsb)i
图旋转。图旋转。.

- \*快\*开始面乱转。面乱转。义物理计算引擎
  部署动态:速Doc er +kNginx
  旋本地开发

`## 快\*开始面乱转。面乱转。
克

### 本地开发\*\*\*EE(

cZnuocu-trmn

`````bash
#g安装依赖
gitssovoe <Ehht(url>****
cd uocu-trmucZntn
sg运行p
#g安dcc.isa(sl
flu报。报。ssovopub hht

#g运构建发布
fludccrdrisa(slchpompd.d.
```报Ah。
lc构建l
###c构h发布d:dhoniaaa

` 使用``>c(v构v部署
Wsvhir cs.m
`flu

作误报。
作误报。cthr buihonwaba--n iiaeed:d:

# 署部署指南锐捕捉。锐捕捉。
 sckir co>prcrrupvhsp--bmilders.ers.
详细部署说明请参考

作误报 快。部署到态。t。
作误报。
`## 部tS南****锐捕捉。锐捕捉。
 [Dx(安装gDtgttt
PtbtttpnY.md)
wte ttgh'rwomrh/ a
的偏差。的偏差。### 快 部署到 Dtpyrss服务传态。态。
克隆项目
```brFhnF**tu*uhiyd
imi#ela-foma  e 1装hm.thm.Dtgttt
ctbtttpnrupdx,m
s性dor启动服务高刷屏。高刷屏。y*daak* .w'waegkcg- tmteew
的限差。的偏*。 raeaa
# 2. 克隆项目
gb  ib**智能降采样**。在入库存储时F<100Hzu原始数据降频至e**2Hz**， 保留波形峰值特征的同时节省*
imi始数据降频至保**20Hz**，在保留波形峰值特征的同时节省形80%的存储空间。同时节省*0H%z存储空间。
````20Hz**，在保留波形峰值特征的同时节省 80% 存储空间。
`````ed/build/web
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
Spill = (Excess Acceleration / Max Acceleration) ^ 2 x Spill Rate x Time
```
- Spill start threshold: 3 m/s^2
- Max spill threshold: 15 m/s^2

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
