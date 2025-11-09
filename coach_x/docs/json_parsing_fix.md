# Firebase Cloud Functions JSON 解析问题修复

## 问题描述

从 Firebase Cloud Functions 返回的 JSON 数据中，嵌套的 Map 对象的运行时类型不是严格的 `Map<String, dynamic>`，而是普通的 `Map`。

在 Dart 中直接使用 `as Map<String, dynamic>` 强制转换会失败，导致数据解析错误，嵌套对象变成 `null`。

## 问题示例

### 症状
```dart
// 后端返回的数据
{
  "exercisePlan": {"id": "abc", "name": "test", "type": "exercise"}
}

// 错误的解析方式
final plan = json['exercisePlan'] as Map<String, dynamic>; // ❌ 运行时异常！

// 或者使用类型检查
if (data is! Map<String, dynamic>) return null; // ❌ 返回 null，因为类型不匹配
```

### 根本原因
Firebase Cloud Functions 使用 Protocol Buffers 序列化数据，返回的嵌套 Map 对象类型是 `_JsonMap` 或其他内部类型，不是严格的 `Map<String, dynamic>`。

## 解决方案

### 1. 创建安全的类型转换工具函数

文件位置：`lib/core/utils/json_utils.dart`

```dart
/// 安全地将 dynamic 转换为 Map<String, dynamic>
Map<String, dynamic>? safeMapCast(dynamic data, [String? fieldName]) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data); // ✅ 关键转换
  print('⚠️ Warning: Expected Map but got ${data.runtimeType}');
  return null;
}

/// 安全地转换 Map 列表
List<Map<String, dynamic>> safeMapListCast(dynamic data, [String? fieldName]) {
  if (data == null) return [];
  if (data is! List) return [];
  return data
      .map((item) => safeMapCast(item))
      .whereType<Map<String, dynamic>>()
      .toList();
}
```

### 2. 在所有 fromJson 方法中使用工具函数

#### 修复前（错误）：
```dart
factory StudentListItemModel.fromJson(Map<String, dynamic> json) {
  StudentPlanInfo? parseExercisePlan(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return null; // ❌
    return StudentPlanInfo.fromJson(data);
  }

  return StudentListItemModel(
    exercisePlan: parseExercisePlan(json['exercisePlan']),
  );
}
```

#### 修复后（正确）：
```dart
import 'package:coach_x/core/utils/json_utils.dart';

factory StudentListItemModel.fromJson(Map<String, dynamic> json) {
  StudentPlanInfo? parsePlan(dynamic data) {
    if (data == null) return null;
    if (data is! Map<String, dynamic>) {
      if (data is Map) {
        return StudentPlanInfo.fromJson(Map<String, dynamic>.from(data)); // ✅
      }
      return null;
    }
    return StudentPlanInfo.fromJson(data);
  }

  return StudentListItemModel(
    exercisePlan: parsePlan(json['exercisePlan']),
  );
}
```

#### 或使用工具函数（推荐）：
```dart
import 'package:coach_x/core/utils/json_utils.dart';

factory StudentPlansModel.fromJson(Map<String, dynamic> json) {
  final exercisePlanData = safeMapCast(json['exercise_plan'], 'exercise_plan'); // ✅

  return StudentPlansModel(
    exercisePlan: exercisePlanData != null
        ? ExercisePlanModel.fromJson(exercisePlanData)
        : null,
  );
}
```

## 已修复的文件

### 核心工具
1. ✅ `lib/core/utils/json_utils.dart` - 安全类型转换工具函数

### 数据模型
2. ✅ `lib/features/coach/students/data/models/student_list_item_model.dart` - 学生列表项
3. ✅ `lib/features/student/home/data/models/student_plans_model.dart` - 学生计划
4. ✅ `lib/features/student/home/data/models/daily_training_model.dart` - 每日训练
5. ✅ `lib/features/coach/plans/data/models/exercise_plan_model.dart` - 训练计划
6. ✅ `lib/features/coach/plans/data/models/exercise_training_day.dart` - 训练日
7. ✅ `lib/features/coach/plans/data/models/exercise.dart` - 训练动作

### Repository 层
8. ✅ `lib/features/student/home/data/repositories/student_home_repository_impl.dart` - 学生首页数据仓库

### 时间戳字段修复（2025-11-02）
9. ✅ `lib/features/coach/plans/data/models/exercise_plan_model.dart` - 时间戳字段
10. ✅ `lib/features/coach/plans/data/models/diet_plan_model.dart` - 时间戳字段
11. ✅ `lib/features/coach/plans/data/models/supplement_plan_model.dart` - 时间戳字段

**问题**: 后端返回的 `createdAt` 和 `updatedAt` 字段是 GMT 格式的日期字符串（如 `"Sun, 02 Nov 2025 21:52:15 GMT"`），而不是 Unix 时间戳数字。

**解决方案**:
- 增强了 `safeIntCast()` 函数，支持自动解析日期字符串并转换为毫秒时间戳
- 在所有计划模型中使用 `safeIntCast()` 替代直接的 `as int?` 转换

### 其他可能需要修复的文件
通过搜索发现还有约 **34** 处使用了 `as Map<String, dynamic>` 强制转换的地方，分布在以下模块：
- Chat 模块的消息和会话模型
- AI 生成相关的模型
- Diet plan 相关模型
- Supplement plan 相关模型
- Plan edit suggestion 相关模型

这些模块目前可能没有问题，因为它们可能不是从 Cloud Functions 返回的，或者数据结构较简单。

## 最佳实践

### 对于所有新的 `fromJson` 方法：

1. **对于嵌套的单个对象**：
   ```dart
   final nestedData = safeMapCast(json['nested'], 'nested');
   return nestedData != null ? NestedModel.fromJson(nestedData) : null;
   ```

2. **对于嵌套的对象列表**：
   ```dart
   final listData = safeMapListCast(json['items'], 'items');
   final items = listData.map((item) => ItemModel.fromJson(item)).toList();
   ```

3. **对于字符串列表**：
   ```dart
   final strings = safeStringListCast(json['tags'], 'tags');
   ```

## 测试建议

对于所有修复的模型，建议测试：

1. **正常情况**：从 Cloud Functions 返回的真实数据
2. **空值情况**：字段为 null
3. **类型错误**：字段类型完全错误（如字符串而不是对象）

```dart
// 测试示例
test('should parse nested objects from Cloud Functions response', () {
  final json = {
    'exercise_plan': {'id': '123', 'name': 'Test', 'type': 'exercise'}
  };
  final model = StudentPlansModel.fromJson(json);
  expect(model.exercisePlan, isNotNull);
  expect(model.exercisePlan!.name, 'Test');
});
```

## 后续行动

- [ ] 监控生产环境中的 JSON 解析错误
- [ ] 对其他 34 处 Map 强制转换进行评估
- [ ] 考虑是否需要对所有 fromJson 方法应用这个修复
- [ ] 添加单元测试覆盖所有修复的模型

## 参考

- Firebase Cloud Functions 文档：https://firebase.google.com/docs/functions
- Dart JSON 序列化指南：https://dart.dev/guides/json
- 相关 Issue：学生列表页面计划信息显示为空（2025-11-02）
