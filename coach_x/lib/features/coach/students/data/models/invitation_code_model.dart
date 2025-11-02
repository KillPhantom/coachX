import 'package:cloud_firestore/cloud_firestore.dart';

/// 邀请码模型
class InvitationCodeModel {
  final String id;
  final String code;
  final String coachId;
  final int totalDays; // 签约总时长（天数）
  final String note; // 备注
  final bool used;
  final String? usedBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int expiresInDays; // 剩余天数

  const InvitationCodeModel({
    required this.id,
    required this.code,
    required this.coachId,
    required this.totalDays,
    this.note = '',
    this.used = false,
    this.usedBy,
    required this.createdAt,
    required this.expiresAt,
    required this.expiresInDays,
  });

  /// 从JSON创建
  factory InvitationCodeModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic data) {
      if (data is Timestamp) {
        return data.toDate();
      }
      if (data is DateTime) {
        return data;
      }
      return DateTime.now();
    }

    return InvitationCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      coachId: json['coachId'] as String,
      totalDays: json['totalDays'] as int? ?? 180,
      note: json['note'] as String? ?? '',
      used: json['used'] as bool? ?? false,
      usedBy: json['usedBy'] as String?,
      createdAt: parseDate(json['createdAt']),
      expiresAt: parseDate(json['expiresAt']),
      expiresInDays: json['expiresInDays'] as int? ?? 0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'coachId': coachId,
      'totalDays': totalDays,
      'note': note,
      'used': used,
      if (usedBy != null) 'usedBy': usedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'expiresInDays': expiresInDays,
    };
  }

  /// 是否已过期
  bool get isExpired => expiresInDays <= 0;

  /// 是否有效（未使用且未过期）
  bool get isValid => !used && !isExpired;

  /// 状态文本
  String get statusText {
    if (used) return '已使用';
    if (isExpired) return '已过期';
    return '有效';
  }

  /// 复制并修改
  InvitationCodeModel copyWith({
    String? id,
    String? code,
    String? coachId,
    int? totalDays,
    String? note,
    bool? used,
    String? usedBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? expiresInDays,
  }) {
    return InvitationCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      coachId: coachId ?? this.coachId,
      totalDays: totalDays ?? this.totalDays,
      note: note ?? this.note,
      used: used ?? this.used,
      usedBy: usedBy ?? this.usedBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      expiresInDays: expiresInDays ?? this.expiresInDays,
    );
  }
}

