import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'plan_base_model.dart';
import 'exercise_training_day.dart';

/// 训练计划模型
class ExercisePlanModel extends PlanBaseModel {
  final List<ExerciseTrainingDay> days;

  const ExercisePlanModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.studentIds,
    required super.createdAt,
    required super.updatedAt,
    required this.days,
  });

  @override
  String get planType => 'exercise';

  /// 从JSON创建
  factory ExercisePlanModel.fromJson(Map<String, dynamic> json) {
    final daysData = safeMapListCast(json['days'], 'days');
    final days = daysData
        .map((dayJson) => ExerciseTrainingDay.fromJson(dayJson))
        .toList();

    return ExercisePlanModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      ownerId: json['ownerId'] as String,
      studentIds:
          (json['studentIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: safeIntCast(json['createdAt'], 0, 'createdAt') ?? 0,
      updatedAt: safeIntCast(json['updatedAt'], 0, 'updatedAt') ?? 0,
      days: days,
    );
  }

  /// 从 Firestore 文档创建
  factory ExercisePlanModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return ExercisePlanModel.fromJson(data);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'studentIds': studentIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'days': days.map((day) => day.toJson()).toList(),
    };
  }

  /// 复制并修改部分字段
  ExercisePlanModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<String>? studentIds,
    int? createdAt,
    int? updatedAt,
    List<ExerciseTrainingDay>? days,
  }) {
    return ExercisePlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
    );
  }

  /// 添加训练日
  ExercisePlanModel addDay(ExerciseTrainingDay day) {
    return copyWith(days: [...days, day]);
  }

  /// 删除训练日
  ExercisePlanModel removeDay(int index) {
    if (index < 0 || index >= days.length) return this;
    final newDays = List<ExerciseTrainingDay>.from(days);
    newDays.removeAt(index);
    return copyWith(days: newDays);
  }

  /// 更新训练日
  ExercisePlanModel updateDay(int index, ExerciseTrainingDay day) {
    if (index < 0 || index >= days.length) return this;
    final newDays = List<ExerciseTrainingDay>.from(days);
    newDays[index] = day;
    return copyWith(days: newDays);
  }

  /// 获取训练日总数
  int get totalDays => days.length;

  /// 获取所有动作总数
  int get totalExercises =>
      days.fold(0, (sum, day) => sum + day.totalExercises);

  /// 获取所有 Sets 总数
  int get totalSets => days.fold(0, (sum, day) => sum + day.totalSets);
}
