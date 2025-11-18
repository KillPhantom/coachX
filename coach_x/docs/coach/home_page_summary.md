# Coach Home Page Architecture

## Overview

教练首页是教练端应用的核心页面，提供教练工作的关键统计信息和快速访问入口。

## Page Structure

```
CoachHomePage
├── SummarySection (统计概览)
├── EventReminderSection (即将到来的日程)
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
- `eventRemindersProvider` (用于刷新)
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
- **第1列**: 过去30天完成训练的学生数 / 总学生数
  - 数据: `CoachSummaryModel.studentsCompletedLast30Days`
  - 格式: `{x}/{total} record training`
  - 点击: TODO - 跳转到学生列表页（筛选过去30天完成训练的学生）

- **第2列**: 待审核的训练记录数
  - 数据: `CoachSummaryModel.unreviewedTrainings`
  - 格式: `{n} training records need to be reviewed`
  - 点击: 跳转到 `RouteNames.coachTrainingReviews`

- **第3列**: 未读消息数
  - 数据: `CoachSummaryModel.unreadMessages`
  - 格式: `{n} unread messages`
  - 点击: TODO - 跳转到Chat Tab

---

### 3. EventReminderSection (即将到来的日程)
**文件**: `lib/features/coach/home/presentation/widgets/event_reminder_section.dart`

**职责**:
- 显示即将到来的事件提醒（线下课程、治疗预约等）

**数据源**:
- `eventRemindersProvider` → `List<EventReminderModel>`

**数据过滤**:
- 只显示未完成的事件 (`isCompleted == false`)
- 按计划时间升序排序
- 限制最多3条

---

### 4. PendingReviewsSection (待审核训练)
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
  final int studentsCompletedLast30Days;  // 过去30天完成训练的学生数
  final int totalStudents;                // 总学生数
  final int unreadMessages;               // 未读消息数
  final int unreviewedTrainings;          // 待审核训练记录数
  final DateTime lastUpdated;             // 最后更新时间

  String get completionRate;              // "{x}/{totalStudents}"
  double get completionPercentage;        // x / totalStudents
}
```

**数据来源** (待实现):
- Cloud Function: `fetchStudentsStats()`
- 整合未读消息统计和待审核训练数（过去30天）

---

### EventReminderModel
**文件**: `lib/features/coach/home/data/models/event_reminder_model.dart`

```dart
enum EventReminderType {
  offlineClass,      // 线下课程
  therapySession,    // 治疗/按摩预约
  planDeadline,      // 计划截止
  studentCheckIn,    // 学生打卡
  custom,            // 自定义事件
}

class EventReminderModel {
  final String id;
  final EventReminderType type;
  final String title;
  final String? description;
  final DateTime scheduledTime;
  final String? studentId;
  final String? studentName;
  final String? location;
  final bool isCompleted;
  final DateTime createdAt;
  final String coachId;
}
```

**数据来源** (待实现):
- Firestore Collection: `eventReminders`
- Query:
  ```
  where('coachId', '==', currentCoachId)
  where('isCompleted', '==', false)
  orderBy('scheduledTime')
  limit(3)
  ```

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
coachSummaryProvider (FutureProvider)
    ↓ fetches
Cloud Function: fetchStudentsStats() (TODO)
    ↓ returns
CoachSummaryModel
    ↓ consumed by
SummarySection
    ↓ renders
3-Column Layout (_StatColumn x3)
```

### Event Reminder Flow
```
CoachHomePage
    ↓ watches
eventRemindersProvider (FutureProvider)
    ↓ queries (TODO)
Firestore: eventReminders collection
    ↓ returns
List<EventReminderModel>
    ↓ consumed by
EventReminderSection
    ↓ renders
EventReminderItem (for each reminder)
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
| `coachSummaryProvider` | FutureProvider | 提供统计概览数据 (mock) |
| `eventRemindersProvider` | FutureProvider | 提供事件提醒列表 (mock) |
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

## TODO Items

### Backend API
1. 实现 Cloud Function: `fetchStudentsStats()`
   - 返回过去30天完成训练的学生数
   - 返回总学生数
   - 返回未读消息数
   - 返回待审核训练记录数

2. 实现 Firestore监听: `eventReminders` collection
   - 按教练ID和完成状态筛选
   - 按计划时间排序

### Frontend功能
1. Summary Section第1列点击跳转
   - 需要确定跳转目标页面和筛选条件

2. Summary Section第3列点击跳转
   - 实现切换到Chat Tab的逻辑

### 性能优化
- 考虑将 `coachSummaryProvider` 改为 `StreamProvider` 以实现实时更新
- 考虑添加缓存机制避免频繁重新获取数据

---

## File Structure

```
lib/features/coach/home/
├── data/
│   └── models/
│       ├── coach_summary_model.dart
│       └── event_reminder_model.dart
└── presentation/
    ├── pages/
    │   └── coach_home_page.dart
    ├── providers/
    │   └── coach_home_providers.dart
    └── widgets/
        ├── summary_section.dart
        ├── event_reminder_section.dart
        ├── event_reminder_item.dart
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

## Recent Changes (2025-11-16)

### UI重构
- Summary Section改为3列横向布局（原为3行纵向布局）
- Recent Activity Section替换为Pending Reviews Section
- Event Reminder Section标题更新为"Upcoming Schedule"

### 数据模型更新
- `CoachSummaryModel.studentsCompletedToday` → `studentsCompletedLast30Days`
- 统计时间范围从"今日"改为"过去30天"

### 新增组件
- `PendingReviewsSection` - 显示最新5条待审核训练
- `_StatColumn` (私有组件) - Summary Section的统计列

### 删除组件
- `RecentActivitySection`
- `RecentActivityItem`
- `RecentActivityModel`
- `SummaryItem`
- `recentActivitiesProvider`

---

## Testing Checklist

- [ ] Summary Section 3列显示正确
- [ ] Summary Section点击跳转功能正常
- [ ] Event Reminder Section标题为"Upcoming Schedule"
- [ ] Pending Reviews Section显示最多5条记录
- [ ] Pending Reviews Section "View More"按钮跳转正确
- [ ] 下拉刷新功能正常
- [ ] 空状态显示正确
- [ ] Loading状态显示正确
- [ ] Error状态显示正确并可重试
- [ ] 中英文切换正常

---

Last Updated: 2025-11-16
