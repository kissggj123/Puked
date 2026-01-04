import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path; 

import 'package:puked/common/widgets/g_force_ball.dart';
import 'package:puked/common/widgets/sensor_waveform.dart';
import 'package:puked/common/widgets/trip_map_view.dart';
import 'package:puked/features/history/presentation/history_screen.dart';
import 'package:puked/features/recording/providers/recording_provider.dart';
import 'package:puked/features/settings/presentation/settings_screen.dart';
import 'package:puked/features/recording/presentation/vehicle_info_screen.dart';
import 'package:puked/common/utils/i18n.dart';
import 'package:puked/models/db_models.dart'; 
import 'package:puked/models/trip_event.dart';
import 'package:puked/services/update_service.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  // 默认展开，展示丰富的仪表盘
  bool _isStatsExpanded = true; 
  final MapController _mapController = MapController();
  int _lastEventCount = 0;
  
  // 地图交互控制
  bool _isUserInteracting = false;
  Timer? _interactionTimer;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) UpdateService.checkUpdate(context);
    });
  }
  
  void _onMapInteraction() {
    setState(() => _isUserInteracting = true);
    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isUserInteracting = false);
    });
  }

  // 🟢 优雅的事件提醒弹窗 (HUD Notification)
  void _showEventNotification(BuildContext context, RecordedEvent event) {
    Color color;
    IconData icon;
    String labelKey;

    switch (event.type) {
      case 'rapidAcceleration':
        color = const Color(0xFFFF9500);
        icon = Icons.speed;
        labelKey = 'rapid_accel';
        break;
      case 'rapidDeceleration':
        color = const Color(0xFFFF3B30);
        icon = Icons.trending_down;
        labelKey = 'rapid_decel';
        break;
      case 'bump':
        color = const Color(0xFF5856D6);
        icon = Icons.vibration;
        labelKey = 'bump';
        break;
      case 'wobble':
        color = const Color(0xFF007AFF);
        icon = Icons.waves;
        labelKey = 'wobble';
        break;
      case 'jerk':
        color = const Color(0xFFE91E63);
        icon = Icons.flash_on;
        labelKey = 'jerk';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        labelKey = 'unknown_event';
    }
    
    final i18n = ref.read(i18nProvider);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 70, // 位于顶部栏下方
        left: 0, 
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              builder: (context, val, child) => Transform.scale(
                scale: val,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: color, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          i18n.t(labelKey).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 16,
                            letterSpacing: 1.2
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2500), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingProvider);
    final isCalibrating = recordingState.isCalibrating;
    final i18n = ref.watch(i18nProvider);

    ref.listen(recordingProvider, (prev, next) {
      // 1. 弹窗逻辑 (保持不变)
      if (next.events.length > _lastEventCount) {
        _lastEventCount = next.events.length;
        if (next.isRecording && next.events.isNotEmpty) {
           _showEventNotification(context, next.events.last);
        }
      }
      
      // 🟢 2. 地图强制跟随修复
      if (_isUserInteracting) return; // 如果人手在动，就不自动动

      final pos = next.currentPosition;
      if (pos != null) {
        final speedKmh = pos.speed * 3.6;
        double targetRotation;

        // 旋转逻辑：只有真的跑起来才旋转，否则保持原样
        if (speedKmh > 3.0) {
           targetRotation = -pos.heading;
        } else {
           targetRotation = _mapController.camera.rotation;
        }
        
        // 🟢 强制移动地图中心
        // 之前可能因为速度为0不触发，现在只要有位置更新就触发居中
        _mapController.moveAndRotate(
          LatLng(pos.latitude, pos.longitude),
          17.0, // 锁定缩放，防止被误触改变
          targetRotation 
        );
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, 
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // 🟢 底层全屏地图 (带交互监听)
            Positioned.fill(
              child: Listener(
                onPointerDown: (_) => _onMapInteraction(),
                onPointerMove: (_) => _onMapInteraction(),
                child: TripMapView(
                  trajectory: recordingState.trajectory,
                  events: recordingState.events,
                  currentPosition: recordingState.currentPosition,
                  mapController: _mapController,
                ),
              ),
            ),
            
            // 恢复跟随按钮
            if (_isUserInteracting)
              Positioned(
                bottom: 160,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.gps_fixed, color: Colors.blue),
                  onPressed: () {
                    setState(() => _isUserInteracting = false);
                    _interactionTimer?.cancel();
                  },
                ),
              ),

            // 交互层
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, i18n, recordingState),
                  
                  // Pro 仪表盘
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity), 
                    secondChild: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildProDashboard(context, i18n, recordingState),
                    ),
                    crossFadeState: _isStatsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),

                  const Spacer(),

                  _buildBottomControls(context, ref, recordingState, i18n),
                ],
              ),
            ),

            if (isCalibrating) _buildCalibrationOverlay(context, i18n),
          ],
        ),
      ),
    );
  }

  // 顶部栏
  Widget _buildTopBar(BuildContext context, dynamic i18n, RecordingState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildCircleBtn(Icons.settings_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
              const SizedBox(width: 12),
              _buildCircleBtn(Icons.history_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
              const SizedBox(width: 12),
              _buildCircleBtn(
                _isStatsExpanded ? Icons.dashboard : Icons.dashboard_outlined,
                () => setState(() => _isStatsExpanded = !_isStatsExpanded),
                color: _isStatsExpanded ? Theme.of(context).colorScheme.primary : Colors.white,
                iconColor: _isStatsExpanded ? Colors.white : Colors.black87,
              ),
            ],
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.satellite_alt, 
                  size: 12, 
                  color: state.gpsAccuracy < 5 ? Colors.greenAccent : (state.gpsAccuracy < 15 ? Colors.orange : Colors.red)
                ),
                const SizedBox(width: 6),
                Text(
                  "GPS ±${state.gpsAccuracy.toStringAsFixed(0)}m",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🟢🟢🟢 全能型仪表盘 (Super HUD) 🟢🟢🟢
  Widget _buildProDashboard(BuildContext context, dynamic i18n, RecordingState state) {
    final speedKmh = (state.currentPosition?.speed ?? 0.0) * 3.6;
    final heading = state.currentPosition?.heading ?? 0.0;
    final altitude = state.currentPosition?.altitude ?? 0.0;
    final lat = state.currentPosition?.latitude ?? 0.0;
    final lng = state.currentPosition?.longitude ?? 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          // 增加高度以容纳更多信息
          height: 180, 
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: Row(
            children: [
              // 1. 左侧：G 力球
              SizedBox(
                width: 100,
                child: Consumer(
                  builder: (context, ref, _) {
                    final sensorDataAsync = ref.watch(sensorStreamProvider);
                    return sensorDataAsync.maybeWhen(
                      data: (data) => Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: -heading * (math.pi / 180),
                            child: Container(
                              width: 90, height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 2),
                                gradient: SweepGradient(
                                  colors: [Colors.grey.withValues(alpha: 0.1), Colors.redAccent.withValues(alpha: 0.5), Colors.grey.withValues(alpha: 0.1)],
                                  stops: const [0.0, 0.5, 1.0],
                                  transform: const GradientRotation(-math.pi / 2),
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Container(width: 2, height: 5, color: Colors.redAccent),
                              ),
                            ),
                          ),
                          GForceBall(
                            acceleration: data.processedAccel,
                            gyroscope: data.gyroscope,
                            size: 64,
                          ),
                        ],
                      ),
                      orElse: () => const SizedBox(),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 2. 中间：数据列 (速度/海拔/经纬度)
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 速度 (SPEED)
                    _buildDigitalStat(i18n.t('speed_label'), speedKmh.toStringAsFixed(0), "km/h", fontSize: 28),
                    const SizedBox(height: 8),
                    // G 值
                    Consumer(
                      builder: (context, ref, _) {
                        final sensorData = ref.watch(sensorStreamProvider).valueOrNull;
                        double gX = 0.0, gY = 0.0, gZ = 0.0;
                        if (sensorData != null) {
                          gX = sensorData.processedAccel.x / 9.80665;
                          gY = sensorData.processedAccel.y / 9.80665;
                          gZ = (sensorData.processedAccel.z / 9.80665) - 1.0;
                        }
                        return Column(
                          children: [
                            _buildCompactGRow(i18n.t('g_long'), gY, const Color(0xFFE57373)),
                            const SizedBox(height: 4),
                            _buildCompactGRow(i18n.t('g_lat'), gX, const Color(0xFF64B5F6)),
                            const SizedBox(height: 4),
                            _buildCompactGRow(i18n.t('g_vert'), gZ, const Color(0xFF81C784)),
                          ],
                        );
                      }
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 3. 右侧：波形 + 地理信息
              Expanded(
                flex: 3,
                child: Consumer(
                  builder: (context, ref, _) {
                     final sensorData = ref.watch(sensorStreamProvider).valueOrNull;
                     if (sensorData == null) return const SizedBox();
                     
                     return Column(
                       children: [
                         // 波形图
                         Expanded(child: _ProTelemetryChart(data: sensorData, i18n: i18n)),
                         const SizedBox(height: 8),
                         // 底部地理信息
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             _buildDigitalStat(i18n.t('altitude_label'), altitude.toStringAsFixed(0), "m", fontSize: 14),
                             const SizedBox(width: 12),
                             _buildDigitalStat(i18n.t('heading_label'), "${heading.toStringAsFixed(0)}°", "", fontSize: 14),
                           ],
                         ),
                         const SizedBox(height: 2),
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             _buildMiniCoord(i18n.t('latitude_short'), lat),
                             _buildMiniCoord(i18n.t('longitude_short'), lng),
                           ],
                         ),
                       ],
                     );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 辅助方法: 迷你坐标显示
  Widget _buildMiniCoord(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label ", style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text(
          value.toStringAsFixed(4), // 4位小数精度
          style: const TextStyle(fontSize: 9, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }

  // 🟢 辅助方法: 紧凑型 G 值进度条
  Widget _buildCompactGRow(String label, double value, Color color) {
    final displayValue = value.abs() < 0.02 ? 0.0 : value;
    final progress = (displayValue.abs() / 1.0).clamp(0.0, 1.0);
    
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            "${displayValue >= 0 ? '+' : ''}${displayValue.abs().toStringAsFixed(2)}",
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildDigitalStat(String label, String value, String unit, {double fontSize = 20}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: Colors.black87)),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey)),
            ]
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildBottomControls(BuildContext context, WidgetRef ref,
      RecordingState state, dynamic i18n) {
    final isRecording = state.isRecording;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
          stops: const [0.0, 0.7],
        )
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRecording) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 1. 里程
                      _SimpleStat(icon: Icons.straighten, value: "${(state.currentDistance / 1000).toStringAsFixed(2)} km"),
                      
                      Container(width: 1, height: 12, color: Colors.white24),
                      
                      // 🟢 2. 峰值 G (Max G)
                      _SimpleStat(icon: Icons.flag, value: "MAX ${state.maxGForce.toStringAsFixed(2)}G"),
                      
                      Container(width: 1, height: 12, color: Colors.white24),

                      // 🟢 3. 实时 G (Real-time G)
                      Consumer(
                        builder: (context, ref, _) {
                          final sensorAsync = ref.watch(sensorStreamProvider);
                          return sensorAsync.maybeWhen(
                            data: (data) {
                              final gx = data.processedAccel.x / 9.80665;
                              final gy = data.processedAccel.y / 9.80665;
                              final totalG = math.sqrt(gx * gx + gy * gy);
                              
                              Color valueColor = Colors.white;
                              if (totalG > 0.5) valueColor = const Color(0xFFFF9500);
                              if (totalG > 0.8) valueColor = const Color(0xFFFF3B30);

                              return Row(
                                children: [
                                  Icon(Icons.shutter_speed, color: valueColor, size: 14),
                                  const SizedBox(width: 6),
                                  Text("${totalG.toStringAsFixed(2)}G", 
                                    style: TextStyle(color: valueColor, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'monospace')),
                                ],
                              );
                            },
                            orElse: () => _SimpleStat(icon: Icons.shutter_speed, value: "0.00 G"),
                          );
                        }
                      ),
                      
                      Container(width: 1, height: 12, color: Colors.white24),
                      
                      // 4. 事件数
                      _SimpleStat(icon: Icons.error_outline, value: "${state.events.length}"),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 40, 
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  SizedBox(width: MediaQuery.of(context).size.width * 0.5 - 170),
                  _MinimalTagButton(
                    label: i18n.t('rapid_accel'),
                    color: const Color(0xFFFF9500),
                    onPressed: () => ref.read(recordingProvider.notifier).tagEvent(EventType.rapidAcceleration),
                  ),
                  const SizedBox(width: 8),
                  _MinimalTagButton(
                    label: i18n.t('rapid_decel'),
                    color: const Color(0xFFFF3B30),
                    onPressed: () => ref.read(recordingProvider.notifier).tagEvent(EventType.rapidDeceleration),
                  ),
                  const SizedBox(width: 8),
                  _MinimalTagButton(
                    label: i18n.t('bump'),
                    color: const Color(0xFF5856D6),
                    onPressed: () => ref.read(recordingProvider.notifier).tagEvent(EventType.bump),
                  ),
                  const SizedBox(width: 8),
                  _MinimalTagButton(
                    label: i18n.t('wobble'),
                    color: const Color(0xFF007AFF),
                    onPressed: () => ref.read(recordingProvider.notifier).tagEvent(EventType.wobble),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildMainActionButton(context, ref, state, i18n),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(BuildContext context, WidgetRef ref,
      RecordingState state, dynamic i18n) {
    final isRecording = state.isRecording;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isRecording ? const Color(0xFFFF3B30) : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: (isRecording ? Colors.red : Theme.of(context).colorScheme.primary).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
        onPressed: state.isCalibrating ? null : () async {
          if (isRecording) {
            final tripId = state.currentTrip?.id;
            await ref.read(recordingProvider.notifier).stopRecording();
            if (tripId != null && context.mounted) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleInfoScreen(tripId: tripId)));
            }
          } else {
            ref.read(recordingProvider.notifier).startRecording();
          }
        },
        child: state.isCalibrating 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Text(
              isRecording ? i18n.t('stop_trip').toUpperCase() : i18n.t('start_trip').toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap, {Color? color, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 22, color: iconColor ?? Colors.black87),
      ),
    );
  }

  Widget _buildCalibrationOverlay(BuildContext context, dynamic i18n) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Text(i18n.t('calibrating'), style: const TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class _MinimalTagButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _MinimalTagButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _SimpleStat({required this.icon, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace')),
      ],
    );
  }
}

class _ProTelemetryChart extends StatefulWidget {
  final dynamic data;
  final dynamic i18n;
  const _ProTelemetryChart({required this.data, required this.i18n});

  @override
  State<_ProTelemetryChart> createState() => _ProTelemetryChartState();
}

class _ProTelemetryChartState extends State<_ProTelemetryChart> {
  final int _windowSize = 300; 
  final ListQueue<double> _yAxis = ListQueue(); 
  final ListQueue<double> _xAxis = ListQueue();

  @override
  void didUpdateWidget(_ProTelemetryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_yAxis.length >= _windowSize) _yAxis.removeFirst();
    if (_xAxis.length >= _windowSize) _xAxis.removeFirst();
    if (widget.data != null) {
      _yAxis.add(widget.data.processedAccel.y / 9.80665);
      _xAxis.add(widget.data.processedAccel.x / 9.80665);
    } else {
      _yAxis.add(0.0);
      _xAxis.add(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<FlSpot> ySpots = [];
    List<FlSpot> xSpots = [];
    int index = 0;
    for (var val in _yAxis) {
      ySpots.add(FlSpot(index.toDouble(), val));
      index++;
    }
    index = 0;
    for (var val in _xAxis) {
      xSpots.add(FlSpot(index.toDouble(), val));
      index++;
    }

    return Column(
      children: [
        Expanded(child: _buildChartRow(ySpots, const Color(0xFFE57373), widget.i18n.t('longitudinal'))),
        const SizedBox(height: 8),
        Expanded(child: _buildChartRow(xSpots, const Color(0xFF64B5F6), widget.i18n.t('lateral'))),
      ],
    );
  }

  Widget _buildChartRow(List<FlSpot> spots, Color color, String label) {
    return Stack(
      children: [
        LineChart(
          LineChartData(
            minY: -1.0, maxY: 1.0, 
            minX: 0, maxX: _windowSize.toDouble(),
            gridData: FlGridData(show: false), 
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 0, right: 0,
          child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}