import 'package:cloud_firestore/cloud_firestore.dart';

/// 用户角色枚举
enum UserRole {
  student,
  coach,
  unknown;

  static UserRole fromString(String? value) {
    switch (value) {
      case 'student':
        return UserRole.student;
      case 'coach':
        return UserRole.coach;
      default:
        return UserRole.unknown;
    }
  }

  String toStringValue() {
    return name;
  }
}

/// 用户数据模型
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final String? coachId; // 学生的教练ID
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.coachId,
    this.createdAt,
    this.updatedAt,
  });

  /// 从Firestore文档创建
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('用户文档数据为空');
    }

    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      avatarUrl: data['avatarUrl'] as String?,
      coachId: data['coachId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 转换为Firestore文档数据
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toStringValue(),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (coachId != null) 'coachId': coachId,
      // createdAt和updatedAt由FirestoreService自动管理
    };
  }

  /// 复制并更新部分字段
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? avatarUrl,
    String? coachId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coachId: coachId ?? this.coachId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role)';
  }
}
