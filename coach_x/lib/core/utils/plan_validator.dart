import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';

/// 计划验证工具类
class PlanValidator {
  PlanValidator._(); // 私有构造函数，防止实例化

  /// 验证训练计划是否有效
  ///
  /// 验证规则：
  /// 1. 计划名称不能为空
  /// 2. 至少包含一个训练日
  /// 3. 每个训练日至少有一个动作
  /// 4. 每个动作至少有一个训练组
  static bool isValidPlan(ExercisePlanModel plan) {
    return getValidationErrors(plan).isEmpty;
  }

  /// 获取验证错误列表
  static List<String> getValidationErrors(ExercisePlanModel plan) {
    final errors = <String>[];

    // 1. 验证计划名称
    if (plan.name.trim().isEmpty) {
      errors.add('计划名称不能为空');
      return errors; // 早期返回，避免后续验证
    }

    // 2. 验证训练日数量
    if (plan.days.isEmpty) {
      errors.add('至少需要添加一个训练日');
      return errors;
    }

    // 3. 验证每个训练日
    for (int i = 0; i < plan.days.length; i++) {
      final day = plan.days[i];

      // 验证训练日名称
      if (day.name.trim().isEmpty) {
        errors.add('第${i + 1}个训练日需要名称');
        continue;
      }

      // 允许训练日有空的exercises列表

      // 验证每个动作
      for (int j = 0; j < day.exercises.length; j++) {
        final exercise = day.exercises[j];

        // 验证动作名称
        if (exercise.name.trim().isEmpty) {
          errors.add('训练日「${day.name}」的第${j + 1}个动作需要名称');
          continue;
        }

        // 验证动作模板 ID
        if (exercise.exerciseTemplateId == null ||
            exercise.exerciseTemplateId!.trim().isEmpty) {
          errors.add('动作「${exercise.name}」必须关联动作模板');
          continue;
        }

        // 验证训练组数量
        if (exercise.sets.isEmpty) {
          errors.add('动作「${exercise.name}」至少需要一个训练组');
          continue;
        }

        // 验证每个训练组
        for (int k = 0; k < exercise.sets.length; k++) {
          final set = exercise.sets[k];

          // 验证 reps（次数是必填的）
          if (set.reps.trim().isEmpty) {
            errors.add('动作「${exercise.name}」的第${k + 1}组需要填写次数');
          }

          // weight 可以为空（例如自重训练）
        }
      }
    }

    return errors;
  }

  /// 快速验证（只返回第一个错误）
  static String? getFirstError(ExercisePlanModel plan) {
    final errors = getValidationErrors(plan);
    return errors.isEmpty ? null : errors.first;
  }

  /// 验证计划名称
  static bool isValidPlanName(String name) {
    return name.trim().isNotEmpty;
  }

  /// 验证训练日
  static bool hasAtLeastOneDay(ExercisePlanModel plan) {
    return plan.days.isNotEmpty;
  }

  /// 验证所有动作名称
  static bool allExercisesHaveNames(ExercisePlanModel plan) {
    for (final day in plan.days) {
      for (final exercise in day.exercises) {
        if (exercise.name.trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  /// 验证所有动作都有训练组
  static bool allExercisesHaveSets(ExercisePlanModel plan) {
    for (final day in plan.days) {
      for (final exercise in day.exercises) {
        if (exercise.sets.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }
}
