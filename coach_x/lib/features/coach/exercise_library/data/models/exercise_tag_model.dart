import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'exercise_tag_model.g.dart';

/// Exercise Tag Model - 动作标签
///
/// 用于分类和筛选动作的标签（预设 + 自定义）
@HiveType(typeId: 11) // TypeId for Hive adapter
class ExerciseTagModel extends HiveObject {
  /// 标签 ID（文档 ID）
  @HiveField(0)
  final String id;

  /// 标签名称（用户语言版本）
  @HiveField(1)
  final String name;

  /// 创建时间
  @HiveField(2)
  final DateTime createdAt;

  ExerciseTagModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  /// 从 Firestore 文档创建模型
  factory ExerciseTagModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseTagModel(
      id: doc.id,
      name: data['name'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// 转换为 Firestore 数据
  Map<String, dynamic> toFirestore() {
    return {'name': name, 'createdAt': Timestamp.fromDate(createdAt)};
  }

  /// 创建副本
  ExerciseTagModel copyWith({String? id, String? name, DateTime? createdAt}) {
    return ExerciseTagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ExerciseTagModel(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseTagModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
