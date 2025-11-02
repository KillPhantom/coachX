/// 训练水平枚举
enum TrainingLevel {
  /// 初级
  beginner,

  /// 中级
  intermediate,

  /// 高级
  advanced,
}

/// TrainingLevel 扩展方法
extension TrainingLevelExtension on TrainingLevel {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case TrainingLevel.beginner:
        return '初级';
      case TrainingLevel.intermediate:
        return '中级';
      case TrainingLevel.advanced:
        return '高级';
    }
  }

  /// 获取英文名称
  String get englishName {
    switch (this) {
      case TrainingLevel.beginner:
        return 'Beginner';
      case TrainingLevel.intermediate:
        return 'Intermediate';
      case TrainingLevel.advanced:
        return 'Advanced';
    }
  }

  /// 获取描述
  String get description {
    switch (this) {
      case TrainingLevel.beginner:
        return '训练经验 < 6个月';
      case TrainingLevel.intermediate:
        return '训练经验 6个月 - 2年';
      case TrainingLevel.advanced:
        return '训练经验 > 2年';
    }
  }

  /// 获取建议的训练频率（天/周）
  int get recommendedFrequency {
    switch (this) {
      case TrainingLevel.beginner:
        return 3;
      case TrainingLevel.intermediate:
        return 4;
      case TrainingLevel.advanced:
        return 5;
    }
  }

  /// 获取建议的每天动作数
  int get recommendedExercises {
    switch (this) {
      case TrainingLevel.beginner:
        return 4;
      case TrainingLevel.intermediate:
        return 5;
      case TrainingLevel.advanced:
        return 6;
    }
  }

  /// 获取建议的每动作组数
  int get recommendedSets {
    switch (this) {
      case TrainingLevel.beginner:
        return 3;
      case TrainingLevel.intermediate:
        return 4;
      case TrainingLevel.advanced:
        return 5;
    }
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    switch (this) {
      case TrainingLevel.beginner:
        return 'beginner';
      case TrainingLevel.intermediate:
        return 'intermediate';
      case TrainingLevel.advanced:
        return 'advanced';
    }
  }
}

/// 从字符串解析 TrainingLevel
TrainingLevel trainingLevelFromString(String value) {
  switch (value.toLowerCase()) {
    case 'beginner':
    case '初级':
    case '新手':
      return TrainingLevel.beginner;
    case 'intermediate':
    case '中级':
      return TrainingLevel.intermediate;
    case 'advanced':
    case '高级':
      return TrainingLevel.advanced;
    default:
      return TrainingLevel.intermediate;
  }
}

