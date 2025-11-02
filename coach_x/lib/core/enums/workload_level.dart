/// 训练量水平枚举
enum WorkloadLevel {
  /// 低
  low,

  /// 中
  medium,

  /// 高
  high,
}

/// WorkloadLevel 扩展方法
extension WorkloadLevelExtension on WorkloadLevel {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case WorkloadLevel.low:
        return '低';
      case WorkloadLevel.medium:
        return '中等';
      case WorkloadLevel.high:
        return '高';
    }
  }

  /// 获取英文名称
  String get englishName {
    switch (this) {
      case WorkloadLevel.low:
        return 'Low';
      case WorkloadLevel.medium:
        return 'Medium';
      case WorkloadLevel.high:
        return 'High';
    }
  }

  /// 获取描述
  String get description {
    switch (this) {
      case WorkloadLevel.low:
        return '12-15 组/天，适合恢复期或入门';
      case WorkloadLevel.medium:
        return '16-20 组/天，适合大多数人';
      case WorkloadLevel.high:
        return '21-30 组/天，适合高级训练者';
    }
  }

  /// 获取每天总组数范围
  (int min, int max) get totalSetsRange {
    switch (this) {
      case WorkloadLevel.low:
        return (12, 15);
      case WorkloadLevel.medium:
        return (16, 20);
      case WorkloadLevel.high:
        return (21, 30);
    }
  }

  /// 获取建议的动作数
  int get recommendedExercises {
    switch (this) {
      case WorkloadLevel.low:
        return 4;
      case WorkloadLevel.medium:
        return 5;
      case WorkloadLevel.high:
        return 6;
    }
  }

  /// 获取建议的每动作组数
  int get recommendedSetsPerExercise {
    switch (this) {
      case WorkloadLevel.low:
        return 3;
      case WorkloadLevel.medium:
        return 4;
      case WorkloadLevel.high:
        return 5;
    }
  }

  /// 获取数值（用于滑块）
  double get value {
    switch (this) {
      case WorkloadLevel.low:
        return 0.0;
      case WorkloadLevel.medium:
        return 0.5;
      case WorkloadLevel.high:
        return 1.0;
    }
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    switch (this) {
      case WorkloadLevel.low:
        return 'low';
      case WorkloadLevel.medium:
        return 'medium';
      case WorkloadLevel.high:
        return 'high';
    }
  }
}

/// 从字符串解析 WorkloadLevel
WorkloadLevel workloadLevelFromString(String value) {
  switch (value.toLowerCase()) {
    case 'low':
    case '低':
      return WorkloadLevel.low;
    case 'medium':
    case '中':
    case '中等':
      return WorkloadLevel.medium;
    case 'high':
    case '高':
      return WorkloadLevel.high;
    default:
      return WorkloadLevel.medium;
  }
}

/// 从数值解析 WorkloadLevel（用于滑块）
WorkloadLevel workloadLevelFromValue(double value) {
  if (value < 0.25) {
    return WorkloadLevel.low;
  } else if (value < 0.75) {
    return WorkloadLevel.medium;
  } else {
    return WorkloadLevel.high;
  }
}

