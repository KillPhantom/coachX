/// 饮食目标枚举
///
/// 用于饮食计划生成时描述用户的目标
enum DietGoal {
  /// 增肌
  muscleGain,

  /// 减脂
  fatLoss,

  /// 维持体重
  maintenance,
}

extension DietGoalExtension on DietGoal {
  /// 显示名称（中文）
  String get displayName {
    switch (this) {
      case DietGoal.muscleGain:
        return '增肌';
      case DietGoal.fatLoss:
        return '减脂';
      case DietGoal.maintenance:
        return '维持';
    }
  }

  /// 描述文本
  String get description {
    switch (this) {
      case DietGoal.muscleGain:
        return '增加肌肉质量，热量盈余';
      case DietGoal.fatLoss:
        return '减少体脂，热量赤字';
      case DietGoal.maintenance:
        return '维持当前体重和体脂';
    }
  }

  /// 转换为 API 参数值
  String get apiValue {
    switch (this) {
      case DietGoal.muscleGain:
        return 'muscle_gain';
      case DietGoal.fatLoss:
        return 'fat_loss';
      case DietGoal.maintenance:
        return 'maintenance';
    }
  }

  /// 从 API 值解析
  static DietGoal fromApiValue(String value) {
    switch (value) {
      case 'muscle_gain':
        return DietGoal.muscleGain;
      case 'fat_loss':
        return DietGoal.fatLoss;
      case 'maintenance':
        return DietGoal.maintenance;
      default:
        return DietGoal.maintenance; // 默认值
    }
  }
}
