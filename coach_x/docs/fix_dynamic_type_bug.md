# 修复计划：`activePlans` 动态类型导致的 `firstWhere` orElse 类型错误

## 问题描述

**错误信息**：
```
type '() => dynamic' is not a subtype of type '(() => ExerciseTrainingDay)?'
```

**根本原因**：
- `currentActivePlansProvider` 返回 `Map<String, dynamic>`
- 从 Map 中取出的值是 `dynamic` 类型
- 当调用 `activeExercisePlan.days.firstWhere()` 时，`orElse` 回调的返回类型被推断为 `() => dynamic`
- 但 `List<ExerciseTrainingDay>.firstWhere` 期望 `orElse` 返回 `(() => ExerciseTrainingDay)?`
- 类型不匹配导致运行时错误

## 修复方案

在使用 `activePlans['exercisePlan']` 时，添加显式类型转换。

## 实施检查清单

1. [ ] 修改 `lib/features/student/home/presentation/widgets/today_training_plan_section.dart:30`
   - 将 `final activeExercisePlan = activePlans['exercisePlan'];`
   - 改为 `final activeExercisePlan = activePlans['exercisePlan'] as ExercisePlanModel?;`
   - 添加 import: `import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';`

2. [ ] 修改 `lib/features/student/training/presentation/widgets/plan_tabs_view.dart:124`
   - 将 `final activePlan = activePlans['exercisePlan'];`
   - 改为 `final activePlan = activePlans['exercisePlan'] as ExercisePlanModel?;`

3. [ ] 修改 `lib/features/student/training/presentation/widgets/plan_tabs_view.dart:167`
   - 将 `final activePlan = activePlans['dietPlan'];`
   - 改为 `final activePlan = activePlans['dietPlan'] as DietPlanModel?;`

4. [ ] 修改 `lib/features/student/training/presentation/widgets/plan_tabs_view.dart:210`
   - 将 `final activePlan = activePlans['supplementPlan'];`
   - 改为 `final activePlan = activePlans['supplementPlan'] as SupplementPlanModel?;`

5. [ ] 修改 `lib/features/student/home/presentation/widgets/today_supplement_section.dart:28`
   - 将 `final activeSupplementPlan = activePlans['supplementPlan'];`
   - 改为 `final activeSupplementPlan = activePlans['supplementPlan'] as SupplementPlanModel?;`
   - 确认 import 已存在（第5行已有）

6. [ ] 运行 `flutter analyze` 验证无错误

7. [ ] 测试验证修复生效
