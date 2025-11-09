# 学生多计划选择与自建功能 - 实施进度

**功能概述**：学生可以查看和切换多个计划（教练分配 + 自己创建），通过自定义 dropdown 选择 active plan，并可创建自己的计划。

**创建时间**：2025-11-08
**最后更新**：2025-11-08

---

## ✅ 已完成任务

### 后端更新（Python Cloud Functions）

1. **✅ 更新 User Model** (`functions/users/handlers.py`)
   - 在 `update_user_info` 中添加对 `activeExercisePlanId`, `activeDietPlanId`, `activeSupplementPlanId` 的支持
   - 文件位置：`functions/users/handlers.py` (行 208-216)

2. **✅ 新增获取学生所有计划 API** (`functions/plans/handlers.py`)
   - 新增函数：`get_student_all_plans(req)`
   - 新增辅助函数：`_get_student_all_plans_by_type(db, student_id, collection_name)`
   - 逻辑：查询 `studentIds` contains user_id OR `ownerId` == user_id
   - 返回：3 个数组（exercise_plans, diet_plans, supplement_plans）
   - 文件位置：`functions/plans/handlers.py` (行 1592-1688)

3. **✅ 新增更新 Active Plan API** (`functions/users/handlers.py`)
   - 新增函数：`update_active_plan(req)`
   - 参数：`planType` ('exercise'|'diet'|'supplement'), `planId`
   - 文件位置：`functions/users/handlers.py` (行 366-422)

4. **✅ 导出新 Cloud Functions** (`functions/main.py`)
   - 导入并导出 `update_active_plan`
   - 导入并导出 `get_student_all_plans`

### 前端更新（Dart/Flutter - Data Layer）

5. **✅ 更新 User Model** (`lib/features/auth/data/models/user_model.dart`)
   - 新增字段：`activeExercisePlanId`, `activeDietPlanId`, `activeSupplementPlanId`
   - 更新 `fromFirestore`, `toFirestore`, `copyWith` 方法

6. **✅ 重构 StudentPlansModel** (`lib/features/student/home/data/models/student_plans_model.dart`)
   - 修改为计划列表结构：
     - `List<ExercisePlanModel> exercisePlans`
     - `List<DietPlanModel> dietPlans`
     - `List<SupplementPlanModel> supplementPlans`
   - 新增方法：
     - `getActiveExercisePlan(String? activePlanId)`
     - `getActiveDietPlan(String? activePlanId)`
     - `getActiveSupplementPlan(String? activePlanId)`
   - 添加向后兼容的 getter：`exercisePlan`, `dietPlan`, `supplementPlan`（返回列表第一项）

7. **✅ 更新 API 文档** (`docs/backend_apis_and_document_db_schemas.md`)
   - 更新 User schema，添加 3 个 active plan ID 字段
   - 新增 API：`updateActivePlan(planType, planId)`
   - 新增 API：`getStudentAllPlans()`

---

## 📋 待完成任务

### 前端 - Service & Repository 层

8. **✅ 在 `cloud_functions_service.dart` 新增 API 调用方法**
   - 新增：`Future<Map<String, dynamic>> getStudentAllPlans()`
   - 新增：`Future<Map<String, dynamic>> updateActivePlan(String planType, String planId)`
   - 文件位置：`lib/core/services/cloud_functions_service.dart`

9. **✅ 在 `student_home_repository.dart` 新增接口方法**
   - 新增接口：`Future<StudentPlansModel> getAllPlans()`
   - 新增接口：`Future<void> updateActivePlan(String planType, String planId)`
   - 文件位置：`lib/features/student/home/data/repositories/student_home_repository.dart`

10. **✅ 在 `student_home_repository_impl.dart` 实现新接口**
    - 实现 `getAllPlans()` - 调用 `CloudFunctionsService.getStudentAllPlans()`
    - 实现 `updateActivePlan()` - 调用 `CloudFunctionsService.updateActivePlan()`
    - 文件位置：`lib/features/student/home/data/repositories/student_home_repository_impl.dart`

### 前端 - State Management

11. **✅ 更新 `student_home_providers.dart`**
    - 修改 `studentPlansProvider` 调用 `getAllPlans()` 而非 `getAssignedPlans()`
    - 新增：`Provider<String?> activeExercisePlanIdProvider` - 从 currentUserDataProvider 获取
    - 新增：`Provider<String?> activeDietPlanIdProvider` - 从 currentUserDataProvider 获取
    - 新增：`Provider<String?> activeSupplementPlanIdProvider` - 从 currentUserDataProvider 获取
    - 新增计算 provider：`currentActivePlansProvider` 返回当前选中的 3 个计划对象（带默认选择第一个计划的逻辑）
    - 文件位置：`lib/features/student/home/presentation/providers/student_home_providers.dart`

### 前端 - UI Components

12. **✅ 创建 `plan_dropdown.dart` 自定义 dropdown 组件**
    - ✅ 位置：`lib/features/student/training/presentation/widgets/plan_dropdown.dart`
    - ✅ 使用泛型 `PlanDropdown<T extends PlanBaseModel>` 支持所有计划类型
    - ✅ Props:
      - `List<T> plans` - 计划列表
      - `String? activePlanId` - 当前选中 ID
      - `Function(String planId) onPlanSelected` - 选择回调
      - `VoidCallback onCreateNew` - 创建新计划回调
    - ✅ UI 结构：
      - Header: 当前选中计划名称 + 箭头（点击展开/收起）
      - Dropdown List: 显示所有计划（当前选中的高亮显示并有 checkmark）
      - Bottom Button: "Create New Plan"

13. **✅ 更新 `plan_tabs_view.dart` 集成 dropdown**
    - ✅ 每个 tab 下新增 `PlanDropdown` widget
    - ✅ 使用 `currentActivePlansProvider` 获取当前选中的计划
    - ✅ 传递对应类型的计划列表（`plans.exercisePlans`, `plans.dietPlans`, `plans.supplementPlans`）到 dropdown
    - ✅ 处理 dropdown 选择事件 - 调用 `CloudFunctionsService.updateActivePlan()`
    - ✅ 选择后 invalidate `studentPlansProvider` 触发刷新
    - 文件位置：`lib/features/student/training/presentation/widgets/plan_tabs_view.dart`

14. **✅ 验证 `training_plan_content.dart`**
    - ✅ 已支持接收 `ExercisePlanModel? plan`（可选）
    - ✅ 无需修改，直接传入 active plan 即可

15. **✅ 验证 `diet_plan_content.dart`**
    - ✅ 已支持接收 `DietPlanModel? plan`（可选）
    - ✅ 无需修改

16. **✅ 验证 `supplement_plan_content.dart`**
    - ✅ 已支持接收 `SupplementPlanModel? plan`（可选）
    - ✅ 无需修改

### 前端 - i18n

17. **✅ 在 `app_en.arb` 和 `app_zh.arb` 添加新字串**
    - ✅ `createNewPlan`: "Create New Plan" / "创建新计划"
    - ✅ `selectPlan`: "Select Plan" / "选择计划"
    - ✅ `myPlans`: "My Plans" / "我的计划"
    - ✅ `coachPlan`: "Coach's Plan" / "教练计划"
    - 文件位置：`lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`

18. **✅ 运行 `flutter gen-l10n`**
    - ✅ 生成本地化代码

---

## 🎯 下一步操作建议

### 选项 A：先测试后端
1. 部署 Cloud Functions：
   ```bash
   cd functions
   firebase deploy --only functions
   ```

2. 测试新 API：
   - 测试 `get_student_all_plans` 返回正确的计划列表
   - 测试 `update_active_plan` 更新 user 文档

3. 确认后端正常后，继续前端实现

### 选项 B：继续完成数据层
- 先完成任务 8-11（Service, Repository, Providers）
- 确保数据流通畅后再做 UI

### 选项 C：完整实现
- 按顺序完成任务 8-18
- 一次性完成整个功能

---

## 🔧 技术细节与注意事项

### 后端

**Firestore 查询逻辑** (in `_get_student_all_plans_by_type`):
```python
# 查询1: 教练分配的计划
assigned_query = db.collection(collection_name) \
    .where('studentIds', 'array_contains', student_id) \
    .order_by('createdAt', direction=firestore.Query.DESCENDING) \
    .get()

# 查询2: 学生自己创建的计划
owned_query = db.collection(collection_name) \
    .where('ownerId', '==', student_id) \
    .order_by('createdAt', direction=firestore.Query.DESCENDING) \
    .get()

# 去重合并
```

**Active Plan 更新逻辑** (in `update_active_plan`):
```python
field_map = {
    'exercise': 'activeExercisePlanId',
    'diet': 'activeDietPlanId',
    'supplement': 'activeSupplementPlanId'
}
field_name = field_map[plan_type]
db_helper.update_document('users', user_id, {field_name: plan_id})
```

### 前端

**向后兼容性**:
- `StudentPlansModel` 添加了 getter (`exercisePlan`, `dietPlan`, `supplementPlan`) 返回列表第一项
- 这样现有代码（如 `plan_tabs_view.dart` 中的 `plans.exercisePlan`）仍可工作
- TODO 标记提示未来应使用 `getActiveExercisePlan(activePlanId)`

**数据流**:
```
TrainingPage
  → watch studentPlansProvider (calls getAllPlans)
  → StudentPlansModel (lists)
  → PlanTabsView
    → PlanDropdown (user selects plan)
      → calls updateActivePlan()
        → updates user.activeXxxPlanId in Firestore
```

**UI 设计要点**:
- Dropdown 使用自定义浮层，不使用 `CupertinoActionSheet`
- Plan description 直接显示，不可折叠（移除了 Coach Note 概念）
- 每个 tab（Training/Diet/Supplement）都有独立的 dropdown

---

## 📝 相关文件清单

### 已修改文件
- `functions/users/handlers.py`
- `functions/plans/handlers.py`
- `functions/main.py`
- `lib/features/auth/data/models/user_model.dart`
- `lib/features/student/home/data/models/student_plans_model.dart`
- `docs/backend_apis_and_document_db_schemas.md`

### 待修改文件
- `lib/core/services/cloud_functions_service.dart`
- `lib/features/student/home/data/repositories/student_home_repository.dart`
- `lib/features/student/home/data/repositories/student_home_repository_impl.dart`
- `lib/features/student/home/presentation/providers/student_home_providers.dart`
- `lib/features/student/training/presentation/widgets/plan_tabs_view.dart`
- `lib/features/student/training/presentation/widgets/training_plan_content.dart`
- `lib/features/student/training/presentation/widgets/diet_plan_content.dart`
- `lib/features/student/training/presentation/widgets/supplement_plan_content.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`

### 待创建文件
- `lib/features/student/training/presentation/widgets/plan_dropdown.dart`

---

## 🐛 潜在问题与解决方案

### 问题 1：首次使用时无 active plan ID
- **现象**：学生首次登录，user 文档中 `activeXxxPlanId` 为 null
- **解决方案**：
  - 前端获取计划列表后，如果 `activePlanId` 为 null 且列表不为空，自动选择列表第一项
  - 或者显示 "请选择一个计划" 的引导 UI

### 问题 2：active plan 被删除
- **现象**：学生的 active plan 被教练删除或取消分配
- **解决方案**：
  - `getActiveXxxPlan` 方法已处理（返回 null）
  - UI 应检测到 null 并提示选择新计划

### 问题 3：计划列表为空
- **现象**：学生既没有被分配计划，也没创建自己的计划
- **解决方案**：
  - 显示空状态 UI
  - 提供 "Create New Plan" 按钮引导创建

---

## 📝 实施完成总结（2025-11-08）

### ✅ 所有任务已完成（任务 8-18）

**第一阶段 - 数据层（任务 8-11, 17-18）**
- ✅ Service 层：添加了 `getStudentAllPlans()` 和 `updateActivePlan()` 方法
- ✅ Repository 层：接口定义和实现
- ✅ State Management 层：
  - 修改 `studentPlansProvider` 调用 `getAllPlans()`
  - 新增 3 个 active plan ID providers（从用户数据自动获取）
  - 新增 `currentActivePlansProvider`（自动选择 active plan，如果无则默认第一个）
- ✅ i18n：添加了 4 个新字符串并生成本地化代码

**第二阶段 - UI 层（任务 12-16）**
- ✅ 创建 `plan_dropdown.dart` 自定义 dropdown 组件（泛型设计，支持所有计划类型）
- ✅ 更新 `plan_tabs_view.dart` 集成 dropdown（3 个 tab 都已集成）
- ✅ 验证 3 个 plan content widgets 兼容性（已支持，无需修改）

### 🎯 功能特性

1. **多计划支持**
   - 学生可以查看所有分配的计划和自己创建的计划
   - 每种类型（训练/饮食/补剂）支持多个计划并存

2. **计划选择**
   - 自定义 dropdown 组件，支持展开/收起
   - 当前选中的计划高亮显示并有 checkmark 标记
   - 底部有"创建新计划"按钮

3. **状态管理**
   - Active plan IDs 自动从 Firebase 用户文档同步
   - 选择计划后立即调用 Cloud Functions 更新
   - 更新成功后自动刷新数据

4. **智能默认选择**
   - 如果用户未设置 active plan，自动选择列表第一项
   - 确保用户始终有可用的计划显示

### 📁 新增/修改的文件清单

**新增文件**：
- `lib/features/student/training/presentation/widgets/plan_dropdown.dart` - 通用计划下拉组件

**修改文件**：
- `lib/core/services/cloud_functions_service.dart` - 新增 2 个 API 方法
- `lib/features/student/home/data/repositories/student_home_repository.dart` - 新增接口定义
- `lib/features/student/home/data/repositories/student_home_repository_impl.dart` - 实现新接口
- `lib/features/student/home/presentation/providers/student_home_providers.dart` - 新增 providers
- `lib/features/student/training/presentation/widgets/plan_tabs_view.dart` - 集成 dropdown
- `lib/l10n/app_en.arb` - 新增英文字符串
- `lib/l10n/app_zh.arb` - 新增中文字符串

### 🚀 后续建议

**必须完成**（功能才能正常工作）：
1. **部署后端**：
   ```bash
   cd functions
   firebase deploy --only functions
   ```
   - 部署 `get_student_all_plans` 函数
   - 部署 `update_active_plan` 函数

2. **测试流程**：
   - 为学生分配多个计划
   - 测试 dropdown 选择功能
   - 验证 active plan 更新到 Firestore
   - 测试刷新后计划显示正确

**可选优化**：
1. 实现"创建新计划"功能（目前只是 TODO 注释）
2. 添加计划删除功能
3. 添加计划编辑功能
4. 优化 dropdown 动画效果

### ⚠️ 注意事项

1. **首次使用**：如果学生的 user 文档中没有 `activeExercisePlanId` 等字段，`currentActivePlansProvider` 会自动选择列表第一项
2. **计划被删除**：如果 active plan 被教练删除，`getActiveXxxPlan` 会返回 null，UI 应显示空状态
3. **性能**：每次切换计划都会调用 Cloud Functions 并刷新数据，在网络慢的情况下可能有延迟

---

**状态**：✅ 所有任务已完成，等待部署和测试
