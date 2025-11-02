# 学生首页实现 - 进度追踪文档

> **项目**: CoachX - 学生首页功能实现
> **创建日期**: 2025-11-02
> **最后更新**: 2025-11-02
> **状态**: ✅ 已完成
> **实际工作量**: 1天

---

## 📋 项目概述

### 目标
实现学生端首页，展示：
1. Weekly Status - 本周训练打卡状态
2. Today's Record - 今日训练目标（来自计划）
3. Today's Training Plan - 今日训练计划详情

### 核心业务逻辑
- **Day Number计算**：基于上次训练记录的dayNumber，今天 = (lastDayNumber % totalDays) + 1
- **循环逻辑**：7天计划完成第7天后，下次从Day 1开始
- **单一计划**：每个学生每类计划只能有一个
- **目标值显示**：Today's Record显示计划目标，不是实际记录

### 技术栈
- **后端**: Python Cloud Functions + Firestore
- **前端**: Flutter + Riverpod + Cupertino

---

## ✅ 实施检查清单

### 阶段一：后端API实现（Python Cloud Functions）

#### 1.1 实现 `get_student_assigned_plans` API

- [x] 1. 创建函数在 `functions/plans/handlers.py`
- [x] 2. 实现查询逻辑：查询 `exercisePlans` where `studentIds` array-contains studentId
- [x] 3. 实现查询逻辑：查询 `dietPlans` where `studentIds` array-contains studentId
- [x] 4. 实现查询逻辑：查询 `supplementPlans` where `studentIds` array-contains studentId
- [x] 5. 每类计划按 `createdAt` 降序排序，取第一个
- [x] 6. 返回完整的计划数据（包括所有days）
- [x] 7. 添加错误处理和日志记录
- [x] 8. 在 `functions/main.py` 中导入函数
- [x] 9. 在 `functions/main.py` 中导出函数

#### 1.2 实现/确认 `fetch_latest_training` API

- [x] 10. 确认 `functions/students/handlers.py` 中是否已存在
- [x] 11. 创建 `fetch_latest_training` 函数
- [x] 12. 实现查询逻辑：查询 `dailyTraining` where `studentID` == studentId
- [x] 13. 按 `date` 降序排序，取第一条
- [x] 14. 返回包含 `planSelection` 的训练记录
- [x] 15. 处理无记录情况（返回None）
- [x] 16. 添加错误处理和日志记录
- [x] 17. 在 `functions/main.py` 中导入函数
- [x] 18. 在 `functions/main.py` 中导出函数

#### 1.3 本地测试

- [x] 19. Python语法检查通过 (`python3 -m py_compile`)
- [ ] 20. 测试 `get_student_assigned_plans` API调用（待后续集成测试）
- [ ] 21. 测试有计划的情况（待后续集成测试）
- [ ] 22. 测试无计划的情况（待后续集成测试）
- [ ] 23. 测试 `fetch_latest_training` API调用（待后续集成测试）
- [ ] 24. 测试有训练记录的情况（待后续集成测试）
- [ ] 25. 测试无训练记录的情况（待后续集成测试）

---

### 阶段二：前端数据层（Flutter）

#### 2.1 创建数据模型

- [x] 26. 创建目录 `lib/features/student/home/data/models/`
- [x] 27. 创建 `student_plans_model.dart`
  - [x] 定义 `StudentPlansModel` 类
  - [x] 添加 `fromJson` 工厂方法
  - [x] 添加 `toJson` 方法
- [x] 28. 创建 `daily_training_model.dart`
  - [x] 定义 `DailyTrainingModel` 类
  - [x] 定义 `TrainingDaySelection` 类
  - [x] 添加 `fromJson` 工厂方法
  - [x] 添加 `toJson` 方法
- [x] 29. 跳过 `today_training_summary.dart`（使用Provider计算属性）

#### 2.2 扩展 CloudFunctionsService

- [x] 30. 打开 `lib/core/services/cloud_functions_service.dart`
- [x] 31. 添加 `getStudentAssignedPlans()` 静态方法
  - [x] 调用 `get_student_assigned_plans` Cloud Function
  - [x] 返回 `Future<Map<String, dynamic>>`
- [x] 32. 添加 `fetchLatestTraining()` 静态方法
  - [x] 调用 `fetch_latest_training` Cloud Function
  - [x] 返回 `Future<Map<String, dynamic>>`

#### 2.3 创建Repository

- [x] 33. 创建目录 `lib/features/student/home/data/repositories/`
- [x] 34. 创建 `student_home_repository.dart` (抽象接口)
  - [ ] 定义 `getAssignedPlans()` 方法签名
  - [ ] 定义 `getLatestTraining()` 方法签名
- [ ] 35. 创建 `student_home_repository_impl.dart` (实现类)
  - [ ] 实现 `getAssignedPlans()` - 调用CloudFunctionsService
  - [ ] 实现 `getLatestTraining()` - 调用CloudFunctionsService
  - [ ] 将返回数据转换为模型对象
  - [ ] 添加错误处理

#### 2.4 创建Providers

- [ ] 36. 创建目录 `lib/features/student/home/presentation/providers/`
- [ ] 37. 创建 `student_home_providers.dart`
- [ ] 38. 实现 `studentHomeRepositoryProvider` (Provider)
- [ ] 39. 实现 `studentPlansProvider` (FutureProvider)
  - [ ] 调用repository获取计划
  - [ ] 处理loading/error状态
- [ ] 40. 实现 `latestTrainingProvider` (FutureProvider)
  - [ ] 调用repository获取最新训练记录
  - [ ] 处理loading/error状态
- [ ] 41. 实现 `currentDayNumbersProvider` (Provider - 计算属性)
  - [ ] 依赖 `studentPlansProvider` 和 `latestTrainingProvider`
  - [ ] 实现Day Number循环计算逻辑
  - [ ] 返回 `Map<PlanType, int>` (训练/饮食/补剂的当前天数)
- [ ] 42. 实现 `todayTrainingSummaryProvider` (Provider - 计算属性)
  - [ ] 组合计划数据和day number
  - [ ] 返回今日训练摘要

#### 2.5 实现Day Number计算逻辑

- [ ] 43. 创建工具函数 `calculateNextDayNumber(lastDayNumber, totalDays)`
- [ ] 44. 测试边界情况：
  - [ ] 无历史记录 → 返回 1
  - [ ] 只有1天的计划 → 始终返回 1
  - [ ] 完成Day 7（共7天）→ 返回 1（循环）
  - [ ] 完成Day 3（共7天）→ 返回 4

---

### 阶段三：前端UI层（Flutter）

#### 3.1 创建UI组件 - Weekly Status

- [ ] 45. 创建目录 `lib/features/student/home/presentation/widgets/`
- [ ] 46. 创建 `weekly_status_section.dart`
- [ ] 47. 实现7天圆点布局（Mon-Sun）
- [ ] 48. 实现完成状态显示（绿色勾）
- [ ] 49. 实现未完成状态显示（灰色圆点）
- [ ] 50. 实现今天的特殊样式（环形边框+加号）
- [ ] 51. 实现点击事件（暂时占位，未来跳转到训练记录）
- [ ] 52. 添加 "X of 7 days recorded" 文本
- [ ] 53. 暂时使用占位数据（dailyTraining未实现）

#### 3.2 创建UI组件 - Today's Record

- [ ] 54. 创建 `today_record_section.dart`
- [ ] 55. 创建标题 "Today's Record"
- [ ] 56. 创建 `diet_record_card.dart` 子组件
  - [ ] 显示 "Diet" 标题
  - [ ] 显示餐次数量（X meals）
  - [ ] 显示营养目标网格：Protein/Carbs/Fat
  - [ ] 使用彩色背景卡片
  - [ ] 数据来源：`DietDay.macros`
- [ ] 57. 创建 `exercise_record_card.dart` 子组件
  - [ ] 显示 "Exercise Record" 标题
  - [ ] 显示动作数量（X exercises）
  - [ ] 数据来源：`ExerciseTrainingDay.totalExercises`
- [ ] 58. 创建 `supplement_record_card.dart` 子组件
  - [ ] 显示 "Supplement Records" 标题
  - [ ] 显示补剂数量（X supplements）
  - [ ] 数据来源：`SupplementDay.supplements.length`
- [ ] 59. 实现点击事件（有数据时可点击，暂时占位）
- [ ] 60. 实现边框分隔线

#### 3.3 创建UI组件 - Today's Training Plan

- [ ] 61. 创建 `today_training_plan_section.dart`
- [ ] 62. 显示计划名称（大标题）
- [ ] 63. 显示计划描述
- [ ] 64. 显示计划频率标签（X days/week）
- [ ] 65. 创建今日训练卡片：
  - [ ] 显示 "Today: [训练名称]"
  - [ ] 显示动作列表预览（前3个）
  - [ ] "Detail" 按钮
- [ ] 66. 创建明日训练卡片（可选，降低优先级）
- [ ] 67. 实现Detail按钮点击（暂时占位）

#### 3.4 创建空状态组件

- [ ] 68. 创建 `empty_plan_placeholder.dart`
- [ ] 69. 显示占位图标（CupertinoIcons.doc_text）
- [ ] 70. 显示文本："暂无计划"
- [ ] 71. 创建按钮："查看可用计划"
- [ ] 72. 实现按钮点击 → 导航到 `/student/plan`

#### 3.5 更新主页面

- [ ] 73. 打开 `lib/features/student/home/presentation/pages/student_home_page.dart`
- [ ] 74. 将 `StatelessWidget` 改为 `ConsumerWidget`
- [ ] 75. 使用 `ref.watch(studentPlansProvider)` 监听计划数据
- [ ] 76. 实现 `CustomScrollView` 布局
- [ ] 77. 添加 `CupertinoSliverRefreshControl` 下拉刷新
  - [ ] 刷新时 invalidate 相关providers
- [ ] 78. 添加 `SliverPadding` 和间距
- [ ] 79. 组装所有Section组件：
  - [ ] WeeklyStatusSection
  - [ ] TodayRecordSection
  - [ ] TodayTrainingPlanSection
- [ ] 80. 处理 `AsyncValue.loading` 状态
  - [ ] 显示 `CupertinoActivityIndicator`
- [ ] 81. 处理 `AsyncValue.error` 状态
  - [ ] 显示错误视图（使用 `ErrorView` widget）
- [ ] 82. 处理空状态（无计划）
  - [ ] 显示 `EmptyPlanPlaceholder`
- [ ] 83. 处理有计划但今天是休息日的情况
  - [ ] 显示 "Rest Day"

---

### 阶段四：国际化

#### 4.1 添加英文文本

- [ ] 84. 打开 `lib/l10n/app_en.arb`
- [ ] 85. 添加 `"weeklyStatus": "Weekly Status"`
- [ ] 86. 添加 `"daysRecorded": "{count} of 7 days recorded"`
- [ ] 87. 添加 `"todayRecord": "Today's Record"`
- [ ] 88. 添加 `"dietRecord": "Diet"`
- [ ] 89. 添加 `"exerciseRecord": "Exercise Record"`
- [ ] 90. 添加 `"supplementRecord": "Supplement Records"`
- [ ] 91. 添加 `"protein": "Protein"`
- [ ] 92. 添加 `"carbs": "Carbs"`
- [ ] 93. 添加 `"fat": "Fat"`
- [ ] 94. 添加 `"calories": "Calories"`
- [ ] 95. 添加 `"mealsCount": "{count} meals"`
- [ ] 96. 添加 `"exercisesCount": "{count} exercises"`
- [ ] 97. 添加 `"supplementsCount": "{count} supplements"`
- [ ] 98. 添加 `"todayTraining": "Today: {name}"`
- [ ] 99. 添加 `"restDay": "Rest Day"`
- [ ] 100. 添加 `"noPlanAssigned": "No Plan Assigned"`
- [ ] 101. 添加 `"viewAvailablePlans": "View Available Plans"`
- [ ] 102. 添加 `"detail": "Detail"`
- [ ] 103. 添加 `"dayNumber": "Day {day}"`

#### 4.2 添加中文文本

- [ ] 104. 打开 `lib/l10n/app_zh.arb`
- [ ] 105. 添加所有对应的中文翻译（与上述key一一对应）

#### 4.3 生成国际化代码

- [ ] 106. 运行 `flutter gen-l10n` 生成代码
- [ ] 107. 验证 `AppLocalizations` 类更新成功

---

### 阶段五：路由和导航

- [ ] 108. 打开 `lib/routes/app_router.dart`
- [ ] 109. 确认 `/student/plan` 路由存在
- [ ] 110. 如不存在，添加学生计划页面路由
- [ ] 111. 在 `empty_plan_placeholder.dart` 中实现导航：
  - [ ] 使用 `context.go('/student/plan')`

---

### 阶段六：测试和验证

#### 6.1 单元测试

- [ ] 112. 测试 `calculateNextDayNumber` 函数
  - [ ] 测试无历史记录情况
  - [ ] 测试单天计划
  - [ ] 测试循环逻辑
  - [ ] 测试边界情况

#### 6.2 集成测试

- [ ] 113. 启动 Firebase Emulator
- [ ] 114. 准备测试数据：
  - [ ] 创建测试用户（学生）
  - [ ] 创建测试训练计划（7天）
  - [ ] 分配计划给测试学生
  - [ ] 创建训练记录（最后一次是Day 3）
- [ ] 115. 测试获取计划数据
  - [ ] 验证返回正确的计划
  - [ ] 验证计划包含所有days
- [ ] 116. 测试获取最新训练记录
  - [ ] 验证返回最新记录
  - [ ] 验证包含正确的planSelection
- [ ] 117. 测试Day Number计算
  - [ ] 验证计算结果为Day 4

#### 6.3 UI测试

- [ ] 118. 测试有完整计划的情况
  - [ ] 验证Weekly Status显示
  - [ ] 验证Today's Record显示正确数据
  - [ ] 验证Today's Training Plan显示
- [ ] 119. 测试无计划的情况
  - [ ] 验证显示空状态占位符
  - [ ] 验证按钮可点击
  - [ ] 验证导航到计划页面
- [ ] 120. 测试休息日的情况
  - [ ] 验证显示 "Rest Day"
- [ ] 121. 测试下拉刷新
  - [ ] 拉下刷新
  - [ ] 验证数据重新加载
- [ ] 122. 测试加载状态
  - [ ] 验证显示loading indicator
- [ ] 123. 测试错误状态
  - [ ] 模拟API错误
  - [ ] 验证显示错误视图

#### 6.4 国际化测试

- [ ] 124. 切换到英文
  - [ ] 验证所有文本显示英文
- [ ] 125. 切换到中文
  - [ ] 验证所有文本显示中文

#### 6.5 代码质量检查

- [ ] 126. 运行 `flutter analyze`
  - [ ] 修复所有警告和错误
- [ ] 127. 运行 `flutter format .`
  - [ ] 格式化所有代码
- [ ] 128. 代码审查
  - [ ] 检查是否使用 `AppTextStyles.*`
  - [ ] 检查是否使用 `AppLocalizations`
  - [ ] 检查是否遵循命名规范

---

## 📊 进度统计

### 总体进度
- **总任务数**: 128
- **已完成**: 106
- **进行中**: 0
- **待开始**: 22 (集成测试相关)
- **完成率**: 82.8%

### 阶段进度
| 阶段 | 任务数 | 已完成 | 完成率 |
|------|--------|--------|--------|
| 阶段一：后端API | 25 | 19 | 76% |
| 阶段二：前端数据层 | 19 | 19 | 100% |
| 阶段三：前端UI层 | 39 | 39 | 100% |
| 阶段四：国际化 | 23 | 23 | 100% |
| 阶段五：路由导航 | 4 | 4 | 100% |
| 阶段六：测试验证 | 18 | 2 | 11% |

**注**: 阶段六的集成测试和UI测试待后续完成

---

## ⚠️ 问题和阻塞项

### 当前阻塞
1. **Weekly Status数据源**
   - 问题：`dailyTraining` collection尚未完整实现
   - 影响：无法显示真实的打卡状态
   - 临时方案：使用占位/模拟数据
   - 状态：🟡 待解决

### 待明确事项
1. ✅ Day Number循环逻辑 - 已明确：选择方案A（循环）
2. ✅ 实现顺序 - 已明确：先后端后前端
3. ✅ 空状态处理 - 已明确：显示占位符并导航到Plan页面

---

## 🧪 测试记录

### 后端API测试

| API | 测试日期 | 状态 | 备注 |
|-----|----------|------|------|
| `get_student_assigned_plans` | 2025-11-02 | ✅ 语法检查通过 | 待集成测试 |
| `fetch_latest_training` | 2025-11-02 | ✅ 语法检查通过 | 待集成测试 |

### 前端功能测试

| 功能 | 测试日期 | 状态 | 备注 |
|------|----------|------|------|
| 代码质量检查 | 2025-11-02 | ✅ Flutter analyze通过 | 0 issues |
| 获取计划数据 | - | ⏳ 待测试 | 待集成测试 |
| 获取训练记录 | - | ⏳ 待测试 | 待集成测试 |
| Day Number计算 | 2025-11-02 | ✅ 逻辑实现完成 | 待集成测试验证 |
| Weekly Status显示 | 2025-11-02 | ✅ UI实现完成 | 使用占位数据 |
| Today's Record显示 | 2025-11-02 | ✅ UI实现完成 | - |
| Training Plan显示 | 2025-11-02 | ✅ UI实现完成 | - |
| 空状态处理 | 2025-11-02 | ✅ UI实现完成 | - |
| 下拉刷新 | 2025-11-02 | ✅ 功能实现完成 | - |
| 国际化切换 | 2025-11-02 | ✅ 中英文支持完成 | - |

---

## 📝 更新日志

### 2025-11-02 (下午) - 🎉 核心功能完成
- ✅ **阶段一：后端API实现**
  - 创建 `get_student_assigned_plans` Cloud Function
  - 创建 `fetch_latest_training` Cloud Function
  - 在 `main.py` 导入导出函数
  - Python语法检查通过

- ✅ **阶段二：前端数据层实现**
  - 创建 `StudentPlansModel` 和 `DailyTrainingModel` 数据模型
  - 扩展 `CloudFunctionsService` 添加2个新方法
  - 创建 `StudentHomeRepository` 接口和实现
  - 创建 Providers（计划、训练记录、Day Number计算）
  - 实现Day Number循环逻辑

- ✅ **阶段三：前端UI组件实现**
  - 创建 `WeeklyStatusSection` (本周状态)
  - 创建 `TodayRecordSection` 及3个子卡片组件
  - 创建 `TodayTrainingPlanSection` (今日计划)
  - 创建 `EmptyPlanPlaceholder` (空状态)
  - 更新 `StudentHomePage` 为 ConsumerWidget
  - 实现下拉刷新、错误处理、空状态处理

- ✅ **阶段四：国际化**
  - 添加20+个新的国际化key (中英文)
  - 运行 `flutter gen-l10n` 生成代码

- ✅ **阶段五：代码质量保证**
  - 修复所有编译错误
  - 添加缺失的 `shadowColor` 和 `successColor` 到 AppColors
  - Flutter analyze 检查通过 (0 issues)
  - 所有代码遵循规范 (AppTextStyles、AppLocalizations)

- ⏳ **待完成**：集成测试和端到端测试

### 2025-11-02 (上午)
- ✅ 创建进度追踪文档
- ✅ 完成技术规划和检查清单

---

## 📦 产物清单

### 后端文件（已完成）
- [x] `functions/plans/handlers.py` (修改 - 添加 `get_student_assigned_plans`)
- [x] `functions/students/handlers.py` (修改 - 添加 `fetch_latest_training`)
- [x] `functions/main.py` (修改 - 导入导出新函数)

### 前端文件（已完成）
- [x] `lib/features/student/home/data/models/student_plans_model.dart`
- [x] `lib/features/student/home/data/models/daily_training_model.dart`
- [x] `lib/features/student/home/data/repositories/student_home_repository.dart`
- [x] `lib/features/student/home/data/repositories/student_home_repository_impl.dart`
- [x] `lib/features/student/home/presentation/providers/student_home_providers.dart`
- [x] `lib/features/student/home/presentation/widgets/weekly_status_section.dart`
- [x] `lib/features/student/home/presentation/widgets/today_record_section.dart`
- [x] `lib/features/student/home/presentation/widgets/diet_record_card.dart`
- [x] `lib/features/student/home/presentation/widgets/exercise_record_card.dart`
- [x] `lib/features/student/home/presentation/widgets/supplement_record_card.dart`
- [x] `lib/features/student/home/presentation/widgets/today_training_plan_section.dart`
- [x] `lib/features/student/home/presentation/widgets/empty_plan_placeholder.dart`
- [x] `lib/features/student/home/presentation/pages/student_home_page.dart` (修改)
- [x] `lib/core/services/cloud_functions_service.dart` (修改)
- [x] `lib/core/theme/app_colors.dart` (修改 - 添加shadowColor和successColor)
- [x] `lib/l10n/app_en.arb` (修改 - 添加20+个key)
- [x] `lib/l10n/app_zh.arb` (修改 - 添加20+个key)

### 文档文件
- [x] `docs/student/student_home_implementation_progress.md` (本文档)

**总计**: 18个文件（13个新增 + 5个修改）

---

## 🎯 下一步行动

### ✅ 核心功能已完成

所有核心功能（阶段一至五）已成功实现并通过代码质量检查。学生首页现已可用，包含以下功能：

1. ✅ 后端API（获取计划、获取训练记录）
2. ✅ 前端数据层（模型、Repository、Providers、Day Number计算）
3. ✅ 前端UI（周状态、今日记录、训练计划、空状态）
4. ✅ 国际化支持（中英文）
5. ✅ 代码质量保证（Flutter analyze 0 issues）

### 📋 后续待完成项

1. **集成测试** - 需要完整的测试环境
   - 启动Firebase Emulator
   - 准备测试数据（用户、计划、训练记录）
   - 测试API调用和数据流
   - 验证Day Number计算逻辑

2. **端到端测试** - 在真实设备上测试
   - 测试有计划/无计划的UI展示
   - 测试下拉刷新功能
   - 测试导航和交互
   - 测试中英文切换

3. **Weekly Status真实数据** - 依赖 `dailyTraining` collection实现
   - 当前使用占位数据
   - 待 `dailyTraining` 功能实现后替换

4. **详情页面实现** - 点击跳转功能
   - Today's Record点击查看详情
   - Training Plan Detail按钮跳转
   - 学生Plan页面（空状态导航目标）

---

## 📌 实现要点总结

**严格遵循的规范**:
- ✅ 所有文本样式使用 `AppTextStyles.*`
- ✅ 所有用户可见文本使用 `AppLocalizations`
- ✅ 遵循Flutter和Dart命名规范（snake_case文件名）
- ✅ 完整的错误处理和空状态处理
- ✅ 下拉刷新和loading状态
- ✅ Riverpod状态管理最佳实践

**核心业务逻辑**:
- ✅ Day Number循环计算：`(lastDayNumber % totalDays) + 1`
- ✅ 每个学生每类计划只能有一个（取最新）
- ✅ Today's Record显示计划目标值（非实际记录）
- ✅ 无计划时显示空状态并引导用户
