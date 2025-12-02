import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_import_stats.dart';

/// 饮食计划文本导入结果
class DietImportResult {
  /// 是否成功
  final bool isSuccess;

  /// 导入的饮食计划
  final DietPlanModel? plan;

  /// 统计数据
  final DietPlanImportStats? stats;

  /// 错误消息
  final String? errorMessage;

  /// 置信度 (0-1)
  final double? confidence;

  /// 警告信息
  final List<String>? warnings;

  const DietImportResult({
    required this.isSuccess,
    this.plan,
    this.stats,
    this.errorMessage,
    this.confidence,
    this.warnings,
  });

  /// 创建成功结果
  factory DietImportResult.success({
    required DietPlanModel plan,
    DietPlanImportStats? stats,
    double? confidence,
    List<String>? warnings,
  }) {
    return DietImportResult(
      isSuccess: true,
      plan: plan,
      stats: stats,
      confidence: confidence,
      warnings: warnings,
    );
  }

  /// 创建失败结果
  factory DietImportResult.failure({
    required String errorMessage,
  }) {
    return DietImportResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() => 'DietImportResult('
      'success: $isSuccess, '
      'plan: ${plan?.name}, '
      'stats: $stats, '
      'error: $errorMessage)';
}
