import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/enums/user_role.dart';
import 'package:coach_x/core/enums/gender.dart';

/// 用户数据模型
class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final Gender? gender;
  final String? coachId; // 学生的教练ID
  final DateTime? bornDate;
  final double? height; // 单位: cm
  final double? initialWeight; // 单位: kg
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Profile 页面新增字段
  final List<String>? tags; // 认证标签，如 ["IFFF Pro", "Certified"]
  final DateTime? contractExpiresAt; // 学生与教练的合约有效期
  final String? subscriptionPlan; // 订阅计划: 'free' | 'pro'
  final DateTime? subscriptionRenewsAt; // 订阅续费日期
  final bool notificationsEnabled; // 是否启用通知
  final String? unitPreference; // 单位偏好: 'metric' | 'imperial'
  final String? languageCode; // 语言偏好: 'en' | 'zh'

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.gender,
    this.coachId,
    this.bornDate,
    this.height,
    this.initialWeight,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
    this.tags,
    this.contractExpiresAt,
    this.subscriptionPlan,
    this.subscriptionRenewsAt,
    this.notificationsEnabled = true,
    this.unitPreference,
    this.languageCode,
  });

  /// 从Firestore文档创建
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception('用户文档数据为空');
    }

    // 解析bornDate (string格式 "yyyy-MM-dd" 转为DateTime)
    DateTime? parsedBornDate;
    if (data['bornDate'] != null && data['bornDate'] is String) {
      try {
        parsedBornDate = DateTime.parse(data['bornDate'] as String);
      } catch (e) {
        // 解析失败则为null
        parsedBornDate = null;
      }
    }

    // 解析gender
    Gender? parsedGender;
    if (data['gender'] != null && data['gender'] is String) {
      try {
        parsedGender = GenderExtension.fromString(data['gender'] as String);
      } catch (e) {
        // 解析失败则为null
        parsedGender = null;
      }
    }

    // 解析 tags
    List<String>? parsedTags;
    if (data['tags'] != null && data['tags'] is List) {
      parsedTags = (data['tags'] as List).map((e) => e.toString()).toList();
    }

    return UserModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: UserRoleExtension.fromString(data['role'] as String? ?? 'student'),
      avatarUrl: data['avatarUrl'] as String?,
      gender: parsedGender,
      coachId: data['coachId'] as String?,
      bornDate: parsedBornDate,
      height: (data['height'] as num?)?.toDouble(),
      initialWeight: (data['initialWeight'] as num?)?.toDouble(),
      isVerified: data['isVerified'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      tags: parsedTags,
      contractExpiresAt: (data['contractExpiresAt'] as Timestamp?)?.toDate(),
      subscriptionPlan: data['subscriptionPlan'] as String?,
      subscriptionRenewsAt: (data['subscriptionRenewsAt'] as Timestamp?)?.toDate(),
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      unitPreference: data['unitPreference'] as String?,
      languageCode: data['languageCode'] as String?,
    );
  }

  /// 转换为Firestore文档数据
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.value,
      'isVerified': isVerified,
      'notificationsEnabled': notificationsEnabled,
      if (unitPreference != null) 'unitPreference': unitPreference,
      if (languageCode != null) 'languageCode': languageCode,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (gender != null) 'gender': gender!.value,
      if (coachId != null) 'coachId': coachId,
      if (bornDate != null) 'bornDate': _formatDate(bornDate!),
      if (height != null) 'height': height,
      if (initialWeight != null) 'initialWeight': initialWeight,
      if (tags != null) 'tags': tags,
      if (contractExpiresAt != null) 'contractExpiresAt': contractExpiresAt,
      if (subscriptionPlan != null) 'subscriptionPlan': subscriptionPlan,
      if (subscriptionRenewsAt != null) 'subscriptionRenewsAt': subscriptionRenewsAt,
      // createdAt和updatedAt由FirestoreService自动管理
    };
  }

  /// 格式化日期为字符串 "yyyy-MM-dd"
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 复制并更新部分字段
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? avatarUrl,
    Gender? gender,
    String? coachId,
    DateTime? bornDate,
    double? height,
    double? initialWeight,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    DateTime? contractExpiresAt,
    String? subscriptionPlan,
    DateTime? subscriptionRenewsAt,
    bool? notificationsEnabled,
    String? unitPreference,
    String? languageCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      coachId: coachId ?? this.coachId,
      bornDate: bornDate ?? this.bornDate,
      height: height ?? this.height,
      initialWeight: initialWeight ?? this.initialWeight,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      contractExpiresAt: contractExpiresAt ?? this.contractExpiresAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionRenewsAt: subscriptionRenewsAt ?? this.subscriptionRenewsAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      unitPreference: unitPreference ?? this.unitPreference,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role, gender: $gender)';
  }
}
