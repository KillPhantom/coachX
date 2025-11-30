# 修复 Exercise demoVideos 错误

## 问题描述

`TodayTrainingPlanSection` 点击 exercise card 时报错：
```
Class 'Exercise' has no instance getter 'demoVideos'
```

## 根本原因

- `Exercise` 模型只有 `exerciseTemplateId` 字段，没有 `demoVideos`
- 视频信息存储在 `ExerciseTemplateModel` 中（通过 templateId 关联）
- 代码直接访问了不存在的属性

## 现有解决方案

学生端已有完整组件：
- `exerciseTemplateProvider` - 根据 templateId 加载模板
- `ExerciseGuidanceSheet` - 显示动作指导弹窗
- `VideoPlayerDialog` - 全屏视频播放

## 实施检查清单

1. [ ] 修改 `_buildExercisesList` 方法，将参数类型从 `List` 改为 `List<Exercise>`
2. [ ] 修改 `_buildExerciseCard` 方法，将参数类型从 `dynamic` 改为 `Exercise`
3. [ ] 修改 `_showVideoOrPlaceholder` 方法，将参数类型从 `dynamic` 改为 `Exercise`
4. [ ] 修改 `_showVideoOrPlaceholder` 逻辑：检查 `exerciseTemplateId` 而非 `demoVideos`
5. [ ] 添加 import: `ExerciseGuidanceSheet`
6. [ ] 添加 import: `Exercise` 模型
7. [ ] 运行 `flutter analyze` 验证无错误

## 文件变更

| 文件 | 变更类型 |
|------|----------|
| `lib/features/student/home/presentation/widgets/today_training_plan_section.dart` | 修改 |

---
**最后更新**: 2025-11-29
