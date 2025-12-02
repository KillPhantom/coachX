/// Coach Summary数据模型
///
/// 用于表示教练首页的统计信息
class CoachSummaryModel {
  /// 本周学生打卡次数（最近7天）
  final int studentCheckInsLast7Days;

  /// 未读消息数
  final int unreadMessages;

  /// 待审核训练记录数
  final int unreviewedTrainings;

  /// 最后更新时间
  final DateTime lastUpdated;

  const CoachSummaryModel({
    required this.studentCheckInsLast7Days,
    required this.unreadMessages,
    required this.unreviewedTrainings,
    required this.lastUpdated,
  });

  /// 从JSON创建
  factory CoachSummaryModel.fromJson(Map<String, dynamic> json) {
    return CoachSummaryModel(
      studentCheckInsLast7Days: json['studentCheckInsLast7Days'] as int,
      unreadMessages: json['unreadMessages'] as int,
      unreviewedTrainings: json['unreviewedTrainings'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'studentCheckInsLast7Days': studentCheckInsLast7Days,
      'unreadMessages': unreadMessages,
      'unreviewedTrainings': unreviewedTrainings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 复制并修改
  CoachSummaryModel copyWith({
    int? studentCheckInsLast7Days,
    int? unreadMessages,
    int? unreviewedTrainings,
    DateTime? lastUpdated,
  }) {
    return CoachSummaryModel(
      studentCheckInsLast7Days:
          studentCheckInsLast7Days ?? this.studentCheckInsLast7Days,
      unreadMessages: unreadMessages ?? this.unreadMessages,
      unreviewedTrainings: unreviewedTrainings ?? this.unreviewedTrainings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
