import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/core/utils/json_utils.dart';

/// 导入结果模型
///
/// 用于图片/文件导入后返回的识别结果
class ImportResult {
  /// 识别出的计划（失败时为 null）
  final ExercisePlanModel? plan;

  /// 识别置信度（0.0 - 1.0）
  final double confidence;

  /// 警告信息列表
  final List<String> warnings;

  /// 是否成功
  final bool isSuccess;

  /// 错误信息（如果失败）
  final String? errorMessage;

  const ImportResult({
    this.plan,
    required this.confidence,
    this.warnings = const [],
    this.isSuccess = true,
    this.errorMessage,
  });

  /// 创建成功结果
  factory ImportResult.success({
    required ExercisePlanModel plan,
    required double confidence,
    List<String> warnings = const [],
  }) {
    return ImportResult(
      plan: plan,
      confidence: confidence,
      warnings: warnings,
      isSuccess: true,
    );
  }

  /// 创建失败结果
  factory ImportResult.failure({required String errorMessage}) {
    return ImportResult(
      plan: null,
      confidence: 0.0,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  /// 从 JSON 解析
  factory ImportResult.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'success') {
      // 安全转换嵌套的 data 对象
      final data = safeMapCast(json['data'], 'data');
      if (data == null) {
        return ImportResult.failure(errorMessage: '数据格式错误');
      }

      // 安全转换 plan 对象
      final planData = safeMapCast(data['plan'], 'plan');
      if (planData == null) {
        return ImportResult.failure(errorMessage: '计划数据格式错误');
      }

      return ImportResult.success(
        plan: ExercisePlanModel.fromJson(planData),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 1.0,
        warnings:
            (data['warnings'] as List<dynamic>?)
                ?.map((w) => w.toString())
                .toList() ??
            [],
      );
    } else {
      return ImportResult.failure(
        errorMessage: json['error'] as String? ?? '导入失败',
      );
    }
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    if (isSuccess && plan != null) {
      return {
        'status': 'success',
        'data': {
          'plan': plan!.toJson(),
          'confidence': confidence,
          'warnings': warnings,
        },
      };
    } else {
      return {'status': 'error', 'error': errorMessage};
    }
  }

  /// 是否为高置信度（>= 0.8）
  bool get isHighConfidence => confidence >= 0.8;

  /// 是否为中等置信度（>= 0.6）
  bool get isMediumConfidence => confidence >= 0.6;

  /// 是否为低置信度（< 0.6）
  bool get isLowConfidence => confidence < 0.6;

  /// 获取置信度描述
  String get confidenceDescription {
    if (confidence >= 0.9) {
      return '识别准确度很高';
    } else if (confidence >= 0.8) {
      return '识别准确度高';
    } else if (confidence >= 0.7) {
      return '识别准确度中等';
    } else if (confidence >= 0.6) {
      return '识别准确度一般';
    } else {
      return '识别准确度较低，建议手动检查';
    }
  }

  /// 获取置信度颜色（用于 UI 显示）
  String get confidenceColor {
    if (confidence >= 0.8) {
      return 'green';
    } else if (confidence >= 0.6) {
      return 'orange';
    } else {
      return 'red';
    }
  }

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 是否需要用户review
  bool get needsReview => isLowConfidence || hasWarnings;

  @override
  String toString() {
    if (isSuccess) {
      return 'ImportResult(success, confidence: ${(confidence * 100).toStringAsFixed(0)}%, warnings: ${warnings.length})';
    } else {
      return 'ImportResult(failure, error: $errorMessage)';
    }
  }
}
