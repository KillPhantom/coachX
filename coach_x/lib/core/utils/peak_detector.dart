import 'dart:math';

/// 峰值检测工具
/// 用于在时间序列数据中检测峰值和谷值
class PeakDetector {
  /// 检测峰值 (局部最大值)
  ///
  /// [series] - 时间序列数据
  /// [minDistance] - 相邻峰值之间的最小距离 (索引差)
  /// [prominence] - 峰值显著性阈值 (峰值与相邻谷值的最小差值)
  ///
  /// 返回峰值的索引列表
  static List<int> detectPeaks(
    List<double> series, {
    int minDistance = 5,
    double prominence = 5.0,
  }) {
    if (series.length < 3) return [];

    final List<int> peaks = [];

    // 遍历数组，查找局部最大值
    for (int i = 1; i < series.length - 1; i++) {
      final current = series[i];
      final prev = series[i - 1];
      final next = series[i + 1];

      // 检查是否为局部最大值
      if (current > prev && current > next) {
        // 检查与上一个峰值的距离
        if (peaks.isEmpty ||
            (i - peaks.last >= minDistance &&
                _checkProminence(series, i, prominence))) {
          peaks.add(i);
        }
      }
    }

    return peaks;
  }

  /// 检测谷值 (局部最小值)
  ///
  /// [series] - 时间序列数据
  /// [minDistance] - 相邻谷值之间的最小距离 (索引差)
  /// [prominence] - 谷值显著性阈值 (谷值与相邻峰值的最小差值)
  ///
  /// 返回谷值的索引列表
  static List<int> detectValleys(
    List<double> series, {
    int minDistance = 5,
    double prominence = 5.0,
  }) {
    if (series.length < 3) return [];

    final List<int> valleys = [];

    // 遍历数组，查找局部最小值
    for (int i = 1; i < series.length - 1; i++) {
      final current = series[i];
      final prev = series[i - 1];
      final next = series[i + 1];

      // 检查是否为局部最小值
      if (current < prev && current < next) {
        // 检查与上一个谷值的距离
        if (valleys.isEmpty ||
            (i - valleys.last >= minDistance &&
                _checkProminence(series, i, prominence, isValley: true))) {
          valleys.add(i);
        }
      }
    }

    return valleys;
  }

  /// 计算某帧的角度变化显著性评分
  ///
  /// [series] - 时间序列数据
  /// [frameIndex] - 当前帧索引
  /// [windowSize] - 计算窗口大小 (前后各取windowSize个帧)
  ///
  /// 返回显著性评分 (0-100)
  static double calculateAngleChangeScore(
    List<double> series,
    int frameIndex, {
    int windowSize = 5,
  }) {
    if (frameIndex < windowSize || frameIndex >= series.length - windowSize) {
      return 0.0;
    }

    // 计算前后窗口的平均值
    double beforeSum = 0.0;
    double afterSum = 0.0;

    for (int i = frameIndex - windowSize; i < frameIndex; i++) {
      beforeSum += series[i];
    }

    for (int i = frameIndex + 1; i <= frameIndex + windowSize; i++) {
      afterSum += series[i];
    }

    final beforeAvg = beforeSum / windowSize;
    final afterAvg = afterSum / windowSize;
    final currentValue = series[frameIndex];

    // 计算相对于前后窗口的变化量
    final beforeChange = (currentValue - beforeAvg).abs();
    final afterChange = (currentValue - afterAvg).abs();

    // 综合评分 (归一化到0-100)
    final score = (beforeChange + afterChange) / 2;

    return min(score, 100.0);
  }

  /// 检查峰值/谷值的显著性
  ///
  /// [series] - 时间序列数据
  /// [index] - 峰值/谷值索引
  /// [prominence] - 显著性阈值
  /// [isValley] - 是否为谷值 (默认为false，即峰值)
  ///
  /// 返回是否满足显著性要求
  static bool _checkProminence(
    List<double> series,
    int index,
    double prominence, {
    bool isValley = false,
  }) {
    final value = series[index];

    // 在前后窗口内查找最近的相邻极值
    double minDiff = double.infinity;

    // 向左查找
    for (int i = max(0, index - 10); i < index; i++) {
      final diff = isValley ? series[i] - value : value - series[i];
      if (diff > 0) {
        minDiff = min(minDiff, diff);
      }
    }

    // 向右查找
    for (int i = index + 1; i < min(series.length, index + 10); i++) {
      final diff = isValley ? series[i] - value : value - series[i];
      if (diff > 0) {
        minDiff = min(minDiff, diff);
      }
    }

    // 如果找不到相邻极值，降低要求
    if (minDiff == double.infinity) {
      return true;
    }

    return minDiff >= prominence;
  }
}
