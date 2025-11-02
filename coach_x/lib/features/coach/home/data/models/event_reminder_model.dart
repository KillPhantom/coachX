import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

/// Event Reminder类型枚举
enum EventReminderType {
  /// 线下课程
  offlineClass,

  /// 治疗/按摩预约
  therapySession,

  /// 计划截止
  planDeadline,

  /// 学生打卡
  studentCheckIn,

  /// 自定义事件
  custom,
}

/// EventReminderType 扩展方法
extension EventReminderTypeExtension on EventReminderType {
  /// 获取显示名称（中文）
  String get displayName {
    switch (this) {
      case EventReminderType.offlineClass:
        return '线下课程';
      case EventReminderType.therapySession:
        return '治疗预约';
      case EventReminderType.planDeadline:
        return '计划截止';
      case EventReminderType.studentCheckIn:
        return '学生打卡';
      case EventReminderType.custom:
        return '自定义';
    }
  }

  /// 获取对应图标
  IconData get icon {
    switch (this) {
      case EventReminderType.offlineClass:
        return CupertinoIcons.person_2;
      case EventReminderType.therapySession:
        return CupertinoIcons.heart;
      case EventReminderType.planDeadline:
        return CupertinoIcons.alarm;
      case EventReminderType.studentCheckIn:
        return CupertinoIcons.checkmark_circle;
      case EventReminderType.custom:
        return CupertinoIcons.calendar;
    }
  }

  /// 获取字符串值
  String get value {
    switch (this) {
      case EventReminderType.offlineClass:
        return 'offline_class';
      case EventReminderType.therapySession:
        return 'therapy_session';
      case EventReminderType.planDeadline:
        return 'plan_deadline';
      case EventReminderType.studentCheckIn:
        return 'student_checkin';
      case EventReminderType.custom:
        return 'custom';
    }
  }

  /// 从字符串转换为枚举
  static EventReminderType fromString(String value) {
    switch (value) {
      case 'offline_class':
        return EventReminderType.offlineClass;
      case 'therapy_session':
        return EventReminderType.therapySession;
      case 'plan_deadline':
        return EventReminderType.planDeadline;
      case 'student_checkin':
        return EventReminderType.studentCheckIn;
      case 'custom':
        return EventReminderType.custom;
      default:
        return EventReminderType.custom;
    }
  }
}

/// Event Reminder数据模型
///
/// 用于表示教练的事件提醒，包括线下课程、治疗预约等
class EventReminderModel {
  /// 事件ID
  final String id;

  /// 事件类型
  final EventReminderType type;

  /// 事件标题
  final String title;

  /// 事件描述（可选）
  final String? description;

  /// 计划时间
  final DateTime scheduledTime;

  /// 关联学生ID（可选）
  final String? studentId;

  /// 关联学生名称（可选）
  final String? studentName;

  /// 地点（可选）
  final String? location;

  /// 是否已完成
  final bool isCompleted;

  /// 创建时间
  final DateTime createdAt;

  /// 教练ID
  final String coachId;

  const EventReminderModel({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.scheduledTime,
    this.studentId,
    this.studentName,
    this.location,
    required this.isCompleted,
    required this.createdAt,
    required this.coachId,
  });

  /// 从JSON创建
  factory EventReminderModel.fromJson(Map<String, dynamic> json) {
    return EventReminderModel(
      id: json['id'] as String,
      type: EventReminderTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String?,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      studentId: json['studentId'] as String?,
      studentName: json['studentName'] as String?,
      location: json['location'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      coachId: json['coachId'] as String,
    );
  }

  /// 从Firestore Document创建
  factory EventReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventReminderModel(
      id: doc.id,
      type: EventReminderTypeExtension.fromString(data['type'] as String),
      title: data['title'] as String,
      description: data['description'] as String?,
      scheduledTime: (data['scheduledTime'] as Timestamp).toDate(),
      studentId: data['studentId'] as String?,
      studentName: data['studentName'] as String?,
      location: data['location'] as String?,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      coachId: data['coachId'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'studentId': studentId,
      'studentName': studentName,
      'location': location,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'coachId': coachId,
    };
  }

  /// 转换为Firestore数据
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.value,
      'title': title,
      'description': description,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'studentId': studentId,
      'studentName': studentName,
      'location': location,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'coachId': coachId,
    };
  }

  /// 复制并修改
  EventReminderModel copyWith({
    String? id,
    EventReminderType? type,
    String? title,
    String? description,
    DateTime? scheduledTime,
    String? studentId,
    String? studentName,
    String? location,
    bool? isCompleted,
    DateTime? createdAt,
    String? coachId,
  }) {
    return EventReminderModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      coachId: coachId ?? this.coachId,
    );
  }
}
