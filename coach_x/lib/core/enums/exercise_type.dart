import 'package:flutter/cupertino.dart';

/// 运动类型枚举
enum ExerciseType {
  /// 力量训练
  strength,

  /// 有氧训练
  cardio,
}

/// ExerciseType 扩展方法
extension ExerciseTypeExtension on ExerciseType {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case ExerciseType.strength:
        return '力量训练';
      case ExerciseType.cardio:
        return '有氧训练';
    }
  }

  /// 获取英文名称
  String get englishName {
    switch (this) {
      case ExerciseType.strength:
        return 'Strength';
      case ExerciseType.cardio:
        return 'Cardio';
    }
  }

  /// 获取图标
  IconData get icon {
    switch (this) {
      case ExerciseType.strength:
        return CupertinoIcons.flame_fill;
      case ExerciseType.cardio:
        return CupertinoIcons.heart_fill;
    }
  }

  /// 转换为字符串（用于JSON序列化）
  String toJsonString() {
    return englishName.toLowerCase();
  }
}

/// 从字符串解析 ExerciseType
ExerciseType exerciseTypeFromString(String value) {
  switch (value.toLowerCase()) {
    case 'strength':
      return ExerciseType.strength;
    case 'cardio':
      return ExerciseType.cardio;
    default:
      return ExerciseType.strength; // 默认力量训练
  }
}


