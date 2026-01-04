import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:puked/features/recording/domain/sensor_engine.dart';
import 'package:puked/models/db_models.dart';
import 'package:puked/models/sensor_data.dart';
import 'package:puked/models/trip_event.dart';
import 'package:puked/services/storage/storage_service.dart';
import 'package:puked/features/settings/providers/settings_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:latlong2/latlong.dart'; // 用于计算距离
import 'dart:async';
import 'dart:collection';

// 🟢 1. 引入 GPS 惯性算法文件
import 'package:puked/common/utils/gps_kalman_filter.dart';

// 传感器引擎 Provider
final sensorEngineProvider = Provider<SensorEngine>((ref) {
  final engine = SensorEngine();
  ref.onDispose(() => engine.dispose());
  return engine;
});

// 实时传感器流
final sensorStreamProvider = StreamProvider<SensorData>((ref) {
  final engine = ref.watch(sensorEngineProvider);
  engine.start();
  return engine.sensorStream;
});

enum AlgorithmMode {
  standard, 
  expert 
}

class RecordingState {
  final bool isRecording;
  final bool isCalibrating;
  final Trip? currentTrip;
  final List<RecordedEvent> events;
  final List<TrajectoryPoint> trajectory;
  final double currentDistance;
  final double maxGForce;
  final double currentGForce;
  final Position? currentPosition;
  final DateTime? lastLocationTime;
  final int locationUpdateCount;
  final String debugMessage;
  final LocationPermission? permissionStatus;
  final bool isLowConfidenceGPS;
  final AlgorithmMode algorithmMode;
  final bool isSensorFrozen;
  
  // 🟢 新增：GPS 精度 (用于 UI 显示)
  final double gpsAccuracy;

  RecordingState({
    required this.isRecording,
    this.isCalibrating = false,
    this.currentTrip,
    this.events = const [],
    this.trajectory = const [],
    this.currentDistance = 0.0,
    this.maxGForce = 0.0,
    this.currentGForce = 0.0,
    this.currentPosition,
    this.lastLocationTime,
    this.locationUpdateCount = 0,
    this.debugMessage = '',
    this.permissionStatus,
    this.isLowConfidenceGPS = false,
    this.algorithmMode = AlgorithmMode.expert, 
    this.isSensorFrozen = false,
    this.gpsAccuracy = 0.0,
  });

  RecordingState copyWith({
    bool? isRecording,
    bool? isCalibrating,
    Trip? currentTrip,
    List<RecordedEvent>? events,
    List<TrajectoryPoint>? trajectory,
    double? currentDistance,
    double? maxGForce,
    double? currentGForce,
    Position? currentPosition,
    DateTime? lastLocationTime,
    int? locationUpdateCount,
    String? debugMessage,
    LocationPermission? permissionStatus,
    bool? isLowConfidenceGPS,
    AlgorithmMode? algorithmMode,
    bool? isSensorFrozen,
    double? gpsAccuracy,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      currentTrip: currentTrip ?? this.currentTrip,
      events: events ?? this.events,
      trajectory: trajectory ?? this.trajectory,
      currentDistance: currentDistance ?? this.currentDistance,
      maxGForce: maxGForce ?? this.maxGForce,
      currentGForce: currentGForce ?? this.currentGForce,
      currentPosition: currentPosition ?? this.currentPosition,
      lastLocationTime: lastLocationTime ?? this.lastLocationTime,
      locationUpdateCount: locationUpdateCount ?? this.locationUpdateCount,
      debugMessage: debugMessage ?? this.debugMessage,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      isLowConfidenceGPS: isLowConfidenceGPS ?? this.isLowConfidenceGPS,
      algorithmMode: algorithmMode ?? this.algorithmMode,
      isSensorFrozen: isSensorFrozen ?? this.isSensorFrozen,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
    );
  }
}

class RecordingNotifier extends StateNotifier<RecordingState>
    with WidgetsBindingObserver {
  final SensorEngine _engine;
  final StorageService _storage;
  final Ref _ref;
  StreamSubscription<Position>? _positionSub;
  ProviderSubscription<AsyncValue<SensorData>>? _sensorSub;

  // 🟢 2. 实例化终极惯性滤波器
  final _navFilter = GpsInertialFilter();

  // 事件检测阈值
  static const double _thresholdAccel = 3.14; 
  static const double _thresholdDecel = -3.14; 
  static const double _thresholdWobbleSpan = 1.8; 
  static const double _thresholdBump = 2.5; 
  static const double _thresholdJerk = 6.0; 

  static const Duration _startProtectionDuration = Duration(seconds: 5);
  static const Duration _wobbleWindow = Duration(milliseconds: 1000);
  static const Duration _jerkWindow = Duration(milliseconds: 300); 
  DateTime? _recordingStartTime;

  final ListQueue<MapEntry<DateTime, double>> _xHistory = ListQueue();
  final ListQueue<MapEntry<DateTime, double>> _yHistory = ListQueue();
  final ListQueue<MapEntry<DateTime, double>> _yawRateHistory = ListQueue();
  final ListQueue<double> _realtimeGHistory = ListQueue();

  final Map<String, DateTime> _lastTriggered = {};
  static const Duration _debounceDuration = Duration(seconds: 2);

  final List<_PendingEvent> _pendingEvents = [];
  Timer? _fusionTimer;
  static const Duration _fusionWindow = Duration(milliseconds: 3000);

  RecordingNotifier(this._engine, this._storage, this._ref)
      : super(RecordingState(isRecording: false)) {
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => _initializeLocation());
    _engine.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.isRecording) {
      debugPrint('App resumed, re-enabling Wakelock');
      WakelockPlus.enable();
    }
  }

  Future<void> _initializeLocation() async {
    try {
      state = state.copyWith(debugMessage: 'Checking Permission...');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      state = state.copyWith(permissionStatus: permission);

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        state = state.copyWith(debugMessage: 'Getting Initial Position...');

        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          state = state.copyWith(
              currentPosition: lastKnown, debugMessage: 'Initial GPS OK');
        }

        _positionSub?.cancel();

        late LocationSettings locationSettings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 1), // 1秒一次，配合惯性算法
            forceLocationManager: true, 
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationText: "Puked 正在记录行程中",
              notificationTitle: "实时记录中",
              enableWakeLock: true,
            ),
          );
        } else {
          locationSettings = AppleSettings(
            // 🟢 iOS 优化：开启导航级精度 (L1+L5)
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 0, 
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
            activityType: ActivityType.automotiveNavigation,
          );
        }

        _positionSub =
            Geolocator.getPositionStream(locationSettings: locationSettings)
                .listen(
          (position) {
            _handlePositionUpdate(position);
          },
          onError: (error) {
            state = state.copyWith(debugMessage: 'Stream Error: $error');
          },
        );

        Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        ).then((pos) {
          if (state.locationUpdateCount == 0) _handlePositionUpdate(pos);
        }).catchError((_) {});
      }
    } catch (e) {
      state = state.copyWith(debugMessage: 'Init Error: $e');
    }
  }

  // 🟢 核心：位置更新与融合算法
  void _handlePositionUpdate(Position position) {
    final now = DateTime.now();
    final timestamp = position.timestamp?.millisecondsSinceEpoch ?? now.millisecondsSinceEpoch;

    // 1. 调用惯性滤波器 (GpsInertialFilter)
    final fixedCoords = _navFilter.process(
      lat: position.latitude,
      lng: position.longitude,
      accuracy: position.accuracy,
      // 保护性处理，部分情况速度可能为负
      speed: position.speed < 0 ? 0 : position.speed,
      heading: position.heading < 0 ? 0 : position.heading,
      timestamp: timestamp,
      speedAccuracy: position.speedAccuracy, 
      headingAccuracy: position.headingAccuracy,
    );

    // 2. 获取平滑后的坐标
    final double smoothLat = fixedCoords[0];
    final double smoothLng = fixedCoords[1];

    // 🟢 修复3：速度死区 (防止静止时数字乱跳)
    double displaySpeed = position.speed;
    if (displaySpeed < 0.8) { // 2.88 km/h 以下显示为 0
      displaySpeed = 0.0;
    }

    final bool isReliable = position.accuracy <= 50.0;
    // 只要精度 > 40m，视为弱信号
    final bool isLowConfidence = position.accuracy > 40.0;

    // 构造修正后的 Position 对象用于 UI 和逻辑
    final smoothPosition = Position(
      latitude: smoothLat,
      longitude: smoothLng,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: displaySpeed, // 使用过滤后的速度
      speedAccuracy: position.speedAccuracy,
      altitudeAccuracy: position.altitudeAccuracy,
      headingAccuracy: position.headingAccuracy,
    );

    // 更新 State
    state = state.copyWith(
      currentPosition: smoothPosition, // UI 使用平滑后的位置
      lastLocationTime: now,
      locationUpdateCount: state.locationUpdateCount + 1,
      isLowConfidenceGPS: isLowConfidence,
      gpsAccuracy: position.accuracy, // 记录原始精度用于 UI
      debugMessage: isReliable
          ? 'GPS OK (±${position.accuracy.toStringAsFixed(0)}m)'
          : 'Poor Signal (±${position.accuracy.toStringAsFixed(0)}m)',
    );

    // 3. 记录轨迹逻辑 (基于平滑坐标)
    if (state.isRecording && state.currentTrip != null && isReliable) {
      if (position.accuracy > 200) return; // 飞点过滤保底

      double distanceDelta = 0;
      if (state.trajectory.isNotEmpty) {
        final lastPoint = state.trajectory.last;
        // 使用 Distance 库计算平滑后的两点距离
        distanceDelta = const Distance().as(
          LengthUnit.Meter,
          LatLng(lastPoint.lat, lastPoint.lng),
          LatLng(smoothLat, smoothLng)
        );
        // 过滤极小漂移 (<0.5m 不计里程)
        if (distanceDelta < 0.5) distanceDelta = 0;
      }

      final point = TrajectoryPoint()
        ..lat = smoothLat // 存入平滑坐标
        ..lng = smoothLng // 存入平滑坐标
        ..altitude = position.altitude
        ..speed = displaySpeed // 存入过滤后的速度
        ..timestamp = now
        ..isLowConfidence = isLowConfidence;

      final newDistance = state.currentDistance + distanceDelta;
      
      _storage.addTrajectoryPoint(state.currentTrip!.id, point,
          distance: newDistance);
      
      state = state.copyWith(
        trajectory: [...state.trajectory, point],
        currentDistance: newDistance,
      );
    }
  }

  void _detectAutoEvents(SensorData data) {
    // ... (传感器检测逻辑，完全保持原样)
    final now = DateTime.now();
    if (state.isCalibrating) return;
    if (_recordingStartTime != null &&
        now.difference(_recordingStartTime!) < _startProtectionDuration) {
      return;
    }

    final accel = data.filteredAccel;
    final gyro = data.processedGyro;

    _xHistory.addLast(MapEntry(now, accel.x));
    _yHistory.addLast(MapEntry(now, accel.y));
    _yawRateHistory.addLast(MapEntry(now, gyro.z));

    while (_xHistory.isNotEmpty &&
        now.difference(_xHistory.first.key) > _wobbleWindow) {
      _xHistory.removeFirst();
    }
    while (_yHistory.isNotEmpty &&
        now.difference(_yHistory.first.key) >
            const Duration(milliseconds: 1500)) {
      _yHistory.removeFirst();
    }
    while (_yawRateHistory.isNotEmpty &&
        now.difference(_yawRateHistory.first.key) > _wobbleWindow) {
      _yawRateHistory.removeFirst();
    }

    final sensitivity = _ref.read(settingsProvider).sensitivity;
    double sensitivityMultiplier = 1.0;
    if (sensitivity == SensitivityLevel.medium) sensitivityMultiplier = 0.8;
    if (sensitivity == SensitivityLevel.high) sensitivityMultiplier = 0.6;

    double speedMultiplier = 1.0;
    final currentSpeedKmh = (state.currentPosition?.speed ?? 0) * 3.6;

    if (currentSpeedKmh < 10.0) {
      speedMultiplier = 0.8;
    } else if (currentSpeedKmh < 60.0) {
      speedMultiplier = 0.8 + 0.2 * ((currentSpeedKmh - 10.0) / 50.0);
    } else if (currentSpeedKmh > 80.0) {
      speedMultiplier = 1.2;
    }

    final finalMultiplier = sensitivityMultiplier * speedMultiplier;

    bool isDebounced(String type) {
      final last = _lastTriggered[type];
      if (last == null) return false;
      return now.difference(last) < _debounceDuration;
    }

    // 检测逻辑
    if (accel.y < (_thresholdDecel * finalMultiplier) &&
        !isDebounced('rapidDeceleration')) {
      _lastTriggered['rapidDeceleration'] = now;
      _enqueueEvent(EventType.rapidDeceleration, now);
    } else if (accel.y > (_thresholdAccel * finalMultiplier) &&
        !isDebounced('rapidAcceleration')) {
      _lastTriggered['rapidAcceleration'] = now;
      _enqueueEvent(EventType.rapidAcceleration, now);
    }

    if (!isDebounced('jerk') && _yHistory.length > 5) {
      final recentY =
          _yHistory.where((e) => now.difference(e.key) < _jerkWindow).toList();
      if (recentY.length >= 3) {
        final deltaA = recentY.last.value - recentY.first.value;
        final deltaT =
            recentY.last.key.difference(recentY.first.key).inMilliseconds /
                1000.0;
        final jerk = deltaA / deltaT;

        if (jerk.abs() >
            (_thresholdJerk * speedMultiplier * sensitivityMultiplier)) {
          _lastTriggered['jerk'] = now;
          _enqueueEvent(EventType.jerk, now);
        }
      }
    }

    if (!isDebounced('jerk') && _yHistory.length > 20) {
      double minAy = 0;
      double maxAfterMin = -999;
      bool foundMin = false;

      for (var entry in _yHistory) {
        if (entry.value < minAy) {
          minAy = entry.value;
          foundMin = true;
          maxAfterMin = -999; 
        }
        if (foundMin && entry.value > maxAfterMin) {
          maxAfterMin = entry.value;
        }
      }

      if (minAy < -1.5 && (maxAfterMin - minAy) > 1.8) {
        if (currentSpeedKmh < 2.0 || accel.y.abs() < 0.2) {
          _lastTriggered['jerk'] = now;
          _enqueueEvent(EventType.jerk, now);
        }
      }
    }

    if (!isDebounced('wobble') && _xHistory.length > 10) {
      double minX = 0;
      double maxX = 0;
      DateTime? minTime;
      DateTime? maxTime;

      for (var entry in _xHistory) {
        if (entry.value < minX) {
          minX = entry.value;
          minTime = entry.key;
        }
        if (entry.value > maxX) {
          maxX = entry.value;
          maxTime = entry.key;
        }
      }

      final span = maxX - minX;
      double totalYawChange = 0;
      if (_yawRateHistory.length > 1) {
        for (int i = 1; i < _yawRateHistory.length; i++) {
          final dt = _yawRateHistory
                  .elementAt(i)
                  .key
                  .difference(_yawRateHistory.elementAt(i - 1).key)
                  .inMilliseconds /
              1000.0;
          totalYawChange += _yawRateHistory.elementAt(i).value * dt;
        }
      }

      bool isTurning = totalYawChange.abs() > 0.26;

      if (span > (_thresholdWobbleSpan * sensitivityMultiplier) && !isTurning) {
        if (maxX > 0.4 && minX < -0.4) {
          if (minTime != null && maxTime != null) {
            final jumpDuration = maxTime.difference(minTime).abs();
            if (jumpDuration < const Duration(milliseconds: 800)) {
              _lastTriggered['wobble'] = now;
              _enqueueEvent(EventType.wobble, now);
            }
          }
        }
      }
    }

    if (accel.z.abs() > (_thresholdBump * sensitivityMultiplier) &&
        !isDebounced('bump')) {
      _lastTriggered['bump'] = now;
      _enqueueEvent(EventType.bump, now);
    }
  }

  Future<void> startRecording({String? carModel, String? notes}) async {
    if (state.isCalibrating || state.isRecording) return;

    try {
      state =
          state.copyWith(isCalibrating: true, debugMessage: 'Calibrating...');
      await WakelockPlus.enable();

      await _engine.calibrate();
      
      // 🟢 3. 开始录制前，重置惯性滤波器
      _navFilter.reset();

      state = state.copyWith(debugMessage: 'Initing Storage...');
      await _storage.init();
      final trip = await _storage.startTrip(carModel: carModel, notes: notes);
      _recordingStartTime = DateTime.now();
      _xHistory.clear();
      _yHistory.clear();
      _yawRateHistory.clear();
      _realtimeGHistory.clear();

      List<TrajectoryPoint> initialTrajectory = [];
      if (state.currentPosition != null) {
        // 使用当前位置作为起始点
        final startPoint = TrajectoryPoint()
          ..lat = state.currentPosition!.latitude
          ..lng = state.currentPosition!.longitude
          ..altitude = state.currentPosition!.altitude
          ..speed = state.currentPosition!.speed
          ..timestamp = DateTime.now();
        _storage.addTrajectoryPoint(trip.id, startPoint, distance: 0);
        initialTrajectory.add(startPoint);
      }

      _sensorSub?.close();
      _sensorSub = _ref.listen<AsyncValue<SensorData>>(
        sensorStreamProvider,
        (previous, next) {
          next.whenData((sensorData) {
            if (state.isRecording) {
              final accelForPeak = sensorData.filteredAccel;
              final rawG = accelForPeak.length / 9.80665;

              _realtimeGHistory.addLast(rawG);
              // 100Hz 采样，平滑窗口适当加大到 6
              if (_realtimeGHistory.length > 6) _realtimeGHistory.removeFirst();

              final smoothedG = _realtimeGHistory.reduce((a, b) => a + b) /
                  _realtimeGHistory.length;

              if (smoothedG > state.maxGForce) {
                state = state.copyWith(maxGForce: smoothedG);
              }
              _detectAutoEvents(sensorData);
            }
          });
        },
        fireImmediately: true,
      );

      state = state.copyWith(
        isRecording: true,
        isCalibrating: false,
        currentTrip: trip,
        events: [],
        trajectory: initialTrajectory,
        currentDistance: 0.0,
        maxGForce: 0.0,
        debugMessage: 'Recording Active',
      );
    } catch (e, stack) {
      debugPrint('ERROR startRecording: $e');
      debugPrint(stack.toString());
      state = state.copyWith(
          isRecording: false, isCalibrating: false, debugMessage: 'CRASH: $e');
    }
  }

  Future<void> stopRecording() async {
    if (state.currentTrip != null) {
      await _storage.endTrip(state.currentTrip!.id);
    }
    _sensorSub?.close();
    _sensorSub = null;
    await WakelockPlus.disable();
    state = state.copyWith(
      isRecording: false,
      isCalibrating: false,
      currentTrip: null,
      events: [],
      trajectory: [],
      currentDistance: 0.0,
      maxGForce: 0.0,
      currentPosition: state.currentPosition,
    );
  }

  Future<void> tagEvent(EventType type,
      {String source = 'MANUAL', String? notes}) async {
    if (!state.isRecording || state.currentTrip == null) return;

    final now = DateTime.now();
    // 🟢 适配 100Hz 下采样：存库时降采样到 20Hz 节省空间
    final fragment = _engine.getLookbackBuffer(10, targetHz: 20);

    final event = RecordedEvent()
      ..uuid = const Uuid().v4()
      ..timestamp = now
      ..type = type.name
      ..source = source
      ..notes = notes ?? ""
      ..sensorData = fragment
          .map((d) => SensorPointEmbedded()
            ..ax = d.processedAccel.x
            ..ay = d.processedAccel.y
            ..az = d.processedAccel.z
            ..gx = d.gyroscope.x
            ..gy = d.gyroscope.y
            ..gz = d.gyroscope.z
            ..mx = d.magnetometer.x
            ..my = d.magnetometer.y
            ..mz = d.magnetometer.z
            ..offsetMs = d.timestamp.difference(now).inMilliseconds)
          .toList();

    if (state.currentPosition != null) {
      event.lat = state.currentPosition!.latitude;
      event.lng = state.currentPosition!.longitude;
    }

    await _storage.saveEvent(state.currentTrip!.id, event);
    state = state.copyWith(events: [...state.events, event]);
  }

  // --- 聚合引擎 ---
  void _enqueueEvent(EventType type, DateTime timestamp) {
    if (!state.isRecording) return;

    _pendingEvents.add(_PendingEvent(
      type: type,
      timestamp: timestamp,
      source: 'AUTO',
      position: state.currentPosition,
      speed: state.currentPosition?.speed ?? 0,
    ));

    _fusionTimer ??= Timer(_fusionWindow, _processPendingEvents);
  }

  void _processPendingEvents() {
    _fusionTimer = null;
    if (_pendingEvents.isEmpty) return;

    final priority = {
      EventType.rapidAcceleration: 1,
      EventType.rapidDeceleration: 1,
      EventType.jerk: 2,
      EventType.bump: 3,
      EventType.wobble: 4,
    };

    _pendingEvents.sort(
        (a, b) => (priority[a.type] ?? 99).compareTo(priority[b.type] ?? 99));

    var mainEvent = _pendingEvents.first;
    final speedKmh = mainEvent.speed * 3.6;
    var finalType = mainEvent.type;

    if (finalType == EventType.rapidDeceleration && speedKmh < 5.0) {
      finalType = EventType.jerk;
    }

    tagEvent(finalType, source: mainEvent.source);
    _pendingEvents.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionSub?.cancel();
    _sensorSub?.close();
    super.dispose();
  }
}

final recordingProvider =
    StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  final engine = ref.watch(sensorEngineProvider);
  final storage = ref.watch(storageServiceProvider);
  return RecordingNotifier(engine, storage, ref);
});

class _PendingEvent {
  final EventType type;
  final DateTime timestamp;
  final String source;
  final Position? position;
  final double speed;

  _PendingEvent({
    required this.type,
    required this.timestamp,
    required this.source,
    this.position,
    required this.speed,
  });
}