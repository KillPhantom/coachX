import 'package:coach_x/core/utils/json_utils.dart';

/// 训练摘要模型
///
/// 用于在反馈列表中显示训练的概要信息
class TrainingSummary {
  final int exerciseCount; // 完成的动作数
  final bool dietCompleted; // 是否完成饮食记录
  final int totalSets; // 总组数
  final double completionRate; // 完成率 0-100

  const TrainingSummary({
    required this.exerciseCount,
    required this.dietCompleted,
    required this.totalSets,
    required this.completionRate,
  });

  /// 创建空摘要
  factory TrainingSummary.empty() {
    return const TrainingSummary(
      exerciseCount: 0,
      dietCompleted: false,
      totalSets: 0,
      completionRate: 0.0,
    );
  }

  /// 从 JSON 创建
  factory TrainingSummary.fromJson(Map<String, dynamic> json) {
    return TrainingSummary(
      exerciseCount:
          safeIntCast(json['exerciseCount'], 0, 'exerciseCount') ?? 0,
      dietCompleted: json['dietCompleted'] as bool? ?? false,
      totalSets: safeIntCast(json['totalSets'], 0, 'totalSets') ?? 0,
      completionRate:
          safeDoubleCast(json['completionRate'], 0.0, 'completionRate') ?? 0.0,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseCount': exerciseCount,
      'dietCompleted': dietCompleted,
      'totalSets': totalSets,
      'completionRate': completionRate,
    };
  }

  /// 复制并修改部分字段
  TrainingSummary copyWith({
    int? exerciseCount,
    bool? dietCompleted,
    int? totalSets,
    double? completionRate,
  }) {
    return TrainingSummary(
      exerciseCount: exerciseCount ?? this.exerciseCount,
      dietCompleted: dietCompleted ?? this.dietCompleted,
      totalSets: totalSets ?? this.totalSets,
      completionRate: completionRate ?? this.completionRate,
    );
  }

  /// 生成训练摘要文本
  /// 示例: "3 exercises · 12 sets · Diet logged · 85% complete"
  String toDisplayString() {
    final parts = <String>[];

    if (exerciseCount > 0) {
      parts.add(
        '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
      );
    }

    if (totalSets > 0) {
      parts.add('$totalSets ${totalSets == 1 ? 'set' : 'sets'}');
    }

    if (dietCompleted) {
      parts.add('Diet logged');
    }

    if (completionRate > 0) {
      parts.add('${completionRate.toStringAsFixed(0)}% complete');
    }

    return parts.join(' · ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingSummary &&
          runtimeType == other.runtimeType &&
          exerciseCount == other.exerciseCount &&
          dietCompleted == other.dietCompleted &&
          totalSets == other.totalSets &&
          completionRate == other.completionRate;

  @override
  int get hashCode =>
      exerciseCount.hashCode ^
      dietCompleted.hashCode ^
      totalSets.hashCode ^
      completionRate.hashCode;

  @override
  String toString() {
    return 'TrainingSummary(exercises: $exerciseCount, sets: $totalSets, diet: $dietCompleted, completion: $completionRate%)';
  }
}
