/// 活动水平枚举
///
/// 用于饮食计划生成时描述用户的日常活动量
enum ActivityLevel {
  /// 久坐（很少或不运动）
  sedentary,

  /// 轻度活跃（每周运动1-3次）
  lightlyActive,

  /// 中度活跃（每周运动3-5次）
  moderatelyActive,

  /// 非常活跃（每周运动6-7次）
  veryActive,

  /// 极度活跃（高强度训练或体力劳动）
  extremelyActive,
}

extension ActivityLevelExtension on ActivityLevel {
  /// 显示名称（中文）
  String get displayName {
    switch (this) {
      case ActivityLevel.sedentary:
        return '久坐';
      case ActivityLevel.lightlyActive:
        return '轻度活跃';
      case ActivityLevel.moderatelyActive:
        return '中度活跃';
      case ActivityLevel.veryActive:
        return '非常活跃';
      case ActivityLevel.extremelyActive:
        return '极度活跃';
    }
  }

  /// 描述文本
  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return '很少或不运动';
      case ActivityLevel.lightlyActive:
        return '每周运动1-3次';
      case ActivityLevel.moderatelyActive:
        return '每周运动3-5次';
      case ActivityLevel.veryActive:
        return '每周运动6-7次';
      case ActivityLevel.extremelyActive:
        return '高强度训练或体力劳动';
    }
  }

  /// 转换为 API 参数值
  String get apiValue {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'sedentary';
      case ActivityLevel.lightlyActive:
        return 'lightly_active';
      case ActivityLevel.moderatelyActive:
        return 'moderately_active';
      case ActivityLevel.veryActive:
        return 'very_active';
      case ActivityLevel.extremelyActive:
        return 'extremely_active';
    }
  }

  /// 从 API 值解析
  static ActivityLevel fromApiValue(String value) {
    switch (value) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'lightly_active':
        return ActivityLevel.lightlyActive;
      case 'moderately_active':
        return ActivityLevel.moderatelyActive;
      case 'very_active':
        return ActivityLevel.veryActive;
      case 'extremely_active':
        return ActivityLevel.extremelyActive;
      default:
        return ActivityLevel.moderatelyActive; // 默认值
    }
  }
}
