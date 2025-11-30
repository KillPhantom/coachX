# Student Home Page - 今日饮食计划优化

**功能**: 学生首页今日饮食计划区块（TodayRecordSection）UI 优化和餐次记录编辑

**实现日期**: 2025-11-17

**状态**: ✅ 已完成

---

## 功能概述

本次优化针对学生首页的今日饮食计划卡片进行了全面的 UI 和交互改进，包括：

1. **实时营养数据显示**: 显示实际摄入值和目标值的对比
2. **动态进度条颜色**: 根据完成度自动改变颜色（未完成/完成/超出）
3. **餐次记录状态识别**: 已记录的餐次显示绿色边框和查看详情按钮
4. **餐次详情查看和编辑**: 完整的 Bottom Sheet 支持查看、编辑、保存餐次信息
5. **图片和食物管理**: 支持添加/删除图片，添加/编辑/删除食物项

---

## 实现功能清单

### 1. TotalNutritionCard（总营养卡片）

**文件**: `lib/features/student/home/presentation/widgets/diet_plan_card_components/total_nutrition_card.dart`

#### 功能改进：

- ✅ **环形进度条 3 色逻辑**
  - **绿色** (`AppColors.successGreen`): 0.95 ≤ progress ≤ 1.05（完成良好）
  - **红色** (`AppColors.errorRed`): progress > 1.05（超出）
  - **米黄色** (`AppColors.primaryColor`): progress < 0.95（未完成）

- ✅ **实际值/目标值显示**
  - 中心上方：实际摄入值（大字体）
  - 中心下方：目标值 + 单位（小字体）
  - 无记录时：仅显示目标值

- ✅ **新增参数**
  ```dart
  final Macros? actualMacros;  // 实际摄入营养数据
  ```

#### 颜色判断逻辑：

```dart
Color progressColor;
if (calorieProgress >= 0.95 && calorieProgress <= 1.05) {
  progressColor = AppColors.successGreen;
} else if (calorieProgress > 1.05) {
  progressColor = AppColors.errorRed;
} else {
  progressColor = AppColors.primaryColor;
}
```

---

### 2. MacroProgressBar（宏营养素进度条）

**文件**: `lib/features/student/home/presentation/widgets/diet_plan_card_components/macro_progress_bar.dart`

#### 功能改进：

- ✅ **显示格式更新**: `95/120g`（实际值/目标值）
- ✅ **内部颜色计算**: 同 TotalNutritionCard 的 3 色逻辑
- ✅ **新增参数**
  ```dart
  final double actualValue;      // 实际摄入值
  final int targetValue;         // 目标值（原 value 重命名）
  ```

#### 示例显示：

```
Protein  95/120g
[========>     ]  (进度条颜色根据 progress 动态变化)
```

---

### 3. MealDetailCard（餐次详情卡片）

**文件**: `lib/features/student/home/presentation/widgets/diet_plan_card_components/meal_detail_card.dart`

#### 功能改进：

- ✅ **记录检测逻辑**: 通过餐名 (`meal.name`) 匹配今日记录
- ✅ **绿色边框**: 有记录时显示 2px 绿色边框
  ```dart
  border: hasRecord
      ? Border.all(color: AppColors.successGreen, width: 2)
      : null
  ```
- ✅ **查看详情按钮**: 右上角显示（仅有记录时）
- ✅ **优先显示记录数据**: 有记录时显示 `recordedMeal` 数据

#### 新增参数：

```dart
final Meal? recordedMeal;        // 今日记录的餐次
final VoidCallback? onViewDetails;  // 查看详情回调
```

---

### 4. MealDetailBottomSheet（餐次详情和编辑）

**文件**: `lib/features/student/home/presentation/widgets/meal_detail_bottom_sheet.dart`

**状态**: ✅ 全新创建

#### 功能模块：

##### 4.1 顶部导航栏
- 左侧：关闭按钮 (`CupertinoIcons.xmark`)
- 中间：标题 "餐次详情"
- 右侧：占位

##### 4.2 照片预览区
- **显示**: 水平滚动的图片列表
- **添加**: 点击 `+` 按钮从相册选择
- **删除**: 每张图片右上角显示删除按钮
- **支持**: 本地图片 (`File`) 和网络图片 (`http`)

##### 4.3 餐次信息区
- **餐名**: 只读显示（灰色背景）
- **备注**: 可编辑 `CupertinoTextField`（2 行）

##### 4.4 食物列表区
- **显示**: 所有食物项，包含名称、数量、营养数据
- **添加**: 点击 "添加食物" 按钮，弹出 Dialog 输入
- **编辑**: 点击食物项的编辑图标
- **删除**: 点击食物项的删除图标

##### 4.5 食物编辑 Dialog
输入字段：
- 食物名称 (`foodName`)
- 数量 (`amount`)
- 卡路里 (`calories`, kcal)
- 蛋白质 (`protein`, g)
- 碳水化合物 (`carbs`, g)
- 脂肪 (`fat`, g)

##### 4.6 总营养数据区
- **自动计算**: 从所有食物项累加
- **显示**: 4 个营养值（卡路里、蛋白质、碳水、脂肪）
- **样式**: 米黄色背景卡片

##### 4.7 底部保存按钮
- **文本**: "保存修改"
- **状态**: 保存中显示 loading 指示器
- **功能**: 调用 `onUpdate` 回调

#### 参数：

```dart
final Meal recordedMeal;                          // 已记录的餐次
final Future<void> Function(Meal) onUpdate;       // 更新回调
```

---

### 5. DietPlanCard（饮食计划卡片）

**文件**: `lib/features/student/home/presentation/widgets/diet_plan_card.dart`

#### 功能改进：

- ✅ **参数定义**
  ```dart
  final DietDay? dietDay;                         // 教练设置的饮食日（可为空）
  final List<Meal> mergedMeals;                   // 合并后的餐次列表（必填）
  final Macros? actualMacros;                     // 实际营养数据
  final StudentDietRecordModel? todayDietRecord;  // 今日饮食记录
  ```

- ✅ **合并餐次展示**：使用 `mergedMeals` 而非 `dietDay.meals` 计算页数和展示餐次
  ```dart
  final totalPages = widget.mergedMeals.length + 1;
  final displayMeal = widget.mergedMeals[mealIndex];
  ```

- ✅ **查找匹配餐次**
  ```dart
  final recordedMeal = todayDietRecord?.meals
      .cast<Meal?>()
      .firstWhere((m) => m?.name == displayMeal.name, orElse: () => null);
  ```

- ✅ **显示 Bottom Sheet**
  ```dart
  void _showMealDetailSheet(BuildContext context, Meal recordedMeal) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => MealDetailBottomSheet(...),
    );
  }
  ```

- ✅ **处理更新逻辑**
  ```dart
  Future<void> _handleMealUpdate(Meal updatedMeal) async {
    // 调用 Cloud Function
    await CloudFunctionsService.call('update_meal_record', {...});
    // 刷新 Providers
    ref.invalidate(optimizedTodayTrainingProvider);
    ref.invalidate(dietProgressProvider);
    ref.invalidate(actualDietMacrosProvider);
  }
  ```

---

### 6. TodayRecordSection（今日记录区块）

**文件**: `lib/features/student/home/presentation/widgets/today_record_section.dart`

#### 功能改进：

- ✅ **获取额外数据**
  ```dart
  final actualMacros = ref.watch(actualDietMacrosProvider);
  final todayTrainingAsync = ref.watch(optimizedTodayTrainingProvider);
  ```

- ✅ **合并餐次逻辑**
  ```dart
  /// 合并计划餐次和学生自行添加的餐次
  List<Meal> _getMergedMeals(List<Meal> planMeals, List<Meal>? recordedMeals) {
    if (recordedMeals == null || recordedMeals.isEmpty) {
      return planMeals;
    }
    final planMealNames = planMeals.map((m) => m.name).toSet();
    final extraMeals = recordedMeals
        .where((m) => !planMealNames.contains(m.name))
        .toList();
    return [...planMeals, ...extraMeals];
  }
  ```

- ✅ **传递数据到子组件**
  ```dart
  DietPlanCard(
    dietDay: dietDay,           // 可为 null
    mergedMeals: mergedMeals,   // 合并后的餐次列表
    actualMacros: actualMacros,
    todayDietRecord: todayTraining?.diet,
    progress: progress,
  )
  ```

---

## 数据层实现

### 7. actualDietMacrosProvider

**文件**: `lib/features/student/home/presentation/providers/student_home_providers.dart`

**类型**: `Provider<Macros?>`

**功能**: 从今日训练记录中提取实际摄入的营养数据

**实现**:
```dart
final actualDietMacrosProvider = Provider<Macros?>((ref) {
  final todayTrainingAsync = ref.watch(optimizedTodayTrainingProvider);

  if (todayTrainingAsync.isLoading || todayTrainingAsync.hasError) {
    return null;
  }

  final todayTraining = todayTrainingAsync.value;

  if (todayTraining == null || todayTraining.diet == null) {
    return null;
  }

  return todayTraining.diet!.macros;
});
```

---

## 后端实现

### 8. update_meal_record Cloud Function

**文件**: `functions/students/training_handlers.py`

**函数名**: `update_meal_record`

**类型**: `@https_fn.on_call()`

#### 请求参数：

```python
{
  "studentId": "string",  # 可选，默认当前用户
  "date": "yyyy-MM-dd",   # 必填
  "meal": {               # 必填
    "name": "早餐",
    "note": "备注",
    "items": [...],
    "images": [...]
  }
}
```

#### 返回：

```python
{
  "status": "success",
  "message": "餐次更新成功"
}
```

#### 逻辑：

1. 验证用户登录和参数
2. 查找 `dailyTrainings` 中指定日期的记录
3. 获取现有的 `diet.meals` 列表
4. 通过 `meal.name` 查找匹配的餐次
5. 如果找到：更新餐次
6. 如果未找到：添加新餐次
7. 更新 Firestore 并返回成功

#### 错误处理：

- `unauthenticated`: 用户未登录
- `invalid-argument`: 参数错误
- `not-found`: 未找到训练记录
- `internal`: 其他错误

---

## 国际化 (i18n)

### 新增 Keys

**文件**: `lib/l10n/app_en.arb`, `lib/l10n/app_zh.arb`

| Key | English | 中文 |
|-----|---------|------|
| `viewDetails` | View Details | 查看详情 |
| `mealDetails` | Meal Details | 餐次详情 |
| `saveChanges` | Save Changes | 保存修改 |
| `addFood` | Add Food | 添加食物 |
| `editFood` | Edit Food | 编辑食物 |
| `deleteFood` | Delete Food | 删除食物 |
| `foodName` | Food Name | 食物名称 |
| `amount` | Amount | 数量 |

---

## 数据流图

```
┌─────────────────────────────────────────────────┐
│  optimizedTodayTrainingProvider                 │
│  ↓                                              │
│  actualDietMacrosProvider ──→ Macros?           │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  StudentPlansModel (计划数据)                    │
│  + actualMacros (实际数据)                       │
│  + todayDietRecord (今日记录)                    │
└─────────────────────────────────────────────────┘
                    ↓
        ┌───────────┴───────────┐
        ↓                       ↓
┌───────────────┐      ┌────────────────┐
│TotalNutrition│      │ MealDetailCard │
│    Card       │      │   (多个餐次)    │
├───────────────┤      ├────────────────┤
│ 环形进度条     │      │ 检测记录状态    │
│ 3色逻辑       │      │ 绿色边框       │
│ 实际/目标值   │      │ 查看详情按钮    │
└───────────────┘      └────────────────┘
        ↓                       ↓
┌───────────────┐      ┌────────────────┐
│MacroProgress  │      │MealDetail      │
│     Bar       │      │ BottomSheet    │
│ (Protein等)   │      ├────────────────┤
├───────────────┤      │ 编辑餐次       │
│ 95/120g       │      │ 管理照片       │
│ 3色进度条     │      │ 编辑食物       │
└───────────────┘      │ 保存更新       │
                       └────────────────┘
                               ↓
                    ┌──────────────────┐
                    │ Cloud Function   │
                    │update_meal_record│
                    └──────────────────┘
                               ↓
                    ┌──────────────────┐
                    │   Firestore      │
                    │  dailyTrainings  │
                    │  diet.meals[]    │
                    └──────────────────┘
```

---

## 文件结构

```
lib/features/student/home/
├── presentation/
│   ├── pages/
│   │   └── student_home_page.dart
│   ├── providers/
│   │   └── student_home_providers.dart          [修改] 新增 actualDietMacrosProvider
│   └── widgets/
│       ├── today_record_section.dart            [修改] 传递额外数据
│       ├── diet_plan_card.dart                  [修改] 连接 Bottom Sheet
│       ├── meal_detail_bottom_sheet.dart        [新建] 餐次详情和编辑
│       └── diet_plan_card_components/
│           ├── total_nutrition_card.dart        [修改] 3色+实际值显示
│           ├── macro_progress_bar.dart          [修改] 3色+格式更新
│           └── meal_detail_card.dart            [修改] 记录检测+边框

lib/l10n/
├── app_en.arb                                   [修改] 新增 8 个 keys
└── app_zh.arb                                   [修改] 新增 8 个 keys

functions/
├── main.py                                      [修改] 导出 update_meal_record
└── students/
    └── training_handlers.py                     [修改] 新增 update_meal_record
```

---

## 使用流程

### 用户视角

1. **查看进度**
   - 打开学生首页
   - 查看"今日记录"卡片
   - 环形进度条和宏营养进度条显示实时数据和颜色

2. **查看餐次详情**（有记录时）
   - 左右滑动查看各餐次卡片
   - 有记录的餐次显示绿色边框
   - 点击右上角"查看详情"按钮

3. **编辑餐次**
   - Bottom Sheet 显示餐次详情
   - 修改备注
   - 添加/删除照片
   - 添加/编辑/删除食物项
   - 点击"保存修改"

4. **查看更新结果**
   - 自动刷新数据
   - 进度条颜色和数值实时更新

---

## 技术要点

### 1. 颜色逻辑统一

所有进度条（环形和横向）使用相同的颜色判断逻辑：

```dart
Color getProgressColor(double progress, bool hasTarget) {
  if (!hasTarget) {
    return AppColors.primaryColor; // 无目标值时使用主题色
  }
  if (progress >= 0.95 && progress <= 1.05) {
    return AppColors.successGreen;
  } else if (progress > 1.05) {
    return AppColors.errorRed;
  } else {
    return AppColors.primaryColor;
  }
}
```

### 1.1 无目标值时的显示逻辑

当教练未设置目标营养值时：
- **环形进度条**: 显示实际摄入值，进度按 2000kcal 为满计算
- **宏营养素进度条**: 只显示 `Xg`（不显示目标），进度按 100g 为满计算
- **颜色**: 统一使用主题色，不进行完成度判断

### 2. 餐次匹配与合并逻辑

**合并策略**：当教练未设置餐次时，学生自行添加的记录也需要展示。

```dart
/// 合并计划餐次和学生自行添加的餐次
List<Meal> _getMergedMeals(List<Meal> planMeals, List<Meal>? recordedMeals) {
  if (recordedMeals == null || recordedMeals.isEmpty) {
    return planMeals;
  }

  // 获取计划餐次的名称集合
  final planMealNames = planMeals.map((m) => m.name).toSet();

  // 找出学生自行添加的餐次（不在计划中的）
  final extraMeals =
      recordedMeals.where((m) => !planMealNames.contains(m.name)).toList();

  // 合并：计划餐次 + 额外餐次
  return [...planMeals, ...extraMeals];
}
```

**匹配场景**：

| 场景 | planMeals | recordedMeals | 结果 |
|------|-----------|---------------|------|
| 教练设置餐次，学生未记录 | [早餐,午餐,晚餐] | [] | 显示3餐 |
| 教练设置餐次，学生已记录 | [早餐,午餐,晚餐] | [早餐] | 显示3餐，早餐有绿色边框 |
| 教练未设置，学生已记录 | [] | [第1餐,第2餐] | 显示2餐 |
| 教练未设置，学生未记录 | [] | [] | 只显示总营养卡片 |
| 混合场景 | [早餐,午餐] | [早餐,第3餐] | 显示3餐：早餐,午餐,第3餐 |

### 3. Provider 刷新策略

更新后刷新所有相关 Provider：

```dart
ref.invalidate(optimizedTodayTrainingProvider);  // 训练记录
ref.invalidate(dietProgressProvider);             // 饮食进度
ref.invalidate(actualDietMacrosProvider);         // 实际营养
```

### 4. 图片处理

支持本地和网络图片：

```dart
imagePath.startsWith('http')
  ? Image.network(imagePath, ...)
  : Image.file(File(imagePath), ...)
```

### 5. FoodItem 数据结构

```dart
FoodItem(
  food: "鸡胸肉",
  amount: "150g",
  calories: 165.0,
  protein: 31.0,
  carbs: 0.0,
  fat: 3.6,
)
```

---

## 测试清单

### 前端测试

- [ ] 无记录时显示米黄色进度条
- [ ] 完成度 95-105% 显示绿色进度条
- [ ] 完成度 >105% 显示红色进度条
- [ ] 实际值/目标值显示正确
- [ ] 宏营养素显示 `95/120g` 格式
- [ ] 无记录餐次无边框
- [ ] 有记录餐次显示绿色边框
- [ ] "查看详情"按钮仅有记录时显示
- [ ] Bottom Sheet 正常打开
- [ ] 照片添加/删除功能
- [ ] 食物添加/编辑/删除功能
- [ ] 备注编辑功能
- [ ] 总营养数据自动计算
- [ ] 保存功能正常

### 后端测试

- [ ] `update_meal_record` 函数部署成功
- [ ] 更新已有餐次成功
- [ ] 添加新餐次成功
- [ ] 参数验证正确
- [ ] 错误处理完整
- [ ] Firestore 数据正确更新

---

## 部署步骤

### 1. 前端部署

```bash
# 生成国际化代码
flutter pub get

# 运行代码检查
flutter analyze

# 构建应用
flutter build ios
# 或
flutter build apk
```

### 2. 后端部署

```bash
cd functions

# 部署 Cloud Function
firebase deploy --only functions:update_meal_record

# 或部署所有函数
firebase deploy --only functions
```

### 3. 验证部署

```bash
# 查看函数日志
firebase functions:log --only update_meal_record

# 测试函数调用
firebase functions:shell
> update_meal_record({studentId: "test", date: "2025-11-17", meal: {...}})
```

---

## 已知问题

### 1. 图片上传

**问题**: 当前仅支持本地图片路径，未实现图片上传到 Firebase Storage

**解决方案**:
- 保存时先上传图片到 Storage
- 获取下载 URL
- 更新 `meal.images` 为 URL 数组

### 2. 离线支持

**问题**: 需要网络连接才能保存更新

**解决方案**:
- 使用 Firestore 离线缓存
- 添加网络状态检测
- 显示同步状态提示

---

## 未来改进

### 短期改进

1. **图片上传功能**
   - 集成 Firebase Storage
   - 压缩图片以节省空间
   - 显示上传进度

2. **快速输入**
   - 食物数据库搜索
   - 历史食物快速添加
   - 常用食物收藏

3. **批量操作**
   - 批量删除食物
   - 复制餐次到其他日期
   - 导出餐次数据

### 长期改进

1. **AI 辅助**
   - 食物识别（拍照识别）
   - 营养数据自动填充
   - 餐次推荐

2. **数据分析**
   - 营养趋势图表
   - 完成率统计
   - 营养均衡评分

3. **社交功能**
   - 分享餐次记录
   - 餐次模板市场
   - 营养师点评

---

## 相关文档

- [Student Home Implementation Progress](./student_home_implementation_progress.md)
- [Diet Record Page Architecture](../diet_record_page_architecture.md)
- [Backend APIs and Document DB Schemas](../backend_apis_and_document_db_schemas.md)
- [AI Food Nutrition Feature](../ai_food_nutrition_feature.md)

---

## 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|----------|------|
| 2025-11-17 | 1.0 | 初始版本，完成所有功能实现 | Claude |
| 2025-11-28 | 1.1 | 修复教练未设置 meals 时学生端无法展示自行添加的餐次记录 | Claude |
| 2025-11-28 | 1.2 | 修复 Summary Card 在无目标值时的显示逻辑 | Claude |

---

## 附录

### A. 颜色参考

```dart
// 功能色
AppColors.successGreen  // #10B981 - 完成良好
AppColors.errorRed      // #EF4444 - 超出
AppColors.primaryColor  // #F2E8CF - 未完成

// 其他
AppColors.primaryText   // #6B5E3F - 主要文字
AppColors.textSecondary // #4B5563 - 次要文字
```

### B. 关键类型定义

```dart
// 营养数据
class Macros {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}

// 餐次
class Meal {
  final String name;
  final String note;
  final List<FoodItem> items;
  final List<String> images;
}

// 食物项
class FoodItem {
  final String food;
  final String amount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
}
```

### C. Provider 依赖关系

```
optimizedTodayTrainingProvider
  ├─ actualDietMacrosProvider
  └─ dietProgressProvider
       └─ currentDayNumbersProvider
            └─ studentPlansProvider
```

---

**文档状态**: ✅ 完成
**最后更新**: 2025-11-28
**维护者**: Development Team
