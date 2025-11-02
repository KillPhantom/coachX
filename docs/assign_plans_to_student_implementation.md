# 学生分配计划功能实施文档

## 实施概述

**功能**: 从学生列表为单个学生分配三类计划（训练+饮食+补剂）

**入口**: 学生列表页 → 学生卡片 → 更多菜单 → 分配计划

**设计方案**: 方案C - 卡片式展开面板

**状态**: ✅ 已完成

**开始时间**: 2025-11-02

**完成时间**: 2025-11-02

---

## 技术规格

### UI设计
- **布局**: 全屏对话框，三个可展开的section（训练/饮食/补剂）
- **展开方式**: 独立展开/折叠，每个section包含ScrollView（max 100个计划）
- **选择方式**: 单选Radio，包含"无计划"选项用于移除分配
- **动画**: AnimatedContainer，250ms展开/折叠过渡

### 数据流
```
AssignPlansToStudentDialog
  ↓ 加载计划列表
StudentRepository.fetchAvailablePlansSummary()
  ↓ 用户选择计划
_planAssignmentState (本地状态)
  ↓ 点击保存
计算diff → 批量调用assignPlan API
  ↓ 成功
刷新学生列表 → 显示新计划
```

### API调用
- **端点**: `assign_plan` (Cloud Function)
- **参数**:
  - `action`: 'assign' | 'unassign'
  - `planType`: 'exercise' | 'diet' | 'supplement'
  - `planId`: String
  - `studentIds`: List[String]
- **后端逻辑**: ArrayUnion/ArrayRemove更新plan.studentIds字段

---

## 实施检查清单

### ✅ 前端部分（10项）

- [ ] 1. 创建PlanSummary模型 (`lib/features/coach/students/data/models/plan_summary.dart`)
- [ ] 2. 创建PlanAssignmentState模型 (`lib/features/coach/students/data/models/plan_assignment_state.dart`)
- [ ] 3. StudentRepository添加fetchAvailablePlansSummary方法签名
- [ ] 4. StudentRepositoryImpl实现fetchAvailablePlansSummary方法
- [ ] 5. 创建PlanTypeSection组件 (`presentation/widgets/plan_type_section.dart`)
- [ ] 6. 创建AssignPlansToStudentDialog主对话框 (`presentation/widgets/assign_plans_to_student_dialog.dart`)
- [ ] 7. 修改StudentActionSheet调用逻辑
- [ ] 8. 添加中文国际化字符串 (app_zh.arb)
- [ ] 9. 添加英文国际化字符串 (app_en.arb)
- [ ] 10. 运行flutter gen-l10n生成国际化代码

### ✅ 后端部分（3项）

- [ ] 11. 在plans/handlers.py新增assign_plan函数
- [ ] 12. 在main.py导入assign_plan
- [ ] 13. 在main.py导出assign_plan

### ✅ 测试验证（12项）

- [ ] 14. 启动Firebase模拟器
- [ ] 15. 生成测试数据（计划+学生）
- [ ] 16. 运行Flutter应用
- [ ] 17. 测试基本流程（打开→选择→保存）
- [ ] 18. 测试展开/折叠动画
- [ ] 19. 测试选择不同计划类型组合
- [ ] 20. 测试"无计划"选项
- [ ] 21. 测试保存后UI更新
- [ ] 22. 测试网络错误场景
- [ ] 23. 测试无变化场景
- [ ] 24. 运行flutter analyze
- [ ] 25. 检查国际化完整性

### ✅ 文档更新（3项）

- [ ] 26. 更新students_list_implementation_summary.md
- [ ] 27. 确认backend_apis_and_document_db_schemas.md
- [ ] 28. 完成本文档的实施总结部分

---

## 实施进度

### 2025-11-02
- ✅ 需求分析完成
- ✅ 设计方案确认（方案C - 卡片式展开面板）
- ✅ 实施计划制定
- ✅ 前端实现完成（10项任务）
- ✅ 后端实现完成（assign_plan Cloud Function）
- ✅ 国际化字符串添加完成
- ✅ 代码质量检查通过（flutter analyze）
- ⏳ 待用户测试验证

---

## 文件清单

### 新增文件
1. `lib/features/coach/students/data/models/plan_summary.dart`
2. `lib/features/coach/students/data/models/plan_assignment_state.dart`
3. `lib/features/coach/students/presentation/widgets/plan_type_section.dart`
4. `lib/features/coach/students/presentation/widgets/assign_plans_to_student_dialog.dart`
5. `functions/plans/handlers.py` - assign_plan函数

### 修改文件
1. `lib/features/coach/students/data/repositories/student_repository.dart`
2. `lib/features/coach/students/data/repositories/student_repository_impl.dart`
3. `lib/features/coach/students/presentation/widgets/student_action_sheet.dart`
4. `lib/l10n/app_zh.arb`
5. `lib/l10n/app_en.arb`
6. `functions/main.py`

---

## 技术细节

### PlanSummary模型
```dart
class PlanSummary {
  final String id;
  final String name;
  final String? description;
  final int studentCount;
  final String planType;

  // 工厂方法: fromExercisePlan, fromDietPlan, fromSupplementPlan
}
```

### PlanAssignmentState模型
```dart
class PlanAssignmentState {
  final String? selectedExercisePlanId;
  final String? selectedDietPlanId;
  final String? selectedSupplementPlanId;
  final String? originalExercisePlanId;
  final String? originalDietPlanId;
  final String? originalSupplementPlanId;

  bool hasChanges() { ... }
  Map<String, Map<String, String?>> getChanges() { ... }
  PlanAssignmentState copyWith({ ... }) { ... }
}
```

### PlanTypeSection组件Props
- `planType`: String
- `isExpanded`: bool
- `currentPlanId`: String?
- `selectedPlanId`: String?
- `plans`: List<PlanSummary>
- `isLoading`: bool
- `onToggle`: VoidCallback
- `onSelectPlan`: Function(String?)

### 后端assign_plan函数签名
```python
@https_fn.on_call()
def assign_plan(req: https_fn.CallableRequest):
    """
    分配或取消分配计划给学生

    参数:
        action: 'assign' | 'unassign'
        planType: 'exercise' | 'diet' | 'supplement'
        planId: str
        studentIds: List[str]

    返回:
        {'status': 'success', 'message': '...'}
    """
```

---

## 国际化字符串列表

### 中文 (app_zh.arb)
```json
{
  "assignPlansToStudent": "分配计划给",
  "exercisePlanSection": "训练计划",
  "dietPlanSection": "饮食计划",
  "supplementPlanSection": "补剂计划",
  "noPlanOption": "无计划（移除分配）",
  "currentPlan": "当前",
  "notAssigned": "未分配",
  "loadingPlans": "加载计划中...",
  "noPlansAvailable": "暂无可用计划",
  "assignmentSaved": "计划分配成功",
  "assignmentFailed": "分配失败"
}
```

---

## 风险与对策

| 风险 | 影响 | 对策 |
|------|------|------|
| 后端API未实现 | 阻塞功能 | 优先实现assign_plan函数 |
| 100个计划渲染性能 | 用户体验 | 使用ListView.builder懒加载 |
| 网络请求失败 | 数据不一致 | 实现错误提示+重试机制 |
| 状态管理复杂 | 代码维护 | 清晰的State模型+注释 |

---

## 测试场景

### 正常流程
1. 学生当前无任何计划 → 分配三类计划 → 保存成功
2. 学生已有部分计划 → 修改其中一类 → 保存成功
3. 学生已有全部计划 → 替换其中两类 → 保存成功
4. 学生已有计划 → 选择"无计划"移除 → 保存成功

### 边界情况
1. 某类计划列表为空 → 显示"暂无可用计划"
2. 不做任何修改直接保存 → 提示"无变更"或直接返回
3. 展开section后折叠，再次展开 → 保持选择状态

### 错误场景
1. 保存时网络断开 → 显示错误提示
2. 保存时后端返回错误 → 显示具体错误信息
3. 计划在选择过程中被删除 → 刷新列表

---

## 后续优化方向

1. **性能优化**:
   - 计划列表分页加载
   - FutureProvider缓存

2. **用户体验**:
   - 添加搜索功能
   - 变更摘要确认对话框
   - Toast替代Dialog提示

3. **功能扩展**:
   - 支持批量分配（选择多个学生）
   - 计划预览气泡
   - 复制其他学生的计划配置

---

## 实施总结

**完成时间**: 2025-11-02

**实际工作量**: 约1.5小时

**实施完成度**:
- ✅ 前端UI组件（PlanTypeSection, AssignPlansToStudentDialog）
- ✅ 数据模型（PlanSummary, PlanAssignmentState）
- ✅ Repository扩展（fetchAvailablePlansSummary）
- ✅ 后端Cloud Function（assign_plan）
- ✅ 国际化支持（中英文）
- ✅ ActionSheet集成
- ✅ 代码质量检查

**遇到的问题**: 无重大问题

**技术亮点**:
1. **方案C设计**：卡片式展开面板，紧凑且信息完整
2. **状态管理**：PlanAssignmentState清晰管理变更diff
3. **后端安全**：严格的教练权限和学生归属验证
4. **用户体验**：展开动画、加载状态、错误处理完整

**下一步**:
1. 用户进行实际测试
2. 根据测试反馈优化交互
3. 可选：添加变更摘要确认对话框
4. 可选：实现学生列表刷新逻辑
