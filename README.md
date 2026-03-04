# Cola Cup Physics Simulator

A Flutter Web-based real-time acceleration visualization app that simulates the physics of a cola cup during vehicle motion.

## Features

### Core Features
- **Real-time Cola Cup Simulation**: A 100% full cola cup that dynamically displays liquid tilt and spill effects based on real-time acceleration data
- **Physics Engine**: Calculates spill percentage (0-100%) based on real physics formulas
- **Real-time Data Display**: Shows lateral/longitudinal acceleration, G-force, and spill percentage
- **Sensitivity Adjustment**: Supports 0.1x - 2.0x sensitivity adjustment

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
