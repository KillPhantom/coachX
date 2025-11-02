import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/enums/exercise_type.dart';
import 'package:coach_x/features/coach/plans/data/models/suggestion_review_state.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_training_day.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise.dart';
import 'package:coach_x/features/coach/plans/data/models/training_set.dart';

/// Suggestion Review Mode 状态管理
class SuggestionReviewNotifier extends StateNotifier<SuggestionReviewState?> {
  SuggestionReviewNotifier() : super(null);

  /// 开始 Review Mode
  void startReview(PlanEditSuggestion suggestion, ExercisePlanModel originalPlan) {
    AppLogger.info('🔍 开始 Review Mode - ${suggestion.changes.length} 处修改');

    state = SuggestionReviewState.initial(
      changes: suggestion.changes,
      originalPlan: originalPlan,
    );
  }

  /// 接受当前修改
  Future<void> acceptCurrent() async {
    if (state == null || state!.currentChange == null) {
      AppLogger.warning('⚠️ 无当前修改可接受');
      return;
    }

    final change = state!.currentChange!;
    AppLogger.info('✅ 接受修改: ${change.id} - ${change.description}');

    try {
      // 应用修改到 workingPlan
      final updatedPlan = _applySingleChange(state!.workingPlan, change);

      // 更新状态
      state = state!.acceptCurrentAndMoveNext(updatedPlan);
    } catch (e, stackTrace) {
      AppLogger.error('❌ 应用修改失败', e, stackTrace);
    }
  }

  /// 拒绝当前修改
  void rejectCurrent() {
    if (state == null || state!.currentChange == null) {
      AppLogger.warning('⚠️ 无当前修改可拒绝');
      return;
    }

    final change = state!.currentChange!;
    AppLogger.info('❌ 拒绝修改: ${change.id} - ${change.description}');

    state = state!.rejectCurrentAndMoveNext();
  }

  /// 移动到下一个
  void moveNext() {
    if (state == null) return;
    state = state!.moveNext();
  }

  /// 移动到上一个
  void movePrevious() {
    if (state == null) return;
    state = state!.movePrevious();
  }

  /// 接受所有剩余修改
  Future<void> acceptAll() async {
    if (state == null) return;

    AppLogger.info('✅ 接受所有剩余修改');

    // 逐个应用所有未处理的修改
    ExercisePlanModel workingPlan = state!.workingPlan;
    for (final change in state!.allChanges) {
      if (!state!.acceptedIds.contains(change.id) &&
          !state!.rejectedIds.contains(change.id)) {
        try {
          workingPlan = _applySingleChange(workingPlan, change);
        } catch (e) {
          AppLogger.error('❌ 应用修改失败: ${change.id}', e);
        }
      }
    }

    // 更新状态
    state = state!.acceptAllRemaining().copyWith(workingPlan: workingPlan);
  }

  /// 拒绝所有剩余修改
  void rejectAll() {
    if (state == null) return;

    AppLogger.info('❌ 拒绝所有剩余修改');
    state = state!.rejectAllRemaining();
  }

  /// 结束 Review Mode 并返回最终计划
  ExercisePlanModel? finishReview() {
    if (state == null) return null;

    AppLogger.info(
      '🏁 完成 Review - 接受: ${state!.acceptedCount}, 拒绝: ${state!.rejectedCount}',
    );

    final finalPlan = state!.workingPlan;
    state = null; // 清除状态
    return finalPlan;
  }

  /// 取消 Review Mode
  void cancelReview() {
    AppLogger.info('🚫 取消 Review Mode');
    state = null;
  }

  /// 切换显示全部改动
  void toggleShowAllChanges() {
    if (state == null) return;

    final newValue = !state!.isShowingAllChanges;
    AppLogger.debug('🔄 切换显示全部改动: $newValue');

    state = state!.copyWith(isShowingAllChanges: newValue);
  }

  /// 应用单个修改到计划（核心逻辑）
  ExercisePlanModel _applySingleChange(
    ExercisePlanModel plan,
    PlanChange change,
  ) {
    AppLogger.debug('📝 应用修改: ${change.type.name} at day ${change.dayIndex}');

    switch (change.type) {
      case ChangeType.modifyExercise:
        return _modifyExercise(plan, change);
      case ChangeType.addExercise:
        return _addExercise(plan, change);
      case ChangeType.removeExercise:
        return _removeExercise(plan, change);
      case ChangeType.modifyExerciseSets:
        return _modifyExerciseSets(plan, change);
      case ChangeType.addDay:
        return _addDay(plan, change);
      case ChangeType.removeDay:
        return _removeDay(plan, change);
      case ChangeType.modifyDayName:
        return _modifyDayName(plan, change);
      case ChangeType.adjustIntensity:
        return _adjustIntensity(plan, change);
      case ChangeType.reorder:
      case ChangeType.other:
        AppLogger.warning('⚠️ 暂不支持的修改类型: ${change.type.name}');
        return plan;
    }
  }

  /// 修改动作
  ExercisePlanModel _modifyExercise(ExercisePlanModel plan, PlanChange change) {
    if (change.exerciseIndex == null) return plan;

    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (change.dayIndex >= days.length) return plan;

    final day = days[change.dayIndex];
    final exercises = List<Exercise>.from(day.exercises);
    if (change.exerciseIndex! >= exercises.length) return plan;

    final currentExercise = exercises[change.exerciseIndex!];
    final modifications = _parseExerciseModification(change.after, currentExercise);

    // 解析 sets（如果有）
    List<TrainingSet>? newSets;
    if (modifications.containsKey('sets')) {
      final setsData = modifications['sets'];
      if (setsData is List) {
        newSets = setsData
            .map((setJson) => TrainingSet.fromJson(setJson as Map<String, dynamic>))
            .toList();
      } else if (setsData is String) {
        newSets = _parseSetsData(setsData);
      }
    }

    exercises[change.exerciseIndex!] = currentExercise.copyWith(
      name: modifications['name'] as String?,
      note: modifications['note'] as String?,
      type: modifications['type'] as ExerciseType?,
      sets: newSets,
    );

    days[change.dayIndex] = day.copyWith(exercises: exercises);
    return plan.copyWith(days: days);
  }

  /// 添加动作
  ExercisePlanModel _addExercise(ExercisePlanModel plan, PlanChange change) {
    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (change.dayIndex >= days.length) return plan;

    final day = days[change.dayIndex];
    final exercises = List<Exercise>.from(day.exercises);

    // 解析完整的动作数据
    final newExercise = _parseCompleteExercise(change.after);

    // 根据 exerciseIndex 决定插入位置
    if (change.exerciseIndex != null &&
        change.exerciseIndex! >= 0 &&
        change.exerciseIndex! <= exercises.length) {
      exercises.insert(change.exerciseIndex!, newExercise);
    } else {
      exercises.add(newExercise);
    }

    days[change.dayIndex] = day.copyWith(exercises: exercises);
    return plan.copyWith(days: days);
  }

  /// 删除动作
  ExercisePlanModel _removeExercise(ExercisePlanModel plan, PlanChange change) {
    if (change.exerciseIndex == null) return plan;

    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (change.dayIndex >= days.length) return plan;

    final day = days[change.dayIndex];
    final exercises = List<Exercise>.from(day.exercises);
    if (change.exerciseIndex! >= exercises.length) return plan;

    exercises.removeAt(change.exerciseIndex!);
    days[change.dayIndex] = day.copyWith(exercises: exercises);
    return plan.copyWith(days: days);
  }

  /// 修改动作的训练组（exercise-level）
  ExercisePlanModel _modifyExerciseSets(ExercisePlanModel plan, PlanChange change) {
    if (change.exerciseIndex == null) return plan;

    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (change.dayIndex >= days.length) return plan;

    final day = days[change.dayIndex];
    final exercises = List<Exercise>.from(day.exercises);
    if (change.exerciseIndex! >= exercises.length) return plan;

    final exercise = exercises[change.exerciseIndex!];

    // change.after 应该是 List<Map<String, String>>
    final afterData = change.after;
    if (afterData is! List) {
      AppLogger.warning('⚠️ modifyExerciseSets 需要数组类型的 after，但得到了 ${afterData.runtimeType}');
      return plan;
    }

    // 解析 sets 数组
    final newSets = <TrainingSet>[];
    for (final setData in afterData) {
      if (setData is Map) {
        final reps = setData['reps']?.toString() ?? '10';
        final weight = setData['weight']?.toString() ?? '0kg';
        newSets.add(TrainingSet(reps: reps, weight: weight));
      }
    }

    if (newSets.isEmpty) {
      AppLogger.warning('⚠️ 解析 sets 数据失败，保留原始数据');
      return plan;
    }

    exercises[change.exerciseIndex!] = exercise.copyWith(sets: newSets);
    days[change.dayIndex] = day.copyWith(exercises: exercises);
    return plan.copyWith(days: days);
  }

  /// 添加训练日
  ExercisePlanModel _addDay(ExercisePlanModel plan, PlanChange change) {
    final days = List<ExerciseTrainingDay>.from(plan.days);

    // 解析完整的训练日数据
    final newDay = _parseCompleteDay(change.after, days.length + 1);

    days.add(newDay);
    return plan.copyWith(days: days);
  }

  /// 删除训练日
  ExercisePlanModel _removeDay(ExercisePlanModel plan, PlanChange change) {
    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (change.dayIndex >= days.length) return plan;

    days.removeAt(change.dayIndex);
    return plan.copyWith(days: days);
  }

  /// 修改训练日名称
  ExercisePlanModel _modifyDayName(ExercisePlanModel plan, PlanChange change) {
    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (change.dayIndex >= days.length) return plan;

    days[change.dayIndex] = days[change.dayIndex].copyWith(
      name: change.after ?? days[change.dayIndex].name,
    );
    return plan.copyWith(days: days);
  }

  /// 调整强度
  ExercisePlanModel _adjustIntensity(ExercisePlanModel plan, PlanChange change) {
    final adjustment = _parseIntensityAdjustment(
      change.after ?? change.description,
    );

    if (adjustment == null) {
      AppLogger.warning('⚠️ 无法解析强度调整: ${change.after}');
      return plan;
    }

    // 根据 target 确定调整范围
    if (change.exerciseIndex != null) {
      // 调整单个动作
      return _adjustExerciseIntensity(plan, change, adjustment);
    } else if (change.target.startsWith('day_')) {
      // 调整整天
      return _adjustDayIntensity(plan, change.dayIndex, adjustment);
    } else {
      // 调整整个计划
      return _adjustPlanIntensity(plan, adjustment);
    }
  }

  // ==================== Helper Methods ====================

  /// 解析单组数据
  /// 支持格式: "10 reps at 60kg", "10@60kg", "10 reps, 60kg"
  TrainingSet? _parseSingleSetData(String data) {
    try {
      final trimmed = data.trim();

      // 尝试 JSON 格式
      if (trimmed.startsWith('{')) {
        final json = Map<String, dynamic>.from(
          const JsonDecoder().convert(trimmed) as Map,
        );
        return TrainingSet.fromJson(json);
      }

      // 正则匹配: "10 reps at 60kg" 或 "10@60kg"
      final pattern = RegExp(
        r'(\d+(?:-\d+)?)\s*(?:reps?|次)?\s*[@,at\s]+\s*(.+)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(trimmed);

      if (match != null) {
        return TrainingSet(
          reps: match.group(1) ?? '',
          weight: match.group(2)?.trim() ?? '',
        );
      }

      // 如果只有数字，假设是 reps
      if (RegExp(r'^\d+$').hasMatch(trimmed)) {
        return TrainingSet(reps: trimmed, weight: '');
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ 解析单组数据失败', e);
      return null;
    }
  }

  /// 解析完整的 sets 数据
  /// 支持格式:
  /// - JSON 数组: [{"reps": "10", "weight": "60kg"}, ...]
  /// - 简单格式: "3×10@60kg" 或 "3 sets of 10 reps at 60kg"
  List<TrainingSet> _parseSetsData(String? data) {
    if (data == null || data.isEmpty) return [];

    try {
      final trimmed = data.trim();

      // 1. 尝试 JSON 数组格式
      if (trimmed.startsWith('[')) {
        final jsonList = const JsonDecoder().convert(trimmed) as List;
        return jsonList
            .map((json) => TrainingSet.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // 2. 尝试 "3×10@60kg" 或 "3 sets of 10 at 60kg" 格式
      final multiSetPattern = RegExp(
        r'(\d+)\s*[×x]\s*(\d+(?:-\d+)?)\s*[@at\s]+\s*(.+)',
        caseSensitive: false,
      );
      final multiMatch = multiSetPattern.firstMatch(trimmed);

      if (multiMatch != null) {
        final setCount = int.tryParse(multiMatch.group(1) ?? '0') ?? 0;
        final reps = multiMatch.group(2) ?? '';
        final weight = multiMatch.group(3)?.trim() ?? '';

        return List.generate(
          setCount,
          (_) => TrainingSet(reps: reps, weight: weight),
        );
      }

      // 3. 尝试 "3 sets of 10 reps at 60kg" 格式
      final setsOfPattern = RegExp(
        r'(\d+)\s*sets?\s*of\s*(\d+(?:-\d+)?)\s*(?:reps?)?\s*(?:at|@)?\s*(.+)?',
        caseSensitive: false,
      );
      final setsOfMatch = setsOfPattern.firstMatch(trimmed);

      if (setsOfMatch != null) {
        final setCount = int.tryParse(setsOfMatch.group(1) ?? '0') ?? 0;
        final reps = setsOfMatch.group(2) ?? '';
        final weight = setsOfMatch.group(3)?.trim() ?? '';

        return List.generate(
          setCount,
          (_) => TrainingSet(reps: reps, weight: weight),
        );
      }

      // 4. 尝试单组格式
      final singleSet = _parseSingleSetData(trimmed);
      if (singleSet != null) {
        return [singleSet];
      }

      return [];
    } catch (e) {
      AppLogger.error('❌ 解析 sets 数据失败', e);
      return [];
    }
  }

  /// 解析强度调整
  /// 返回 Map: {'type': 'percentage'/'absolute', 'value': double, 'unit': 'kg'/'lb'/'%'}
  Map<String, dynamic>? _parseIntensityAdjustment(String data) {
    try {
      final trimmed = data.trim();

      // 百分比格式: "+10%", "-20%", "increase by 10%"
      final percentPattern = RegExp(
        r'([+-]?\d+(?:\.\d+)?)\s*%',
        caseSensitive: false,
      );
      final percentMatch = percentPattern.firstMatch(trimmed);

      if (percentMatch != null) {
        final value = double.tryParse(percentMatch.group(1) ?? '0') ?? 0;
        return {
          'type': 'percentage',
          'value': value,
          'unit': '%',
        };
      }

      // 绝对值格式: "+5kg", "-10lb", "add 5kg"
      final absolutePattern = RegExp(
        r'([+-]?\d+(?:\.\d+)?)\s*(kg|lb|lbs?)?',
        caseSensitive: false,
      );
      final absoluteMatch = absolutePattern.firstMatch(trimmed);

      if (absoluteMatch != null) {
        final value = double.tryParse(absoluteMatch.group(1) ?? '0') ?? 0;
        final unit = absoluteMatch.group(2)?.toLowerCase() ?? 'kg';
        return {
          'type': 'absolute',
          'value': value,
          'unit': unit,
        };
      }

      return null;
    } catch (e) {
      AppLogger.error('❌ 解析强度调整失败', e);
      return null;
    }
  }

  /// 调整单个动作的强度
  ExercisePlanModel _adjustExerciseIntensity(
    ExercisePlanModel plan,
    PlanChange change,
    Map<String, dynamic> adjustment,
  ) {
    if (change.exerciseIndex == null) return plan;

    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (change.dayIndex >= days.length) return plan;

    final day = days[change.dayIndex];
    final exercises = List<Exercise>.from(day.exercises);
    if (change.exerciseIndex! >= exercises.length) return plan;

    final exercise = exercises[change.exerciseIndex!];
    final adjustedSets = exercise.sets
        .map((set) => _applyWeightAdjustment(set, adjustment))
        .toList();

    exercises[change.exerciseIndex!] = exercise.copyWith(sets: adjustedSets);
    days[change.dayIndex] = day.copyWith(exercises: exercises);
    return plan.copyWith(days: days);
  }

  /// 调整整天的强度
  ExercisePlanModel _adjustDayIntensity(
    ExercisePlanModel plan,
    int dayIndex,
    Map<String, dynamic> adjustment,
  ) {
    final days = List<ExerciseTrainingDay>.from(plan.days);
    if (dayIndex >= days.length) return plan;

    final day = days[dayIndex];
    final exercises = day.exercises.map((exercise) {
      final adjustedSets = exercise.sets
          .map((set) => _applyWeightAdjustment(set, adjustment))
          .toList();
      return exercise.copyWith(sets: adjustedSets);
    }).toList();

    days[dayIndex] = day.copyWith(exercises: exercises);
    return plan.copyWith(days: days);
  }

  /// 调整整个计划的强度
  ExercisePlanModel _adjustPlanIntensity(
    ExercisePlanModel plan,
    Map<String, dynamic> adjustment,
  ) {
    final days = plan.days.map((day) {
      final exercises = day.exercises.map((exercise) {
        final adjustedSets = exercise.sets
            .map((set) => _applyWeightAdjustment(set, adjustment))
            .toList();
        return exercise.copyWith(sets: adjustedSets);
      }).toList();
      return day.copyWith(exercises: exercises);
    }).toList();

    return plan.copyWith(days: days);
  }

  /// 应用重量调整到单组
  TrainingSet _applyWeightAdjustment(
    TrainingSet set,
    Map<String, dynamic> adjustment,
  ) {
    if (set.weight.isEmpty) return set;

    try {
      // 提取当前重量的数值部分
      final weightPattern = RegExp(r'(\d+(?:\.\d+)?)');
      final weightMatch = weightPattern.firstMatch(set.weight);

      if (weightMatch == null) return set;

      final currentWeight = double.tryParse(weightMatch.group(1) ?? '0') ?? 0;
      final adjustmentType = adjustment['type'] as String;
      final adjustmentValue = adjustment['value'] as double;

      double newWeight;
      if (adjustmentType == 'percentage') {
        // 百分比调整
        newWeight = currentWeight * (1 + adjustmentValue / 100);
      } else {
        // 绝对值调整
        newWeight = currentWeight + adjustmentValue;
      }

      // 保留原单位，如果有的话
      final unitPattern = RegExp(r'\d+(?:\.\d+)?\s*(.*)');
      final unitMatch = unitPattern.firstMatch(set.weight);
      final unit = unitMatch?.group(1)?.trim() ?? 'kg';

      // 格式化新重量（保留1位小数）
      final formattedWeight = newWeight.toStringAsFixed(1);
      final cleanedWeight = formattedWeight.endsWith('.0')
          ? formattedWeight.substring(0, formattedWeight.length - 2)
          : formattedWeight;

      return set.copyWith(weight: '$cleanedWeight$unit');
    } catch (e) {
      AppLogger.error('❌ 应用重量调整失败', e);
      return set;
    }
  }

  /// 解析动作修改数据
  /// 返回包含 name, note, type 的 Map
  Map<String, dynamic> _parseExerciseModification(
    dynamic data,
    Exercise currentExercise,
  ) {
    if (data == null) {
      return {};
    }

    try {
      // 如果已经是 Map，直接使用
      if (data is Map<String, dynamic>) {
        return {
          if (data.containsKey('name')) 'name': data['name'] as String,
          if (data.containsKey('note')) 'note': data['note'] as String,
          if (data.containsKey('type'))
            'type': exerciseTypeFromString(data['type'] as String),
          if (data.containsKey('sets')) 'sets': data['sets'],
        };
      }

      // 如果是 String
      if (data is String) {
        if (data.isEmpty) return {};

        final trimmed = data.trim();

        // 尝试 JSON 格式
        if (trimmed.startsWith('{')) {
          final json = Map<String, dynamic>.from(
            jsonDecode(trimmed) as Map,
          );

          return {
            if (json.containsKey('name')) 'name': json['name'] as String,
            if (json.containsKey('note')) 'note': json['note'] as String,
            if (json.containsKey('type'))
              'type': exerciseTypeFromString(json['type'] as String),
            if (json.containsKey('sets')) 'sets': json['sets'],
          };
        }

        // 简单文本格式：假设是动作名称
        return {'name': trimmed};
      }

      return {};
    } catch (e) {
      AppLogger.error('❌ 解析动作修改数据失败', e);
      return {};
    }
  }

  /// 解析完整的动作数据
  /// 支持 JSON 格式和简单文本格式
  Exercise _parseCompleteExercise(dynamic data) {
    if (data == null) {
      return Exercise.empty().copyWith(name: '新动作');
    }

    try {
      // 如果是 Map，直接解析
      if (data is Map<String, dynamic>) {
        // 解析 sets 数据
        List<TrainingSet> sets = [TrainingSet.empty()];
        if (data.containsKey('sets')) {
          if (data['sets'] is List) {
            // JSON 数组格式
            final setsJson = data['sets'] as List;
            sets = setsJson
                .map((setJson) => TrainingSet.fromJson(setJson as Map<String, dynamic>))
                .toList();
          } else if (data['sets'] is String) {
            // 字符串格式，需要解析
            sets = _parseSetsData(data['sets'] as String);
          }
        }

        if (sets.isEmpty) {
          sets = [TrainingSet.empty()];
        }

        return Exercise(
          name: data['name'] as String? ?? '新动作',
          note: data['note'] as String? ?? '',
          type: data.containsKey('type')
              ? exerciseTypeFromString(data['type'] as String)
              : ExerciseType.strength,
          sets: sets,
        );
      }

      // 如果是 String，按原有逻辑处理
      if (data is String) {
        if (data.isEmpty) {
          return Exercise.empty().copyWith(name: '新动作');
        }

        final trimmed = data.trim();

        // 尝试 JSON 格式
        if (trimmed.startsWith('{')) {
          final json = Map<String, dynamic>.from(
            jsonDecode(trimmed) as Map,
          );

          // 解析 sets 数据
          List<TrainingSet> sets = [TrainingSet.empty()];
          if (json.containsKey('sets')) {
            if (json['sets'] is List) {
              // JSON 数组格式
              final setsJson = json['sets'] as List;
              sets = setsJson
                  .map((setJson) => TrainingSet.fromJson(setJson as Map<String, dynamic>))
                  .toList();
            } else if (json['sets'] is String) {
              // 字符串格式，需要解析
              sets = _parseSetsData(json['sets'] as String);
            }
          }

          if (sets.isEmpty) {
            sets = [TrainingSet.empty()];
          }

          return Exercise(
            name: json['name'] as String? ?? '新动作',
            note: json['note'] as String? ?? '',
            type: json.containsKey('type')
                ? exerciseTypeFromString(json['type'] as String)
                : ExerciseType.strength,
            sets: sets,
          );
        }

        // 简单文本格式：假设是动作名称
        return Exercise.empty().copyWith(name: trimmed);
      }

      // 其他类型，返回默认值
      return Exercise.empty().copyWith(name: '新动作');
    } catch (e) {
      AppLogger.error('❌ 解析完整动作数据失败', e);
      return Exercise.empty().copyWith(name: data.toString());
    }
  }

  /// 解析完整的训练日数据
  /// 支持 JSON 格式和简单文本格式
  ExerciseTrainingDay _parseCompleteDay(dynamic data, int dayNumber) {
    if (data == null) {
      return ExerciseTrainingDay(
        day: dayNumber,
        name: 'Day $dayNumber',
        exercises: [],
      );
    }

    try {
      // 如果是字符串，尝试解析
      if (data is String) {
        final trimmed = data.trim();

        // 尝试 JSON 格式
        if (trimmed.startsWith('{')) {
          final json = Map<String, dynamic>.from(
            jsonDecode(trimmed) as Map,
          );

          // 解析 exercises 数据
          List<Exercise> exercises = [];
          if (json.containsKey('exercises') && json['exercises'] is List) {
            final exercisesJson = json['exercises'] as List;
            exercises = exercisesJson.map((exerciseJson) {
              if (exerciseJson is Map) {
                // 解析 sets 数据
                List<TrainingSet> sets = [TrainingSet.empty()];
                if (exerciseJson.containsKey('sets')) {
                  if (exerciseJson['sets'] is List) {
                    final setsJson = exerciseJson['sets'] as List;
                    sets = setsJson
                        .map((setJson) => TrainingSet.fromJson(setJson as Map<String, dynamic>))
                        .toList();
                  }
                }

                if (sets.isEmpty) {
                  sets = [TrainingSet.empty()];
                }

                return Exercise(
                  name: exerciseJson['name'] as String? ?? '新动作',
                  note: exerciseJson['note'] as String? ?? '',
                  type: exerciseJson.containsKey('type')
                      ? exerciseTypeFromString(exerciseJson['type'] as String)
                      : ExerciseType.strength,
                  sets: sets,
                );
              }
              return Exercise.empty();
            }).toList();
          }

          return ExerciseTrainingDay(
            day: dayNumber,
            name: json['name'] as String? ?? 'Day $dayNumber',
            note: json['note'] as String? ?? '',
            exercises: exercises,
          );
        }

        // 简单文本格式：假设是训练日名称
        return ExerciseTrainingDay(
          day: dayNumber,
          name: trimmed,
          exercises: [],
        );
      }

      // 如果是 Map，直接解析
      if (data is Map) {
        final json = Map<String, dynamic>.from(data);

        // 解析 exercises 数据
        List<Exercise> exercises = [];
        if (json.containsKey('exercises') && json['exercises'] is List) {
          final exercisesJson = json['exercises'] as List;
          exercises = exercisesJson.map((exerciseJson) {
            if (exerciseJson is Map) {
              // 解析 sets 数据
              List<TrainingSet> sets = [TrainingSet.empty()];
              if (exerciseJson.containsKey('sets')) {
                if (exerciseJson['sets'] is List) {
                  final setsJson = exerciseJson['sets'] as List;
                  sets = setsJson
                      .map((setJson) => TrainingSet.fromJson(setJson as Map<String, dynamic>))
                      .toList();
                }
              }

              if (sets.isEmpty) {
                sets = [TrainingSet.empty()];
              }

              return Exercise(
                name: exerciseJson['name'] as String? ?? '新动作',
                note: exerciseJson['note'] as String? ?? '',
                type: exerciseJson.containsKey('type')
                    ? exerciseTypeFromString(exerciseJson['type'] as String)
                    : ExerciseType.strength,
                sets: sets,
              );
            }
            return Exercise.empty();
          }).toList();
        }

        return ExerciseTrainingDay(
          day: dayNumber,
          name: json['name'] as String? ?? 'Day $dayNumber',
          note: json['note'] as String? ?? '',
          exercises: exercises,
        );
      }

      // 其他类型，返回默认值
      return ExerciseTrainingDay(
        day: dayNumber,
        name: 'Day $dayNumber',
        exercises: [],
      );
    } catch (e) {
      AppLogger.error('❌ 解析完整训练日数据失败', e);
      return ExerciseTrainingDay(
        day: dayNumber,
        name: data?.toString() ?? 'Day $dayNumber',
        exercises: [],
      );
    }
  }
}
