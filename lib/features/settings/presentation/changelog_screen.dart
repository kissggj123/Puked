
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 更新日志页面
class ChangelogScreen extends ConsumerWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更新日志'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前版本
          _buildVersionCard(
            version: 'v3.0.0',
            date: '2026-03-04',
            isLatest: true,
            changes: [
              ChangeItem(
                type: ChangeType.feature,
                text: '全新可乐杯物理模拟器，实时显示加速度对可乐杯的影响',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '新增行程回放功能，支持播放控制和速度调节',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '支持 Web 平台，可在浏览器中直接运行',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '新增更新日志页面',
              ),
              ChangeItem(
                type: ChangeType.improvement,
                text: '优化设置界面，移除 Web 平台不支持的选项',
              ),
              ChangeItem(
                type: ChangeType.improvement,
                text: '针对 Chromium 浏览器和安卓车机优化',
              ),
              ChangeItem(
                type: ChangeType.removal,
                text: '移除 Arena 排行榜功能',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 历史版本
          _buildVersionCard(
            version: 'v2.2.0',
            date: '2026-01',
            changes: [
              ChangeItem(
                type: ChangeType.feature,
                text: '新增 Pro 仪表盘，显示更丰富的驾驶数据',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '新增 G 力球可视化',
              ),
              ChangeItem(
                type: ChangeType.improvement,
                text: '优化地图交互体验',
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildVersionCard(
            version: 'v2.1.0',
            date: '2026-01',
            changes: [
              ChangeItem(
                type: ChangeType.feature,
                text: '新增车辆信息编辑功能',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '支持品牌 Logo 显示',
              ),
              ChangeItem(
                type: ChangeType.improvement,
                text: '优化事件标记功能',
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildVersionCard(
            version: 'v2.0.0',
            date: '2026-01',
            changes: [
              ChangeItem(
                type: ChangeType.feature,
                text: '全新 UI 设计',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '新增 Arena 排行榜功能',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '支持云端数据同步',
              ),
              ChangeItem(
                type: ChangeType.improvement,
                text: '优化传感器数据采集',
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildVersionCard(
            version: 'v1.0.0',
            date: '2026-01',
            changes: [
              ChangeItem(
                type: ChangeType.feature,
                text: '首次发布',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '基础行程记录功能',
              ),
              ChangeItem(
                type: ChangeType.feature,
                text: '传感器数据采集',
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildVersionCard({
    required String version,
    required String date,
    required List<ChangeItem> changes,
    bool isLatest = false,
  }) {
    return Card(
      elevation: isLatest ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isLatest
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      version,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '最新',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            ...changes.map((change) => _buildChangeItem(change)),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeItem(ChangeItem change) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: change.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              change.type.label,
              style: TextStyle(
                color: change.type.color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              change.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 变更类型
enum ChangeType {
  feature,
  improvement,
  fix,
  removal,
}

extension ChangeTypeExtension on ChangeType {
  String get label {
    switch (this) {
      case ChangeType.feature:
        return '新功能';
      case ChangeType.improvement:
        return '优化';
      case ChangeType.fix:
        return '修复';
      case ChangeType.removal:
        return '移除';
    }
  }

  Color get color {
    switch (this) {
      case ChangeType.feature:
        return Colors.green;
      case ChangeType.improvement:
        return Colors.blue;
      case ChangeType.fix:
        return Colors.orange;
      case ChangeType.removal:
        return Colors.red;
    }
  }
}

/// 变更项
class ChangeItem {
  final ChangeType type;
  final String text;

  ChangeItem({
    required this.type,
    required this.text,
  });
}
