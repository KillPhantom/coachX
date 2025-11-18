import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'exercise_template_model.g.dart';

/// Exercise Template Model - 动作模板
///
/// 教练创建的动作模板，包含指导视频、文字说明、辅助图片等
@HiveType(typeId: 10) // TypeId for Hive adapter
class ExerciseTemplateModel extends HiveObject {
  /// 模板 ID（文档 ID）
  @HiveField(0)
  final String id;

  /// 创建者（教练）ID
  @HiveField(1)
  final String ownerId;

  /// 动作名称
  @HiveField(2)
  final String name;

  /// 标签列表（用户语言版本）
  @HiveField(3)
  final List<String> tags;

  /// 文字说明（可选）
  @HiveField(5)
  final String? textGuidance;

  /// 辅助图片 URLs（最多5张）
  @HiveField(6)
  final List<String> imageUrls;

  /// 创建时间
  @HiveField(7)
  final DateTime createdAt;

  /// 更新时间
  @HiveField(8)
  final DateTime updatedAt;

  /// 指导视频 URLs（多个视频）
  @HiveField(10)
  final List<String> videoUrls;

  /// 视频缩略图 URLs（多个缩略图）
  @HiveField(11)
  final List<String> thumbnailUrls;

  ExerciseTemplateModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.tags,
    this.textGuidance,
    List<String>? imageUrls,
    required this.createdAt,
    required this.updatedAt,
    List<String>? videoUrls,
    List<String>? thumbnailUrls,
  }) : imageUrls = imageUrls ?? [],
       videoUrls = videoUrls ?? [],
       thumbnailUrls = thumbnailUrls ?? [];

  /// 从 Firestore 文档创建模型
  factory ExerciseTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ExerciseTemplateModel(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      name: data['name'] as String,
      tags: List<String>.from(data['tags'] as List),
      textGuidance: data['textGuidance'] as String?,
      imageUrls: List<String>.from(data['imageUrls'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      videoUrls: List<String>.from(data['videoUrls'] as List? ?? []),
      thumbnailUrls: List<String>.from(data['thumbnailUrls'] as List? ?? []),
    );
  }

  /// 转换为 Firestore 数据
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'tags': tags,
      'textGuidance': textGuidance,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'videoUrls': videoUrls,
      'thumbnailUrls': thumbnailUrls,
    };
  }

  /// 创建副本
  ExerciseTemplateModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    List<String>? tags,
    String? textGuidance,
    List<String>? imageUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? videoUrls,
    List<String>? thumbnailUrls,
  }) {
    return ExerciseTemplateModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      textGuidance: textGuidance ?? this.textGuidance,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      videoUrls: videoUrls ?? this.videoUrls,
      thumbnailUrls: thumbnailUrls ?? this.thumbnailUrls,
    );
  }

  @override
  String toString() {
    return 'ExerciseTemplateModel(id: $id, name: $name, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseTemplateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
