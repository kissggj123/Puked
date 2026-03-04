
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puked/common/widgets/cola_cup.dart';
import 'package:puked/features/cola_simulator/providers/cola_simulator_provider.dart';

/// 可乐杯模拟器主页面
class ColaSimulatorScreen extends ConsumerWidget {
  const ColaSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(colaSimulatorProvider);
    final notifier = ref.read(colaSimulatorProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部状态栏
            _buildStatusBar(context, state),

            // 主要内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 可乐杯可视化
                    _buildColaCupSection(context, state),

                    const SizedBox(height: 30),

                    // 实时数据显示
                    _buildDataDisplay(context, state),

                    const SizedBox(height: 30),

                    // 灵敏度调节
                    _buildSensitivityControl(context, state, notifier),
                  ],
                ),
              ),
            ),

            // 底部控制按钮
            _buildControlButtons(context, state, notifier),
          ],
        ),
      ),
    );
  }

  /// 构建顶部状态栏
  Widget _buildStatusBar(BuildContext context, ColaSimulatorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '可乐杯模拟器',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.isRunning ? '模拟进行中' : '准备就绪',
                style: TextStyle(
                  color: state.isRunning ? Colors.green : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // 状态指示器
          Row(
            children: [
              // 权限状态
              _buildStatusIndicator(
                '传感器',
                state.hasPermission,
                Icons.sensors,
              ),
              const SizedBox(width: 12),
              // 校准状态
              _buildStatusIndicator(
                '校准',
                state.isCalibrated,
                Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(String label, bool isActive, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green : Colors.white30,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? Colors.green : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.green : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可乐杯区域
  Widget _buildColaCupSection(BuildContext context, ColaSimulatorState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 撒出百分比大数字
          Text(
            '${(state.spillPercentage * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: _getSpillColor(state.spillPercentage),
              fontSize: 56,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            state.spillDescription,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),

          // 可乐杯可视化
          ColaCup(
            lateralAccel: state.lateralAccel,
            longitudinalAccel: state.longitudinalAccel,
            spillPercentage: state.spillPercentage,
            size: 200,
            showBubbles: true,
          ),
        ],
      ),
    );
  }

  /// 获取撒出量对应的颜色
  Color _getSpillColor(double percentage) {
    if (percentage < 0.3) return Colors.green;
    if (percentage < 0.6) return Colors.orange;
    return Colors.red;
  }

  /// 构建数据显示区域
  Widget _buildDataDisplay(BuildContext context, ColaSimulatorState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 加速度数据
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAccelDisplay(
                '横向加速度',
                state.lateralAccel,
                Icons.swap_horiz,
                Colors.blue,
              ),
              _buildAccelDisplay(
                '纵向加速度',
                state.longitudinalAccel,
                Icons.swap_vert,
                Colors.purple,
              ),
              _buildAccelDisplay(
                'G 值',
                state.gForce,
                Icons.speed,
                Colors.orange,
                isGForce: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 状态描述
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '当前状态: ${state.accelDescription}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),

          // 运行时间
          if (state.isRunning)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '运行时间: ${_formatDuration(state.elapsedTime)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建加速度显示
  Widget _buildAccelDisplay(
    String label,
    double value,
    IconData icon,
    Color color, {
    bool isGForce = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          isGForce ? value.toStringAsFixed(2) : '${value.toStringAsFixed(2)} m/s²',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// 格式化时间
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((duration.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  /// 构建灵敏度控制
  Widget _buildSensitivityControl(
    BuildContext context,
    ColaSimulatorState state,
    ColaSimulatorNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '灵敏度',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                '${state.sensitivity.toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.green,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.green,
              overlayColor: Colors.green.withOpacity(0.2),
            ),
            child: Slider(
              value: state.sensitivity,
              min: 0.1,
              max: 2.0,
              divisions: 19,
              onChanged: (value) {
                notifier.setSensitivity(value);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('低', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text('中', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text('高', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons(
    BuildContext context,
    ColaSimulatorState state,
    ColaSimulatorNotifier notifier,
  ) {
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
        children: [
          // 重置按钮
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: () {
                notifier.resetSimulation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 开始/停止按钮
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                if (state.isRunning) {
                  notifier.stopSimulation();
                } else {
                  notifier.startSimulation();
                }
              },
              icon: Icon(state.isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(state.isRunning ? '停止' : '开始模拟'),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.isRunning ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
