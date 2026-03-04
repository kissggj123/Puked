
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puked/common/widgets/cola_cup.dart';
import 'package:puked/features/cola_simulator/domain/physics_engine.dart';
import 'package:puked/models/db_models.dart';
import 'package:puked/services/storage/storage_service.dart';

/// 行程回放页面
class TripReplayScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripReplayScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripReplayScreen> createState() => _TripReplayScreenState();
}

class _TripReplayScreenState extends ConsumerState<TripReplayScreen> {
  // 回放状态
  bool _isPlaying = false;
  bool _isLoading = true;
  double _playbackSpeed = 1.0;
  double _progress = 0.0; // 0.0 - 1.0

  // 行程数据
  List<SensorDataPoint> _sensorData = [];
  Trip? _trip;
  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  // 物理引擎
  final ColaPhysicsEngine _physicsEngine = ColaPhysicsEngine();

  // 当前显示状态
  double _lateralAccel = 0.0;
  double _longitudinalAccel = 0.0;
  double _spillPercentage = 0.0;
  double _gForce = 0.0;

  // 定时器
  Timer? _playbackTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTripData();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  /// 加载行程数据
  Future<void> _loadTripData() async {
    setState(() => _isLoading = true);

    try {
      final storage = ref.read(storageServiceProvider);

      // 加载行程信息
      _trip = await storage.getTrip(widget.tripId);

      // 加载传感器数据
      _sensorData = await storage.getTripSensorData(widget.tripId);

      if (_sensorData.isNotEmpty) {
        // 计算总时长
        final firstTimestamp = _sensorData.first.timestamp;
        final lastTimestamp = _sensorData.last.timestamp;
        _totalDuration = lastTimestamp.difference(firstTimestamp);
      }

      setState(() {
        _isLoading = false;
        if (_sensorData.isNotEmpty) {
          _updateDisplay(0);
        }
      });
    } catch (e) {
      debugPrint('Error loading trip data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 更新显示
  void _updateDisplay(int index) {
    if (index < 0 || index >= _sensorData.length) return;

    final data = _sensorData[index];
    _currentIndex = index;

    // 更新加速度值
    _lateralAccel = data.lateralAccel;
    _longitudinalAccel = data.longitudinalAccel;

    // 更新物理引擎
    _physicsEngine.update(_lateralAccel, _longitudinalAccel);
    _spillPercentage = _physicsEngine.spillPercentage;

    // 计算 G 值
    _gForce = _physicsEngine.calculateGForce(_lateralAccel, _longitudinalAccel);

    // 更新进度
    _progress = index / (_sensorData.length - 1);

    // 更新时间位置
    if (_sensorData.isNotEmpty) {
      final firstTimestamp = _sensorData.first.timestamp;
      _currentPosition = data.timestamp.difference(firstTimestamp);
    }

    setState(() {});
  }

  /// 开始/暂停回放
  void _togglePlayback() {
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  /// 开始回放
  void _startPlayback() {
    if (_sensorData.isEmpty) return;

    // 如果已经到结尾，从头开始
    if (_currentIndex >= _sensorData.length - 1) {
      _currentIndex = 0;
      _physicsEngine.reset();
    }

    setState(() => _isPlaying = true);

    // 计算播放间隔 (根据速度)
    // 假设数据是 30Hz，每帧 33ms
    final interval = Duration(
      milliseconds: (33 / _playbackSpeed).round(),
    );

    _playbackTimer = Timer.periodic(interval, (_) {
      if (_currentIndex < _sensorData.length - 1) {
        _currentIndex++;
        _updateDisplay(_currentIndex);
      } else {
        _pausePlayback();
      }
    });
  }

  /// 暂停回放
  void _pausePlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    setState(() => _isPlaying = false);
  }

  /// 停止回放
  void _stopPlayback() {
    _pausePlayback();
    _currentIndex = 0;
    _physicsEngine.reset();
    _updateDisplay(0);
  }

  /// 跳转到指定进度
  void _seekToProgress(double value) {
    _pausePlayback();

    final targetIndex = (value * (_sensorData.length - 1)).round().clamp(
      0,
      _sensorData.length - 1,
    );

    // 重置物理引擎并重新计算到当前位置的撒出量
    _physicsEngine.reset();
    for (int i = 0; i <= targetIndex; i++) {
      final data = _sensorData[i];
      _physicsEngine.update(data.lateralAccel, data.longitudinalAccel);
    }

    _updateDisplay(targetIndex);
  }

  /// 设置播放速度
  void _setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    if (_isPlaying) {
      _pausePlayback();
      _startPlayback();
    }
  }

  /// 步进一帧
  void _stepForward() {
    _pausePlayback();
    if (_currentIndex < _sensorData.length - 1) {
      _currentIndex++;
      _updateDisplay(_currentIndex);
    }
  }

  /// 步退一帧
  void _stepBackward() {
    _pausePlayback();
    if (_currentIndex > 0) {
      _currentIndex--;
      // 重新计算物理状态
      _physicsEngine.reset();
      for (int i = 0; i <= _currentIndex; i++) {
        final data = _sensorData[i];
        _physicsEngine.update(data.lateralAccel, data.longitudinalAccel);
      }
      _updateDisplay(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1a1a2e),
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    if (_sensorData.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('行程回放'),
        ),
        body: const Center(
          child: Text(
            '暂无传感器数据',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_trip?.title ?? '行程回放'),
        actions: [
          // 播放速度选择
          PopupMenuButton<double>(
            initialValue: _playbackSpeed,
            onSelected: _setPlaybackSpeed,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 0.5, child: Text('0.5x')),
              const PopupMenuItem(value: 1.0, child: Text('1.0x')),
              const PopupMenuItem(value: 2.0, child: Text('2.0x')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${_playbackSpeed}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 可乐杯可视化
          Expanded(
            flex: 3,
            child: Center(
              child: ColaCup(
                lateralAccel: _lateralAccel,
                longitudinalAccel: _longitudinalAccel,
                spillPercentage: _spillPercentage,
                size: 180,
                showBubbles: true,
              ),
            ),
          ),

          // 数据显示
          _buildDataDisplay(),

          // 进度条
          _buildProgressBar(),

          // 控制按钮
          _buildControls(),
        ],
      ),
    );
  }

  /// 构建数据显示
  Widget _buildDataDisplay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDataItem('横向', '${_lateralAccel.toStringAsFixed(2)} m/s²', Colors.blue),
              _buildDataItem('纵向', '${_longitudinalAccel.toStringAsFixed(2)} m/s²', Colors.purple),
              _buildDataItem('G值', '${_gForce.toStringAsFixed(2)} G', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          // 撒出百分比
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_drink, color: Colors.brown, size: 20),
              const SizedBox(width: 8),
              Text(
                '撒出: ${(_spillPercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: _spillPercentage > 0.5 ? Colors.orange : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // 时间显示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.green,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.green,
              overlayColor: Colors.green.withOpacity(0.2),
            ),
            child: Slider(
              value: _progress,
              onChanged: (value) {
                setState(() => _progress = value);
              },
              onChangeEnd: _seekToProgress,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 后退一帧
          IconButton(
            onPressed: _stepBackward,
            icon: const Icon(Icons.skip_previous, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // 停止
          IconButton(
            onPressed: _stopPlayback,
            icon: const Icon(Icons.stop, color: Colors.red),
          ),
          const SizedBox(width: 16),

          // 播放/暂停
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _isPlaying ? Colors.orange : Colors.green,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _togglePlayback,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 重置
          IconButton(
            onPressed: () {
              _stopPlayback();
              _physicsEngine.reset();
              _updateDisplay(0);
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // 前进一帧
          IconButton(
            onPressed: _stepForward,
            icon: const Icon(Icons.skip_next, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// 传感器数据点 (简化版)
class SensorDataPoint {
  final DateTime timestamp;
  final double lateralAccel;
  final double longitudinalAccel;
  final double verticalAccel;

  SensorDataPoint({
    required this.timestamp,
    required this.lateralAccel,
    required this.longitudinalAccel,
    required this.verticalAccel,
  });
}
