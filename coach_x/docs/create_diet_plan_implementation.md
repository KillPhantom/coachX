# Create Diet Plan Page - 实现总结

**实现日期**: 2025-10-28
**状态**: ✅ 完成
**版本**: v1.0

---

## 📋 概述

本文档记录了饮食计划创建/编辑页面的完整实现，包括前端 UI、后端 API、数据模型和 AI 集成。

### 功能范围

- ✅ 完整的 CRUD 操作（创建、读取、更新、删除、列表、复制）
- ✅ 饮食计划编辑界面（Day → Meal → FoodItem 三层结构）
- ✅ 营养数据自动计算和显示（Protein, Carbs, Fat, Calories）
- ✅ AI 获取食物营养信息
- ✅ 手动输入自定义食物和营养数据
- 🔲 AI 引导创建（占位符，待实现）
- 🔲 AI 对话式编辑（待实现）

---

## 🏗️ 架构设计

### 数据结构

```
DietPlanModel
├── id, name, description
├── ownerId, studentIds
├── createdAt, updatedAt
└── days: List<DietDay>
    ├── day: int (序号)
    ├── name: String (可编辑，如 "Day 1", "High Protein Day")
    ├── completed: bool
    └── meals: List<Meal>
        ├── name: String (e.g., "Meal 1", "Breakfast")
        ├── note: String
        ├── completed: bool
        ├── items: List<FoodItem>
        │   ├── food: String (食物名称)
        │   ├── amount: String (份量，如 "200g")
        │   ├── protein: double
        │   ├── carbs: double
        │   ├── fat: double
        │   ├── calories: double
        │   └── isCustomInput: bool
        └── macros: Macros (自动计算)
            ├── protein: double
            ├── carbs: double
            ├── fat: double
            └── calories: double
```

### 技术栈

**后端:**
- Firebase Cloud Functions (Python 2nd gen)
- Anthropic Claude API (食物营养信息获取)
- Firestore (数据存储)

**前端:**
- Flutter + Cupertino (iOS-first design)
- Riverpod 2.x (状态管理)
- go_router (导航)

---

## 📂 文件清单

### 后端文件 (7 个)

#### 1. `functions/plans/models.py`
**新增模型:**
- `Macros` - 营养数据模型
- `FoodItem` - 食物条目模型
- `Meal` - 餐次模型
- `DietDay` - 饮食日模型
- `DietPlan` - 饮食计划模型

**关键方法:**
- `Macros.__add__()` - 支持营养数据相加
- `Meal.calculate_macros()` - 自动计算餐次营养
- `DietDay.calculate_macros()` - 自动计算每日营养

#### 2. `functions/plans/handlers.py`
**新增函数:**
- `diet_plan(req)` - 主路由函数
- `_create_diet_plan()` - 创建计划
- `_update_diet_plan()` - 更新计划
- `_get_diet_plan()` - 获取单个计划
- `_delete_diet_plan()` - 删除计划
- `_list_diet_plans()` - 列表查询
- `_copy_diet_plan()` - 复制计划
- `_validate_diet_plan_data()` - 数据验证

**集合名称:** `dietPlans`

#### 3. `functions/ai/handlers.py`
**新增函数:**
- `get_food_macros(req)` - AI 获取食物营养信息

**实现逻辑:**
- 接收参数: `food_name`
- 调用 Claude API
- System prompt: "你是营养专家，提供食物营养信息"
- User prompt: "提供 {food_name} 每100g的营养成分"
- 返回结构化 JSON: `{protein, carbs, fat, calories}`

#### 4. `functions/main.py`
**修改:**
- 导入 `diet_plan` 函数
- 导入 `get_food_macros` 函数

### 前端文件 (20 个)

#### 数据模型 (6 个)

**5. `lib/features/coach/plans/data/models/macros.dart`**
- 营养数据模型
- 支持加法运算 (`operator +`)
- `Macros.zero()` 工厂方法

**6. `lib/features/coach/plans/data/models/food_item.dart`**
- 食物条目模型
- 计算属性: `macros`

**7. `lib/features/coach/plans/data/models/meal.dart`**
- 餐次模型
- 计算属性: `macros` (汇总所有 FoodItem)

**8. `lib/features/coach/plans/data/models/diet_day.dart`**
- 饮食日模型
- 计算属性: `macros` (汇总所有 Meal)

**9. `lib/features/coach/plans/data/models/diet_plan_model.dart`**
- 饮食计划模型（扩展）
- 新增字段: `days: List<DietDay>`
- 计算属性: `totalDays`, `totalMeals`, `totalFoodItems`

**10. `lib/features/coach/plans/data/models/create_diet_plan_state.dart`**
- 页面状态模型
- 字段: `planId`, `planName`, `description`, `days`, `isLoading`, `errorMessage`, 等
- 计算属性: `canSave`, `hasUnsavedChanges`

#### 服务层 (2 个)

**11. `lib/features/coach/plans/data/repositories/diet_plan_repository.dart`**
- CRUD 方法: `createPlan()`, `updatePlan()`, `getPlan()`, `deletePlan()`, `listPlans()`, `copyPlan()`
- 调用 Cloud Function: `diet_plan`

**12. `lib/core/services/ai_service.dart` (扩展)**
- 新增方法: `getFoodMacros(String foodName)`
- 调用 Cloud Function: `get_food_macros`

#### 状态管理 (2 个)

**13. `lib/features/coach/plans/presentation/providers/create_diet_plan_notifier.dart`**
- Day 操作: `addDay()`, `removeDay()`, `updateDayName()`
- Meal 操作: `addMeal()`, `removeMeal()`, `updateMealName()`, `updateMealNote()`
- FoodItem 操作: `addFoodItem()`, `removeFoodItem()`, `updateFoodItem()`
- Plan 操作: `updatePlanName()`, `loadPlan()`, `savePlan()`, `validate()`

**14. `lib/features/coach/plans/presentation/providers/create_diet_plan_providers.dart`**
- `dietPlanRepositoryProvider`
- `createDietPlanNotifierProvider`
- Computed providers: `totalDaysProvider`, `totalMealsProvider`, `canSaveProvider`

#### UI 组件 (6 个)

**15. `lib/features/coach/plans/presentation/widgets/macros_display.dart`**
- 显示营养信息（Protein, Carbs, Fat）
- 支持两种模式: `compact`（横向小卡片）, `detailed`（详细显示）

**16. `lib/features/coach/plans/presentation/widgets/food_item_row.dart`**
- 显示单个食物条目
- 格式: `"food name -> amount (P:Xg C:Xg F:Xg)"`
- 右侧删除按钮

**17. `lib/features/coach/plans/presentation/widgets/add_food_dialog.dart`**
- 添加食物对话框
- 步骤:
  1. 输入食物名称
  2. 输入份量
  3. 点击 "AI 获取" → 调用 `AIService.getFoodMacros()`
  4. 显示营养数据，允许手动编辑
  5. 确认添加
- 支持手动输入自定义营养数据

**18. `lib/features/coach/plans/presentation/widgets/meal_card.dart`**
- 餐次卡片
- Header: Meal 名称 + MacrosDisplay + Edit 按钮
- Body: Note + FoodItems 列表 + Add Food 按钮

**19. `lib/features/coach/plans/presentation/widgets/diet_day_editor.dart`**
- 饮食日编辑器（容器组件）
- 包含: Meals 列表 + Add Meal 按钮

**20. `lib/features/coach/plans/presentation/widgets/guided_diet_creation_sheet.dart`**
- AI 引导创建占位符
- 显示 "功能开发中，敬请期待！"

#### 页面 (1 个)

**21. `lib/features/coach/plans/presentation/pages/create_diet_plan_page.dart`**
- 主页面，完全参考 `create_training_plan_page.dart` 架构
- 布局:
  - NavigationBar (Back + Title + Sparkle)
  - PlanHeaderWidget (计划名称 + 统计)
  - Day Pills (横向滚动)
  - DietDayEditor (内容区)
  - Save Button

**功能:**
- 创建模式 vs 编辑模式
- Day/Meal/FoodItem 的 CRUD 操作
- 验证和保存
- 错误处理

#### 路由 (3 个)

**22. `lib/routes/route_names.dart`**
- 新增常量: `createDietPlan = 'create-diet-plan'`

**23. `lib/routes/app_router.dart`**
- 新增路由: `/coach/create-diet-plan?planId={id}`

**24. `lib/features/coach/plans/presentation/pages/plans_page.dart`**
- Diet 标签 FAB: 跳转到创建页面
- Diet 列表 onTap: 跳转到编辑页面

---

## 🔑 核心功能实现

### 1. 营养数据自动计算

**实现逻辑:**
```dart
// FoodItem 层面
class FoodItem {
  Macros get macros => Macros(
    protein: protein,
    carbs: carbs,
    fat: fat,
    calories: calories,
  );
}

// Meal 层面
class Meal {
  Macros get macros => items.fold(
    Macros.zero(),
    (sum, item) => sum + item.macros,
  );
}

// DietDay 层面
class DietDay {
  Macros get macros => meals.fold(
    Macros.zero(),
    (sum, meal) => sum + meal.macros,
  );
}
```

**优势:**
- ✅ 实时更新
- ✅ 无需手动计算
- ✅ 准确性保证

### 2. AI 获取食物营养信息

**前端调用:**
```dart
final macros = await AIService.getFoodMacros('chicken breast');
// 返回: Macros(protein: 31, carbs: 0, fat: 3.6, calories: 165)
```

**后端实现:**
```python
@https_fn.on_call()
def get_food_macros(req: https_fn.CallableRequest):
    food_name = req.data.get('food_name')

    # 调用 Claude API
    response = anthropic_client.messages.create(
        model="claude-3-5-sonnet-20241022",
        system="你是营养专家...",
        messages=[{
            "role": "user",
            "content": f"提供 {food_name} 每100g的营养成分..."
        }],
        max_tokens=500,
    )

    # 解析 JSON
    data = json.loads(response.content[0].text)
    return {"status": "success", "data": data}
```

**用户体验:**
1. 输入 "鸡胸肉" → 点击 "AI 获取"
2. 加载中...
3. 自动填充: P:31g, C:0g, F:3.6g, Calories:165
4. 可手动调整
5. 确认添加

### 3. 手动输入自定义营养数据

**场景:**
- AI 无法识别的食物
- 自制食品
- 需要自定义配比

**实现:**
- AddFoodDialog 所有字段可编辑
- 设置 `isCustomInput: true`
- 保存时不依赖 AI

---

## 📊 API 文档

### 后端 API

#### 1. `diet_plan` (Cloud Function)

**请求格式:**
```json
{
  "action": "create | update | get | delete | list | copy",
  "planId": "plan_id_here",  // 非 create 时必需
  "planData": {              // create/update 时必需
    "name": "My Diet Plan",
    "description": "...",
    "days": [
      {
        "day": 1,
        "name": "Day 1",
        "meals": [
          {
            "name": "Meal 1",
            "note": "",
            "items": [
              {
                "food": "chicken breast",
                "amount": "200g",
                "protein": 62,
                "carbs": 0,
                "fat": 7.2,
                "calories": 330,
                "isCustomInput": false
              }
            ],
            "completed": false
          }
        ],
        "completed": false
      }
    ]
  }
}
```

**响应格式:**
```json
{
  "status": "success",
  "data": {
    "id": "plan_id",
    "name": "My Diet Plan",
    "days": [...]
  },
  "message": "操作成功"
}
```

#### 2. `get_food_macros` (Cloud Function)

**请求:**
```json
{
  "food_name": "chicken breast"
}
```

**响应:**
```json
{
  "status": "success",
  "data": {
    "protein": 31.0,
    "carbs": 0.0,
    "fat": 3.6,
    "calories": 165.0
  }
}
```

---

## 🎨 UI 设计

### 页面布局

```
┌─────────────────────────────────┐
│ ← Create Diet Plan          ✨ │ NavigationBar
├─────────────────────────────────┤
│ Plan Name: [_______________]    │ PlanHeaderWidget
│ Days: 3  Meals: 9  Items: 27    │
├─────────────────────────────────┤
│ [Day 1] [Day 2] [Day 3] [+ Add]│ Day Pills (horizontal scroll)
├─────────────────────────────────┤
│                                 │
│ ┌─ Meal 1 ─────────────────┐   │
│ │ P:40g C:80g F:15g     ✏️ │   │ MealCard
│ │                           │   │
│ │ • chicken breast -> 200g  │   │ FoodItemRow
│ │   (P:62g C:0g F:7.2g)  ❌│   │
│ │ • rice -> 100g            │   │
│ │   (P:2.7g C:28g F:0.3g)❌│   │
│ │                           │   │
│ │ [+ Add Food]              │   │
│ └───────────────────────────┘   │
│                                 │
│ ┌─ Meal 2 ─────────────────┐   │
│ │ ...                       │   │
│ └───────────────────────────┘   │
│                                 │
│ [+ Add Meal]                    │
│                                 │
├─────────────────────────────────┤
│ [      Save Plan      ]         │ Save Button
└─────────────────────────────────┘
```

### 颜色和样式

遵循项目 Typography 标准:
- Plan Name: `AppTextStyles.title2`
- Day Pill: `AppTextStyles.callout`
- Meal Name: `AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)`
- Macros: `AppTextStyles.caption1`
- Food Item: `AppTextStyles.footnote`

主题色:
- Primary: `#f2e8cf`
- Card Background: `CupertinoColors.systemBackground`
- Text Primary: `CupertinoColors.label`

---

## ✅ 测试清单

### 后端测试

- [ ] `diet_plan` create action - 创建新计划
- [ ] `diet_plan` update action - 更新现有计划
- [ ] `diet_plan` get action - 获取单个计划
- [ ] `diet_plan` delete action - 删除计划
- [ ] `diet_plan` list action - 列表查询
- [ ] `diet_plan` copy action - 复制计划
- [ ] `get_food_macros` - AI 获取食物营养信息
- [ ] 权限验证 - 仅 owner 可修改/删除
- [ ] 数据验证 - name 非空，days 结构合法

### 前端测试

- [ ] 创建新计划 - 默认添加 Day 1
- [ ] 添加/删除 Day
- [ ] 编辑 Day 名称
- [ ] 添加/删除 Meal
- [ ] 编辑 Meal 名称和 Note
- [ ] AI 获取食物营养信息
- [ ] 手动输入自定义营养数据
- [ ] 添加/删除 FoodItem
- [ ] Macros 自动计算（Meal 和 Day 层面）
- [ ] 保存计划（创建模式）
- [ ] 加载并编辑现有计划（编辑模式）
- [ ] 表单验证 - planName 必填，至少一个 day
- [ ] 错误处理 - 网络错误、AI 调用失败
- [ ] 导航 - 返回时检查未保存更改

### 集成测试

- [ ] 端到端流程: 创建 → 保存 → 列表显示 → 编辑 → 保存
- [ ] Plans Page 跳转到 Create Diet Plan Page
- [ ] Create Diet Plan Page 返回到 Plans Page
- [ ] 多设备同步（Firestore 实时更新）

---

## 🚀 部署步骤

### 1. 部署后端

```bash
cd functions
firebase deploy --only functions:diet_plan,functions:get_food_macros
```

### 2. 验证后端

```bash
# 本地测试
firebase emulators:start --only functions

# 测试 diet_plan
curl -X POST http://localhost:5001/.../diet_plan \
  -H "Content-Type: application/json" \
  -d '{"action": "list"}'

# 测试 get_food_macros
curl -X POST http://localhost:5001/.../get_food_macros \
  -H "Content-Type: application/json" \
  -d '{"food_name": "chicken breast"}'
```

### 3. 部署前端

```bash
# 运行代码生成（如果使用了 Riverpod generators）
flutter pub run build_runner build --delete-conflicting-outputs

# 运行 app
flutter run -d ios  # 或 android
```

### 4. Firestore Rules（如需更新）

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /dietPlans/{planId} {
      allow read: if request.auth != null &&
                    (resource.data.ownerId == request.auth.uid ||
                     request.auth.uid in resource.data.studentIds);
      allow create: if request.auth != null &&
                      request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null &&
                              resource.data.ownerId == request.auth.uid;
    }
  }
}
```

---

## 🔮 未来优化

### 优先级 1

- [ ] **AI 引导创建** - 类似 Training Plan 的流式生成
  - 用户输入: 目标、饮食偏好、热量目标
  - AI 生成: 完整的多天饮食计划

- [ ] **AI 对话编辑** - 自然语言修改计划
  - "将第一天的鸡胸肉改成牛肉"
  - "增加一顿晚餐"

### 优先级 2

- [ ] **Food Library 集成** - 从食物库快速添加
  - 搜索公共食物库
  - 保存常用食物

- [ ] **营养目标设置** - 每日目标跟踪
  - 设置目标 Macros
  - 实时显示完成度

- [ ] **模板功能** - 复用常见餐次
  - 保存 "典型早餐"
  - 一键添加到新 day

### 优先级 3

- [ ] **图片上传** - 餐次照片
- [ ] **营养建议** - AI 分析并提供优化建议
- [ ] **购物清单** - 根据计划生成食材清单

---

## 📝 总结

### 已完成功能

1. ✅ 完整的饮食计划 CRUD 操作
2. ✅ 三层嵌套数据结构（Day → Meal → FoodItem）
3. ✅ 营养数据自动计算和显示
4. ✅ AI 智能获取食物营养信息
5. ✅ 手动输入自定义营养数据
6. ✅ Cupertino 风格的完整 UI
7. ✅ 与现有 Plans Page 集成

### 技术亮点

- 🏗️ **模块化架构** - 清晰的分层（models, repositories, providers, widgets, pages）
- 🔄 **响应式状态管理** - Riverpod + computed properties
- 🧮 **智能计算** - Macros 自动汇总
- 🤖 **AI 集成** - Claude API 提供营养信息
- 📱 **原生体验** - Cupertino 组件 + iOS 风格设计
- ♻️ **代码复用** - 参考 Training Plan 架构

### 代码统计

- 📁 新建文件: 20 个
- ✏️ 修改文件: 4 个
- 📄 代码行数: ~3500 行（估计）
- 🧪 测试覆盖: 待完善

---

**最后更新**: 2025-10-28
**维护者**: Claude Code
**文档版本**: 1.0
