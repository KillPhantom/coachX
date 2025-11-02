/// 训练目标枚举
enum TrainingGoal {
  /// 增肌
  muscleGain,

  /// 减脂
  fatLoss,

  /// 力量
  strength,

  /// 塑形
  toning,
}

/// TrainingGoal 扩展方法
extension TrainingGoalExtension on TrainingGoal {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case TrainingGoal.muscleGain:
        return '增肌';
      case TrainingGoal.fatLoss:
        return '减脂';
      case TrainingGoal.strength:
        return '力量';
      case TrainingGoal.toning:
        return '塑形';
    }
  }

  /// 获取英文名称
  String get englishName {
    switch (this) {
      case TrainingGoal.muscleGain:
        return 'Muscle Gain';
      case TrainingGoal.fatLoss:
        return 'Fat Loss';
      case TrainingGoal.strength:
        return 'Strength';
      case TrainingGoal.toning:
        return 'Toning';
    }
  }

  /// 获取描述
  String get description {
    switch (this) {
      case TrainingGoal.muscleGain:
        return '增加肌肉量，提升身体维度';
      case TrainingGoal.fatLoss:
        return '减少体脂，塑造线条';
      case TrainingGoal.strength:
        return '提升力量，突破重量';
      case TrainingGoal.toning:
        return '塑形美体，改善体态';
    }
  }

  /// 获取图标名称
  String get iconName {
    switch (this) {
      case TrainingGoal.muscleGain:
        return '💪';
      case TrainingGoal.fatLoss:
        return '🔥';
      case TrainingGoal.strength:
        return '🏋️';
      case TrainingGoal.toning:
        return '✨';
    }
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    switch (this) {
      case TrainingGoal.muscleGain:
        return 'muscle_gain';
      case TrainingGoal.fatLoss:
        return 'fat_loss';
      case TrainingGoal.strength:
        return 'strength';
      case TrainingGoal.toning:
        return 'toning';
    }
  }
}

/// 从字符串解析 TrainingGoal
TrainingGoal trainingGoalFromString(String value) {
  switch (value.toLowerCase()) {
    case 'muscle_gain':
    case 'musclegain':
    case '增肌':
      return TrainingGoal.muscleGain;
    case 'fat_loss':
    case 'fatloss':
    case '减脂':
      return TrainingGoal.fatLoss;
    case 'strength':
    case '力量':
      return TrainingGoal.strength;
    case 'toning':
    case '塑形':
      return TrainingGoal.toning;
    default:
      return TrainingGoal.muscleGain;
  }
}

