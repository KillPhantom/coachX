# Features Implementation Rules

---
alwaysApply: true
---

## ⚠️ CRITICAL: JSON Parsing from Firebase Cloud Functions

### Problem
From Firebase Cloud Functions 返回的嵌套 Map 对象的运行时类型**不是**严格的 `Map<String, dynamic>`，而是内部类型如 `_JsonMap`。

### ❌ NEVER Do This
```dart
// ❌ 错误 - 会导致运行时类型检查失败
factory Model.fromJson(Map<String, dynamic> json) {
  if (data is! Map<String, dynamic>) return null; // 总是返回 null！

  return Model(
    nested: NestedModel.fromJson(json['nested'] as Map<String, dynamic>), // 运行时异常！
  );
}
```

### ✅ ALWAYS Do This
```dart
import 'package:coach_x/core/utils/json_utils.dart';

// ✅ 正确 - 使用安全的类型转换
factory Model.fromJson(Map<String, dynamic> json) {
  // 对于单个嵌套对象
  final nestedData = safeMapCast(json['nested'], 'nested');

  // 对于对象列表
  final itemsData = safeMapListCast(json['items'], 'items');

  return Model(
    nested: nestedData != null ? NestedModel.fromJson(nestedData) : null,
    items: itemsData.map((item) => ItemModel.fromJson(item)).toList(),
  );
}
```

### Required Tools
**MUST import** `package:coach_x/core/utils/json_utils.dart` when parsing nested data:

- `safeMapCast(data, fieldName)` - 单个嵌套对象
- `safeMapListCast(data, fieldName)` - 对象数组
- `safeStringListCast(data, fieldName)` - 字符串数组

### When to Apply
✅ **ALWAYS** use for data from:
- Cloud Functions responses
- Firestore document snapshots (with nested objects)
- Any external API responses

❌ **NOT needed** for:
- Simple primitive types (String, int, bool)
- Top-level fields in the JSON
- Data you construct yourself in Dart

## Examples by Data Type

### 1. Nested Object
```dart
// JSON: { "user": { "id": "123", "name": "Test" } }
final userData = safeMapCast(json['user'], 'user');
return userData != null ? UserModel.fromJson(userData) : null;
```

### 2. Object Array
```dart
// JSON: { "plans": [{ "id": "1", "name": "Plan 1" }] }
final plansData = safeMapListCast(json['plans'], 'plans');
final plans = plansData.map((p) => PlanModel.fromJson(p)).toList();
```

### 3. Mixed Nested Structure
```dart
// JSON: { "training": { "days": [{ "exercises": [...] }] } }
final trainingData = safeMapCast(json['training'], 'training');
if (trainingData != null) {
  final daysData = safeMapListCast(trainingData['days'], 'days');
  final days = daysData.map((day) {
    final exercisesData = safeMapListCast(day['exercises'], 'exercises');
    return DayModel(
      exercises: exercisesData.map((e) => ExerciseModel.fromJson(e)).toList(),
    );
  }).toList();
}
```

## Checklist for New Models

When creating any new `fromJson` method:

- [ ] Import `json_utils.dart` if parsing nested data
- [ ] Use `safeMapCast()` for all nested objects
- [ ] Use `safeMapListCast()` for all object arrays
- [ ] Provide field name as second parameter (for debugging)
- [ ] Handle null cases gracefully
- [ ] Test with real Cloud Functions response data

## Reference Files

**Good Examples** (already fixed):
- ✅ `lib/features/coach/students/data/models/student_list_item_model.dart`
- ✅ `lib/features/student/home/data/models/student_plans_model.dart`
- ✅ `lib/features/coach/plans/data/models/exercise_plan_model.dart`

**Documentation**:
- 📖 `/Users/ivan/coachX/docs/json_parsing_fix.md` - Complete fix guide

## Common Patterns

### Repository Layer
```dart
class MyRepositoryImpl {
  Future<List<ItemModel>> fetchItems() async {
    final response = await CloudFunctionsService.call('fetch_items');
    final data = Map<String, dynamic>.from(response['data'] as Map);

    // ✅ Safe parsing
    final itemsData = safeMapListCast(data['items'], 'items');
    return itemsData.map((item) => ItemModel.fromJson(item)).toList();
  }
}
```

### Model with Complex Nesting
```dart
class ComplexModel {
  final NestedModel? nested;
  final List<ItemModel> items;

  factory ComplexModel.fromJson(Map<String, dynamic> json) {
    final nestedData = safeMapCast(json['nested'], 'nested');
    final itemsData = safeMapListCast(json['items'], 'items');

    return ComplexModel(
      nested: nestedData != null ? NestedModel.fromJson(nestedData) : null,
      items: itemsData.map((item) => ItemModel.fromJson(item)).toList(),
    );
  }
}
```

---

## Other Implementation Rules

### Typography
- **NEVER** use hardcoded `fontSize` values
- **ALWAYS** use `AppTextStyles.*` from `lib/core/theme/app_text_styles.dart`
- See `/Users/ivan/coachX/coach_x/CLAUDE.md` for full typography guidelines

### Internationalization
- **NEVER** use hardcoded user-visible strings
- **ALWAYS** use `AppLocalizations.of(context)!.*`
- Add new keys to both `app_en.arb` and `app_zh.arb`
- Run `flutter gen-l10n` after adding new keys

### State Management
- Use **Riverpod 2.x** for all state management
- Repository pattern: `Repository` interface + `RepositoryImpl`
- Provider types: `Provider`, `StateProvider`, `StateNotifierProvider`, `FutureProvider`, `StreamProvider`

### Error Handling
- Always wrap Cloud Functions calls in try-catch
- Use `AppLogger.error()` for logging errors with stack traces
- Provide user-friendly error messages via i18n

---

**Last Updated**: 2025-11-02
**Related Issue**: Student list plans showing null (Fixed)
