# Exercise Record Page 架构文档

**版本**: 2.4
**更新日期**: 2025-11-16
**作者**: Claude Code

---

## 📋 目录

1. [概述](#概述)
2. [架构设计](#架构设计)
3. [数据流](#数据流)
4. [组件层次结构](#组件层次结构)
5. [状态管理](#状态管理)
6. [核心功能实现](#核心功能实现)
7. [API 集成](#api-集成)
8. [UI 设计规范](#ui-设计规范)
9. [关键代码位置](#关键代码位置)
10. [未来扩展点](#未来扩展点)

---

## 概述

### 功能简介

Exercise Record Page（训练记录页面）是学生端的核心功能，用于记录每日训练完成情况。学生可以：

- 横向滑动查看当日训练计划的动作列表（PageView）
- 编辑每个 Set 的 reps（次数）和 weight（重量，支持文本如"自重"）
- 自动标记 Set 完成状态（reps 不为空时）
- 快捷完成整个动作（自动填充计划数据）
- 启动训练计时器，记录总时长和每个动作耗时
- 上传训练视频（最多3个）
- 查看教练备注
- 重新编辑已完成的 Set

### 技术栈

- **UI 框架**: Flutter (Cupertino Design)
- **状态管理**: Riverpod 2.x
- **后端**: Firebase Cloud Functions (Python)
- **存储**: Firestore + Firebase Storage
- **视频处理**: `video_thumbnail`, `video_player`

### 核心特性

1. ✅ **横向滚动**: PageView 实现动作卡片横向滑动，底部显示自定义页面指示器（含左右箭头）
2. ✅ **手动导航**: 移除自动跳转，用户完全控制页面切换
3. ✅ **智能保存**: 仅在 Exercise 完成时保存（节省资源）
4. ✅ **自动完成**: reps 不为空时自动标记 Set 完成，所有 Sets 完成后自动完成 Exercise
5. ✅ **双列计时器**: 左侧显示当前Exercise耗时（MM:SS:MS），右侧显示全局总时长（HH:MM:SS）
6. ✅ **智能计时器重置**: Exercise完成时自动重置到下一个未完成的exercise，页面滑动不影响计时
7. ✅ **状态切换**: 可编辑 → 完成 → 点击重新编辑（自动取消 Exercise 完成状态）
8. ✅ **视频管理**: 缩略图显示、播放、删除（最多3个）
9. ✅ **数据预填充**: Placeholder 显示计划默认值，快捷完成时自动填充
10. ✅ **离线友好**: 本地状态管理，Exercise 完成时异步保存

---

## 架构设计

### 分层架构

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌─────────────────────────────────────────────────┐   │
│  │        ExerciseRecordPage (UI Entry)             │   │
│  │  ┌───────────────────────────────────────────┐  │   │
│  │  │    PageView (Horizontal Scroll)          │  │   │
│  │  │  ┌───────────────────────────────────┐  │  │   │
│  │  │  │  ExerciseRecordCard (Item)        │  │  │   │
│  │  │  │  ┌─────────────────────────────┐  │  │  │   │
│  │  │  │  │ ExerciseTimeHeader          │  │  │  │   │
│  │  │  │  │ SetInputRow (multiple)      │  │  │  │   │
│  │  │  │  │ MyRecordingsSection         │  │  │  │   │
│  │  │  │  └─────────────────────────────┘  │  │  │   │
│  │  │  └───────────────────────────────────┘  │  │   │
│  │  │  TimerHeader (if timer running)       │  │   │
│  │  │  CustomPageIndicator (bottom)         │  │   │
│  │  └───────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↕ (Provider)
┌─────────────────────────────────────────────────────────┐
│                      Business Logic                      │
│  ┌─────────────────────────────────────────────────┐   │
│  │       ExerciseRecordNotifier (State + Logic)    │   │
│  │  - loadExercisesForToday()                      │   │
│  │  - updateSetRealtime()                          │   │
│  │  - quickComplete()                              │   │
│  │  - uploadVideo() / deleteVideo()                │   │
│  │  - saveRecord() [with debounce]                 │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↕ (Repository)
┌─────────────────────────────────────────────────────────┐
│                       Data Layer                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │    TrainingRecordRepository (Interface)         │   │
│  │  - fetchTodayTraining()                         │   │
│  │  - upsertTodayTraining()                        │   │
│  │  - uploadVideo()                                │   │
│  └─────────────────────────────────────────────────┘   │
│                          ↕                               │
│  ┌─────────────────────────────────────────────────┐   │
│  │  TrainingRecordRepositoryImpl (Implementation)  │   │
│  │  → CloudFunctionsService                        │   │
│  │  → FirebaseStorage                              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↕
┌─────────────────────────────────────────────────────────┐
│                   Backend (Firebase)                     │
│  - Cloud Function: fetch_today_training                 │
│  - Cloud Function: upsert_today_training                │
│  - Firestore: dailyTrainings/{id}                       │
│  - Storage: students/trainings/{date}/{exercise}/...    │
└─────────────────────────────────────────────────────────┘
```

---

## 数据流

### 1. 页面加载流程

```
用户打开页面
    ↓
ExerciseRecordPage.initState()
    ↓
_loadData() 调用
    ↓
读取 studentPlansProvider (当前学生的计划)
    ↓
获取今日应该训练的 exerciseDayNumber
    ↓
ExerciseRecordNotifier.loadExercisesForToday()
    ↓
├─ 尝试从后端获取已保存的记录
│  └─ Repository.fetchTodayTraining(date)
│      └─ Cloud Function: fetch_today_training
│          └─ Firestore: dailyTrainings 查询
│
├─ 如果有已保存记录
│  └─ 加载保存的数据 (exercises, videos, completed status)
│
└─ 如果没有记录
   └─ 从 exercisePlan 预填充
      └─ 转换 Exercise → StudentExerciseModel
          └─ 保留计划的 sets, name, note
          └─ 初始化 videos: [], completed: false
```

### 2. Set 编辑与自动完成流程（v2.0 优化）

```
用户修改 reps/weight 输入框
    ↓
SetInputRow.onChanged 回调
    ↓
ExerciseRecordNotifier.updateSetRealtime(exerciseIndex, setIndex, updatedSet)
    ↓
├─ 如果计时器运行且首次编辑，记录 exercise 开始时间
│
├─ 自动标记 Set 完成（如果 reps 不为空）
│  └─ set.copyWith(completed: true)
│
├─ 更新本地状态: state.exercises[exerciseIndex].sets[setIndex] = updatedSet
│
└─ 检查该 exercise 的所有 Sets 是否都已完成
    ↓
    [如果所有 Sets completed = true]
    ↓
    _checkAndCompleteExercise(exerciseIndex)
        ↓
        计算 exercise 耗时（从开始时间到现在）
        ↓
        标记 exercise.completed = true, timeSpent = 耗时秒数
        ↓
        立即保存到 Firebase (saveRecord())
            ↓
            构建 DailyTrainingModel
            ├─ studentId: FirebaseAuth.currentUser.uid
            ├─ coachId: state.coachId
            ├─ date: state.currentDate (yyyy-MM-dd)
            ├─ exercises: state.exercises (含 timeSpent)
            └─ completionStatus: 'completed'
            ↓
            Repository.upsertTodayTraining(training)
            ↓
            Cloud Function: upsert_today_training
            ↓
            Firestore: dailyTrainings/{id} (upsert)
        ↓
        ExerciseRecordPage 监听完成事件，自动滑到下一页 (300ms)
```

**v2.0 优化点**:
- ❌ 移除 debounce 自动保存（节省资源）
- ✅ 仅在 Exercise 完成时保存
- ✅ 自动标记 Set 完成
- ✅ 记录动作耗时
- ✅ 自动滑到下一个动作

### 3. 快捷完成流程

```
用户点击 "快捷完成" 按钮
    ↓
ExerciseRecordCard.onQuickComplete
    ↓
ExerciseRecordNotifier.quickComplete(exerciseIndex)
    ↓
├─ 计算动作耗时
│
├─ 将所有 Sets 标记为 completed = true
│  └─ 保留计划的 reps/weight（placeholder 数据）
│
├─ 标记 exercise.completed = true, timeSpent = 耗时
│
└─ 立即保存
    └─ saveRecord()
        └─ [同上保存流程]
```

### 4. 计时器流程（v2.0 新增）

```
用户点击右上角 Timer Icon
    ↓
显示确认对话框："确认开始训练计时吗？"
    ↓
用户点击"开始"
    ↓
ExerciseRecordNotifier.startTimer()
    ↓
├─ 设置 timerStartTime = DateTime.now()
├─ 设置 isTimerRunning = true
│
└─ TimerHeader 显示在页面顶部
    ↓
    每秒刷新，显示 HH:MM:SS
    ├─ elapsedTime = DateTime.now().difference(timerStartTime)
    └─ 格式化为 "01:23:45"

[当用户首次编辑某个 exercise]
    ↓
记录 exerciseStartTimes[index] = DateTime.now()

[当 exercise 完成]
    ↓
计算 timeSpent = DateTime.now().difference(exerciseStartTimes[index])
    ↓
保存到 exercise.timeSpent (秒数)
    ↓
ExerciseTimeHeader 显示在卡片顶部
    ├─ 格式化为 "⏱️ 用时: 05:30"
    └─ 样式: caption1, 浅灰背景
```

### 5. 重新编辑已完成 Set 流程（v2.0 新增）

```
用户点击已完成的 Set（绿色 checkmark）
    ↓
SetInputRow.onTap → widget.onToggleEdit
    ↓
ExerciseRecordNotifier.toggleSetCompleted(exerciseIndex, setIndex)
    ↓
├─ 如果 Exercise 已完成，先取消 Exercise 的完成状态
│  └─ exercise.copyWith(completed: false)
│
├─ 切换 Set 完成状态
│  └─ set.copyWith(completed: !set.completed)
│
└─ SetInputRow.didUpdateWidget 检测状态变化
    ├─ 如果 Set 变为未完成，清空 TextController
    └─ 显示输入框，允许重新编辑
```

### 6. 视频上传流程（v2.4 更新）

```
用户点击 "录制视频" 占位符
    ↓
VideoUploadSection._showVideoSourceOptions()
    ↓
选择相机录制 or 从相册选择
    ↓
获得 File videoFile
    ↓
VideoUploadSection._processAndUploadVideo(videoFile)
    ↓
├─ 生成缩略图（本地临时文件）
│  └─ VideoUtils.generateThumbnail()
│
├─ 添加到 VideoUploadSection._videos (pending 状态)
│
├─ 回调: onVideoSelected(index, file)
│  └─ ExerciseRecordNotifier.addPendingVideo(index, file.path, null)
│      └─ 添加到 state.exercises[index].videos (pending, 缩略图为 null)
│
└─ 启动后台压缩和上传
    ↓
    VideoUploadSection._compressAndUpload()
        ↓
        ├─ 条件压缩（如果超过阈值）
        │
        ├─ 上传视频到 Firebase Storage
        │  └─ 路径: 'students/trainings/{userId}/{timestamp}.mp4'
        │
        ├─ 上传缩略图到 Firebase Storage
        │  └─ 路径: 'students/trainings/{userId}/{timestamp}_thumb.jpg'
        │
        └─ 回调: onUploadCompleted(index, videoUrl, thumbnailUrl)
            └─ ExerciseRecordNotifier.completeVideoUpload(exerciseIndex, videoIndex, videoUrl, thumbnailUrl)
                ├─ 更新 state.exercises[exerciseIndex].videos[videoIndex]
                │  └─ status = completed, downloadUrl, thumbnailUrl
                │
                └─ 立即保存到 Firestore
                    └─ saveRecord()
```

**v2.4 关键变更**:
- ✅ 使用 VideoUploadSection 自管理上传（不再重复上传）
- ✅ 通过回调同步状态到 ExerciseRecordNotifier
- ✅ 上传完成后立即保存

### 7. 视频删除流程

```
用户点击视频卡片的删除按钮
    ↓
VideoThumbnailCard.onDelete
    ↓
ExerciseRecordCard.onVideoDeleted(videoIndex)
    ↓
ExerciseRecordNotifier.deleteVideo(exerciseIndex, videoIndex)
    ↓
├─ 更新本地状态
│  └─ exercises[index].videos.removeAt(videoIndex)
│
└─ 自动保存
    └─ saveRecord()
        └─ ⚠️ 注意：只删除 Firestore 引用，不删除 Storage 文件
```

---

## 组件层次结构

### UI 组件树（v2.0）

```
ExerciseRecordPage (Stateful)
├── CupertinoPageScaffold
│   ├── CupertinoNavigationBar
│   │   ├── middle: Text("训练记录")
│   │   └── trailing: Timer Icon (启动计时器)
│   │
│   └── SafeArea
│       └── Column
│           ├── [isTimerRunning] → TimerHeader
│           │   └── Timer.periodic 每秒刷新，显示 HH:MM:SS
│           │
│           ├── Expanded: [状态判断]
│           │   ├── [isLoading] → LoadingIndicator
│           │   ├── [hasError] → ErrorView (with retry button)
│           │   ├── [isEmpty] → EmptyPlaceholder
│           │   └── [hasData] → PageView.builder (横向滚动)
│           │       └── ExerciseRecordCard (单页)
│           │           └── SingleChildScrollView
│           │               ├── [timeSpent != null] → ExerciseTimeHeader
│           │               │   └── "⏱️ 用时: MM:SS"
│           │               ├── Row: fitness_center Icon + 动作名称 + 快捷完成按钮
│           │               ├── [note.isNotEmpty] → 教练备注 (移到 Sets 之前)
│           │               ├── Set 列表
│           │               │   └── SetInputRow (多个)
│           │               │       ├── [未完成] → 可编辑输入框 (placeholder)
│           │               │       └── [已完成] → 只读文本 + 绿色 checkmark
│           │               └── MyRecordingsSection
│           │                   └── 横向滚动列表 (最多3个视频)
│           │
│           └── [hasData] → SmoothPageIndicator (底部指示器)
│               └── WormEffect, 黄色激活点
```

### 组件职责分离（v2.0）

| 组件 | 职责 | 状态类型 | v2.0 变更 |
|------|------|----------|-----------|
| `ExerciseRecordPage` | 页面容器、PageController 管理、计时器 UI | Stateful (lifecycle + PageController) | ✅ 新增 PageView、Timer Icon、自动滑动 |
| `TimerHeader` | 全局计时器显示（HH:MM:SS） | Stateful (Timer.periodic) | ✅ 新增组件 |
| `ExerciseTimeHeader` | 动作耗时显示（MM:SS） | Stateless (pure) | ✅ 新增组件 |
| `ExerciseRecordCard` | 单个动作的完整 UI 容器 | Stateless (pure) | ✅ 新增 fitness_center Icon、绿色 border、教练备注位置调整 |
| `SetInputRow` | 单个 Set 的输入/显示 | Stateful (TextController) | ✅ 新增 placeholder、绿色 checkmark、重新编辑支持 |
| `MyRecordingsSection` | 视频列表管理 | Stateless (pure) | 无变更 |
| `VideoThumbnailCard` | 视频缩略图展示 | Stateful (async thumbnail) | 无变更 |
| `VideoPlaceholderCard` | 上传入口 | Stateless (pure) | 无变更 |

---

## 状态管理

### ExerciseRecordState 数据结构（v2.0）

```dart
class ExerciseRecordState {
  final List<StudentExerciseModel> exercises;  // 动作列表
  final bool isLoading;                         // 加载状态
  final bool isSaving;                          // 保存状态
  final String? error;                          // 错误信息
  final String currentDate;                     // 当前日期 (yyyy-MM-dd)
  final String? exercisePlanId;                 // 训练计划 ID
  final int? exerciseDayNumber;                 // 训练日编号
  final String? coachId;                        // 教练 ID

  // v2.0 新增：计时器相关
  final DateTime? timerStartTime;               // ✅ 全局计时器开始时间
  final bool isTimerRunning;                    // ✅ 是否正在计时
  final Map<int, DateTime> exerciseStartTimes; // ✅ 每个 exercise 的开始时间

  // v2.0 新增：计算属性
  Duration get elapsedTime {                    // ✅ 计时器经过时间
    if (timerStartTime == null) return Duration.zero;
    return DateTime.now().difference(timerStartTime!);
  }
}
```

### StudentExerciseModel 数据结构（v2.0）

```dart
class StudentExerciseModel {
  final String name;                          // 动作名称
  final String note;                          // 教练备注
  final ExerciseType type;                    // 动作类型
  final List<TrainingSet> sets;               // Set 列表
  final bool completed;                       // 是否完成
  final List<String> videos;                  // 视频 URL 列表
  final List<VoiceFeedbackModel> voiceFeedbacks; // 语音反馈
  final int? timeSpent;                       // ✅ v2.0 新增：动作耗时（秒数）
}
```

### TrainingSet 数据结构（v2.0）

```dart
class TrainingSet {
  final String reps;      // 次数 (字符串，支持任意文本如 "8-12")
  final String weight;    // ✅ v2.0 更新：重量 (字符串，支持文本如 "自重"、"60kg"，最多10字符)
  final bool completed;   // ✅ v2.0 更新：该 Set 是否完成 (reps 不为空时自动标记)
}
```

### Provider 层次

```dart
// Repository Provider
final trainingRecordRepositoryProvider = Provider<TrainingRecordRepository>(
  (ref) => TrainingRecordRepositoryImpl(
    cloudFunctions: ref.watch(cloudFunctionsServiceProvider),
    storage: ref.watch(firebaseStorageProvider),
  ),
);

// State Notifier Provider (auto-dispose)
final exerciseRecordNotifierProvider =
  StateNotifierProvider.autoDispose<ExerciseRecordNotifier, ExerciseRecordState>(
    (ref) {
      final repository = ref.watch(trainingRecordRepositoryProvider);
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return ExerciseRecordNotifier(repository, today);
    },
  );
```

---

## 核心功能实现

**关键方法** (详见代码):

| 功能 | 方法 | 位置 |
|------|------|------|
| Set 编辑 | `updateSetRealtime()` | `exercise_record_notifier.dart` |
| 快捷完成 | `quickComplete()` | `exercise_record_notifier.dart` |
| 视频上传 | `addPendingVideo()`, `completeVideoUpload()` | `exercise_record_notifier.dart` |
| 计时器 | `startTimer()`, `stopTimer()` | `exercise_record_notifier.dart` |
| 数据保存 | `saveRecord()` | `exercise_record_notifier.dart` |

**设计原则**:
- ✅ 仅 exercise 完成时保存（节省 Firebase 写入）
- ✅ 状态同步：VideoUploadSection ↔ Notifier
- ✅ 异步操作：视频压缩、上传不阻塞 UI
- ✅ Auto-dispose: 离开页面自动释放资源

---

## API 集成

### Cloud Functions API

#### 1. fetch_today_training

**用途**: 获取今日训练记录（如果存在）

**请求**:
```json
{
  "date": "2025-11-08"
}
```

**响应**:
```json
{
  "id": "abc123",
  "studentID": "user_xyz",
  "coachID": "coach_abc",
  "date": "2025-11-08",
  "planSelection": {
    "exercisePlanId": "plan_123",
    "exerciseDayNumber": 1
  },
  "exercises": [
    {
      "name": "Barbell Squats",
      "note": "Focus on form",
      "type": "strength",
      "sets": [
        {"reps": "10", "weight": "50kg", "completed": true}
      ],
      "completed": true,
      "videos": ["https://..."],
      "voiceFeedbacks": [],
      "timeSpent": 180  // ✅ v2.0 新增：动作耗时（秒数）
    }
  ],
  "completionStatus": "in_progress",
  "isReviewed": false
}
```

#### 2. upsert_today_training

**用途**: 创建或更新今日训练记录

**请求**:
```json
{
  "studentID": "user_xyz",      // ✅ 必需 (从 FirebaseAuth 获取)
  "coachID": "coach_abc",        // ✅ 必需
  "date": "2025-11-08",          // ✅ 必需
  "planSelection": {...},
  "exercises": [...],
  "completionStatus": "in_progress"
}
```

**响应**:
```json
{
  "id": "abc123",
  "message": "Training record updated successfully"
}
```

**错误处理**:
- `invalid-argument`: 缺少必需字段
- `unauthenticated`: 用户未登录
- `permission-denied`: 权限不足

### Firebase Storage 路径规范

**视频存储路径**:
```
students/trainings/{date}/{exerciseIndex}/{timestamp}.mp4
```

**示例**:
```
students/trainings/2025-11-08/0/1699999999999.mp4
students/trainings/2025-11-08/1/1700000000000.mp4
```

**缩略图缓存** (临时目录):
```
/tmp/flutter_video_thumbnails/{video_hash}.jpg
```

---

## UI 设计规范

**参考**:
- 全局样式: `lib/core/theme/app_text_styles.dart`, `lib/core/theme/app_colors.dart`
- 设计系统: [CLAUDE.md](../CLAUDE.md#typography)

**关键样式**:
- **已完成状态**: 绿色 checkmark (`AppColors.successGreen`)
- **卡片圆角**: `12px` (AppDimensions.radiusM)
- **间距**: `16px` (Card), `8px` (行间距)
- **字体**: `AppTextStyles.callout` (动作), `AppTextStyles.body` (输入)

---

## 关键代码位置

### 核心文件

| 文件路径 | 功能 | 行数 |
|---------|------|------|
| `lib/features/student/training/presentation/pages/exercise_record_page.dart` | 页面入口 | ~180 |
| `lib/features/student/training/presentation/providers/exercise_record_notifier.dart` | 业务逻辑 | ~270 |
| `lib/features/student/training/data/repositories/training_record_repository_impl.dart` | 数据访问 | ~100 |
| `lib/features/student/training/presentation/widgets/exercise_record_card.dart` | 动作卡片 | ~140 |
| `lib/features/student/training/presentation/widgets/set_input_row.dart` | Set 输入 | ~210 |
| `lib/features/student/training/presentation/widgets/my_recordings_section.dart` | 视频管理 | ~150 |
| `lib/features/student/training/presentation/widgets/video_thumbnail_card.dart` | 视频缩略图 | ~170 |
| `lib/core/utils/video_utils.dart` | 视频工具 | ~110 |

### 数据模型

| 文件路径 | 模型 |
|---------|------|
| `lib/features/student/training/data/models/student_exercise_model.dart` | StudentExerciseModel |
| `lib/features/coach/plans/data/models/training_set.dart` | TrainingSet |
| `lib/features/student/home/data/models/daily_training_model.dart` | DailyTrainingModel |
| `lib/features/student/training/data/models/student_exercise_record_state.dart` | ExerciseRecordState |

### 路由配置

**文件**: `lib/routes/app_router.dart` (line 88-93)

```dart
GoRoute(
  path: RouteNames.studentExerciseRecord,
  pageBuilder: (context, state) =>
    CupertinoPage(key: state.pageKey, child: const ExerciseRecordPage()),
),
```

**入口**: `lib/features/student/presentation/widgets/record_activity_bottom_sheet.dart` (line 99-102)

```dart
onTap: () {
  Navigator.pop(context);
  context.push(RouteNames.studentExerciseRecord);
},
```

---

## 未来扩展点

### 1. 相机录制功能

**状态**: 🚧 待实现

**需要创建**:
- `lib/features/student/training/presentation/pages/camera_record_page.dart`
- 集成 `camera` package
- 实现录制、预览、确认流程
- 添加从相册选择功能
- 验证视频时长（≤60秒）

**路由配置**:
```dart
GoRoute(
  path: RouteNames.cameraRecord,
  pageBuilder: (context, state) =>
    CupertinoPage(key: state.pageKey, child: const CameraRecordPage()),
),
```

**调用位置**: `MyRecordingsSection._showRecordOptions()`

### 2. 视频压缩优化

**状态**: 💡 建议

**优化方案**:
- 上传前压缩视频（使用 `flutter_ffmpeg`）
- 限制分辨率（720p）和码率
- 显示上传进度
- 支持后台上传

### 3. 离线模式支持

**状态**: 💡 建议

**方案**:
- 使用 Hive 本地缓存训练记录
- 网络恢复后自动同步
- 冲突解决策略（后写入覆盖）

### 4. 教练反馈集成

**状态**: 💡 未来功能

**功能**:
- 教练查看学生视频
- 添加语音/文字反馈
- 学生接收通知并查看反馈
- 显示在动作卡片底部

**数据结构** (已预留):
```dart
class VoiceFeedbackModel {
  final String id;
  final String filePath;
  final int duration;
  final String tempUrl;
}
```

### 5. 数据分析

**状态**: 💡 未来功能

**功能**:
- 训练完成率统计
- Set 重量进步趋势图
- 视频上传次数统计
- 与计划对比分析

### 6. 社交分享

**状态**: 💡 未来功能

**功能**:
- 分享训练视频到社交平台
- 生成训练成果卡片
- 与好友对比数据

---

## 参考资料

### 相关文档

- [Backend APIs and Document DB Schemas](./backend_apis_and_document_db_schemas.md)
- [Flutter Cupertino Design Guidelines](https://docs.flutter.dev/development/ui/widgets/cupertino)
- [Riverpod Documentation](https://riverpod.dev/)

### 相关 Issue

- [Student Training Feature Implementation](https://github.com/...)
- [Video Upload Performance Optimization](https://github.com/...)

### 代码规范

- [CLAUDE.md](../CLAUDE.md) - 项目编码规范
- [JSON Parsing Fix](./json_parsing_fix.md) - Firebase 数据解析规范

---

## 版本历史

### v2.0-v2.2 (2025-01-08 至 2025-11-08)
**核心变更**:
- ✅ PageView 横向滚动 + 自定义页面指示器
- ✅ 训练计时器（全局 + 单个 exercise）
- ✅ 智能保存策略（仅 exercise 完成时保存）
- ✅ 自动完成逻辑（reps 不为空 → Set 完成）
- ✅ 重新编辑已完成 Set
- ✅ Weight 输入支持文本（如"自重"）
- ✅ 祝贺横幅 + 进度条

**详细信息**: 参见 Git 历史 `git log --grep="v2.[0-2]"`
## v2.3 更新摘要（2025-11-15）

### 🎯 核心功能新增

#### 训练总时长 (totalDuration) ✅

**功能描述**:
- 记录从启动计时器到最后一个 exercise 完成的总时长（秒数）
- 用于教练查看学生训练效率和 AI 分析运动表现
- 区别于各 exercise 的 `timeSpent`（单个动作耗时）

**实现细节**:

**1. 数据模型变更**

`DailyTrainingModel` 新增字段:
```dart
final int? totalDuration;  // 训练总时长（秒数），nullable
```

**2. 保存逻辑**

位置：`ExerciseRecordNotifier.saveRecord()` (exercise_record_notifier.dart:347-354)

```dart
// 计算 totalDuration（仅当所有 exercise 完成且计时器运行过）
int? totalDuration;
final allExercisesCompleted = state.exercises.isNotEmpty &&
                               state.exercises.every((e) => e.completed);
if (allExercisesCompleted && state.timerStartTime != null) {
  totalDuration = DateTime.now().difference(state.timerStartTime!).inSeconds;
}
```

**3. 保存条件**

| 场景 | 计时器状态 | 完成状态 | totalDuration |
|------|-----------|---------|---------------|
| 完成所有 exercise + 启动计时器 | ✅ 已启动 | ✅ 全部完成 | 实际秒数 ✅ |
| 完成部分 exercise + 启动计时器 | ✅ 已启动 | ❌ 部分完成 | null ❌ |
| 完成所有 exercise + 未启动计时器 | ❌ 未启动 | ✅ 全部完成 | null ❌ |
| 中途退出页面 | - | ❌ 部分完成 | null ❌ (不保存) |

**4. 数据关系**

```
totalDuration (全局总时长)
    ≥
sum(exercise.timeSpent) (各动作耗时总和)

差值 = 休息时间 + 页面浏览时间 + 其他非训练时间
```

**示例**:
```json
{
  "id": "abc123",
  "date": "2025-11-15",
  "totalDuration": 1800,  // 30 分钟（从启动计时器到完成所有动作）
  "exercises": [
    {
      "name": "Barbell Squats",
      "timeSpent": 180,    // 3 分钟（该动作实际操作时间）
      "completed": true
    },
    {
      "name": "Deadlift",
      "timeSpent": 240,    // 4 分钟
      "completed": true
    },
    {
      "name": "Bench Press",
      "timeSpent": 200,    // 3.3 分钟
      "completed": true
    }
    // sum(timeSpent) = 620s (10.3 分钟)
    // totalDuration = 1800s (30 分钟)
    // 差值 = 1180s (19.7 分钟休息/切换时间)
  ]
}
```

---

### 🗂️ 数据模型变更

#### DailyTrainingModel
```dart
// 新增字段
+ int? totalDuration  // 训练总时长（秒数）
```

#### 后端 Schema 更新

**dailyTrainings 集合** (`backend_apis_and_document_db_schemas.md:227`):
```
| totalDuration | number (optional) |
```

**说明**: 从启动计时器到最后一个 exercise 完成的总时长（秒数），仅在所有 exercise 完成且计时器已启动时保存。

---

### 🔧 业务逻辑变更

#### ExerciseRecordNotifier
```dart
// 修改方法
~ saveRecord()  // 添加 totalDuration 计算逻辑
```

**计算时机**:
- 每次调用 `saveRecord()` 时检查条件
- 如果满足条件（所有 exercise 完成 + 计时器启动），计算并保存
- 不满足条件时，`totalDuration` 保持为 null

---

### 📦 兼容性

**向后兼容**: ✅
- `totalDuration` 为可选字段（nullable）
- 旧记录没有此字段不影响读取
- 后端 Cloud Functions 无需修改（已支持任意字段）

**Coach 端显示**: ⚠️ 待开发
- 当前仅实现 Student 端数据保存
- Coach 端查看功能需单独实现

---

### 📝 文档更新

**已更新文档**:
1. `docs/backend_apis_and_document_db_schemas.md`
   - 添加 `dailyTrainings.totalDuration` 字段说明
   - 补充 `StudentExercise.timeSpent` 字段说明（已有功能，补充文档）

2. `docs/student/exercise_record_page_architecture.md` (本文档)
   - 版本号: 2.2 → 2.3
   - 新增 v2.3 更新摘要

---

### 🎯 用途

**1. 教练端分析**:
- 查看学生训练效率（实际操作时间 vs 总时长）
- 评估训练节奏和休息时间合理性
- 对比不同学生的训练速度

**2. AI 分析**:
- 分析运动表现趋势
- 评估训练强度和恢复时间
- 提供个性化建议

---

**v2.3 贡献者**: Claude Code
**v2.3 审核**: 待用户测试反馈

---

## v2.4 更新摘要（2025-11-16）

### 🐛 Bug 修复

#### 问题 1: 第二个视频切换 exercise 后消失
**根本原因**: `ExerciseRecordCard` 只传入 `completed` 状态的视频给 `VideoUploadSection`

**修复**:
- 移除视频过滤逻辑，传入所有视频状态（pending, uploading, completed, error）
- 位置: `exercise_record_card.dart:171`

#### 问题 2: 第二个视频没保存到后端
**根本原因**: 双重状态管理冲突
- `VideoUploadSection` 自管理上传，完成后更新自己的状态
- `ExerciseRecordNotifier` 的状态未同步，保存时被过滤

**修复**:
- 新增 `addPendingVideo()` 方法：添加 pending 视频占位符
- 新增 `completeVideoUpload()` 方法：同步上传完成状态并保存
- 通过 `onUploadCompleted` 回调正确同步状态

---

### 🔧 技术变更

#### ExerciseRecordNotifier 新增方法

**`addPendingVideo(int exerciseIndex, String localPath, String? thumbnailPath)`**
- 功能: 添加 pending 状态视频，不启动上传
- 由 VideoUploadSection 选择视频后调用
- 位置: `exercise_record_notifier.dart:709-732`

**`completeVideoUpload(int exerciseIndex, int videoIndex, String downloadUrl, {String? thumbnailUrl})`**
- 功能: 更新视频状态为 completed，立即保存到 Firestore
- 由 VideoUploadSection 上传完成后调用
- 位置: `exercise_record_notifier.dart:737-781`

#### 旧方法标记为 Deprecated

- `uploadVideo()` - 现由 VideoUploadSection 处理
- `_compressAndUpload()` - 现由 VideoUploadSection 处理
- `_startAsyncUpload()` - 现由 VideoUploadSection 处理

---

### 📊 数据流更新

**新的视频上传流程** (v2.4):

```
用户选择视频
    ↓
VideoUploadSection 生成缩略图（本地）
    ↓
VideoUploadSection 添加到自己的 _videos (pending)
    ↓
回调: onVideoSelected(index, file)
    ↓
ExerciseRecordNotifier.addPendingVideo()
    └─ 添加到 state.exercises[i].videos (pending, 缩略图路径为 null)
    ↓
VideoUploadSection 启动后台压缩和上传
    ↓
上传进度更新: VideoUploadSection._videos[i].progress
    ↓
上传完成: 获取 downloadUrl 和 thumbnailUrl
    ↓
回调: onUploadCompleted(index, downloadUrl, thumbnailUrl)
    ↓
ExerciseRecordNotifier.completeVideoUpload()
    ├─ 更新 state.exercises[i].videos[i].status = completed
    ├─ 设置 downloadUrl 和 thumbnailUrl
    └─ 立即保存到 Firestore ✅
```

**对比旧流程** (v2.3):
- ❌ 双重上传逻辑（ExerciseRecordNotifier 和 VideoUploadSection 都上传）
- ❌ 状态不同步（VideoUploadSection 完成了，notifier 还是 pending）
- ❌ 只传入 completed 视频（切换后丢失 uploading 的视频）

---

### 🔄 职责划分

| 组件 | 职责 | v2.4 变更 |
|------|------|-----------|
| **VideoUploadSection** | UI 展示、视频选择、压缩上传 | 无变更（继续负责上传） |
| **ExerciseRecordNotifier** | 唯一状态源、数据持久化 | ✅ 新增状态同步方法 |
| **ExerciseRecordCard** | UI 容器、回调连接 | ✅ 传入所有视频、连接新回调 |
| **ExerciseRecordPage** | 页面管理、回调绑定 | ✅ 绑定新的回调方法 |

---

### 📝 关键代码位置

| 文件 | 变更 |
|------|------|
| `exercise_record_notifier.dart:709-781` | 新增 `addPendingVideo()` 和 `completeVideoUpload()` |
| `exercise_record_notifier.dart:414-417` | 标记 `uploadVideo()` 为 Deprecated |
| `exercise_record_card.dart:171` | 移除视频过滤 |
| `exercise_record_card.dart:26-27` | 新增 `onVideoUploadCompleted` 回调参数 |
| `exercise_record_card.dart:175-183` | 修改回调逻辑 |
| `exercise_record_page.dart:295-311` | 连接新回调 |

---

**v2.4 贡献者**: Claude Code
**v2.4 审核**: 待用户测试反馈
