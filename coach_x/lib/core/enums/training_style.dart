/// 训练风格枚举
enum TrainingStyle {
  /// 金字塔递增
  pyramid,

  /// 超级组
  superset,

  /// 递减组
  dropSet,

  /// 巨型组
  giantSet,

  /// 高次数低重量
  highReps,

  /// 低次数高重量
  lowReps,

  /// 间歇训练
  intervalTraining,

  /// 循环训练
  circuitTraining,
}

/// TrainingStyle 扩展方法
extension TrainingStyleExtension on TrainingStyle {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case TrainingStyle.pyramid:
        return '金字塔递增';
      case TrainingStyle.superset:
        return '超级组';
      case TrainingStyle.dropSet:
        return '递减组';
      case TrainingStyle.giantSet:
        return '巨型组';
      case TrainingStyle.highReps:
        return '高次数低重量';
      case TrainingStyle.lowReps:
        return '低次数高重量';
      case TrainingStyle.intervalTraining:
        return '间歇训练';
      case TrainingStyle.circuitTraining:
        return '循环训练';
    }
  }

  /// 获取英文名称
  String get englishName {
    switch (this) {
      case TrainingStyle.pyramid:
        return 'Pyramid';
      case TrainingStyle.superset:
        return 'Superset';
      case TrainingStyle.dropSet:
        return 'Drop Set';
      case TrainingStyle.giantSet:
        return 'Giant Set';
      case TrainingStyle.highReps:
        return 'High Reps';
      case TrainingStyle.lowReps:
        return 'Low Reps';
      case TrainingStyle.intervalTraining:
        return 'Interval Training';
      case TrainingStyle.circuitTraining:
        return 'Circuit Training';
    }
  }

  /// 获取描述
  String get description {
    switch (this) {
      case TrainingStyle.pyramid:
        return '重量递增，次数递减（如 12→10→8→6）';
      case TrainingStyle.superset:
        return '连续做两个动作，不休息';
      case TrainingStyle.dropSet:
        return '力竭后立即减重继续';
      case TrainingStyle.giantSet:
        return '连续做3-4个动作，不休息';
      case TrainingStyle.highReps:
        return '高次数（12-20次），适合减脂塑形';
      case TrainingStyle.lowReps:
        return '低次数（3-6次），适合力量训练';
      case TrainingStyle.intervalTraining:
        return '高强度运动和休息交替';
      case TrainingStyle.circuitTraining:
        return '多个动作循环进行';
    }
  }

  /// 适合的目标
  List<String> get suitableGoals {
    switch (this) {
      case TrainingStyle.pyramid:
        return ['增肌', '力量'];
      case TrainingStyle.superset:
        return ['增肌', '减脂'];
      case TrainingStyle.dropSet:
        return ['增肌'];
      case TrainingStyle.giantSet:
        return ['减脂', '耐力'];
      case TrainingStyle.highReps:
        return ['减脂', '塑形', '耐力'];
      case TrainingStyle.lowReps:
        return ['力量'];
      case TrainingStyle.intervalTraining:
        return ['减脂', '心肺'];
      case TrainingStyle.circuitTraining:
        return ['减脂', '全身'];
    }
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    switch (this) {
      case TrainingStyle.pyramid:
        return 'pyramid';
      case TrainingStyle.superset:
        return 'superset';
      case TrainingStyle.dropSet:
        return 'drop_set';
      case TrainingStyle.giantSet:
        return 'giant_set';
      case TrainingStyle.highReps:
        return 'high_reps';
      case TrainingStyle.lowReps:
        return 'low_reps';
      case TrainingStyle.intervalTraining:
        return 'interval_training';
      case TrainingStyle.circuitTraining:
        return 'circuit_training';
    }
  }
}

/// 从字符串解析 TrainingStyle
TrainingStyle trainingStyleFromString(String value) {
  switch (value.toLowerCase()) {
    case 'pyramid':
    case '金字塔':
      return TrainingStyle.pyramid;
    case 'superset':
    case '超级组':
      return TrainingStyle.superset;
    case 'drop_set':
    case 'dropset':
    case '递减组':
      return TrainingStyle.dropSet;
    case 'giant_set':
    case 'giantset':
    case '巨型组':
      return TrainingStyle.giantSet;
    case 'high_reps':
    case 'highreps':
    case '高次数':
      return TrainingStyle.highReps;
    case 'low_reps':
    case 'lowreps':
    case '低次数':
      return TrainingStyle.lowReps;
    case 'interval_training':
    case 'intervaltraining':
    case '间歇':
      return TrainingStyle.intervalTraining;
    case 'circuit_training':
    case 'circuittraining':
    case '循环':
      return TrainingStyle.circuitTraining;
    default:
      return TrainingStyle.pyramid;
  }
}
