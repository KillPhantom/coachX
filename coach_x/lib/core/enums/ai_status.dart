/// AI 生成状态枚举
enum AIGenerationStatus {
  /// 空闲
  idle,

  /// 生成中
  generating,

  /// 成功
  success,

  /// 错误
  error,
}

/// AIGenerationStatus 扩展方法
extension AIGenerationStatusExtension on AIGenerationStatus {
  /// 是否为空闲状态
  bool get isIdle => this == AIGenerationStatus.idle;

  /// 是否为生成中
  bool get isGenerating => this == AIGenerationStatus.generating;

  /// 是否为成功
  bool get isSuccess => this == AIGenerationStatus.success;

  /// 是否为错误
  bool get isError => this == AIGenerationStatus.error;

  /// 获取显示文本
  String get displayText {
    switch (this) {
      case AIGenerationStatus.idle:
        return '就绪';
      case AIGenerationStatus.generating:
        return '生成中...';
      case AIGenerationStatus.success:
        return '生成成功';
      case AIGenerationStatus.error:
        return '生成失败';
    }
  }
}

/// AI 建议类型枚举
enum AISuggestionType {
  /// 完整计划生成
  fullPlan,

  /// 推荐下一个训练日
  nextDay,

  /// 推荐动作
  exercises,

  /// 推荐 Sets 配置
  sets,

  /// 优化现有计划
  optimize,
}

/// AISuggestionType 扩展方法
extension AISuggestionTypeExtension on AISuggestionType {
  /// 是否为完整计划生成
  bool get isFullPlan => this == AISuggestionType.fullPlan;

  /// 是否为推荐下一天
  bool get isNextDay => this == AISuggestionType.nextDay;

  /// 是否为推荐动作
  bool get isExercises => this == AISuggestionType.exercises;

  /// 是否为推荐 Sets
  bool get isSets => this == AISuggestionType.sets;

  /// 是否为优化计划
  bool get isOptimize => this == AISuggestionType.optimize;

  /// 获取显示名称
  String get displayName {
    switch (this) {
      case AISuggestionType.fullPlan:
        return '完整计划';
      case AISuggestionType.nextDay:
        return '推荐训练日';
      case AISuggestionType.exercises:
        return '推荐动作';
      case AISuggestionType.sets:
        return '推荐组数';
      case AISuggestionType.optimize:
        return '优化计划';
    }
  }

  /// 转换为字符串
  String toJsonString() {
    switch (this) {
      case AISuggestionType.fullPlan:
        return 'full_plan';
      case AISuggestionType.nextDay:
        return 'next_day';
      case AISuggestionType.exercises:
        return 'exercises';
      case AISuggestionType.sets:
        return 'sets';
      case AISuggestionType.optimize:
        return 'optimize';
    }
  }
}

/// 从字符串解析 AISuggestionType
AISuggestionType aiSuggestionTypeFromString(String value) {
  switch (value.toLowerCase()) {
    case 'fullplan':
    case 'full_plan':
      return AISuggestionType.fullPlan;
    case 'nextday':
    case 'next_day':
      return AISuggestionType.nextDay;
    case 'exercises':
      return AISuggestionType.exercises;
    case 'sets':
      return AISuggestionType.sets;
    case 'optimize':
      return AISuggestionType.optimize;
    default:
      return AISuggestionType.fullPlan;
  }
}


