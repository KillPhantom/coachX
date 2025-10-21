import 'package:intl/intl.dart';

/// Recent Activity数据模型
///
/// 用于表示学生的最近活跃记录
class RecentActivityModel {
  /// 学生ID
  final String studentId;

  /// 学生姓名
  final String studentName;

  /// 头像URL
  final String? avatarUrl;

  /// 最后活跃时间
  final DateTime lastActiveTime;

  /// 活动类型（训练/打卡/消息等）
  final String? activityType;

  /// 活动描述
  final String? activityDescription;

  const RecentActivityModel({
    required this.studentId,
    required this.studentName,
    this.avatarUrl,
    required this.lastActiveTime,
    this.activityType,
    this.activityDescription,
  });

  /// 从JSON创建
  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      lastActiveTime: DateTime.parse(json['lastActiveTime'] as String),
      activityType: json['activityType'] as String?,
      activityDescription: json['activityDescription'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'avatarUrl': avatarUrl,
      'lastActiveTime': lastActiveTime.toIso8601String(),
      'activityType': activityType,
      'activityDescription': activityDescription,
    };
  }

  /// 获取相对时间文本
  ///
  /// 返回格式:
  /// - 今天 2小时前 → "10:30 AM"
  /// - 昨天 → "Yesterday"
  /// - 2天前 → "2 days ago"
  /// - 7天前 → "Oct 14"
  /// - 1年前 → "Oct 14, 2024"
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastActiveTime);

    // 今天：显示具体时间
    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(lastActiveTime);
    }

    // 昨天
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    // 2-6天前
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    // 7天-1年：显示月日
    if (difference.inDays < 365) {
      return DateFormat('MMM dd').format(lastActiveTime);
    }

    // 超过1年：显示月日年
    return DateFormat('MMM dd, yyyy').format(lastActiveTime);
  }

  /// 复制并修改
  RecentActivityModel copyWith({
    String? studentId,
    String? studentName,
    String? avatarUrl,
    DateTime? lastActiveTime,
    String? activityType,
    String? activityDescription,
  }) {
    return RecentActivityModel(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastActiveTime: lastActiveTime ?? this.lastActiveTime,
      activityType: activityType ?? this.activityType,
      activityDescription: activityDescription ?? this.activityDescription,
    );
  }
}
