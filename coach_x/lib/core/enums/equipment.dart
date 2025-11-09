/// 训练设备枚举
enum Equipment {
  /// 杠铃
  barbell,

  /// 哑铃
  dumbbell,

  /// 固定器械
  machine,

  /// 壶铃
  kettlebell,

  /// 弹力带
  resistanceBand,

  /// 自重
  bodyweight,

  /// 缆绳
  cable,

  /// 史密斯架
  smithMachine,
}

/// Equipment 扩展方法
extension EquipmentExtension on Equipment {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case Equipment.barbell:
        return '杠铃';
      case Equipment.dumbbell:
        return '哑铃';
      case Equipment.machine:
        return '固定器械';
      case Equipment.kettlebell:
        return '壶铃';
      case Equipment.resistanceBand:
        return '弹力带';
      case Equipment.bodyweight:
        return '自重';
      case Equipment.cable:
        return '缆绳';
      case Equipment.smithMachine:
        return '史密斯架';
    }
  }

  /// 获取英文名称
  String get englishName {
    switch (this) {
      case Equipment.barbell:
        return 'Barbell';
      case Equipment.dumbbell:
        return 'Dumbbell';
      case Equipment.machine:
        return 'Machine';
      case Equipment.kettlebell:
        return 'Kettlebell';
      case Equipment.resistanceBand:
        return 'Resistance Band';
      case Equipment.bodyweight:
        return 'Bodyweight';
      case Equipment.cable:
        return 'Cable';
      case Equipment.smithMachine:
        return 'Smith Machine';
    }
  }

  /// 获取图标 emoji
  String get icon {
    switch (this) {
      case Equipment.barbell:
        return '🏋️';
      case Equipment.dumbbell:
        return '💪';
      case Equipment.machine:
        return '🔧';
      case Equipment.kettlebell:
        return '⚖️';
      case Equipment.resistanceBand:
        return '🎗️';
      case Equipment.bodyweight:
        return '🤸';
      case Equipment.cable:
        return '🔗';
      case Equipment.smithMachine:
        return '🏗️';
    }
  }

  /// 获取适用场景
  String get suitableFor {
    switch (this) {
      case Equipment.barbell:
        return '力量训练、复合动作';
      case Equipment.dumbbell:
        return '通用，适合各种训练';
      case Equipment.machine:
        return '初学者、孤立肌群';
      case Equipment.kettlebell:
        return '功能性训练、爆发力';
      case Equipment.resistanceBand:
        return '居家训练、康复';
      case Equipment.bodyweight:
        return '随时随地、入门训练';
      case Equipment.cable:
        return '持续张力、多角度';
      case Equipment.smithMachine:
        return '安全训练、固定轨迹';
    }
  }

  /// 是否需要健身房
  bool get requiresGym {
    switch (this) {
      case Equipment.barbell:
      case Equipment.machine:
      case Equipment.cable:
      case Equipment.smithMachine:
        return true;
      case Equipment.dumbbell:
      case Equipment.kettlebell:
      case Equipment.resistanceBand:
      case Equipment.bodyweight:
        return false;
    }
  }

  /// 转换为 JSON 字符串
  String toJsonString() {
    switch (this) {
      case Equipment.barbell:
        return 'barbell';
      case Equipment.dumbbell:
        return 'dumbbell';
      case Equipment.machine:
        return 'machine';
      case Equipment.kettlebell:
        return 'kettlebell';
      case Equipment.resistanceBand:
        return 'resistance_band';
      case Equipment.bodyweight:
        return 'bodyweight';
      case Equipment.cable:
        return 'cable';
      case Equipment.smithMachine:
        return 'smith_machine';
    }
  }
}

/// 从字符串解析 Equipment
Equipment equipmentFromString(String value) {
  switch (value.toLowerCase()) {
    case 'barbell':
    case '杠铃':
      return Equipment.barbell;
    case 'dumbbell':
    case '哑铃':
      return Equipment.dumbbell;
    case 'machine':
    case '器械':
    case '固定器械':
      return Equipment.machine;
    case 'kettlebell':
    case '壶铃':
      return Equipment.kettlebell;
    case 'resistance_band':
    case 'resistanceband':
    case '弹力带':
      return Equipment.resistanceBand;
    case 'bodyweight':
    case '自重':
      return Equipment.bodyweight;
    case 'cable':
    case '缆绳':
      return Equipment.cable;
    case 'smith_machine':
    case 'smithmachine':
    case '史密斯':
      return Equipment.smithMachine;
    default:
      return Equipment.dumbbell;
  }
}
