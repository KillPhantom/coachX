import 'package:coach_x/core/utils/json_utils.dart';

/// 身体测量记录模型
///
/// 对应后端 bodyMeasure 集合
class BodyMeasurementModel {
  /// 记录ID
  final String id;

  /// 学生ID
  final String studentId;

  /// 记录日期 (ISO 8601格式，如 "2025-11-05")
  final String recordDate;

  /// 创建时间戳（毫秒）
  final int createdAt;

  /// 体重值
  final double weight;

  /// 体重单位 ('kg' 或 'lbs')
  final String weightUnit;

  /// 体脂率 (可选, 0-100)
  final double? bodyFat;

  /// 照片URL列表（最多3个）
  final List<String> photos;

  const BodyMeasurementModel({
    required this.id,
    required this.studentId,
    required this.recordDate,
    required this.createdAt,
    required this.weight,
    required this.weightUnit,
    this.bodyFat,
    this.photos = const [],
  });

  /// 从 JSON 创建
  factory BodyMeasurementModel.fromJson(Map<String, dynamic> json) {
    return BodyMeasurementModel(
      id: json['id'] as String? ?? '',
      studentId: json['studentID'] as String? ?? '',
      recordDate: json['recordDate'] as String? ?? '',
      createdAt: safeIntCast(json['createdAt'], 0, 'createdAt') ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      bodyFat: json['bodyFat'] != null
          ? (json['bodyFat'] as num).toDouble()
          : null,
      photos: safeStringListCast(json['photos'], 'photos'),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentID': studentId,
      'recordDate': recordDate,
      'createdAt': createdAt,
      'weight': weight,
      'weightUnit': weightUnit,
      'bodyFat': bodyFat,
      'photos': photos,
    };
  }

  /// 复制并修改部分字段
  BodyMeasurementModel copyWith({
    String? id,
    String? studentId,
    String? recordDate,
    int? createdAt,
    double? weight,
    String? weightUnit,
    double? bodyFat,
    List<String>? photos,
  }) {
    return BodyMeasurementModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      bodyFat: bodyFat ?? this.bodyFat,
      photos: photos ?? this.photos,
    );
  }

  /// 单位转换辅助方法
  ///
  /// 将体重转换为指定单位
  /// - kg to lbs: × 2.20462
  /// - lbs to kg: ÷ 2.20462
  double getWeightInUnit(String targetUnit) {
    if (weightUnit == targetUnit) {
      return weight;
    }

    if (targetUnit == 'kg') {
      // lbs to kg
      return weight / 2.20462;
    } else {
      // kg to lbs
      return weight * 2.20462;
    }
  }

  @override
  String toString() {
    return 'BodyMeasurementModel(id: $id, date: $recordDate, weight: $weight$weightUnit, bodyFat: $bodyFat%, photos: ${photos.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BodyMeasurementModel &&
        other.id == id &&
        other.studentId == studentId &&
        other.recordDate == recordDate &&
        other.createdAt == createdAt &&
        other.weight == weight &&
        other.weightUnit == weightUnit &&
        other.bodyFat == bodyFat &&
        _listEquals(other.photos, photos);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      studentId,
      recordDate,
      createdAt,
      weight,
      weightUnit,
      bodyFat,
      Object.hashAll(photos),
    );
  }

  /// 列表比较辅助方法
  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
