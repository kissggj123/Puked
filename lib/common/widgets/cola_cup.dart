
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// 可乐杯可视化组件
/// 显示一个装满可乐的杯子，根据加速度数据模拟液体倾斜和撒出效果
class ColaCup extends StatefulWidget {
  /// 横向加速度 (m/s²)
  final double lateralAccel;

  /// 纵向加速度 (m/s²)
  final double longitudinalAccel;

  /// 当前撒出百分比 (0.0 - 1.0)
  final double spillPercentage;

  /// 杯子尺寸
  final double size;

  /// 是否显示气泡动画
  final bool showBubbles;

  const ColaCup({
    super.key,
    required this.lateralAccel,
    required this.longitudinalAccel,
    required this.spillPercentage,
    this.size = 200,
    this.showBubbles = true,
  });

  @override
  State<ColaCup> createState() => _ColaCupState();
}

class _ColaCupState extends State<ColaCup> with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _waveController;

  // 气泡列表
  final List<Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // 初始化气泡
    _initBubbles();
  }

  void _initBubbles() {
    for (int i = 0; i < 15; i++) {
      _bubbles.add(Bubble(
        x: math.Random().nextDouble(),
        y: math.Random().nextDouble(),
        size: 2 + math.Random().nextDouble() * 4,
        speed: 0.5 + math.Random().nextDouble() * 1.5,
        delay: math.Random().nextDouble() * 2,
      ));
    }
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bubbleController, _waveController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size * 1.4),
          painter: ColaCupPainter(
            lateralAccel: widget.lateralAccel,
            longitudinalAccel: widget.longitudinalAccel,
            spillPercentage: widget.spillPercentage,
            bubbles: widget.showBubbles ? _bubbles : [],
            bubbleProgress: _bubbleController.value,
            waveProgress: _waveController.value,
          ),
        );
      },
    );
  }
}

/// 气泡数据类
class Bubble {
  double x; // 0-1 相对位置
  double y; // 0-1 相对位置
  final double size;
  final double speed;
  final double delay;

  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

/// 可乐杯绘制器
class ColaCupPainter extends CustomPainter {
  final double lateralAccel;
  final double longitudinalAccel;
  final double spillPercentage;
  final List<Bubble> bubbles;
  final double bubbleProgress;
  final double waveProgress;

  ColaCupPainter({
    required this.lateralAccel,
    required this.longitudinalAccel,
    required this.spillPercentage,
    required this.bubbles,
    required this.bubbleProgress,
    required this.waveProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cupWidth = size.width * 0.7;
    final cupHeight = size.height * 0.75;
    final cupLeft = (size.width - cupWidth) / 2;
    final cupTop = size.height * 0.15;

    // 计算倾斜角度
    final tiltAngle = _calculateTiltAngle();

    // 绘制杯子阴影
    _drawShadow(canvas, cupLeft, cupTop, cupWidth, cupHeight);

    // 绘制杯子主体
    _drawCupBody(canvas, cupLeft, cupTop, cupWidth, cupHeight);

    // 绘制可乐液体
    _drawColaLiquid(canvas, cupLeft, cupTop, cupWidth, cupHeight, tiltAngle);

    // 绘制气泡
    if (bubbles.isNotEmpty) {
      _drawBubbles(canvas, cupLeft, cupTop, cupWidth, cupHeight, tiltAngle);
    }

    // 绘制杯子边缘高光
    _drawCupHighlight(canvas, cupLeft, cupTop, cupWidth, cupHeight);

    // 绘制撒出的液体
    if (spillPercentage > 0) {
      _drawSpilledLiquid(canvas, cupLeft, cupTop, cupWidth, cupHeight, tiltAngle);
    }
  }

  /// 计算倾斜角度
  double _calculateTiltAngle() {
    // 根据加速度计算倾斜角度
    // 最大倾斜角度限制在 45 度
    const maxTilt = math.pi / 4;
    const sensitivity = 0.1; // 灵敏度系数

    // 合成加速度方向
    final accelMagnitude = math.sqrt(
      lateralAccel * lateralAccel + longitudinalAccel * longitudinalAccel,
    );

    // 计算倾斜角度
    double tilt = (accelMagnitude * sensitivity).clamp(0.0, maxTilt);

    // 根据加速度方向确定倾斜方向
    final tiltDirection = math.atan2(lateralAccel, longitudinalAccel);

    return tiltDirection;
  }

  /// 绘制阴影
  void _drawShadow(Canvas canvas, double left, double top, double width, double height) {
    final shadowPath = Path()
      ..moveTo(left + width * 0.1, top + height)
      ..lineTo(left + width * 0.9, top + height)
      ..lineTo(left + width, top + height + 10)
      ..lineTo(left, top + height + 10)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(shadowPath, shadowPaint);
  }

  /// 绘制杯子主体
  void _drawCupBody(Canvas canvas, double left, double top, double width, double height) {
    // 杯子路径 - 梯形
    final cupPath = Path()
      ..moveTo(left + width * 0.1, top)
      ..lineTo(left + width * 0.9, top)
      ..lineTo(left + width, top + height)
      ..lineTo(left, top + height)
      ..close();

    // 杯子渐变 - 透明玻璃效果
    final cupPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(left, top, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(cupPath, cupPaint);

    // 杯子边框
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(cupPath, borderPaint);

    // 杯口椭圆
    final rimRect = Rect.fromLTWH(left + width * 0.1, top - 5, width * 0.8, 10);
    final rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawOval(rimRect, rimPaint);
  }

  /// 绘制可乐液体
  void _drawColaLiquid(Canvas canvas, double left, double top, double width, double height, double tiltAngle) {
    // 计算液面高度 (根据撒出百分比)
    final fillLevel = 1.0 - spillPercentage.clamp(0.0, 1.0);
    final liquidHeight = height * 0.85 * fillLevel;

    // 液体底部 Y 坐标
    final liquidBottom = top + height - 5;
    final liquidTop = liquidBottom - liquidHeight;

    // 保存画布状态
    canvas.save();

    // 移动到杯口中心并旋转
    final centerX = left + width / 2;
    final centerY = liquidTop;
    canvas.translate(centerX, centerY);
    canvas.rotate(tiltAngle);
    canvas.translate(-centerX, -centerY);

    // 液体路径
    final liquidPath = Path();

    // 液面波浪效果
    final waveAmplitude = 3.0;
    final waveFrequency = 0.02;

    liquidPath.moveTo(left + width * 0.15, liquidTop);

    // 绘制波浪液面
    for (double x = left + width * 0.15; x <= left + width * 0.85; x += 2) {
      final waveY = liquidTop + math.sin((x * waveFrequency) + (waveProgress * math.pi * 2)) * waveAmplitude;
      liquidPath.lineTo(x, waveY);
    }

    liquidPath.lineTo(left + width * 0.95, liquidBottom);
    liquidPath.lineTo(left + width * 0.05, liquidBottom);
    liquidPath.close();

    // 可乐颜色渐变 - 深褐色到黑色
    final colaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3D2817).withOpacity(0.9), // 浅褐色
          const Color(0xFF1A0F08).withOpacity(0.95), // 深褐色
          const Color(0xFF0D0704), // 近黑色
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(left, liquidTop, width, liquidHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(liquidPath, colaPaint);

    // 液面高光
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final highlightPath = Path();
    highlightPath.moveTo(left + width * 0.2, liquidTop + 5);
    highlightPath.lineTo(left + width * 0.4, liquidTop + 5);
    highlightPath.lineTo(left + width * 0.35, liquidTop + 15);
    highlightPath.lineTo(left + width * 0.25, liquidTop + 15);
    highlightPath.close();

    canvas.drawPath(highlightPath, highlightPaint);

    canvas.restore();
  }

  /// 绘制气泡
  void _drawBubbles(Canvas canvas, double left, double top, double width, double height, double tiltAngle) {
    final liquidHeight = height * 0.85 * (1.0 - spillPercentage.clamp(0.0, 1.0));
    final liquidBottom = top + height - 5;
    final liquidTop = liquidBottom - liquidHeight;

    final bubbleAreaLeft = left + width * 0.15;
    final bubbleAreaWidth = width * 0.7;
    final bubbleAreaHeight = liquidHeight * 0.9;

    for (final bubble in bubbles) {
      // 计算气泡位置 (考虑动画)
      var bubbleY = bubble.y + (bubbleProgress * bubble.speed) % 1.0;
      if (bubbleY > 1) bubbleY -= 1;

      // 气泡从底部上升到液面
      final actualY = liquidBottom - (bubbleY * bubbleAreaHeight);
      final actualX = bubbleAreaLeft + (bubble.x * bubbleAreaWidth);

      // 检查气泡是否在液面以下
      if (actualY < liquidTop + 10) continue;

      // 绘制气泡
      final bubblePaint = Paint()
        ..color = Colors.white.withOpacity(0.3 + bubbleY * 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(actualX, actualY),
        bubble.size,
        bubblePaint,
      );

      // 气泡高光
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(actualX - bubble.size * 0.3, actualY - bubble.size * 0.3),
        bubble.size * 0.3,
        highlightPaint,
      );
    }
  }

  /// 绘制杯子高光
  void _drawCupHighlight(Canvas canvas, double left, double top, double width, double height) {
    // 左侧高光
    final leftHighlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(left, top, width * 0.2, height))
      ..style = PaintingStyle.fill;

    final leftHighlightPath = Path()
      ..moveTo(left + 5, top + height * 0.1)
      ..lineTo(left + width * 0.15, top + height * 0.05)
      ..lineTo(left + width * 0.1, top + height * 0.9)
      ..lineTo(left + 3, top + height * 0.85)
      ..close();

    canvas.drawPath(leftHighlightPath, leftHighlightPaint);

    // 右侧高光
    final rightHighlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(left + width * 0.8, top, width * 0.2, height))
      ..style = PaintingStyle.fill;

    final rightHighlightPath = Path()
      ..moveTo(left + width - 5, top + height * 0.1)
      ..lineTo(left + width * 0.85, top + height * 0.05)
      ..lineTo(left + width * 0.9, top + height * 0.9)
      ..lineTo(left + width - 3, top + height * 0.85)
      ..close();

    canvas.drawPath(rightHighlightPath, rightHighlightPaint);
  }

  /// 绘制撒出的液体
  void _drawSpilledLiquid(Canvas canvas, double left, double top, double width, double height, double tiltAngle) {
    final spillAmount = spillPercentage.clamp(0.0, 1.0);
    if (spillAmount <= 0) return;

    // 撒出液体的位置 (根据倾斜方向)
    final spillDistance = spillAmount * width * 0.5;
    final spillX = left + width / 2 + math.cos(tiltAngle) * spillDistance;
    final spillY = top + height + 10;

    // 绘制液滴
    final dropPaint = Paint()
      ..color = const Color(0xFF3D2817).withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // 主液滴
    canvas.drawCircle(
      Offset(spillX, spillY),
      8 + spillAmount * 12,
      dropPaint,
    );

    // 小液滴
    for (int i = 0; i < 3; i++) {
      final offsetX = math.cos(tiltAngle + i * 0.5) * (15 + i * 10) * spillAmount;
      final offsetY = math.sin(i * 0.5) * 5;

      canvas.drawCircle(
        Offset(spillX + offsetX, spillY + offsetY),
        3 + spillAmount * 5,
        dropPaint,
      );
    }

    // 液体飞溅效果
    if (spillAmount > 0.3) {
      final splashPaint = Paint()
        ..color = const Color(0xFF3D2817).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (int i = 0; i < 5; i++) {
        final angle = tiltAngle + (i - 2) * 0.3;
        final length = 10 + spillAmount * 20;

        canvas.drawLine(
          Offset(spillX, spillY),
          Offset(
            spillX + math.cos(angle) * length,
            spillY + math.sin(angle) * length,
          ),
          splashPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant ColaCupPainter oldDelegate) {
    return oldDelegate.lateralAccel != lateralAccel ||
        oldDelegate.longitudinalAccel != longitudinalAccel ||
        oldDelegate.spillPercentage != spillPercentage ||
        oldDelegate.bubbleProgress != bubbleProgress ||
        oldDelegate.waveProgress != waveProgress;
  }
}

/// 可乐杯状态指示器
class ColaCupIndicator extends StatelessWidget {
  final double spillPercentage;
  final double size;

  const ColaCupIndicator({
    super.key,
    required this.spillPercentage,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (spillPercentage * 100).clamp(0.0, 100.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 迷你可乐杯图标
        Container(
          width: size,
          height: size * 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(size * 0.1),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.1),
            child: CustomPaint(
              size: Size(size, size * 1.2),
              painter: MiniColaCupPainter(
                fillLevel: 1.0 - spillPercentage,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // 百分比文字
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: percentage > 50 ? Colors.orange : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// 迷你可乐杯绘制器
class MiniColaCupPainter extends CustomPainter {
  final double fillLevel;

  MiniColaCupPainter({required this.fillLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * 0.7;
    final height = size.height * 0.8;
    final left = (size.width - width) / 2;
    final top = size.height * 0.1;

    // 杯子轮廓
    final cupPath = Path()
      ..moveTo(left + width * 0.1, top)
      ..lineTo(left + width * 0.9, top)
      ..lineTo(left + width, top + height)
      ..lineTo(left, top + height)
      ..close();

    // 杯子背景
    final cupPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(cupPath, cupPaint);

    // 液体
    if (fillLevel > 0) {
      final liquidHeight = height * fillLevel;
      final liquidTop = top + height - liquidHeight;

      final liquidPath = Path()
        ..moveTo(left + width * 0.12, liquidTop)
        ..lineTo(left + width * 0.88, liquidTop)
        ..lineTo(left + width * 0.98, top + height - 2)
        ..lineTo(left + 2, top + height - 2)
        ..close();

      final liquidPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3D2817),
            const Color(0xFF0D0704),
          ],
        ).createShader(Rect.fromLTWH(left, liquidTop, width, liquidHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(liquidPath, liquidPaint);
    }

    // 杯子边框
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(cupPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant MiniColaCupPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel;
  }
}
