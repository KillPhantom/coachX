# Exercise Record Page 架构文档

**版本**: 2.2
**更新日期**: 2025-11-08
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

### 6. 视频上传流程

```
用户点击 "录制视频" 占位符
    ↓
MyRecordingsSection._showRecordOptions()
    ↓
[TODO: 选择相机录制 or 从相册选择]
    ↓
获得 File videoFile
    ↓
ExerciseRecordCard.onVideoUploaded(videoFile)
    ↓
ExerciseRecordNotifier.uploadVideo(exerciseIndex, videoFile)
    ↓
├─ 构建存储路径
│  └─ 'students/trainings/{date}/{exerciseIndex}/{timestamp}.mp4'
│
├─ Repository.uploadVideo(file, path)
│  └─ FirebaseStorage.putFile()
│      └─ 返回 downloadUrl
│
├─ 更新本地状态
│  └─ exercises[index].videos.add(downloadUrl)
│
└─ 自动保存
    └─ saveRecord()
```

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
│   │   └── trailing: Row
│   │       ├── Timer Icon (启动计时器)
│   │       └── Add Icon (添加自定义动作)
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

### 1. Debounce 自动保存

**实现位置**: `ExerciseRecordNotifier.updateSetRealtime()`

```dart
Timer? _debounceTimer;

void updateSetRealtime(int exerciseIndex, int setIndex, TrainingSet set) {
  // 更新本地状态
  final exercise = state.exercises[exerciseIndex];
  final updatedExercise = exercise.updateSet(setIndex, set);
  updateExercise(exerciseIndex, updatedExercise);

  // Debounce 保存
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
    saveRecord().catchError((e) => AppLogger.error('实时保存失败', e));
  });
}
```

**优点**:
- 减少频繁的网络请求
- 提升用户体验（无感保存）
- 避免并发冲突

**注意事项**:
- 必须在 `dispose()` 时取消 Timer
- 错误处理要优雅（不能阻塞 UI）

### 2. 状态切换（可编辑 ↔ 已完成）

**实现位置**: `SetInputRow` 组件

```dart
// 未完成状态：显示可编辑输入框
CupertinoTextField(
  controller: _repsController,
  onChanged: (value) {
    final updatedSet = widget.set.copyWith(reps: value);
    widget.onChanged(updatedSet);  // 触发实时保存
  },
)

// 已完成状态：显示只读文本 + checkmark
GestureDetector(
  onTap: widget.onToggleEdit,  // 点击重新编辑
  child: Container(
    // 浅色背景 + 绿色边框
    child: Row([
      Text('${set.reps} reps x ${set.weight} kg'),
      Icon(CupertinoIcons.checkmark_circle_fill),
    ]),
  ),
)
```

### 3. 视频缩略图生成

**实现位置**: `VideoThumbnailCard._loadThumbnailAndDuration()`

```dart
Future<void> _loadThumbnailAndDuration() async {
  // 异步生成缩略图
  final thumbnail = await VideoUtils.generateThumbnail(widget.videoUrl);

  // 异步获取视频时长
  final duration = await VideoUtils.getVideoDuration(widget.videoUrl);

  if (mounted) {
    setState(() {
      _thumbnailFile = thumbnail;
      _duration = duration;
      _isLoading = false;
    });
  }
}
```

**优化**:
- 使用 `video_thumbnail` package (原生支持)
- 缓存到临时目录（避免重复生成）
- 异步加载（不阻塞主线程）

### 4. 快捷完成

**实现位置**: `ExerciseRecordNotifier.quickComplete()`

```dart
Future<void> quickComplete(int index) async {
  // 1. 标记完成（保留 prefill data）
  final exercise = state.exercises[index];
  final completedExercise = exercise.copyWith(completed: true);
  updateExercise(index, completedExercise);

  // 2. 立即保存（不走 debounce）
  await saveRecord();
}
```

**关键点**:
- 使用计划的默认数据（不需要手动输入）
- 立即保存（不延迟）
- 适合快速打卡场景

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

### 颜色使用

| 元素 | 颜色 | 说明 |
|------|------|------|
| 未完成 Set 背景 | `AppColors.backgroundWhite` | 白色 |
| 已完成 Set 背景 | `AppColors.primaryColor.withOpacity(0.1)` | 浅黄色 |
| 已完成 Set 边框 | `AppColors.primaryColor.withOpacity(0.3)` | 半透明黄色 |
| Checkmark 图标 | `AppColors.primaryColor` | 主题黄色 |
| 删除按钮 | `CupertinoColors.systemRed` | 系统红色 |
| 占位框边框 | `AppColors.dividerLight` | 浅灰色虚线 |

### 字体使用

| 元素 | 字体样式 | 大小 |
|------|---------|------|
| 动作名称 | `AppTextStyles.callout` (Bold) | 16px |
| Set 标签 | `AppTextStyles.callout` | 16px |
| 输入框文字 | `AppTextStyles.body` | 17px |
| 教练备注 | `AppTextStyles.subhead` | 15px |
| 快捷完成按钮 | `AppTextStyles.footnote` | 13px |
| 视频时长 | `AppTextStyles.caption2` | 11px |

### 尺寸规范

| 元素 | 宽度 | 高度 | 圆角 |
|------|------|------|------|
| Exercise Card | 100% | auto | 12px |
| Set Input Row | 100% | auto | 8px |
| Video Thumbnail | 100px | 100px | 12px |
| Video Placeholder | 100px | 100px | 12px |
| Checkmark Icon | 24px | 24px | - |
| Delete Button | 24px | 24px | 圆形 |

### 间距规范

- Card 间距: `16px`
- Set 行间距: `8px`
- 区域内边距: `16px`
- 小元素间距: `8px`

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

### 2. 自定义动作添加

**状态**: 🚧 待实现

**功能**:
- 点击右上角 "+" 按钮
- 弹出对话框输入动作名称、Sets 数量
- 添加到当日记录（不影响计划）
- 保存到 Firestore

**实现位置**: `ExerciseRecordPage._showAddCustomExerciseAlert()`

### 3. 视频压缩优化

**状态**: 💡 建议

**优化方案**:
- 上传前压缩视频（使用 `flutter_ffmpeg`）
- 限制分辨率（720p）和码率
- 显示上传进度
- 支持后台上传

### 4. 离线模式支持

**状态**: 💡 建议

**方案**:
- 使用 Hive 本地缓存训练记录
- 网络恢复后自动同步
- 冲突解决策略（后写入覆盖）

### 5. 教练反馈集成

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

### 6. 数据分析

**状态**: 💡 未来功能

**功能**:
- 训练完成率统计
- Set 重量进步趋势图
- 视频上传次数统计
- 与计划对比分析

### 7. 社交分享

**状态**: 💡 未来功能

**功能**:
- 分享训练视频到社交平台
- 生成训练成果卡片
- 与好友对比数据

---

## 常见问题 (FAQ)

### Q1: 为什么保存时需要 FirebaseAuth.currentUser.uid？

**A**: 后端 Cloud Function 需要 `studentID` 字段来标识数据所有权，不能从认证上下文自动获取（与其他 API 不同），必须显式传递。

### Q2: 为什么使用 debounce 而不是立即保存？

**A**:
- 减少网络请求频率（用户可能连续编辑多个 Set）
- 避免 Firestore 写入配额过快消耗
- 提升 UI 响应速度（不阻塞输入）

### Q3: 视频删除后 Storage 文件会被删除吗？

**A**:
- **当前实现**: 只删除 Firestore 引用，不删除 Storage 文件
- **原因**: 避免误删、保留教练反馈历史
- **建议**: 添加定期清理任务（Cloud Function + Scheduler）

### Q4: 如何处理日期跨越时区问题？

**A**:
- 使用 `DateFormat('yyyy-MM-dd').format(DateTime.now())` 获取本地日期
- 后端按字符串存储（不做时区转换）
- 保证同一自然日的数据一致性

### Q5: 为什么 ExerciseRecordState 使用 List 而不是 Map？

**A**:
- 保持顺序（计划中的动作有固定顺序）
- 简化 UI 渲染（ListView.builder 直接使用 index）
- 避免 Map key 管理复杂性

---

## 性能优化建议

### 1. 视频缩略图缓存

**问题**: 每次打开页面重新生成缩略图

**优化**:
```dart
// 使用 cached_network_image 缓存逻辑
// 或者存储缩略图 URL 到 Firestore
final thumbnailUrl = '${videoUrl}_thumbnail.jpg';
```

### 2. Provider Auto-Dispose

**已实现**: ✅
```dart
StateNotifierProvider.autoDispose<...>
```

**优点**:
- 离开页面自动释放内存
- 取消未完成的异步操作
- 防止内存泄漏

### 3. 输入框 Controller 管理

**已实现**: ✅ SetInputRow 内部管理 TextEditingController

**优点**:
- 避免父组件重建时 Controller 丢失
- 正确处理 dispose 生命周期

### 4. 列表滚动优化

**建议**:
```dart
ListView.builder(
  itemExtent: 200, // 固定高度（如果可能）
  cacheExtent: 500, // 预加载范围
)
```

---

## 测试清单

### 功能测试

- [ ] 页面加载显示今日计划的动作
- [ ] 修改 Set 的 reps/weight 能实时保存
- [ ] 点击"快捷完成"能标记动作完成
- [ ] 已完成的 Set 显示绿色 checkmark
- [ ] 点击已完成的 Set 能重新编辑
- [ ] 上传视频显示缩略图和时长
- [ ] 删除视频后列表更新
- [ ] 最多只能上传3个视频
- [ ] 离开页面后数据持久化

### 边界测试

- [ ] 没有训练计划时显示空状态
- [ ] 网络断开时显示错误提示
- [ ] 视频上传失败后的错误处理
- [ ] 多次快速编辑 Set 不会导致数据丢失
- [ ] 视频时长超过1分钟时提示错误

### 性能测试

- [ ] 包含10个动作时滚动流畅
- [ ] 上传大视频（50MB）时不卡顿
- [ ] 缩略图生成不阻塞主线程
- [ ] 离开页面后内存正常释放

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

## v2.0 更新摘要（2025-01-08）

### 🎯 核心功能升级

#### 1. PageView 横向滚动 ✅
- **变更**: ListView.builder → PageView.builder
- **新增**: 底部 `SmoothPageIndicator` 页面指示器
- **新增**: Exercise 完成后自动滑到下一页（300ms 动画）
- **优点**: 更好的用户体验，每次专注一个动作

#### 2. 训练计时器 ✅
- **新增组件**: `TimerHeader` (全局计时器，HH:MM:SS)
- **新增组件**: `ExerciseTimeHeader` (动作耗时，MM:SS)
- **新增字段**: `ExerciseRecordState.timerStartTime`, `isTimerRunning`, `exerciseStartTimes`
- **新增字段**: `StudentExerciseModel.timeSpent` (秒数)
- **交互**: 右上角 Timer Icon → 确认对话框 → 启动计时
- **自动记录**: 首次编辑时记录开始时间，完成时计算耗时

#### 3. 智能保存策略 ✅
- **移除**: Set 修改时的 debounce 自动保存（500ms）
- **新增**: 仅在 Exercise 完成时保存
- **优点**: 节省 Firebase 写入次数，降低成本
- **场景**: Set 编辑不触发保存，只有所有 Sets 完成后才保存

#### 4. 自动完成逻辑 ✅
- **自动标记 Set**: reps 不为空时，自动 `set.completed = true`
- **自动完成 Exercise**: 所有 Sets 完成后，自动 `exercise.completed = true`
- **自动滑动**: Exercise 完成后，PageView 自动滑到下一个
- **自动保存**: Exercise 完成时立即保存到 Firebase

#### 5. 重新编辑支持 ✅
- **新增**: 点击已完成的 Set（绿色 checkmark）可重新编辑
- **自动取消**: 点击后自动取消 Exercise 的完成状态
- **UI 更新**: SetInputRow 清空文本，显示输入框
- **灵活性**: 允许用户修正错误输入

#### 6. Weight 输入优化 ✅
- **移除**: "kg" suffix label
- **新增**: Placeholder "自重/60kg" (i18n)
- **支持**: 文本输入，如 "自重"、"60kg"、"155 lbs"
- **限制**: 最多 10 字符
- **移除**: 数字限制 `FilteringTextInputFormatter`

#### 7. UI 细节改进 ✅
- **ExerciseRecordCard**:
  - 添加 Material `Icons.fitness_center` icon
  - 完成后显示绿色 border (`AppColors.successGreen`)
  - 移除背景色变化（保持白色）
  - 教练备注移到 Sets 之前
- **SetInputRow**:
  - Checkmark 改为绿色（`AppColors.successGreen`）
  - Placeholder 显示计划默认值
  - 快捷完成时自动填充 placeholder
- **ExerciseRecordPage**:
  - NavigationBar trailing 添加 Timer Icon 和 Add Icon

### 🗂️ 数据模型变更

```dart
// ExerciseRecordState 新增字段
+ DateTime? timerStartTime
+ bool isTimerRunning
+ Map<int, DateTime> exerciseStartTimes
+ Duration get elapsedTime

// StudentExerciseModel 新增字段
+ int? timeSpent

// TrainingSet 行为变更
weight: 字符串类型，支持文本输入（最多10字符）
completed: reps 不为空时自动标记为 true
```

### 📦 新增依赖

```yaml
smooth_page_indicator: ^1.2.0
```

### 🔧 业务逻辑变更

```dart
// ExerciseRecordNotifier 新增方法
+ startTimer() / stopTimer()
+ _recordExerciseStartTime(int index)
+ _calculateExerciseTimeSpent(int index) -> int?
+ _checkAndCompleteExercise(int index)

// ExerciseRecordNotifier 修改方法
~ updateSetRealtime() - 移除 debounce 保存，添加自动完成检查
~ quickComplete() - 添加耗时计算
~ toggleSetCompleted() - 添加取消 Exercise 完成状态逻辑
```

### 🎨 新增 UI 组件

1. **TimerHeader** (`timer_header.dart`)
   - 全局计时器显示
   - Timer.periodic 每秒刷新
   - 格式: HH:MM:SS

2. **ExerciseTimeHeader** (`exercise_time_header.dart`)
   - 动作耗时显示
   - 格式: ⏱️ 用时: MM:SS
   - 样式: caption1, 浅灰背景

### 🌐 国际化新增

```json
// app_en.arb & app_zh.arb
"startTimerConfirmTitle": "Start Timer" / "开始计时"
"startTimerConfirmMessage": "Start training timer?" / "确认开始训练计时吗？"
"startTimerButton": "Start" / "开始"
"weightPlaceholder": "Bodyweight/60kg" / "自重/60kg"
"timeSpentLabel": "Time Spent" / "用时"
"trainingRecord": "Training Record" / "训练记录"
"loadFailed": "Load Failed" / "加载失败"
"retry": "Retry" / "重试"
"noExercises": "No Exercises" / "暂无训练动作"
"addCustomExerciseHint": "Tap '+' to add" / "点击右上角\"+\"添加"
```

### 🐛 Bug 修复

1. **Set 无法重新编辑** - 修复 `toggleSetCompleted` 逻辑
2. **计时器不刷新** - `TimerHeader` 改为接收 `DateTime? startTime` 而非 `Duration`

### 📝 文档更新

- 版本号: 1.0 → 2.0
- 更新日期: 2025-01-08
- 新增章节: 计时器流程、重新编辑流程、v2.0 优化点
- 更新章节: 所有数据结构、组件层次、数据流

---

**文档维护**: 此文档应随代码更新保持同步。如有架构变更，请及时更新相应章节。

**v2.0 贡献者**: Claude Code
**v2.0 审核**: 待用户测试反馈

---

## v2.1 更新摘要（2025-11-08）

### 🎯 核心功能优化

#### 1. 移除自动跳转逻辑 ✅
**变更**:
- 删除 `_autoScrollToNext` 方法
- 删除监听 completed 数量变化的 `ref.listen`
- 用户完成 exercise 后不再自动跳转到下一页

**优点**:
- 用户完全控制页面导航
- 避免在重新编辑场景下意外跳转
- 更符合用户预期的交互行为

#### 2. 自定义页面指示器 ✅
**新增组件**: `CustomPageIndicator`

**功能**:
- 显示格式: `1 / 3 (2 completed)`
- 左右箭头按钮支持点击切换页面
- 实时显示当前页/总页数/已完成数量

**实现位置**: `lib/features/student/training/presentation/widgets/custom_page_indicator.dart`

**UI布局**:
```
[<] 箭头  |  1 / 3 (2 completed)  |  [>] 箭头
```

**替换**: 移除 `smooth_page_indicator` 依赖

#### 3. 双列计时器 UI ✅
**组件**: `TimerHeader` 重新设计

**布局**:
```
┌──────────────────────────────────────────┐
│ 当前动作              总时长              │
│ 05:23:45            01:23:45            │
│ (MM:SS:MS)          (HH:MM:SS)          │
└──────────────────────────────────────────┘
```

**变更**:
- 左列: 当前Exercise耗时（分:秒:毫秒，2位）
- 右列: 全局计时器（时:分:秒）
- 刷新频率: 每100毫秒（支持毫秒显示）

**新增参数**: `DateTime? currentExerciseStartTime`

#### 4. 智能计时器重置逻辑 ✅
**新增字段** (`ExerciseRecordState`):
```dart
final DateTime? currentExerciseStartTime;  // 当前Exercise开始时间
final int? currentExerciseIndex;           // 当前Exercise索引
Duration? get currentExerciseElapsed;      // 计算属性
```

**新增方法** (`ExerciseRecordNotifier`):
```dart
void startExerciseTimer(int index)         // 启动Exercise计时
void resetExerciseTimer(int newIndex)      // 重置到新Exercise
void _resetTimerToNextIncomplete(int completedIndex)  // 智能查找下一个未完成
```

**重置逻辑**:
1. ✅ 页面滑动**不会**重置计时器
2. ✅ Exercise完成时**自动**重置计时器
3. ✅ 优先重置到完成exercise **后面**的第一个未完成exercise
4. ✅ 如果后面没有，从头查找
5. ✅ 所有exercise完成后停止重置

**触发时机**:
- `_checkAndCompleteExercise()` - 所有Sets完成时
- `quickComplete()` - 快捷完成时

#### 5. 计时器计算优化 ✅
**修改**: `_calculateExerciseTimeSpent(int index)`

**逻辑**:
```dart
// 优先使用 currentExerciseStartTime
if (state.currentExerciseIndex == index && state.currentExerciseStartTime != null) {
  return DateTime.now().difference(state.currentExerciseStartTime!).inSeconds;
}
// 降级使用 exerciseStartTimes
return exerciseStartTimes[index] 的耗时;
```

**优点**: 更精确地跟踪当前正在进行的exercise耗时

---

### 🗂️ 数据模型变更

#### ExerciseRecordState
```dart
// 新增字段
+ DateTime? currentExerciseStartTime
+ int? currentExerciseIndex

// 新增计算属性
+ Duration? get currentExerciseElapsed
```

#### 组件参数变更
```dart
// TimerHeader
+ DateTime? currentExerciseStartTime  // 新增参数

// CustomPageIndicator (新组件)
+ int currentPage
+ int totalPages
+ int completedCount
+ VoidCallback? onPreviousPage
+ VoidCallback? onNextPage
```

---

### 📦 依赖变更

**移除**:
```yaml
- smooth_page_indicator: ^1.2.0  # 不再使用
```

---

### 🔧 业务逻辑变更

#### ExerciseRecordNotifier
```dart
// 新增方法
+ startExerciseTimer(int index)
+ resetExerciseTimer(int newIndex)
+ _resetTimerToNextIncomplete(int completedIndex)

// 修改方法
~ _calculateExerciseTimeSpent()  // 优先使用currentExerciseStartTime
~ _checkAndCompleteExercise()    // 完成后重置计时器
~ quickComplete()                // 完成后重置计时器
```

#### ExerciseRecordPage
```dart
// 修改方法
~ _onPageChanged()  // 简化逻辑，不再重置计时器
~ _startTimerMode() // 启动时同时启动第一个exercise计时器

// 移除方法
- _autoScrollToNext()  // 删除自动跳转
```

---

### 🎨 新增 UI 组件

#### CustomPageIndicator
**文件**: `lib/features/student/training/presentation/widgets/custom_page_indicator.dart`

**职责**:
- 显示当前页/总页数/已完成数
- 左右箭头导航
- 根据状态禁用箭头（首页/末页）

**样式**:
- 左右箭头使用 `CupertinoIcons.chevron_left/right`
- 中间文本居中显示
- 禁用状态箭头变灰色

---

### 🌐 国际化新增

```json
// app_en.arb & app_zh.arb
"completedCount": "{count} completed" / "{count} 已完成"
"currentExercise": "Current Exercise" / "当前动作"
"totalDuration": "Total Duration" / "总时长"
```

---

### 🐛 Bug 修复

1. **计时器在滑动时归零** - 修复：页面切换不再重置计时器
2. **向后滑到已完成exercise时重置** - 修复：只有切换到**未完成**exercise时才重置
3. **未使用的导入和字段** - 清理代码，移除 `flutter/material.dart` 导入和 `_previousExerciseCount` 字段

---

### 📝 文档更新

- 版本号: 2.0 → 2.1
- 更新日期: 2025-11-08
- 新增章节: v2.1 更新摘要
- 更新章节: 核心特性、技术栈、数据模型

---

### 🔄 用户体验改进

#### 导航控制
- ✅ 用户可随意滑动查看不同exercise，不会被强制跳转
- ✅ 点击左右箭头快速切换
- ✅ 底部指示器清晰显示进度

#### 计时体验
- ✅ 滑动浏览不影响计时
- ✅ Exercise完成后自动切换到下一个
- ✅ 精确到10毫秒的当前exercise计时
- ✅ 全局总时长一目了然

#### 灵活性
- ✅ 支持非顺序完成（跳过某些exercise）
- ✅ 计时器智能适应完成顺序
- ✅ 随时可回头完成跳过的exercise

---

**v2.1 贡献者**: Claude Code
**v2.1 审核**: 待用户测试反馈

---

## v2.2 更新摘要（2025-11-08）

### 🎨 UI 优化

#### CustomPageIndicator 进度条显示 ✅

**变更**:
- 移除文字显示 `(X completed)`
- 新增底部绿色进度条，直观显示完成比例
- 布局变更: `Row` (单层) → `Column` (双层: 箭头+页码 | 进度条)

**目标布局**:
```
┌───────────────────────────────────────┐
│  <       1 / 3        >               │ ← 箭头导航 + 页码
│  ███████████░░░░░░░░░░░░░░░░░░░      │ ← 进度条（completedCount / totalPages）
└───────────────────────────────────────┘
```

**进度条规格**:
- **填充色**: `AppColors.successGreen` (#10B981, 绿色)
- **背景色**: `AppColors.dividerLight` (#E5E7EB, 浅灰色)
- **高度**: 4.0
- **圆角**: `AppDimensions.radiusFull` (完全圆角)
- **进度计算**: `completedCount / totalPages` (自动处理边界情况)

**实现细节**:
- 使用 `Stack` + `FractionallySizedBox` 实现自定义进度条
- 使用 `ClipRRect` 实现圆角效果
- 使用 `clamp(0.0, 1.0)` 限制进度值范围
- 箭头行与进度条间距: `AppDimensions.spacingS` (8.0)

**代码变更**:
```dart
// 进度计算（边界安全）
final double progress = totalPages > 0 ? completedCount / totalPages : 0.0;

// 进度条组件
ClipRRect(
  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
  child: SizedBox(
    height: 4.0,
    child: Stack(
      children: [
        Container(decoration: BoxDecoration(color: AppColors.dividerLight)),
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          alignment: Alignment.centerLeft,
          child: Container(decoration: BoxDecoration(color: AppColors.successGreen)),
        ),
      ],
    ),
  ),
)
```

**移除依赖**:
- 移除 `AppLocalizations` 导入（不再使用 `l10n.completedCount()`）

**边界处理**:
- ✅ `totalPages = 0` → `progress = 0.0`
- ✅ `completedCount = 0` → `progress = 0.0`
- ✅ `completedCount = totalPages` → `progress = 1.0`
- ✅ `completedCount > totalPages` → `progress = 1.0` (clamp 限制)

---

### 🔄 用户体验改进

#### 视觉清晰度提升
- ✅ 绿色进度条与 ExerciseRecordCard 的绿色 checkmark 保持一致
- ✅ 进度一目了然，无需阅读文字
- ✅ 页码与进度条分离，各司其职（导航 vs 进度）

#### 设计语义
- ✅ 绿色 = 成功/完成（符合通用设计语言）
- ✅ 进度条 = 整体完成度（与 Set 完成状态区分）
- ✅ 极简风格（移除冗余文字）

---

#### Congrats Banner 祝贺横幅 ✅

**功能**: 当所有 exercise 完成时，在页面顶部显示祝贺横幅

**显示条件**:
```dart
state.exercises.isNotEmpty && state.exercises.every((e) => e.completed)
```

**样式规格**:
- **布局**: Row（单行横向布局）
- **背景**: `AppColors.primaryColor` (米黄色 #F2E8CF)
- **圆角**: `AppDimensions.radiusL` (12.0)
- **图标**: `Icons.celebration` (24px, 棕色 `AppColors.primaryAction`)
  - ✅ **动画**: 缩放动画 (1.0 ↔ 1.2, 1秒周期, easeInOut)
- **文字**: `l10n.congratsMessageCompact`
  - 英文: "Congrats! All exercises done!"
  - 中文: "恭喜！所有训练已完成！"
  - 样式: `AppTextStyles.footnote` (13px, Regular)
  - 颜色: `AppColors.textPrimary`
  - 约束: `maxLines: 1`, `overflow: TextOverflow.ellipsis`
- **间距**: 图标与文字间距 8.0

**位置**: CustomPageIndicator 下方（页面最底部）

**内边距**:
- 外层: `Padding(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0)`
- 内层: `Container(horizontal: 16.0, vertical: 12.0)`

**组件文件**: `lib/features/student/training/presentation/widgets/congrats_banner.dart`

**国际化字段**:
- `congratsMessageCompact` - 单行紧凑文字（当前使用）
- `congratsTitle` - 标题文字（已废弃）
- `congratsMessage` - 多行文字（已废弃）

**技术实现**:
- **组件类型**: StatefulWidget (支持动画)
- **Mixin**: SingleTickerProviderStateMixin
- **AnimationController**:
  - 持续时间: 1000ms
  - 重复模式: `repeat(reverse: true)`
  - Vsync: this
- **ScaleAnimation**:
  - Tween: 1.0 → 1.2
  - Curve: Curves.easeInOut
- **应用方式**: ScaleTransition 包裹图标

**性能优化**:
- ✅ 使用 AnimationController 而非 TweenAnimationBuilder（性能更优）
- ✅ 在 dispose 中正确释放 controller（避免内存泄漏）
- ✅ 动画仅应用于图标（减少重绘区域）

#### 单行布局优化 ✅

**变更**: Column（多行）→ Row（单行）

**调整前后对比**:
| 维度 | 多行布局 | 单行布局（当前） |
|------|---------|-----------------|
| **布局** | Column（垂直） | Row（水平） |
| **图标大小** | 32px | 24px |
| **文字** | 标题 + 副标题（2行） | 合并为1行 |
| **垂直占用** | ~80-100px | ~40-50px（减少50%） |
| **文字内容** | "Congrats!" + "You have..." | "Congrats! All exercises done!" |

**优点**:
- ✅ 节省50%垂直空间
- ✅ 更紧凑，一目了然
- ✅ 适合底部显示

#### 位置优化 ✅

**变更**: 从顶部移动到底部

**调整前后对比**:
| 位置 | 优点 | 缺点 |
|------|------|------|
| **顶部**（旧） | 立即看到 | ❌ 占用宝贵空间，压缩内容 |
| **底部**（新） | ✅ 不影响主内容，视觉流程更自然 | 需向下滑动查看 |

**新位置**: CustomPageIndicator 下方
- ✅ 进度条100% + Congrats Banner = 双重视觉强化
- ✅ 符合"完成 → 确认 → 奖励"的自然流程
- ✅ Exercise Card 获得更多垂直空间

**新布局结构**:
```
Column(
  children: [
    TimerHeader (if running),
    Expanded(PageView),
    CustomPageIndicator,     ← 进度条
    CongratsBanner,          ← 紧随其后
  ],
)
```

---

**v2.2 贡献者**: Claude Code
**v2.2 审核**: 待用户测试反馈
