/// Coach Summary数据模型
///
/// 用于表示教练首页的统计信息
class CoachSummaryModel {
  /// 今日完成训练的学生数
  final int studentsCompletedToday;

  /// 总学生数
  final int totalStudents;

  /// 未读消息数
  final int unreadMessages;

  /// 待审核训练记录数
  final int unreviewedTrainings;

  /// 最后更新时间
  final DateTime lastUpdated;

  const CoachSummaryModel({
    required this.studentsCompletedToday,
    required this.totalStudents,
    required this.unreadMessages,
    required this.unreviewedTrainings,
    required this.lastUpdated,
  });

  /// 从JSON创建
  factory CoachSummaryModel.fromJson(Map<String, dynamic> json) {
    return CoachSummaryModel(
      studentsCompletedToday: json['studentsCompletedToday'] as int,
      totalStudents: json['totalStudents'] as int,
      unreadMessages: json['unreadMessages'] as int,
      unreviewedTrainings: json['unreviewedTrainings'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'studentsCompletedToday': studentsCompletedToday,
      'totalStudents': totalStudents,
      'unreadMessages': unreadMessages,
      'unreviewedTrainings': unreviewedTrainings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 获取完成率文本
  ///
  /// 例如: "15/25"
  String get completionRate {
    return '$studentsCompletedToday/$totalStudents';
  }

  /// 获取完成率百分比
  ///
  /// 例如: 0.6 (60%)
  double get completionPercentage {
    if (totalStudents == 0) return 0.0;
    return studentsCompletedToday / totalStudents;
  }

  /// 复制并修改
  CoachSummaryModel copyWith({
    int? studentsCompletedToday,
    int? totalStudents,
    int? unreadMessages,
    int? unreviewedTrainings,
    DateTime? lastUpdated,
  }) {
    return CoachSummaryModel(
      studentsCompletedToday:
          studentsCompletedToday ?? this.studentsCompletedToday,
      totalStudents: totalStudents ?? this.totalStudents,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      unreviewedTrainings: unreviewedTrainings ?? this.unreviewedTrainings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
