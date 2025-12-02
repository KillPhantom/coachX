# Coach Home Page Architecture

## Overview

教练首页是教练端应用的核心页面，提供教练工作的关键统计信息和快速访问入口。

## Page Structure

```
CoachHomePage
├── SummarySection (统计概览)
└── PendingReviewsSection (待审核训练)
```

## Components

### 1. CoachHomePage
**文件**: `lib/features/coach/home/presentation/pages/coach_home_page.dart`

**职责**:
- 作为首页的容器页面
- 管理下拉刷新逻辑
- 组织和排列子组件

**数据依赖**:
- `coachSummaryProvider` (用于刷新)
- `trainingReviewsStreamProvider` (用于刷新)

---

### 2. SummarySection (统计概览)
**文件**: `lib/features/coach/home/presentation/widgets/summary_section.dart`

**职责**:
- 显示3列统计数据（横向布局）
- 提供快速跳转功能

**UI布局**:
```
┌─────────────────────────────────────┐
│ Summary                             │
├─────────────────────────────────────┤
│  [图标]    [图标]    [图标]         │
│   20/25     14        20            │
│  record    training  unread         │
│  training  records   messages       │
│           need to be                │
│           reviewed                  │
└─────────────────────────────────────┘
```

**数据源**:
- `coachSummaryProvider` → `CoachSummaryModel`

**字段说明**:
- **第1列**: 本周学生打卡次数（最近7天）
  - 数据: `CoachSummaryModel.studentCheckInsLast7Days`
  - 格式: `{n}` (显示打卡次数数字)
  - 点击: 跳转到学生列表页 (`RouteNames.coachStudents`)

- **第2列**: 待审核的训练记录数
  - 数据: `CoachSummaryModel.unreviewedTrainings`
  - 格式: `{n} training records need to be reviewed`
  - 点击: 跳转到 `RouteNames.coachTrainingReviews`

- **第3列**: 未读消息数
  - 数据: `CoachSummaryModel.unreadMessages`
  - 格式: `{n} unread messages`
  - 点击: TODO - 跳转到Chat Tab

---

### 3. PendingReviewsSection (待审核训练)
**文件**: `lib/features/coach/home/presentation/widgets/pending_reviews_section.dart`

**职责**:
- 显示最新的5条待审核训练记录
- 提供"View More"按钮跳转到完整列表

**数据源**:
- `top5PendingReviewsProvider` → `List<TrainingReviewListItemModel>`

**数据处理流程**:
```
filteredTrainingReviewsProvider (来自 training_reviews feature)
    ↓
过滤: isReviewed == false
    ↓
排序: 按 createdAt 降序
    ↓
取前5条
    ↓
top5PendingReviewsProvider
    ↓
PendingReviewsSection
```

**子组件**:
- `TrainingReviewCard` - 复用自 `training_reviews` feature
  - 显示学生头像、姓名、日期、状态Badge
  - 显示运动名称pills（最多3个 + "more"）
  - 显示统计摘要（exercises, videos, meals）
  - 点击跳转到 `/training-review/{dailyTrainingId}`

**View More按钮**:
- 点击跳转: `RouteNames.coachTrainingReviews` (`/coach/training-reviews`)

---

## Data Models

### CoachSummaryModel
**文件**: `lib/features/coach/home/data/models/coach_summary_model.dart`

```dart
class CoachSummaryModel {
  final int studentCheckInsLast7Days;     // 本周学生打卡次数（最近7天）
  final int unreadMessages;               // 未读消息数
  final int unreviewedTrainings;          // 待审核训练记录数
  final DateTime lastUpdated;             // 最后更新时间
}
```

**数据来源**:
- Repository: `CoachHomeRepositoryImpl`
- 直接查询 Firestore：
  - `dailyTrainings` collection (打卡次数、待审核数)
  - `conversations` collection (未读消息数)

---

### TrainingReviewListItemModel
**文件**: `lib/features/coach/training_reviews/data/models/training_review_list_item_model.dart`

```dart
class TrainingReviewListItemModel {
  final String dailyTrainingId;
  final String studentId;
  final String studentName;
  final String? studentAvatarUrl;
  final String date;                          // "yyyy-MM-dd"
  final bool isReviewed;
  final DateTime createdAt;
  final String? planName;
  final String? dietPlanName;
  final List<StudentExerciseModel>? exercises;
  final int mealCount;
}
```

---

## Data Flow

### Summary Section Flow
```
CoachHomePage
    ↓ watches
coachSummaryProvider (FutureProvider.autoDispose)
    ↓ calls
CoachHomeRepository.fetchCoachSummary()
    ↓ queries
Firestore (dailyTrainings + conversations)
    ↓ returns
CoachSummaryModel
    ↓ consumed by
SummarySection
    ↓ renders
3-Column Layout (_StatColumn x3)
```

### Pending Reviews Flow
```
CoachHomePage
    ↓ watches indirectly through
PendingReviewsSection
    ↓ watches
top5PendingReviewsProvider (Provider)
    ↓ depends on
filteredTrainingReviewsProvider (from training_reviews feature)
    ↓ filters & sorts
List<TrainingReviewListItemModel>
    ↓ renders
TrainingReviewCard x5 + View More Button
```

---

## Providers

### coach_home_providers.dart

| Provider | Type | Purpose |
|----------|------|---------|
| `currentCoachIdProvider` | Provider | 提供当前教练ID |
| `coachHomeRepositoryProvider` | Provider | 提供 CoachHomeRepository 实例 |
| `coachSummaryProvider` | FutureProvider.autoDispose | 提供统计概览数据（1小时缓存） |
| `top5PendingReviewsProvider` | Provider | 提供最新5条待审核训练 |

### Dependencies from other features

| Provider | Feature | Purpose |
|----------|---------|---------|
| `trainingReviewsStreamProvider` | training_reviews | Firestore实时流 - 所有训练审核记录 |
| `filteredTrainingReviewsProvider` | training_reviews | 筛选和排序后的训练审核记录 |

---

## Internationalization

### Used i18n Keys

| Key | English | 中文 |
|-----|---------|------|
| `coachHomeSummaryTitle` | Summary | 统计概览 |
| `upcomingScheduleTitle` | Upcoming Schedule | 即将到来的日程 |
| `pendingReviewsTitle` | Pending Reviews | 待审核训练 |
| `viewMore` | View More | 查看更多 |
| `recordTraining` | record training | 学生打卡 |
| `noPendingReviews` | No pending reviews | 暂无待审核记录 |
| `noPendingReviewsDesc` | All training records have been reviewed | 所有训练记录已审核完毕 |
| `noUpcomingEvents` | No upcoming events | 暂无即将到来的事件 |

---

## Navigation Routes

### From Summary Section
- 第1列点击: TODO - 跳转到学生列表页（筛选条件待定）
- 第2列点击: `/coach/training-reviews` (`RouteNames.coachTrainingReviews`)
- 第3列点击: TODO - 切换到Chat Tab

### From Pending Reviews Section
- TrainingReviewCard点击: `/training-review/{dailyTrainingId}`
- View More按钮: `/coach/training-reviews` (`RouteNames.coachTrainingReviews`)

---

## File Structure

```
lib/features/coach/home/
├── data/
│   ├── models/
│   │   └── coach_summary_model.dart
│   └── repositories/
│       ├── coach_home_repository.dart
│       └── coach_home_repository_impl.dart
└── presentation/
    ├── pages/
    │   └── coach_home_page.dart
    ├── providers/
    │   └── coach_home_providers.dart
    └── widgets/
        ├── summary_section.dart
        └── pending_reviews_section.dart
```

---

## Dependencies

### Internal Dependencies
- `core/theme/` - AppColors, AppTextStyles, AppDimensions
- `core/widgets/` - CupertinoCard, LoadingIndicator, ErrorView
- `core/services/` - AuthService
- `routes/` - RouteNames
- `l10n/` - AppLocalizations
- `features/coach/training_reviews/` - TrainingReviewCard, providers, models

### External Packages
- `flutter_riverpod` - State management
- `go_router` - Navigation

---

**Last Updated**: 2025-12-01
