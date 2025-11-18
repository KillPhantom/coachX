import 'package:coach_x/core/utils/peak_detector.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 帧数据模型
/// 包含帧编号、时间戳、关节角度和帧图片路径
class FrameData {
  final int frameNumber;
  final double timestamp;
  final Map<String, double> angles;
  final String framePath;

  FrameData({
    required this.frameNumber,
    required this.timestamp,
    required this.angles,
    required this.framePath,
  });

  @override
  String toString() {
    return 'FrameData(frame: $frameNumber, time: ${timestamp.toStringAsFixed(2)}s, angles: ${angles.length})';
  }
}

/// 关键帧选择器
/// 基于姿态角度变化选择关键帧
class KeyframeSelector {
  /// 基于角度变化选择关键帧
  ///
  /// [framesData] - 所有帧的数据列表
  /// [maxFrames] - 最大关键帧数量 (默认5)
  ///
  /// 返回选中的关键帧索引列表
  static List<int> selectKeyframesByAngleChange(
    List<FrameData> framesData, {
    int maxFrames = 5,
  }) {
    try {
      AppLogger.info('Selecting keyframes from ${framesData.length} frames');

      if (framesData.isEmpty) {
        AppLogger.warning('No frames data provided');
        return [];
      }

      if (framesData.length <= maxFrames) {
        // 如果帧数不多，直接返回所有帧的索引
        AppLogger.debug('Frames count <= maxFrames, returning all frames');
        return List.generate(framesData.length, (i) => i);
      }

      // 提取所有角度的时间序列
      final angleTimeSeries = _extractAngleTimeSeries(framesData);

      if (angleTimeSeries.isEmpty) {
        AppLogger.warning('No angle data available, using fallback');
        return selectKeyframesFallback(framesData, maxFrames);
      }

      // 检测每个角度的峰值和谷值
      final candidateFrames = <int>{};

      for (final entry in angleTimeSeries.entries) {
        final angleName = entry.key;
        final series = entry.value;

        // 检测峰值
        final peaks = PeakDetector.detectPeaks(
          series,
          minDistance: 5,
          prominence: 5.0,
        );

        // 检测谷值
        final valleys = PeakDetector.detectValleys(
          series,
          minDistance: 5,
          prominence: 5.0,
        );

        AppLogger.debug(
          '$angleName: ${peaks.length} peaks, ${valleys.length} valleys',
        );

        candidateFrames.addAll(peaks);
        candidateFrames.addAll(valleys);
      }

      AppLogger.debug('Total candidate frames: ${candidateFrames.length}');

      // 如果候选帧不足，补充综合评分高的帧
      if (candidateFrames.length < maxFrames) {
        final additionalFrames = _findAdditionalFrames(
          framesData,
          angleTimeSeries,
          candidateFrames,
          maxFrames - candidateFrames.length,
        );
        candidateFrames.addAll(additionalFrames);
      }

      // 如果候选帧过多，使用分布均匀化筛选
      List<int> selectedFrames;
      if (candidateFrames.length > maxFrames) {
        selectedFrames = selectDistributedFrames(
          candidateFrames.toList()..sort(),
          maxFrames,
        );
      } else {
        selectedFrames = candidateFrames.toList()..sort();
      }

      AppLogger.info('Selected ${selectedFrames.length} keyframes');
      return selectedFrames;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to select keyframes by angle change',
        e,
        stackTrace,
      );
      return selectKeyframesFallback(framesData, maxFrames);
    }
  }

  /// 从候选帧中选择时间分布均匀的帧
  ///
  /// [candidates] - 候选帧索引列表 (已排序)
  /// [maxFrames] - 最大选择数量
  ///
  /// 返回选中的帧索引列表
  static List<int> selectDistributedFrames(
    List<int> candidates,
    int maxFrames,
  ) {
    if (candidates.length <= maxFrames) {
      return candidates;
    }

    // 使用贪心算法：每次选择与已选帧距离最大的候选帧
    final selected = <int>[candidates.first]; // 先选择第一帧

    while (selected.length < maxFrames) {
      int bestCandidate = -1;
      double maxMinDistance = 0;

      // 遍历所有候选帧
      for (final candidate in candidates) {
        if (selected.contains(candidate)) continue;

        // 计算该候选帧到所有已选帧的最小距离
        double minDistance = double.infinity;
        for (final selectedFrame in selected) {
          final distance = (candidate - selectedFrame).abs().toDouble();
          if (distance < minDistance) {
            minDistance = distance;
          }
        }

        // 选择最小距离最大的候选帧
        if (minDistance > maxMinDistance) {
          maxMinDistance = minDistance;
          bestCandidate = candidate;
        }
      }

      if (bestCandidate != -1) {
        selected.add(bestCandidate);
      } else {
        break;
      }
    }

    selected.sort();
    AppLogger.debug('Distributed selection: ${selected.length} frames');
    return selected;
  }

  /// 降级方案：均匀采样
  ///
  /// [framesData] - 所有帧的数据列表
  /// [maxFrames] - 最大关键帧数量
  ///
  /// 返回均匀分布的帧索引列表
  static List<int> selectKeyframesFallback(
    List<FrameData> framesData,
    int maxFrames,
  ) {
    AppLogger.debug('Using fallback uniform sampling');

    if (framesData.isEmpty) return [];
    if (framesData.length <= maxFrames) {
      return List.generate(framesData.length, (i) => i);
    }

    // 均匀采样
    final step = framesData.length / maxFrames;
    final selected = <int>[];

    for (int i = 0; i < maxFrames; i++) {
      final index = (i * step).floor();
      selected.add(index);
    }

    AppLogger.debug('Fallback selected ${selected.length} frames');
    return selected;
  }

  /// 提取所有角度的时间序列
  static Map<String, List<double>> _extractAngleTimeSeries(
    List<FrameData> framesData,
  ) {
    final Map<String, List<double>> timeSeries = {};

    // 获取所有角度名称
    if (framesData.isEmpty) return timeSeries;

    final angleNames = framesData.first.angles.keys.toSet();

    // 初始化时间序列
    for (final name in angleNames) {
      timeSeries[name] = [];
    }

    // 填充时间序列
    for (final frame in framesData) {
      for (final name in angleNames) {
        final angle = frame.angles[name];
        if (angle != null) {
          timeSeries[name]!.add(angle);
        }
      }
    }

    // 移除数据不完整的角度
    timeSeries.removeWhere((key, value) => value.length != framesData.length);

    return timeSeries;
  }

  /// 查找额外的高评分帧
  static List<int> _findAdditionalFrames(
    List<FrameData> framesData,
    Map<String, List<double>> angleTimeSeries,
    Set<int> existingCandidates,
    int count,
  ) {
    if (count <= 0) return [];

    // 计算每帧的综合评分
    final scores = <int, double>{};

    for (int i = 0; i < framesData.length; i++) {
      if (existingCandidates.contains(i)) continue;

      double totalScore = 0;
      int validScores = 0;

      for (final series in angleTimeSeries.values) {
        final score = PeakDetector.calculateAngleChangeScore(
          series,
          i,
          windowSize: 5,
        );
        if (score > 0) {
          totalScore += score;
          validScores++;
        }
      }

      if (validScores > 0) {
        scores[i] = totalScore / validScores;
      }
    }

    // 按评分排序，选择top N
    final sortedFrames = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final additional = sortedFrames.take(count).map((e) => e.key).toList();

    AppLogger.debug('Found ${additional.length} additional frames');
    return additional;
  }
}
