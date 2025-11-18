# Weight Card 智能显示实现文档

## 概述

本文档记录了 Student Home Page 中 Weight Card 智能显示功能的完整实现过程。该功能实现了根据体重记录的时间跨度，智能选择显示格式：
- **相对天数模式**：记录跨度 < 7 天，显示如 "-0.1kg 3 days ago"
- **周对比模式**：记录跨度 >= 7 天，显示如 "-0.2kg last week"

---

## 问题背景

### 原始问题

用户在有 3 条体重记录的情况下，Weight Card 显示为：
```
|73.9kg    |
|上周数据   |
```

这个显示不准确，因为：
1. 3 条记录可能都在最近几天，没有"上周"数据
2. 后端按"本周 vs 上周"计算，但用户记录跨度可能 < 7 天
3. 缺少对短期记录对比的支持

### 用户需求

- 记录跨度 >= 7 天：显示 `-0.2kg last week`
- 记录跨度 < 7 天：显示 `-0.1kg 3 days ago`
- 提供更直观的体重变化信息

---

## 架构设计

### 整体架构

```
┌─────────────────────────────────────────┐
│         UI Layer (Widgets)              │
│  ┌─────────────────────────────────┐    │
│  │  WeeklyStatusSection            │    │
│  │    └─ Weight Card (Consumer)   │    │
│  └─────────────────────────────────┘    │
└──────────────┬──────────────────────────┘
               │ watch
               ↓
┌─────────────────────────────────────────┐
│      Provider Layer (Riverpod)          │
│  ┌─────────────────────────────────┐    │
│  │  weightComparisonProvider       │    │
│  │  (FutureProvider)               │    │
│  └─────────────────────────────────┘    │
└──────────────┬──────────────────────────┘
               │ uses
               ↓
┌─────────────────────────────────────────┐
│       Repository Layer                  │
│  ┌─────────────────────────────────┐    │
│  │  WeightRepository               │    │
│  │    - getRecentMeasurements()    │    │
│  │    - calculateRelativeChange()  │    │
│  └─────────────────────────────────┘    │
└──────────────┬──────────────────────────┘
               │ queries
               ↓
┌─────────────────────────────────────────┐
│         Data Layer                      │
│  ┌─────────────────────────────────┐    │
│  │  Firestore (bodyMeasure)        │    │
│  │    - studentID                  │    │
│  │    - weight                     │    │
│  │    - recordDate                 │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### 设计原则

1. **渐进增强**：前端补丁方案，不影响后端逻辑
2. **数据优先**：优先使用实时记录，降级使用周统计
3. **用户体验**：智能判断显示模式，提供最相关的信息
4. **可维护性**：清晰的分层架构，易于测试和扩展

---

## 实现细节

### 1. 数据模型

**文件：** `lib/features/student/home/data/models/weight_comparison_model.dart`

```dart
class WeightComparisonResult {
  final double? currentWeight;      // 当前体重
  final double? previousWeight;     // 上次体重
  final double? change;              // 变化量
  final int? daysSince;              // 距离上次记录天数
  final DateTime? currentDate;       // 当前记录日期
  final DateTime? previousDate;      // 上次记录日期
  final bool hasData;                // 是否有数据
}
```

**设计要点：**
- 存储完整的对比信息
- 支持空数据状态
- 提供工厂方法创建空结果和单条记录结果

---

### 2. Repository 层

**接口：** `lib/features/student/home/data/repositories/weight_repository.dart`

```dart
abstract class WeightRepository {
  // 获取最近 N 条体重记录
  Future<List<BodyMeasurementModel>> getRecentMeasurements({
    required String studentId,
    int limit = 10,
  });

  // 计算相对天数的体重变化
  WeightComparisonResult calculateRelativeChange(
    List<BodyMeasurementModel> measurements,
  );
}
```

**实现：** `lib/features/student/home/data/repositories/weight_repository_impl.dart`

**核心逻辑：**

```dart
WeightComparisonResult calculateRelativeChange(
  List<BodyMeasurementModel> measurements,
) {
  // 1. 无数据检查
  if (measurements.isEmpty) return WeightComparisonResult.empty();

  // 2. 单条记录检查
  if (measurements.length == 1) {
    return WeightComparisonResult.single(...);
  }

  // 3. 按日期排序（最新在前）
  final sorted = [...measurements]
    ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

  // 4. 获取最近两条记录
  final current = sorted[0];
  final previous = sorted[1];

  // 5. 计算天数差和变化量
  final daysDiff = currentDate.difference(previousDate).inDays;
  final change = current.weight - previous.weight;

  return WeightComparisonResult(...);
}
```

**设计要点：**
- 从 Firestore 查询最近 10 条记录
- 按日期降序排序
- 计算最近两条记录的差异
- 完善的错误处理和日志

---

### 3. Provider 层

**文件：** `lib/features/student/home/presentation/providers/weight_comparison_provider.dart`

```dart
final weightComparisonProvider = FutureProvider<WeightComparisonResult>((ref) async {
  final repository = ref.watch(weightRepositoryProvider);
  final userId = AuthService.currentUserId;

  if (userId == null) {
    return WeightComparisonResult.empty();
  }

  // 获取最近 10 条记录
  final measurements = await repository.getRecentMeasurements(
    studentId: userId,
    limit: 10,
  );

  // 计算相对变化
  return repository.calculateRelativeChange(measurements);
});
```

**设计要点：**
- 使用 `FutureProvider` 异步加载数据
- 依赖 `weightRepositoryProvider`
- 自动获取当前用户 ID
- 返回计算后的对比结果

---

### 4. UI 层

**文件：** `lib/features/student/home/presentation/widgets/weekly_status_section.dart`

#### 主要修改

**1. 添加导入**
```dart
import '../../data/models/weight_comparison_model.dart';
import '../providers/weight_comparison_provider.dart';
```

**2. 使用 Consumer 包裹 Weight Card**
```dart
Expanded(
  child: Consumer(
    builder: (context, ref, _) {
      final weightComparisonAsync = ref.watch(weightComparisonProvider);

      return weightComparisonAsync.when(
        loading: () => StatCard(...),     // Loading 状态
        error: (_, __) => StatCard(...),  // Error 降级
        data: (comparison) {
          // 智能显示逻辑
        },
      );
    },
  ),
)
```

**3. 智能显示逻辑**
```dart
data: (comparison) {
  // 决定显示模式
  final useRelativeMode = comparison.hasData &&
                          comparison.daysSince != null &&
                          comparison.daysSince! < 7;

  // 构建变化文本
  final changeText = useRelativeMode
      ? _buildRelativeChangeText(comparison, l10n)  // "3 days ago"
      : _buildWeeklyChangeText(stats.weightChange);  // 周对比

  return StatCard(
    title: l10n.weightChange,
    currentValue: currentValue,
    previousValue: previousValue,
    changeText: changeText,
    isPositiveChange: isPositive,
    hasData: comparison.hasData || stats.weightChange.hasData,
    onTap: () => context.push(RouteNames.studentBodyStatsHistory),
  );
}
```

**4. 辅助方法**

```dart
// 构建相对天数文本
String? _buildRelativeChangeText(
  WeightComparisonResult comparison,
  AppLocalizations l10n,
) {
  if (comparison.change == null || comparison.daysSince == null) {
    return null;
  }

  final changeStr = comparison.change! >= 0
      ? '+${comparison.change!.toStringAsFixed(1)}'
      : '${comparison.change!.toStringAsFixed(1)}';

  final daysText = comparison.daysSince == 1
      ? l10n.yesterday          // "昨天"
      : l10n.daysAgo(comparison.daysSince!);  // "3天前"

  return '$changeStr $daysText';  // "-0.1kg 3天前"
}

// 构建周对比文本
String? _buildWeeklyChangeText(dynamic weightChange) {
  if (weightChange.change == null) {
    return null;
  }

  return weightChange.change! >= 0
      ? '+${weightChange.change}'
      : '${weightChange.change}';
}
```

---

### 5. 国际化

**文件：** `lib/l10n/app_en.arb`
```json
{
  "yesterday": "yesterday",
  "daysAgo": "{days} days ago",
  "@daysAgo": {
    "placeholders": {
      "days": {"type": "int"}
    }
  }
}
```

**文件：** `lib/l10n/app_zh.arb`
```json
{
  "yesterday": "昨天",
  "daysAgo": "{days}天前"
}
```

---

## 数据流详解

### 完整数据流

```
1. 用户打开 Student Home Page
   ↓
2. WeeklyStatusSection 构建
   ↓
3. Consumer 监听 weightComparisonProvider
   ↓
4. Provider 触发数据加载
   ├─ 获取当前用户 ID
   ├─ 调用 Repository.getRecentMeasurements()
   │   └─ Firestore 查询最近 10 条记录
   ├─ 调用 Repository.calculateRelativeChange()
   │   ├─ 排序记录
   │   ├─ 获取最近两条
   │   ├─ 计算天数差: 3 天
   │   └─ 计算变化量: -0.1kg
   └─ 返回 WeightComparisonResult
   ↓
5. UI 层接收数据
   ├─ 判断：daysSince < 7? → 是
   ├─ 调用 _buildRelativeChangeText()
   │   └─ 生成："-0.1kg 3 days ago"
   └─ 渲染 StatCard
   ↓
6. 用户看到：
   |73.9kg            |
   |-0.1kg 3 days ago |
```

### 状态管理

```
Provider 状态：
┌─────────────────────────────────┐
│  AsyncValue<WeightComparisonResult>  │
├─────────────────────────────────┤
│  Loading: 显示 loading StatCard │
│  Error:   降级使用周统计数据     │
│  Data:    智能显示相对天数/周对比 │
└─────────────────────────────────┘
```

---

## 决策树

```
获取体重记录
  ↓
有数据？
  ├─ 否 → 返回空结果 → 显示空状态
  └─ 是 → 继续
       ↓
记录数量 >= 2？
  ├─ 否 → 返回单条记录结果 → 只显示当前值，无对比
  └─ 是 → 计算差异
       ↓
获取最近两条记录
  ├─ current:  73.9kg (2025-01-17)
  └─ previous: 74.0kg (2025-01-14)
       ↓
计算天数差：3 天
计算变化量：-0.1kg
       ↓
天数差 < 7？
  ├─ 是 → 相对天数模式
  │       ├─ daysSince == 1?
  │       │   ├─ 是 → "yesterday"
  │       │   └─ 否 → "{days} days ago"
  │       └─ 显示："-0.1kg 3 days ago"
  │
  └─ 否 → 周对比模式
          └─ 显示："-0.2kg"（使用后端周统计）
```

---

## 文件清单

### 新建文件（4个）

1. **数据模型**
   - `lib/features/student/home/data/models/weight_comparison_model.dart`

2. **Repository**
   - `lib/features/student/home/data/repositories/weight_repository.dart`
   - `lib/features/student/home/data/repositories/weight_repository_impl.dart`

3. **Provider**
   - `lib/features/student/home/presentation/providers/weight_comparison_provider.dart`

### 修改文件（4个）

1. **国际化**
   - `lib/l10n/app_en.arb`
   - `lib/l10n/app_zh.arb`

2. **UI 组件**
   - `lib/features/student/home/presentation/widgets/weekly_status_section.dart`

3. **文档**
   - `docs/student/weight_card_implementation.md`（本文档）

---

## 测试指南

### 单元测试（建议）

```dart
// weight_repository_impl_test.dart
test('calculateRelativeChange - 两条记录，间隔3天', () {
  final measurements = [
    BodyMeasurementModel(weight: 73.9, recordDate: '2025-01-17'),
    BodyMeasurementModel(weight: 74.0, recordDate: '2025-01-14'),
  ];

  final result = repository.calculateRelativeChange(measurements);

  expect(result.change, -0.1);
  expect(result.daysSince, 3);
  expect(result.hasData, true);
});
```

### 集成测试场景

#### 场景 1：相对天数模式（3 天）

**前置条件：**
- 添加两条体重记录：
  - 2025-01-17: 73.9kg
  - 2025-01-14: 74.0kg

**期望结果：**
```
Weight Card 显示：
├─ 当前值: 73.9kg
├─ 变化: -0.1kg 3 days ago
└─ 颜色: 红色（负变化）
```

#### 场景 2：昨天模式（1 天）

**前置条件：**
- 添加两条体重记录：
  - 今天: 73.9kg
  - 昨天: 74.0kg

**期望结果：**
```
Weight Card 显示：
├─ 当前值: 73.9kg
├─ 变化: -0.1kg yesterday
└─ 颜色: 红色（负变化）
```

#### 场景 3：周对比模式（> 7 天）

**前置条件：**
- 添加多条记录，跨度 > 7 天

**期望结果：**
```
Weight Card 显示：
├─ 当前值: 73.5kg（周平均）
├─ 变化: -0.2kg
└─ 颜色: 红色（负变化）
```

#### 场景 4：只有 1 条记录

**前置条件：**
- 只有 1 条体重记录

**期望结果：**
```
Weight Card 显示：
├─ 当前值: 73.9kg
└─ 无变化信息
```

#### 场景 5：无数据

**前置条件：**
- 无体重记录

**期望结果：**
```
Weight Card 显示空状态
```

---

## 性能优化

### 1. 数据缓存

**Provider 自动缓存：**
- Riverpod `FutureProvider` 自动缓存结果
- 避免重复查询 Firestore
- 页面重建时复用缓存数据

### 2. 查询优化

**限制查询数量：**
```dart
.limit(10)  // 只查询最近 10 条，而非全部
```

**索引优化：**
```javascript
// firestore.indexes.json
{
  "collectionGroup": "bodyMeasure",
  "fields": [
    { "fieldPath": "studentID", "order": "ASCENDING" },
    { "fieldPath": "recordDate", "order": "DESCENDING" }
  ]
}
```

### 3. UI 优化

**降级策略：**
- Loading: 显示简化的 StatCard
- Error: 降级使用周统计数据
- 避免因网络问题导致空白

---

## 常见问题

### Q1: 为什么不修改后端逻辑？

**A:** 前端补丁方案的优势：
- 快速实现，不影响其他功能
- 易于测试和回滚
- 不需要重新部署 Cloud Functions
- 后端周统计逻辑保持不变，用于其他场景

### Q2: 为什么查询 10 条记录而不是 2 条？

**A:** 冗余设计，提高容错性：
- 避免数据异常（如中间某条记录损坏）
- 支持未来扩展（如显示趋势）
- 性能影响微小（10 条 vs 2 条）

### Q3: 如果用户同时有相对天数数据和周统计数据，优先显示哪个？

**A:** 优先显示相对天数：
- 更精确、更实时
- 用户更关心最近的变化
- 周统计作为降级方案

### Q4: 国际化如何处理？

**A:** 使用 Flutter 的 intl 包：
- `yesterday` 和 `daysAgo` 支持多语言
- 自动根据系统语言切换
- 支持参数化字符串

---

## 未来扩展

### 可能的优化方向

1. **趋势分析**
   - 显示 7 天趋势线
   - 添加体重预测

2. **个性化建议**
   - 根据变化趋势提供建议
   - 结合饮食和训练数据

3. **数据可视化**
   - 点击 Card 显示详细图表
   - 添加体重目标进度条

4. **离线支持**
   - 本地缓存历史数据
   - 离线模式下仍可显示

---

## 参考资料

- [Flutter Riverpod 文档](https://riverpod.dev/)
- [Firestore 查询文档](https://firebase.google.com/docs/firestore/query-data/queries)
- [Flutter 国际化指南](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)

---

## 变更记录

| 日期 | 版本 | 作者 | 说明 |
|------|------|------|------|
| 2025-01-17 | 1.0.0 | Claude | 初始版本，完整实现相对天数显示 |

---

## 总结

Weight Card 智能显示功能通过引入相对天数计算，显著提升了用户体验：
- **更精确**：显示实际记录间隔天数
- **更直观**：用户一眼就能看懂变化
- **更智能**：自动选择最合适的显示模式

实现采用了清晰的分层架构，易于维护和扩展，为未来的功能增强奠定了良好基础。
