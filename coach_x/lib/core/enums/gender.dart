/// 性别枚举
enum Gender {
  /// 男性
  male,

  /// 女性
  female,
}

/// Gender 扩展方法
extension GenderExtension on Gender {
  /// 获取英文名称
  String get value {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
    }
  }

  /// 是否为男性
  bool get isMale => this == Gender.male;

  /// 是否为女性
  bool get isFemale => this == Gender.female;

  /// 从字符串转换为枚举
  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        throw ArgumentError('Invalid Gender: $value');
    }
  }
}
