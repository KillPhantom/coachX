# 学生多计划选择与自建功能

**功能概述**：学生可以查看和切换多个计划（教练分配 + 自己创建），通过自定义 dropdown 选择 active plan，并可创建自己的计划。

**完成时间**：2025-11-08

---

## 用户流程

### 查看和切换计划
1. 学生首页显示所有计划（教练分配 + 自建）
2. 点击 dropdown 查看完整计划列表
3. 选择计划后自动切换为 active plan
4. 页面刷新显示新计划内容

### 创建自建计划
1. 点击"Create New Plan"按钮
2. 跳转到计划创建页面
3. 填写计划信息并保存
4. 自动添加到计划列表

---

## 技术架构

### 数据模型

**User Model** (`user_model.dart`):
```dart
class UserModel {
  String? activeExercisePlanId;
  String? activeDietPlanId;
  String? activeSupplementPlanId;
  // ... other fields
}
```

**StudentPlansModel** (`student_plans_model.dart`):
```dart
class StudentPlansModel {
  List<ExercisePlanModel> exercisePlans;
  List<DietPlanModel> dietPlans;
  List<SupplementPlanModel> supplementPlans;

  // 获取当前 active plan
  ExercisePlanModel? getActiveExercisePlan(String? activePlanId);
  DietPlanModel? getActiveDietPlan(String? activePlanId);
  SupplementPlanModel? getActiveSupplementPlan(String? activePlanId);
}
```

### 核心组件

**PlanDropdown** (`plan_dropdown.dart`):
- 泛型组件：支持所有计划类型
- Props:
  - `List<T> plans` - 计划列表
  - `String? activePlanId` - 当前选中 ID
  - `Function(String planId) onPlanSelected` - 选择回调
  - `VoidCallback onCreateNew` - 创建新计划回调
- UI：Header（当前计划名称）+ Dropdown List + "Create New Plan" 按钮

---

## API 接口

### 1. 获取学生所有计划

**Cloud Function**: `get_student_all_plans`

**请求**:
```http
POST /get_student_all_plans
```

**响应**:
```json
{
  "exercise_plans": [
    {
      "id": "plan_id_1",
      "name": "教练计划",
      "ownerId": "coach_id",
      "studentIds": ["student_id"],
      "days": [...]
    },
    {
      "id": "plan_id_2",
      "name": "我的计划",
      "ownerId": "student_id",
      "studentIds": [],
      "days": [...]
    }
  ],
  "diet_plans": [...],
  "supplement_plans": [...]
}
```

**查询逻辑**:
- `studentIds` contains user_id (教练分配的计划)
- OR `ownerId` == user_id (自建计划)

### 2. 更新 Active Plan

**Cloud Function**: `update_active_plan`

**请求**:
```http
POST /update_active_plan
Content-Type: application/json

{
  "planType": "exercise",  // 'exercise' | 'diet' | 'supplement'
  "planId": "plan_id_123"
}
```

**响应**:
```json
{
  "success": true,
  "message": "Active exercise plan updated"
}
```

**更新字段**:
- `planType=exercise` → 更新 `activeExercisePlanId`
- `planType=diet` → 更新 `activeDietPlanId`
- `planType=supplement` → 更新 `activeSupplementPlanId`

---

## 数据流

### 加载计划列表
```
页面加载
  ↓
studentPlansProvider (调用 getAllPlans())
  ↓
CloudFunctionsService.getStudentAllPlans()
  ↓
Firestore 查询（studentIds contains user_id OR ownerId == user_id）
  ↓
返回 3 个计划列表
  ↓
StudentPlansModel 解析
  ↓
显示在 UI
```

### 切换 Active Plan
```
用户选择计划
  ↓
onPlanSelected(planId)
  ↓
StudentHomeRepository.updateActivePlan(planType, planId)
  ↓
CloudFunctionsService.updateActivePlan()
  ↓
更新 Firestore users/{userId}
  ↓
刷新 currentUserDataProvider
  ↓
UI 显示新计划内容
```

---

## State Management

**Providers** (`student_home_providers.dart`):

```dart
// 获取所有计划
final studentPlansProvider = FutureProvider<StudentPlansModel>((ref) async {
  final repository = ref.read(studentHomeRepositoryProvider);
  return await repository.getAllPlans();
});

// 获取 active plan IDs
final activeExercisePlanIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserDataProvider).value;
  return user?.activeExercisePlanId;
});

// 获取当前 active plans
final currentActivePlansProvider = Provider((ref) {
  final plansAsync = ref.watch(studentPlansProvider);
  final activeExerciseId = ref.watch(activeExercisePlanIdProvider);

  return plansAsync.when(
    data: (plans) => plans.getActiveExercisePlan(activeExerciseId),
    loading: () => null,
    error: (_, __) => null,
  );
});
```

---

## 核心文件

### 后端 (Python)
- `functions/users/handlers.py` - `update_user_info()`, `update_active_plan()`
- `functions/plans/handlers.py` - `get_student_all_plans()`

### 前端 (Dart)
- `lib/features/auth/data/models/user_model.dart` - User 模型
- `lib/features/student/home/data/models/student_plans_model.dart` - Plans 模型
- `lib/features/student/home/data/repositories/student_home_repository.dart` - 数据访问接口
- `lib/features/student/home/presentation/providers/student_home_providers.dart` - 状态管理
- `lib/features/student/training/presentation/widgets/plan_dropdown.dart` - Dropdown 组件

---

## 错误处理

| 错误场景 | 处理方式 |
|---------|---------|
| 无计划 | 显示空状态，引导创建第一个计划 |
| 网络错误 | 显示错误提示，允许重试 |
| Active plan ID 无效 | 自动选择列表第一个计划 |
| 创建计划失败 | 显示错误对话框，保持当前状态 |

---

## 相关文档

- 后端 API：`docs/backend_apis_and_document_db_schemas.md`
- 训练记录：`docs/student/training_record_page_architecture.md`

---

**最后更新**: 2025-11-08
