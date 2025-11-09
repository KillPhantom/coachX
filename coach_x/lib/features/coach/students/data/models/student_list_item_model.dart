import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_plan_info.dart';

/// 学生列表项模型
class StudentListItemModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String coachId;
  final StudentPlanInfo? exercisePlan;
  final StudentPlanInfo? dietPlan;
  final StudentPlanInfo? supplementPlan;
  final DateTime? createdAt;

  const StudentListItemModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.coachId,
    this.exercisePlan,
    this.dietPlan,
    this.supplementPlan,
    this.createdAt,
  });

  /// 从JSON创建
  factory StudentListItemModel.fromJson(Map<String, dynamic> json) {
    StudentPlanInfo? parsePlan(dynamic data) {
      if (data == null) return null;
      if (data is! Map<String, dynamic>) {
        if (data is Map) {
          return StudentPlanInfo.fromJson(Map<String, dynamic>.from(data));
        }
        return null;
      }
      return StudentPlanInfo.fromJson(data);
    }

    // 解析createdAt
    DateTime? parseCreatedAt(dynamic data) {
      if (data == null) return null;
      if (data is Timestamp) {
        return data.toDate();
      }
      if (data is String) {
        try {
          return DateTime.parse(data);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return StudentListItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      coachId: json['coachId'] as String,
      exercisePlan: parsePlan(json['exercisePlan']),
      dietPlan: parsePlan(json['dietPlan']),
      supplementPlan: parsePlan(json['supplementPlan']),
      createdAt: parseCreatedAt(json['createdAt']),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'coachId': coachId,
      if (exercisePlan != null) 'exercisePlan': exercisePlan!.toJson(),
      if (dietPlan != null) 'dietPlan': dietPlan!.toJson(),
      if (supplementPlan != null) 'supplementPlan': supplementPlan!.toJson(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  /// 是否有任何计划
  bool get hasAnyPlan =>
      exercisePlan != null || dietPlan != null || supplementPlan != null;

  /// 获取姓名首字母（用于默认头像）
  String get nameInitial {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }

  /// 复制并修改
  StudentListItemModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    String? coachId,
    StudentPlanInfo? exercisePlan,
    StudentPlanInfo? dietPlan,
    StudentPlanInfo? supplementPlan,
    DateTime? createdAt,
  }) {
    return StudentListItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coachId: coachId ?? this.coachId,
      exercisePlan: exercisePlan ?? this.exercisePlan,
      dietPlan: dietPlan ?? this.dietPlan,
      supplementPlan: supplementPlan ?? this.supplementPlan,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
