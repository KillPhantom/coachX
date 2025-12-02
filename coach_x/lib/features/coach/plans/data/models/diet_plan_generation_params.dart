import 'package:coach_x/core/enums/activity_level.dart';
import 'package:coach_x/core/enums/diet_goal.dart';
import 'package:coach_x/core/enums/dietary_preference.dart';

/// 饮食计划生成参数模型
///
/// 用于AI引导创建饮食计划时传递给后端API
class DietPlanGenerationParams {
  /// 体重（公斤）
  final double weightKg;

  /// 身高（厘米）
  final double heightCm;

  /// 年龄
  final int age;

  /// 性别（"male" | "female"）
  final String gender;

  /// 活动水平
  final ActivityLevel activityLevel;

  /// 饮食目标
  final DietGoal goal;

  /// 体脂率（可选）
  final double? bodyFatPercentage;

  /// 训练计划ID（可选，用于引用现有训练计划并启用碳循环）
  final String? trainingPlanId;

  /// 饮食偏好列表（可选）
  final List<DietaryPreference>? dietaryPreferences;

  /// 每日餐数（可选，默认4餐）
  final int? mealCount;

  /// 饮食限制和其他要求（可选）
  final String? dietaryRestrictions;

  /// 计划天数（可选，默认7天）
  final int? planDurationDays;

  const DietPlanGenerationParams({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    this.bodyFatPercentage,
    this.trainingPlanId,
    this.dietaryPreferences,
    this.mealCount,
    this.dietaryRestrictions,
    this.planDurationDays,
  });

  /// 转换为API请求参数
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'age': age,
      'gender': gender,
      'activity_level': activityLevel.apiValue,
      'goal': goal.apiValue,
    };

    // 添加可选参数
    if (bodyFatPercentage != null) {
      json['body_fat_percentage'] = bodyFatPercentage;
    }

    if (trainingPlanId != null && trainingPlanId!.isNotEmpty) {
      json['training_plan_id'] = trainingPlanId;
    }

    if (dietaryPreferences != null && dietaryPreferences!.isNotEmpty) {
      json['dietary_preferences'] = dietaryPreferences!
          .map((p) => p.apiValue)
          .toList();
    }

    if (mealCount != null) {
      json['meal_count'] = mealCount;
    }

    if (dietaryRestrictions != null && dietaryRestrictions!.trim().isNotEmpty) {
      json['dietary_restrictions'] = dietaryRestrictions!.trim();
    }

    if (planDurationDays != null) {
      json['plan_duration_days'] = planDurationDays;
    }

    return json;
  }

  /// 复制并修改参数
  DietPlanGenerationParams copyWith({
    double? weightKg,
    double? heightCm,
    int? age,
    String? gender,
    ActivityLevel? activityLevel,
    DietGoal? goal,
    double? bodyFatPercentage,
    String? trainingPlanId,
    List<DietaryPreference>? dietaryPreferences,
    int? mealCount,
    String? dietaryRestrictions,
    int? planDurationDays,
  }) {
    return DietPlanGenerationParams(
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      trainingPlanId: trainingPlanId ?? this.trainingPlanId,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      mealCount: mealCount ?? this.mealCount,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      planDurationDays: planDurationDays ?? this.planDurationDays,
    );
  }
}
