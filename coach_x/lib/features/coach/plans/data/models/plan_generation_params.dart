import 'package:coach_x/core/enums/training_goal.dart';
import 'package:coach_x/core/enums/muscle_group.dart';
import 'package:coach_x/core/enums/training_style.dart';
import 'package:coach_x/core/enums/equipment.dart';
import 'package:coach_x/core/enums/training_level.dart';
import 'package:coach_x/core/enums/workload_level.dart';

/// 训练计划生成参数
/// 
/// 用于 AI 引导创建流程，传递给后端的结构化参数
class PlanGenerationParams {
  /// 训练目标
  final TrainingGoal goal;

  /// 目标肌肉群（可多选）
  final List<MuscleGroup> muscleGroups;

  /// 每周训练天数
  final int daysPerWeek;

  /// 每次训练时长（分钟）
  final int durationMinutes;

  /// 训练水平
  final TrainingLevel level;

  /// 训练量
  final WorkloadLevel workload;

  /// 每天动作数（最小值）
  final int exercisesPerDayMin;

  /// 每天动作数（最大值）
  final int exercisesPerDayMax;

  /// 每动作组数（最小值）
  final int setsPerExerciseMin;

  /// 每动作组数（最大值）
  final int setsPerExerciseMax;

  /// 训练风格（可多选）
  final List<TrainingStyle> trainingStyles;

  /// 可用设备（可多选）
  final List<Equipment> equipment;

  /// 补充说明（可选）
  final String? notes;

  /// 语言设置
  final String language;

  const PlanGenerationParams({
    required this.goal,
    required this.muscleGroups,
    required this.daysPerWeek,
    required this.durationMinutes,
    required this.level,
    required this.workload,
    required this.exercisesPerDayMin,
    required this.exercisesPerDayMax,
    required this.setsPerExerciseMin,
    required this.setsPerExerciseMax,
    required this.trainingStyles,
    required this.equipment,
    this.notes,
    this.language = '中文',
  });

  /// 创建默认参数
  factory PlanGenerationParams.initial() {
    return const PlanGenerationParams(
      goal: TrainingGoal.muscleGain,
      muscleGroups: [],
      daysPerWeek: 3,
      durationMinutes: 60,
      level: TrainingLevel.intermediate,
      workload: WorkloadLevel.medium,
      exercisesPerDayMin: 4,
      exercisesPerDayMax: 6,
      setsPerExerciseMin: 3,
      setsPerExerciseMax: 5,
      trainingStyles: [TrainingStyle.pyramid],
      equipment: [Equipment.barbell, Equipment.dumbbell],
      notes: null,
      language: '中文',
    );
  }

  /// 复制并修改部分字段
  PlanGenerationParams copyWith({
    TrainingGoal? goal,
    List<MuscleGroup>? muscleGroups,
    int? daysPerWeek,
    int? durationMinutes,
    TrainingLevel? level,
    WorkloadLevel? workload,
    int? exercisesPerDayMin,
    int? exercisesPerDayMax,
    int? setsPerExerciseMin,
    int? setsPerExerciseMax,
    List<TrainingStyle>? trainingStyles,
    List<Equipment>? equipment,
    String? notes,
    String? language,
  }) {
    return PlanGenerationParams(
      goal: goal ?? this.goal,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      level: level ?? this.level,
      workload: workload ?? this.workload,
      exercisesPerDayMin: exercisesPerDayMin ?? this.exercisesPerDayMin,
      exercisesPerDayMax: exercisesPerDayMax ?? this.exercisesPerDayMax,
      setsPerExerciseMin: setsPerExerciseMin ?? this.setsPerExerciseMin,
      setsPerExerciseMax: setsPerExerciseMax ?? this.setsPerExerciseMax,
      trainingStyles: trainingStyles ?? this.trainingStyles,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      language: language ?? this.language,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'goal': goal.toJsonString(),
      'muscle_groups': muscleGroups.map((g) => g.toJsonString()).toList(),
      'days_per_week': daysPerWeek,
      'duration_minutes': durationMinutes,
      'level': level.toJsonString(),
      'workload': workload.toJsonString(),
      'exercises_per_day_min': exercisesPerDayMin,
      'exercises_per_day_max': exercisesPerDayMax,
      'sets_per_exercise_min': setsPerExerciseMin,
      'sets_per_exercise_max': setsPerExerciseMax,
      'training_styles': trainingStyles.map((s) => s.toJsonString()).toList(),
      'equipment': equipment.map((e) => e.toJsonString()).toList(),
      if (notes != null) 'notes': notes,
      'language': language,
    };
  }

  /// 从 JSON 解析
  factory PlanGenerationParams.fromJson(Map<String, dynamic> json) {
    return PlanGenerationParams(
      goal: trainingGoalFromString(json['goal'] as String),
      muscleGroups: (json['muscle_groups'] as List<dynamic>)
          .map((g) => muscleGroupFromString(g as String))
          .toList(),
      daysPerWeek: json['days_per_week'] as int,
      durationMinutes: json['duration_minutes'] as int,
      level: trainingLevelFromString(json['level'] as String),
      workload: workloadLevelFromString(json['workload'] as String),
      exercisesPerDayMin: json['exercises_per_day_min'] as int,
      exercisesPerDayMax: json['exercises_per_day_max'] as int,
      setsPerExerciseMin: json['sets_per_exercise_min'] as int,
      setsPerExerciseMax: json['sets_per_exercise_max'] as int,
      trainingStyles: (json['training_styles'] as List<dynamic>)
          .map((s) => trainingStyleFromString(s as String))
          .toList(),
      equipment: (json['equipment'] as List<dynamic>)
          .map((e) => equipmentFromString(e as String))
          .toList(),
      notes: json['notes'] as String?,
      language: json['language'] as String? ?? '中文',
    );
  }

  /// 验证参数是否有效
  bool get isValid {
    // 必须选择至少一个肌肉群
    if (muscleGroups.isEmpty) return false;

    // 天数范围验证
    if (daysPerWeek < 1 || daysPerWeek > 7) return false;

    // 时长验证
    if (durationMinutes < 10 || durationMinutes > 180) return false;

    // 动作数范围验证
    if (exercisesPerDayMin > exercisesPerDayMax) return false;
    if (exercisesPerDayMin < 1 || exercisesPerDayMax > 10) return false;

    // 组数范围验证
    if (setsPerExerciseMin > setsPerExerciseMax) return false;
    if (setsPerExerciseMin < 1 || setsPerExerciseMax > 10) return false;

    // 必须选择至少一种训练风格
    if (trainingStyles.isEmpty) return false;

    // 必须选择至少一种设备
    if (equipment.isEmpty) return false;

    return true;
  }

  /// 获取验证错误信息
  List<String> get validationErrors {
    final errors = <String>[];

    if (muscleGroups.isEmpty) {
      errors.add('请至少选择一个训练部位');
    }

    if (daysPerWeek < 1 || daysPerWeek > 7) {
      errors.add('每周训练天数必须在 1-7 之间');
    }

    if (durationMinutes < 10 || durationMinutes > 180) {
      errors.add('每次训练时长必须在 10-180 分钟之间');
    }

    if (exercisesPerDayMin > exercisesPerDayMax) {
      errors.add('动作数最小值不能大于最大值');
    }

    if (setsPerExerciseMin > setsPerExerciseMax) {
      errors.add('组数最小值不能大于最大值');
    }

    if (trainingStyles.isEmpty) {
      errors.add('请至少选择一种训练风格');
    }

    if (equipment.isEmpty) {
      errors.add('请至少选择一种可用设备');
    }

    return errors;
  }

  @override
  String toString() {
    return 'PlanGenerationParams('
        'goal: ${goal.displayName}, '
        'muscleGroups: ${muscleGroups.length}, '
        'days: $daysPerWeek, '
        'duration: ${durationMinutes}min'
        ')';
  }
}

