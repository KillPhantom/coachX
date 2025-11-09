/// 肌肉群枚举
enum MuscleGroup {
  /// 胸部
  chest,

  /// 背部
  back,

  /// 腿部
  leg,

  /// 肩部
  shoulder,

  /// 手臂
  arm,

  /// 臀部
  glute,

  /// 小腿
  calf,

  /// 腹部
  abs,

  /// 核心
  core,

  /// 全身
  fullBody,
}

/// MuscleGroup 扩展方法
extension MuscleGroupExtension on MuscleGroup {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return '胸部';
      case MuscleGroup.back:
        return '背部';
      case MuscleGroup.leg:
        return '腿部';
      case MuscleGroup.shoulder:
        return '肩部';
      case MuscleGroup.arm:
        return '手臂';
      case MuscleGroup.glute:
        return '臀部';
      case MuscleGroup.calf:
        return '小腿';
      case MuscleGroup.abs:
        return '腹部';
      case MuscleGroup.core:
        return '核心';
      case MuscleGroup.fullBody:
        return '全身';
    }
  }

  /// 获取英文名称
  String get englishName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.leg:
        return 'Leg';
      case MuscleGroup.shoulder:
        return 'Shoulder';
      case MuscleGroup.arm:
        return 'Arm';
      case MuscleGroup.glute:
        return 'Glute';
      case MuscleGroup.calf:
        return 'Calf';
      case MuscleGroup.abs:
        return 'Abs';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }

  /// 获取训练日类型名称
  String get dayTypeName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest Day';
      case MuscleGroup.back:
        return 'Back Day';
      case MuscleGroup.leg:
        return 'Leg Day';
      case MuscleGroup.shoulder:
        return 'Shoulder Day';
      case MuscleGroup.arm:
        return 'Arm Day';
      case MuscleGroup.glute:
        return 'Glute Day';
      case MuscleGroup.calf:
        return 'Calf Day';
      case MuscleGroup.abs:
        return 'Abs Day';
      case MuscleGroup.core:
        return 'Core Day';
      case MuscleGroup.fullBody:
        return 'Full Body';
    }
  }

  /// 判断是否为上肢
  bool get isUpperBody {
    return this == MuscleGroup.chest ||
        this == MuscleGroup.back ||
        this == MuscleGroup.shoulder ||
        this == MuscleGroup.arm;
  }

  /// 判断是否为下肢
  bool get isLowerBody {
    return this == MuscleGroup.leg ||
        this == MuscleGroup.glute ||
        this == MuscleGroup.calf;
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    switch (this) {
      case MuscleGroup.chest:
        return 'chest';
      case MuscleGroup.back:
        return 'back';
      case MuscleGroup.leg:
        return 'leg';
      case MuscleGroup.shoulder:
        return 'shoulder';
      case MuscleGroup.arm:
        return 'arm';
      case MuscleGroup.glute:
        return 'glute';
      case MuscleGroup.calf:
        return 'calf';
      case MuscleGroup.abs:
        return 'abs';
      case MuscleGroup.core:
        return 'core';
      case MuscleGroup.fullBody:
        return 'full_body';
    }
  }
}

/// 从字符串解析 MuscleGroup
MuscleGroup muscleGroupFromString(String value) {
  switch (value.toLowerCase()) {
    case 'chest':
    case '胸':
    case '胸部':
      return MuscleGroup.chest;
    case 'back':
    case '背':
    case '背部':
      return MuscleGroup.back;
    case 'leg':
    case '腿':
    case '腿部':
      return MuscleGroup.leg;
    case 'shoulder':
    case '肩':
    case '肩部':
      return MuscleGroup.shoulder;
    case 'arm':
    case '手臂':
      return MuscleGroup.arm;
    case 'glute':
    case '臀':
    case '臀部':
      return MuscleGroup.glute;
    case 'calf':
    case '小腿':
      return MuscleGroup.calf;
    case 'abs':
    case '腹':
    case '腹部':
      return MuscleGroup.abs;
    case 'core':
    case '核心':
      return MuscleGroup.core;
    case 'full_body':
    case 'fullbody':
    case '全身':
      return MuscleGroup.fullBody;
    default:
      return MuscleGroup.chest;
  }
}
