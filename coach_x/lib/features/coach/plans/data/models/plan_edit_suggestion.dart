/// 修改类型
enum ChangeType {
  modifyExercise, // 修改动作名称
  addExercise, // 添加动作
  removeExercise, // 删除动作
  modifyExerciseSets, // 修改动作的训练组（exercise-level）
  addDay, // 添加训练日
  removeDay, // 删除训练日
  modifyDayName, // 修改训练日名称
  reorder, // 调整顺序
  adjustIntensity, // 调整强度
  other, // 其他修改
}

/// 单个计划修改
class PlanChange {
  final ChangeType type;
  final String target;
  final String description;
  final String reason;

  // before/after 可以是字符串或数组（取决于修改类型）
  // 对于 modifyExerciseSets: List<Map<String, String>> (训练组数组)
  // 对于其他类型: String (简单描述)
  final dynamic before;
  final dynamic after;

  // 精确定位信息
  final int dayIndex; // 训练日索引
  final int? exerciseIndex; // 动作索引（可选，取决于修改类型）

  // 唯一标识
  final String id; // 用于追踪已接受/拒绝的修改

  const PlanChange({
    required this.type,
    required this.target,
    required this.description,
    required this.reason,
    this.before,
    this.after,
    required this.dayIndex,
    this.exerciseIndex,
    required this.id,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'target': target,
      'description': description,
      'reason': reason,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      'dayIndex': dayIndex,
      if (exerciseIndex != null) 'exerciseIndex': exerciseIndex,
      'id': id,
    };
  }

  /// 从 JSON 创建
  factory PlanChange.fromJson(Map<String, dynamic> json) {
    // 处理 type，将蛇形命名转换为驼峰命名
    String typeStr = json['type'] as String;
    ChangeType changeType;

    // 尝试匹配枚举值
    try {
      // 先尝试 snake_case 转 camelCase
      if (typeStr.contains('_')) {
        final parts = typeStr.split('_');
        typeStr =
            parts.first +
            parts
                .skip(1)
                .map((p) => p[0].toUpperCase() + p.substring(1))
                .join('');
      }

      changeType = ChangeType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => ChangeType.other,
      );
    } catch (e) {
      changeType = ChangeType.other;
    }

    // 处理 dayIndex（兼容蛇形和驼峰命名）
    final dayIndex = (json['dayIndex'] ?? json['day_index'] ?? 0) as int;
    final exerciseIndex =
        (json['exerciseIndex'] ?? json['exercise_index']) as int?;
    final id =
        json['id'] as String? ??
        'change_${DateTime.now().millisecondsSinceEpoch}';

    // before/after 保持为 dynamic，可以是字符串、数组或Map
    final before = json['before'];
    final after = json['after'];

    return PlanChange(
      type: changeType,
      target: json['target'] as String? ?? '',
      description: json['description'] as String,
      reason: json['reason'] as String,
      before: before,
      after: after,
      dayIndex: dayIndex,
      exerciseIndex: exerciseIndex,
      id: id,
    );
  }

  @override
  String toString() {
    return 'PlanChange(id: $id, type: ${type.name}, dayIndex: $dayIndex, exerciseIndex: $exerciseIndex, target: $target)';
  }
}

/// 计划编辑建议
class PlanEditSuggestion {
  final String analysis; // AI 的分析
  final List<PlanChange> changes; // 修改列表（source of truth）
  final String? summary; // 修改总结（可选）

  const PlanEditSuggestion({
    required this.analysis,
    required this.changes,
    this.summary,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'changes': changes.map((c) => c.toJson()).toList(),
      if (summary != null) 'summary': summary,
    };
  }

  /// 从 JSON 创建
  factory PlanEditSuggestion.fromJson(Map<String, dynamic> json) {
    return PlanEditSuggestion(
      analysis: json['analysis'] as String,
      changes: (json['changes'] as List<dynamic>)
          .map((c) => PlanChange.fromJson(c as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String?,
    );
  }

  /// 复制并修改
  PlanEditSuggestion copyWith({
    String? analysis,
    List<PlanChange>? changes,
    String? summary,
    bool clearSummary = false,
  }) {
    return PlanEditSuggestion(
      analysis: analysis ?? this.analysis,
      changes: changes ?? this.changes,
      summary: clearSummary ? null : (summary ?? this.summary),
    );
  }

  @override
  String toString() {
    return 'PlanEditSuggestion(changes: ${changes.length}, summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlanEditSuggestion &&
        other.analysis == analysis &&
        other.summary == summary &&
        other.changes.length == changes.length;
  }

  @override
  int get hashCode {
    return analysis.hashCode ^
        (summary?.hashCode ?? 0) ^
        changes.length.hashCode;
  }
}
