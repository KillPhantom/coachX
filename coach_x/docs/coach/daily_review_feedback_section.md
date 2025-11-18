# Daily Review Feedback Section - Architecture Documentation

**Feature**: Read-Only Feedback Preview + Bottom Sheet Input (只读反馈预览 + Bottom Sheet 输入)
**Components**: `ReadOnlyFeedbackSection` + `FeedbackBottomSheet` + `ExerciseFeedbackHistorySection` + `FeedbackInputBar`
**Last Updated**: 2025-11-16

---

## Overview

教练训练审核页面的反馈功能，采用"只读预览 + 独立输入界面"的设计模式。用户可以在主页面查看最近的反馈记录，点击"添加反馈"按钮弹出 Bottom Sheet 进行完整的反馈操作。

### Key Features

- ✅ **只读预览区域**：在 video section 下方显示最近 10 条反馈（动态高度）
- ✅ **独立输入界面**：通过 Bottom Sheet 提供完整的反馈功能（历史 + 输入）
- ✅ **动作关联**：自动关联当前选中的 exercise
- ✅ **多种输入方式**：支持文字、语音、图片三种反馈类型
- ✅ **分页加载**：Bottom Sheet 中支持加载更多历史反馈

---

## Architecture

### Component Hierarchy

```
DailyTrainingReviewPage (CupertinoPageScaffold)
└─ SafeArea
   └─ _PageContent (CustomScrollView) ← 可滚动主内容
      ├─ SliverToBoxAdapter: _TrainingSummaryCard
      ├─ SliverToBoxAdapter: _ExerciseVideoSection
      └─ SliverToBoxAdapter: ReadOnlyFeedbackSection ← 新增
          ├─ 标题栏 + "添加反馈"按钮
          └─ 反馈列表（最近 10 条，动态高度）

当用户点击"添加反馈"按钮:
FeedbackBottomSheet (Modal Popup)
├─ Handle bar (拖动指示器)
├─ 标题栏 (Exercise 名称 + 关闭按钮)
├─ ExerciseFeedbackHistorySection (可滚动，支持分页)
│   └─ showHeader: false (隐藏内部标题)
└─ FeedbackInputBar (固定在底部)
    └─ 接收 exerciseIndex + exerciseName (固定关联)
```

### File Structure

```
lib/features/chat/presentation/
├── pages/
│   └── daily_training_review_page.dart
│       ├─ _PageContent (修改：添加 ReadOnlyFeedbackSection)
│       └─ _showFeedbackBottomSheet() (新增)
├── widgets/
│   ├── read_only_feedback_section.dart (新增)
│   │   └─ 只读反馈预览，最近 10 条
│   ├── feedback_bottom_sheet.dart (新增)
│   │   └─ 完整反馈界面（历史 + 输入）
│   ├── exercise_feedback_history_section.dart (修改)
│   │   ├─ showHeader: bool (控制是否显示内部标题)
│   │   └─ showLoadMoreButton: bool (控制是否显示"加载更多")
│   └── feedback_input_bar.dart (修改)
│       ├─ exerciseName?: String (可选，固定关联 exercise)
│       └─ exerciseIndex?: int (可选，固定关联 exercise)
└── providers/
    └── daily_training_review_providers.dart
        ├─ selectedExerciseIndexProvider
        └─ exerciseFeedbackHistoryProvider
```

---

## User Flow

### 主流程：查看和添加反馈

```
1. 进入训练审核页面
   ↓
2. 查看训练总结和视频
   ↓
3. 在 video section 下方看到"最近反馈"预览区域
   ├─ 有反馈：显示最近 10 条（紧凑卡片）
   └─ 无反馈：显示紧凑空状态（"暂无反馈"）
   ↓
4. 点击"添加反馈"按钮
   ↓
5. 弹出 Bottom Sheet
   ├─ 顶部：Exercise 名称 (Squat - 反馈历史)
   ├─ 中间：完整反馈历史（可滚动，支持分页）
   └─ 底部：反馈输入栏（文字/语音/图片）
   ↓
6. 输入反馈并发送
   ↓
7. 反馈保存到 Firestore
   ↓
8. UI 自动刷新（Stream Provider）
```

### Exercise 切换行为

```
用户切换 Exercise Tab
   ↓
selectedExerciseIndexProvider 更新
   ↓
ReadOnlyFeedbackSection 自动重新构建
   └─ 显示新 exercise 的反馈
   ↓
如果 Bottom Sheet 已打开
   └─ 保持打开，显示原 exercise 的反馈（标题栏明确标注）
```

---

## Layout Structure

### Visual Layout - Main Page

```
┌─────────────────────────────────────────┐
│  CupertinoNavigationBar                  │
├─────────────────────────────────────────┤
│ ┌─ CustomScrollView (Scrollable) ─────┐│
│ │                                      ││
│ │ 📊 Training Summary Card            ││
│ │ ┌────────────────────────────────┐  ││
│ │ │ Today Summary | Details        │  ││
│ │ │ 3 exercises, 100% done         │  ││
│ │ └────────────────────────────────┘  ││
│ │                                      ││
│ │ 🎥 Exercise Video Section           ││
│ │ ┌────────────────────────────────┐  ││
│ │ │ [Squat✓] [Bench] [Deadlift]   │  ││
│ │ │ ┌──────┬────────┐              │  ││
│ │ │ │Video │Keyframe│              │  ││
│ │ │ └──────┴────────┘              │  ││
│ │ └────────────────────────────────┘  ││
│ │                                      ││
│ │ 💬 最近反馈     [添加反馈] ← 新增  ││
│ │ ┌────────────────────────────────┐  ││
│ │ │ 📅 2025-11-16 | 2h ago        │  ││ ← 动态高度
│ │ │ "Great depth on squats!"      │  ││   最多 350px
│ │ │ ───────────────────────────── │  ││   空状态时紧凑
│ │ │ 📅 2025-11-15 | 1d ago        │  ││
│ │ │ [🎵 Voice 15s]                │  ││
│ │ └────────────────────────────────┘  ││
│ │                                      ││
│ └──────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### Visual Layout - Bottom Sheet

```
┌─────────────────────────────────────────┐
│         [拖动 handle bar]                │
│ Squat - 反馈历史                  [X]   │ ← 标题栏
├─────────────────────────────────────────┤
│ ┌─ 反馈历史（可滚动）──────────────────┐ │
│ │ 📅 2025-11-16 | 2h ago             │ │
│ │ "Great depth on squats!"           │ │
│ │ ─────────────────────────────────  │ │
│ │ 📅 2025-11-15 | 1d ago             │ │
│ │ [🎵 Voice 15s]                     │ │
│ │ ─────────────────────────────────  │ │
│ │ [加载更多]                          │ │
│ └───────────────────────────────────── │
├─────────────────────────────────────────┤
│ [🎤] [_______________] [📷] [⬆]        │ ← 输入栏
└─────────────────────────────────────────┘
```

---

## Data Flow

### 查看反馈历史

```
用户进入页面
   ↓
ReadOnlyFeedbackSection.build()
   ↓
watch(exerciseFeedbackHistoryProvider(params))
   ├─ params: { studentId, exerciseName }
   └─ 查询 Firestore (限制 10 条)
   ↓
Firestore Stream 返回数据
   ↓
UI 渲染最近 10 条反馈
```

### 添加反馈

```
用户点击"添加反馈"
   ↓
_showFeedbackBottomSheet(exerciseIndex, exerciseName)
   ↓
FeedbackBottomSheet.show()
   └─ 传递固定的 exerciseIndex + exerciseName
   ↓
用户输入反馈（文字/语音/图片）
   ↓
FeedbackInputBar._handleSend()
   ├─ 使用传入的 exerciseIndex/exerciseName (优先)
   └─ 或从 selectedExerciseIndexProvider 读取 (兼容)
   ↓
FeedbackRepository.addFeedback()
   ├─ 上传媒体文件（如需要）
   └─ 保存到 Firestore: dailyTrainingFeedback
   ↓
exerciseFeedbackHistoryProvider Stream 自动更新
   ↓
UI 自动刷新（ReadOnlyFeedbackSection + Bottom Sheet）
```

---

## Key Components

### 1. ReadOnlyFeedbackSection

**Purpose**: 只读反馈预览，显示最近 10 条反馈

**Parameters**:
- `studentId`: String - 学生ID
- `exerciseName`: String - 动作名称
- `onAddFeedbackTap`: VoidCallback - "添加反馈"按钮回调

**Features**:
- 动态高度（有反馈时最大 350px，空状态时紧凑）
- 只读模式，不支持输入
- 点击"添加反馈"按钮弹出 Bottom Sheet

---

### 2. FeedbackBottomSheet

**Purpose**: 完整的反馈界面（历史 + 输入）

**Parameters**:
- `dailyTrainingId`: String
- `studentId`: String
- `exerciseIndex`: int - 固定关联的 exercise 索引
- `exerciseName`: String - 固定关联的 exercise 名称

**Features**:
- 使用 `DraggableScrollableSheet`，支持拖动调整高度
- 初始高度 70% 屏幕，范围 50%-95%
- 顶部标题栏显示 exercise 名称
- 内部不显示重复标题（`showHeader: false`）

---

### 3. ExerciseFeedbackHistorySection (Modified)

**New Parameters**:
- `showHeader`: bool (默认 true) - 控制是否显示内部标题
- `showLoadMoreButton`: bool (默认 true) - 控制是否显示"加载更多"按钮

**Usage**:
- 在 ReadOnlyFeedbackSection 中：`showHeader: true`, `showLoadMoreButton: false`
- 在 FeedbackBottomSheet 中：`showHeader: false`, `showLoadMoreButton: true`

---

### 4. FeedbackInputBar (Modified)

**New Parameters**:
- `exerciseName`: String? (可选) - 固定关联的 exercise 名称
- `exerciseIndex`: int? (可选) - 固定关联的 exercise 索引

**Logic**:
```dart
if (widget.exerciseIndex != null && widget.exerciseName != null) {
  // 使用传入的固定值（Bottom Sheet 场景）
  selectedExerciseIndex = widget.exerciseIndex!;
  exerciseName = widget.exerciseName;
} else {
  // 从 provider 读取（原有场景）
  selectedExerciseIndex = ref.read(selectedExerciseIndexProvider);
  exerciseName = exercises[selectedExerciseIndex].name;
}
```

**Why**: 解决 Bottom Sheet 中 provider 无法正确同步的问题

---

## Design Decisions

### 为什么从"固定底部"改为"Bottom Sheet"？

**之前的问题**：
- ❌ 固定底部占用大量垂直空间（~300px）
- ❌ 压缩主内容的可视区域
- ❌ 反馈历史和输入栏始终可见，即使用户不需要

**现在的优势**：
- ✅ 只读预览区域动态高度（空状态时仅 ~52px）
- ✅ 主内容可视区域更大
- ✅ 完整反馈功能按需显示（Bottom Sheet）
- ✅ 更符合移动端的交互习惯

### 为什么 ReadOnlyFeedbackSection 使用动态高度？

**目标**: 最大化主内容的可视空间

**实现**:
- 有反馈：`ConstrainedBox(maxHeight: 350)` + `ListView.builder`
- 空状态：紧凑的水平布局（图标 + 文字），无 ConstrainedBox

**效果**: 从固定 350px 压缩到 52px（空状态），节省 ~300px 垂直空间

### 为什么 FeedbackInputBar 需要可选参数？

**问题**: Bottom Sheet 中 `selectedExerciseIndexProvider` 无法正确工作
- Bottom Sheet 是独立的 modal 上下文
- 主页面切换 exercise 时，Bottom Sheet 不更新

**解决方案**: 添加可选参数 `exerciseIndex` 和 `exerciseName`
- Bottom Sheet 传入固定值（弹出时的 exercise）
- 原有场景从 provider 读取（兼容性）

---

## Error Handling

| 错误场景 | 处理方式 |
|---------|---------|
| 反馈历史加载失败 | 显示错误状态，提供重试选项 |
| 反馈发送失败 | 显示错误弹窗，保留用户输入 |
| 媒体上传失败 | 显示错误提示，允许重试 |
| Exercise 索引越界 | 降级为只显示输入栏 |
| 网络超时 | 显示超时提示，允许重试 |

---

## Related Documentation

- **Backend APIs**: `/docs/backend_apis_and_document_db_schemas.md`
- **Training Review Implementation**: `/docs/coach/daily_training_review_page_implementation.md`
- **Project Guidelines**: `/CLAUDE.md`

---

**Last Updated**: 2025-11-16
