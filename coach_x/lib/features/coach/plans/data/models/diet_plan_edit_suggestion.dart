import 'package:coach_x/features/coach/plans/data/models/macros.dart';

/// 饮食计划修改类型
enum DietChangeType {
  modifyMeal,          // 修改餐次名称
  addMeal,             // 添加餐次
  removeMeal,          // 删除餐次
  modifyFoodItem,      // 修改食物
  addFoodItem,         // 添加食物
  removeFoodItem,      // 删除食物
  adjustMacros,        // 调整营养比例
  addDay,              // 添加饮食日
  removeDay,           // 删除饮食日
  modifyDayName,       // 修改饮食日名称
  reorder,             // 调整顺序
  other,               // 其他修改
}

/// 饮食计划单个修改
class DietPlanChange {
  final DietChangeType type;
  final String target;
  final String description;
  final String reason;

  // before/after 可以是字符串或数组（取决于修改类型）
  final dynamic before;
  final dynamic after;

  // 精确定位信息
  final int dayIndex;              // 饮食日索引
  final int? mealIndex;            // 餐次索引（可选）
  final int? foodItemIndex;        // 食物条目索引（可选）

  // 唯一标识
  final String id;

  const DietPlanChange({
    required this.type,
    required this.target,
    required this.description,
    required this.reason,
    this.before,
    this.after,
    required this.dayIndex,
    this.mealIndex,
    this.foodItemIndex,
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
      if (mealIndex != null) 'mealIndex': mealIndex,
      if (foodItemIndex != null) 'foodItemIndex': foodItemIndex,
      'id': id,
    };
  }

  /// 从 JSON 创建
  factory DietPlanChange.fromJson(Map<String, dynamic> json) {
    // 处理 type，将蛇形命名转换为驼峰命名
    String typeStr = json['type'] as String;
    DietChangeType changeType;

    // 尝试匹配枚举值
    try {
      // 先尝试 snake_case 转 camelCase
      if (typeStr.contains('_')) {
        final parts = typeStr.split('_');
        typeStr = parts.first +
            parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join('');
      }

      changeType = DietChangeType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => DietChangeType.other,
      );
    } catch (e) {
      changeType = DietChangeType.other;
    }

    // 处理 dayIndex（兼容蛇形和驼峰命名）
    final dayIndex = (json['dayIndex'] ?? json['day_index'] ?? 0) as int;
    final mealIndex = (json['mealIndex'] ?? json['meal_index']) as int?;
    final foodItemIndex = (json['foodItemIndex'] ?? json['food_item_index']) as int?;
    final id = json['id'] as String? ?? 'change_${DateTime.now().millisecondsSinceEpoch}';

    // before/after 保持为 dynamic
    final before = json['before'];
    final after = json['after'];

    return DietPlanChange(
      type: changeType,
      target: json['target'] as String? ?? '',
      description: json['description'] as String,
      reason: json['reason'] as String,
      before: before,
      after: after,
      dayIndex: dayIndex,
      mealIndex: mealIndex,
      foodItemIndex: foodItemIndex,
      id: id,
    );
  }

  @override
  String toString() {
    return 'DietPlanChange(id: $id, type: ${type.name}, dayIndex: $dayIndex, mealIndex: $mealIndex, target: $target)';
  }
}

/// 营养数据变化
class MacrosChange {
  final Macros before;
  final Macros after;
  final Macros delta; // 变化量

  const MacrosChange({
    required this.before,
    required this.after,
    required this.delta,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'before': before.toJson(),
      'after': after.toJson(),
      'delta': delta.toJson(),
    };
  }

  /// 从 JSON 创建
  factory MacrosChange.fromJson(Map<String, dynamic> json) {
    return MacrosChange(
      before: Macros.fromJson(Map<String, dynamic>.from(json['before'] as Map)),
      after: Macros.fromJson(Map<String, dynamic>.from(json['after'] as Map)),
      delta: Macros.fromJson(Map<String, dynamic>.from(json['delta'] as Map)),
    );
  }

  @override
  String toString() {
    return 'MacrosChange(delta: $delta)';
  }
}

/// 饮食计划编辑建议
class DietPlanEditSuggestion {
  final String analysis; // AI 的分析
  final List<DietPlanChange> changes; // 修改列表
  final String? summary; // 修改总结（可选）
  final MacrosChange? macrosChange; // 营养数据变化（可选）

  const DietPlanEditSuggestion({
    required this.analysis,
    required this.changes,
    this.summary,
    this.macrosChange,
  });

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'analysis': analysis,
      'changes': changes.map((c) => c.toJson()).toList(),
      if (summary != null) 'summary': summary,
      if (macrosChange != null) 'macrosChange': macrosChange!.toJson(),
    };
  }

  /// 从 JSON 创建
  factory DietPlanEditSuggestion.fromJson(Map<String, dynamic> json) {
    final changesJson = json['changes'] as List<dynamic>? ?? [];
    final changes = changesJson
        .map((c) => DietPlanChange.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();

    MacrosChange? macrosChange;
    if (json['macrosChange'] != null || json['macros_change'] != null) {
      final macrosData = json['macrosChange'] ?? json['macros_change'];
      if (macrosData != null) {
        macrosChange = MacrosChange.fromJson(
          Map<String, dynamic>.from(macrosData as Map),
        );
      }
    }

    return DietPlanEditSuggestion(
      analysis: json['analysis'] as String,
      changes: changes,
      summary: json['summary'] as String?,
      macrosChange: macrosChange,
    );
  }

  /// 复制并修改
  DietPlanEditSuggestion copyWith({
    String? analysis,
    List<DietPlanChange>? changes,
    String? summary,
    MacrosChange? macrosChange,
    bool clearSummary = false,
    bool clearMacrosChange = false,
  }) {
    return DietPlanEditSuggestion(
      analysis: analysis ?? this.analysis,
      changes: changes ?? this.changes,
      summary: clearSummary ? null : (summary ?? this.summary),
      macrosChange: clearMacrosChange ? null : (macrosChange ?? this.macrosChange),
    );
  }

  @override
  String toString() {
    return 'DietPlanEditSuggestion(changes: ${changes.length}, summary: $summary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DietPlanEditSuggestion &&
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
