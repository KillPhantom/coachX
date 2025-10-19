/// 用户角色枚举
enum UserRole {
  /// 学生
  student,

  /// 教练
  coach,
}

/// UserRole 扩展方法
extension UserRoleExtension on UserRole {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case UserRole.student:
        return '学生';
      case UserRole.coach:
        return '教练';
    }
  }

  /// 获取英文名称
  String get value {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.coach:
        return 'coach';
    }
  }

  /// 是否为学生
  bool get isStudent => this == UserRole.student;

  /// 是否为教练
  bool get isCoach => this == UserRole.coach;

  /// 从字符串转换为枚举
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'student':
        return UserRole.student;
      case 'coach':
        return UserRole.coach;
      default:
        throw ArgumentError('Invalid UserRole: $value');
    }
  }
}
