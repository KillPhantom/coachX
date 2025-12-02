# Media Upload Implementation - Complete Architecture

**版本**: 4.0
**更新日期**: 2025-11-30
**作者**: Claude Code
**状态**: ✅ 已完成 - 后台上传架构 + 通用组件
**关联功能**: 训练媒体上传（图片 + 视频）+ 动作库媒体上传

---

## 📋 目录

1. [版本历史](#版本历史)
2. [功能概述](#功能概述)
3. [核心架构](#核心架构)
4. [数据流图](#数据流图)
5. [核心组件](#核心组件)
6. [实施状态](#实施状态)
7. [测试指南](#测试指南)
8. [参考资料](#参考资料)

---

## 版本历史

### v1.0 - 基础上传 (2025-11)
- ✅ 相机录制 + 相册选择
- ✅ 视频时长验证（≤60秒）
- ✅ 自动压缩（≥50MB）
- ✅ 上传到 Firebase Storage
- ✅ 自动保存到 Firestore

### v2.0 - 进度显示 (2025-11)
- ✅ 异步非阻塞上传
- ✅ 实时进度显示（0-100%）
- ✅ 本地缩略图预览
- ✅ 上传失败重试机制
- ✅ 状态管理（pending → uploading → completed/error）

### v3.0 - 通用组件 (2025-11-15)
- ✅ 抽取为可复用组件（`VideoUploadSection`）
- ✅ 支持多场景（学生训练、教练动作库）
- ✅ 自管理状态，父组件只需处理回调
- ✅ 灵活配置（路径、数量、时长、视频源）

### v4.0 - 后台上传架构 (2025-11-30 - 当前版本)
- ✅ **核心问题解决**：切换页面时上传不中断
- ✅ **架构重构**：
  - 上传逻辑从 UI 层提升到应用层（Notifier）
  - 新增 `MediaUploadManager` 统一管理所有上传任务
  - 订阅持久化，不受 widget 生命周期影响
  - 通过 Stream 实时同步进度到 UI
- ✅ **进度优化**：
  - 压缩进度显示（0-60%）
  - 上传进度显示（60-100%）
  - 状态新增 `compressing`
- ✅ **状态同步**：
  - `MediaUploadSection` 通过 `didUpdateWidget` 同步 Riverpod state
  - 双向数据流：Notifier ↔ UI
- ✅ **支持图片 + 视频**：重命名为 `MediaUploadSection`（通用媒体上传）

---

## 功能概述

### 核心功能

**媒体类型**:
- ✅ 图片（jpg, png）
- ✅ 视频（mp4, mov）

**选择方式**:
- 📷 相机拍照/录制
- 🖼️ 相册选择（多选）

**自动处理**:
- 🗜️ 视频自动压缩（≥50MB）
- 🖼️ 自动生成缩略图
- 📊 实时进度显示（压缩 + 上传）
- 💾 自动上传到 Firebase Storage
- 🔄 自动保存到 Firestore

**用户体验**:
- ⚡ 非阻塞上传（后台异步）
- 🔄 切换页面不中断上传
- 📊 实时进度反馈
- ⚠️ 错误处理 + 重试机制
- 🎯 支持多文件并发上传

---

### 用户体验对比

**v3.0 之前**：
```
用户选择媒体
    ↓
[等待] 验证 + 压缩...（UI 阻塞）
    ↓
[等待] 上传中...（UI 阻塞）
    ↓
❌ 切换页面时上传中断
```

**v4.0 当前**：
```
用户选择媒体
    ↓
立即显示占位符 ⚡
    ↓
用户可继续操作（切换页面、编辑数据）✅
    ↓
后台异步上传，实时更新进度 📊
    ├─ 压缩进度：0-60%
    └─ 上传进度：60-100%
    ↓
✅ 切换页面不中断上传
    ↓
上传完成自动保存 🔔
```

---

## 核心架构

### 系统架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                         Presentation Layer                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  ExerciseRecordPage                                       │   │
│  │    └─ PageView                                            │   │
│  │        └─ ExerciseRecordCard (per exercise)              │   │
│  │            └─ MediaUploadSection (通用组件)              │   │
│  │                ├─ MediaThumbnailCard (completed)         │   │
│  │                ├─ MediaThumbnailCard (uploading)         │   │
│  │                │   └─ Stack                               │   │
│  │                │       ├─ Thumbnail (local/network)      │   │
│  │                │       ├─ Progress Overlay               │   │
│  │                │       │   └─ CircularProgressIndicator  │   │
│  │                │       └─ Error/Retry Overlay            │   │
│  │                └─ VideoPlaceholderCard (add new)        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                ↕ (通过回调通信)
┌─────────────────────────────────────────────────────────────────┐
│                         Business Logic Layer                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  ExerciseRecordNotifier (StateNotifier)                  │   │
│  │                                                            │   │
│  │  State: ExerciseRecordState                               │   │
│  │    └─ exercises: List<StudentExerciseModel>              │   │
│  │        └─ media: List<MediaUploadState>                  │   │
│  │                                                            │   │
│  │  Methods:                                                  │   │
│  │    ├─ addPendingMedia(exerciseIndex, localPath, type)    │   │
│  │    │   1. 添加到 state (pending)                          │   │
│  │    │   2. MediaUploadManager.startUpload(taskId) ← 核心   │   │
│  │    │                                                       │   │
│  │    ├─ _listenToUploadProgress()                          │   │
│  │    │   └─ 订阅 MediaUploadManager.progressStream         │   │
│  │    │                                                       │   │
│  │    └─ _handleUploadProgress(UploadProgress)              │   │
│  │        ├─ 更新 state.exercises[i].media[j]               │   │
│  │        └─ 完成时 saveRecord()                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                ↕                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  MediaUploadManager (核心上传管理器) 🆕                   │   │
│  │                                                            │   │
│  │  内部状态:                                                 │   │
│  │    ├─ _tasks: Map<String, _UploadTask>                   │   │
│  │    └─ _progressController: StreamController              │   │
│  │                                                            │   │
│  │  Methods:                                                  │   │
│  │    ├─ startUpload(taskId, file, type, storagePath)       │   │
│  │    │   1. 生成缩略图（仅视频）                             │   │
│  │    │   2. 验证视频时长                                     │   │
│  │    │   3. 条件压缩（≥50MB）                               │   │
│  │    │   4. 上传主文件                                       │   │
│  │    │   5. 上传缩略图（仅视频）                             │   │
│  │    │   6. 发送完成事件                                     │   │
│  │    │                                                       │   │
│  │    ├─ cancelTask(taskId)                                  │   │
│  │    └─ dispose()                                           │   │
│  │                                                            │   │
│  │  Output:                                                   │   │
│  │    └─ progressStream: Stream<UploadProgress>             │   │
│  │        └─ 持续发送进度事件                                 │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                ↕
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  MediaUploadService                                       │   │
│  │    ├─ uploadFileWithProgress(file, path) → Stream<double>│   │
│  │    ├─ uploadThumbnail(file, path) → Future<String>       │   │
│  │    └─ getDownloadUrl(path) → Future<String>              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                ↕                                 │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  VideoService (视频处理)                                   │   │
│  │    ├─ shouldCompress(file, threshold) → Future<bool>     │   │
│  │    ├─ compressVideo(file) → Stream<CompressProgress>     │   │
│  │    └─ cancelCompression() → Future<void>                 │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                ↕
┌─────────────────────────────────────────────────────────────────┐
│                         External Services                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Firebase Storage                                          │   │
│  │    └─ students/trainings/{userId}/{timestamp}.(mp4|jpg)  │   │
│  │                                                            │   │
│  │  Firestore                                                 │   │
│  │    └─ dailyTrainings/{userId}/{date}                     │   │
│  │        └─ exercises[].media[] (download URLs)            │   │
│  │                                                            │   │
│  │  ImagePicker (System)                                      │   │
│  │    ├─ pickVideo(source: camera)                           │   │
│  │    ├─ pickImage(source: camera)                           │   │
│  │    └─ pickMultipleMedia()                                 │   │
│  │                                                            │   │
│  │  VideoCompress                                             │   │
│  │    └─ compressVideo(path, quality: Medium)               │   │
│  │        └─ compressProgress$ (Stream)                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 数据流图

### 1. 完整上传流程（v4.0）

```
┌─────────────────────────────────────────────────────────────────┐
│ Phase 1: 媒体选择（MediaUploadSection）                          │
└─────────────────────────────────────────────────────────────────┘

用户点击 "添加"
    ↓
显示 CupertinoActionSheet
    ├─ [录制视频] → ImagePicker.pickVideo(source: camera)
    ├─ [从相册选择] → ImagePicker.pickMultipleMedia()
    └─ [拍照] → ImagePicker.pickImage(source: camera)
    ↓
返回 File(s)
    ↓
_processAndUploadMedia(file, type)
    ↓
widget.onMediaSelected(file, type) ← 只通知父组件，不启动上传


┌─────────────────────────────────────────────────────────────────┐
│ Phase 2: 添加媒体并启动上传（ExerciseRecordNotifier）             │
└─────────────────────────────────────────────────────────────────┘

onMediaSelected 回调
    ↓
ExerciseRecordNotifier.addPendingMedia(exerciseIndex, localPath, type)
    ↓
1. 添加到 Riverpod state
    exercise.addPendingMedia(localPath, type, thumbnailPath: null)
    → state.exercises[exerciseIndex].media 新增 MediaUploadState.pending
    ↓
2. 立即启动后台上传（关键！）
    taskId = "{exerciseIndex}_{mediaIndex}"
    storagePath = "students/trainings/{userId}/{timestamp}.(mp4|jpg)"
    ↓
    MediaUploadManager.startUpload(
        file: File(localPath),
        type: type,
        storagePath: storagePath,
        taskId: taskId,
        maxVideoSeconds: 60,
        compressionThresholdMB: 50,
    )
    ↓
    返回（UI 解除阻塞）✅


┌─────────────────────────────────────────────────────────────────┐
│ Phase 3: 后台上传流程（MediaUploadManager）                       │
└─────────────────────────────────────────────────────────────────┘

MediaUploadManager._executeUpload(task)
    ↓
if (type == MediaType.video) {
    ↓
    1. 生成缩略图（本地）
        thumbnailFile ← VideoUtils.generateThumbnail(file.path)
        → 发送事件: UploadProgress(status: pending, thumbnailPath: path)
        ↓
    2. 验证视频时长
        isValid ← VideoUtils.validateVideoFile(file, maxSeconds: 60)
        ├─ ✅ ≤60秒 → 继续
        └─ ❌ >60秒 → 发送错误事件，中止
        ↓
    3. 条件压缩（可选）
        shouldCompress ← VideoService.shouldCompress(file, threshold: 50MB)
        ↓
        if (shouldCompress) {
            VideoService.compressVideo(file) → Stream<CompressProgress>
            ↓
            监听压缩进度:
            subscription.listen((compressProgress) {
                displayProgress = compressProgress.progress * 0.6  // 映射到 0-60%
                → 发送事件: UploadProgress(status: compressing, progress: 0.X)
            })
            ↓
            压缩完成 → 使用压缩后的文件
        }
}
    ↓
4. 上传主文件
    uploadService.uploadFileWithProgress(file, path) → Stream<double>
    ↓
    监听上传进度:
    subscription.listen((progress) {
        baseProgress = compressedFile != null ? 0.6 : 0.0
        range = compressedFile != null ? 0.4 : 1.0
        displayProgress = baseProgress + (progress * range)  // 映射到 60-100% 或 0-100%
        → 发送事件: UploadProgress(status: uploading, progress: X)
    })
    ↓
    onDone: {
        downloadUrl ← uploadService.getDownloadUrl(path)
        ↓
        if (type == MediaType.video && thumbnailPath != null) {
            5. 上传缩略图
            thumbPath = path.replace('.mp4', '_thumb.jpg')
            thumbnailUrl ← uploadService.uploadThumbnail(File(thumbnailPath), thumbPath)
        }
        ↓
        6. 发送完成事件
        → UploadProgress(
            status: completed,
            progress: 1.0,
            downloadUrl: downloadUrl,
            thumbnailUrl: thumbnailUrl,
        )
    }


┌─────────────────────────────────────────────────────────────────┐
│ Phase 4: 进度同步（ExerciseRecordNotifier）                       │
└─────────────────────────────────────────────────────────────────┘

MediaUploadManager.progressStream
    ↓
ExerciseRecordNotifier._uploadProgressSubscription.listen((progress) {
    ↓
    _handleUploadProgress(progress)
        ↓
        解析 taskId: "{exerciseIndex}_{mediaIndex}"
        ↓
        更新 state.exercises[exerciseIndex].media[mediaIndex]:
            - status: progress.status
            - progress: progress.progress
            - downloadUrl: progress.downloadUrl
            - thumbnailUrl: progress.thumbnailUrl
            - thumbnailPath: progress.thumbnailPath
        ↓
        if (progress.status == MediaUploadStatus.completed) {
            saveRecord() → 保存到 Firestore ✅
        }
})


┌─────────────────────────────────────────────────────────────────┐
│ Phase 5: UI 状态同步（MediaUploadSection）                        │
└─────────────────────────────────────────────────────────────────┘

didUpdateWidget(MediaUploadSection oldWidget)
    ↓
if (widget.initialMedia != oldWidget.initialMedia) {
    _syncMediaFromProps()
        ↓
        setState(() {
            _mediaList.clear()
            _mediaList.addAll(widget.initialMedia!)
        })
        ↓
        UI 自动刷新，显示最新状态 🔄
}
```

---

### 2. 关键特性

#### 2.1 后台上传（不受 UI 生命周期影响）

```
用户在 Exercise 1 上传视频（进度 20%）
    ↓
切换到 Exercise 2（PageView 滑动）
    ↓
Exercise 1 的 MediaUploadSection 被销毁（dispose）
    ↓
✅ 上传继续！（由 MediaUploadManager 管理）
    ↓
上传进度更新 → Notifier state 更新
    ↓
返回 Exercise 1（PageView 滑动回来）
    ↓
MediaUploadSection 重建（initState）
    ↓
didUpdateWidget 检测到 initialMedia 变化
    ↓
_syncMediaFromProps() 同步最新状态
    ↓
✅ 显示正确的进度（例如 75%）
```

#### 2.2 进度映射

```dart
// 有压缩阶段（视频 ≥50MB）
compressProgress: 0.0 → 0.6  (原始: 0.0 → 1.0)
uploadProgress:   0.6 → 1.0  (原始: 0.0 → 1.0)

// 无压缩阶段（小视频或图片）
uploadProgress:   0.0 → 1.0  (原始: 0.0 → 1.0)
```

---

## 核心组件

### 1. MediaUploadManager

**文件**: `lib/core/services/media_upload_manager.dart`

**职责**:
- 管理所有媒体上传任务（视频 + 图片）
- 与 UI 生命周期解耦
- 通过 Stream 发送进度事件

**核心方法**:
```dart
class MediaUploadManager {
  /// 启动上传任务
  Future<void> startUpload({
    required File file,
    required MediaType type,
    required String storagePath,
    required String taskId,  // 格式: "exerciseIndex_mediaIndex"
    int? maxVideoSeconds,
    int? compressionThresholdMB,
  });

  /// 取消任务
  void cancelTask(String taskId);

  /// 进度事件流
  Stream<UploadProgress> get progressStream;

  /// 清理所有任务
  void dispose();
}
```

**内部流程**:
1. 生成缩略图（仅视频）
2. 验证视频时长
3. 条件压缩（>50MB 的视频）
4. 上传主文件
5. 上传缩略图（仅视频）
6. 发送完成事件

---

### 2. MediaUploadSection

**文件**: `lib/core/widgets/media_upload_section.dart`

**职责**:
- 通用媒体上传 UI 组件
- 支持图片 + 视频
- 自管理本地显示状态
- 通过 `didUpdateWidget` 同步 Riverpod state

**核心特性**:
```dart
class MediaUploadSection extends ConsumerStatefulWidget {
  /// Storage 路径前缀
  final String storagePathPrefix;

  /// 最大媒体数量
  final int maxCount;

  /// 最大视频时长（秒）
  final int maxVideoSeconds;

  /// 视频压缩阈值（MB）
  final int videoCompressionThresholdMB;

  /// 初始媒体状态列表（来自 Riverpod state）
  final List<MediaUploadState>? initialMedia;

  /// 回调
  final void Function(int index, File file, MediaType type)? onMediaSelected;
  final void Function(int index, double progress)? onUploadProgress;
  final void Function(int index, String url, String? thumbnailUrl, MediaType type)? onUploadCompleted;
  final void Function(int index, String error)? onUploadFailed;
  final void Function(int index)? onMediaDeleted;
}
```

**关键实现**:
```dart
// v4.0 简化后的逻辑
Future<void> _processAndUploadMedia(File file, MediaType type) async {
  // 只通知父组件，由父组件（Notifier）负责添加到状态并启动上传
  // MediaUploadManager 会处理缩略图生成、验证、压缩和上传
  widget.onMediaSelected?.call(_mediaList.length, file, type);
}

// 状态同步
@override
void didUpdateWidget(MediaUploadSection oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.initialMedia != oldWidget.initialMedia) {
    _syncMediaFromProps();
  }
}

void _syncMediaFromProps() {
  setState(() {
    _mediaList.clear();
    if (widget.initialMedia != null) {
      _mediaList.addAll(widget.initialMedia!);
    }
  });
}
```

---

### 3. MediaUploadState

**文件**: `lib/core/models/media_upload_state.dart`

**状态枚举**:
```dart
enum MediaUploadStatus {
  pending,      // 等待处理
  compressing,  // 压缩中（仅视频）
  uploading,    // 上传中
  completed,    // 已完成
  error,        // 上传失败
}

enum MediaType {
  image,
  video,
}
```

**数据模型**:
```dart
class MediaUploadState {
  final String? localPath;        // 本地文件路径
  final String? thumbnailPath;    // 本地缩略图路径
  final String? downloadUrl;      // Firebase Storage URL
  final String? thumbnailUrl;     // 缩略图 URL
  final MediaType type;           // 媒体类型
  final MediaUploadStatus status; // 上传状态
  final double progress;          // 上传进度 (0.0 - 1.0)
  final String? error;            // 错误信息

  // Factory constructors
  factory MediaUploadState.pending(String localPath, MediaType type, {String? thumbnailPath});
  factory MediaUploadState.completed(String downloadUrl, MediaType type, {String? thumbnailUrl});

  // JSON 序列化（只保存已完成的媒体）
  Map<String, dynamic>? toJson() => status == MediaUploadStatus.completed
    ? {
        'type': type == MediaType.video ? 'video' : 'image',
        'downloadUrl': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
      }
    : null;
}
```

---

### 4. UploadProgress

**文件**: `lib/core/services/media_upload_manager.dart`

**进度事件模型**:
```dart
class UploadProgress {
  final String taskId;              // 任务ID (格式: "exerciseIndex_mediaIndex")
  final double progress;            // 进度 (0.0-1.0)
  final MediaUploadStatus status;   // pending/compressing/uploading/completed/error
  final String? error;              // 错误信息
  final String? downloadUrl;        // 完成时的下载URL
  final String? thumbnailUrl;       // 缩略图URL
  final String? thumbnailPath;      // 本地缩略图路径

  const UploadProgress({
    required this.taskId,
    this.progress = 0.0,
    required this.status,
    this.error,
    this.downloadUrl,
    this.thumbnailUrl,
    this.thumbnailPath,
  });
}
```

---

## 实施状态

### ✅ 已完成 (18/18)

#### 核心架构层
1. ✅ 创建 `MediaUploadManager` 管理所有上传任务
2. ✅ 创建 `UploadProgress` 事件模型
3. ✅ 集成到 `ExerciseRecordNotifier`（添加订阅和处理逻辑）
4. ✅ 创建 `mediaUploadManagerProvider` (Riverpod)

#### 数据模型层
5. ✅ 更新 `MediaUploadStatus` 枚举（新增 `compressing`）
6. ✅ `VideoService.compressVideo()` 改为返回 `Stream<CompressProgress>`
7. ✅ `StudentExerciseModel` 添加媒体管理方法

#### UI 层优化
8. ✅ 移除 `MediaUploadSection` 的旧上传逻辑
9. ✅ 删除 `_compressAndUploadVideo` 方法
10. ✅ 简化 `_processAndUploadMedia` 方法（只通知父组件）
11. ✅ 添加 `didUpdateWidget` 方法（状态同步）
12. ✅ 添加 `_syncMediaFromProps` 方法
13. ✅ 简化 `_cancelAllUploads` 方法
14. ✅ 修改 `_handleMediaRetry` 方法（通过回调）
15. ✅ 修改 `_handleMediaDelete` 方法
16. ✅ 移除未使用的导入和字段

#### 注释和文档
17. ✅ 更新 `ExerciseRecordCard` 和 `exercise_record_page` 的注释
18. ✅ 运行 `flutter analyze` 确保无编译错误

---

### 📁 文件变更列表

**新增文件 (1)**:
- `lib/core/services/media_upload_manager.dart` - 后台上传管理器

**修改文件 (7)**:
- `lib/core/services/video_service.dart` - 压缩进度 Stream
- `lib/core/models/media_upload_state.dart` - 新增 `compressing` 状态
- `lib/core/providers/media_upload_providers.dart` - 新增 `mediaUploadManagerProvider`
- `lib/core/widgets/media_upload_section.dart` - UI 层简化
- `lib/core/widgets/media_thumbnail_card.dart` - 支持 `compressing` 状态
- `lib/features/student/training/presentation/providers/exercise_record_notifier.dart` - 集成 MediaUploadManager
- `lib/features/student/training/presentation/providers/exercise_record_providers.dart` - 注入 MediaUploadManager

---

## 测试指南

### 功能测试清单

#### 基本上传流程
- [x] **选择视频后立即开始上传**
- [x] **进度条显示 0-60%（压缩阶段）**
- [x] **进度条显示 60-100%（上传阶段）**
- [x] **完成后显示缩略图和播放按钮**

#### 切换页面（核心功能验证）
- [x] **在 Exercise 1 开始上传视频（20%进度）**
- [x] **切换到 Exercise 2**
- [x] **切换回 Exercise 1**
- [x] **验证：进度继续显示，上传未中断**
- [x] **等待完成，验证上传成功**

#### 并发上传
- [ ] 在 Exercise 1 上传 3 个视频
- [ ] 在 Exercise 2 上传 2 个视频
- [ ] 切换页面
- [ ] 验证所有上传都在后台进行

#### 删除功能
- [ ] 上传中删除媒体
- [ ] 验证任务被取消
- [ ] 验证 state 更新
- [ ] 验证 Firestore 同步

#### 重试功能
- [ ] 上传失败后点击重试
- [ ] 验证重新上传
- [ ] 验证成功后状态更新

#### 错误处理
- [ ] 上传超大视频（>1GB）
- [ ] 上传超长视频（>60秒）
- [ ] 网络断开时上传
- [ ] 验证错误状态显示

#### 应用生命周期
- [ ] 上传中切换到后台
- [ ] 返回前台
- [ ] 验证上传继续（或恢复）

---

### 验证点

#### 日志检查
```bash
# 查看上传相关日志
flutter logs 2>&1 | grep -E "(MediaUploadManager|上传|Upload|压缩|Compress)"

# 监控进度更新
flutter logs 2>&1 | grep "上传进度更新"

# 监控错误
flutter logs 2>&1 | grep -E "(error|Error|失败|❌)"
```

**预期日志**:
```
[MediaUploadManager] 启动上传任务: 0_0
[MediaUploadManager] 生成缩略图: 0_0
[MediaUploadManager] 开始压缩视频: 0_0
[MediaUploadManager] 压缩完成: 0_0
[MediaUploadManager] 开始上传文件: 0_0
[ExerciseRecordNotifier] 上传进度更新: 0_0 - 65% (uploading)
[ExerciseRecordNotifier] 媒体上传完成，保存记录: 0_0
```

#### 状态验证
```dart
// 检查只有一个压缩订阅
// 不应该看到 "Bad state: Stream has already been listened to"
```

---

## 参考资料

### 官方文档
- [image_picker | pub.dev](https://pub.dev/packages/image_picker)
- [video_compress | pub.dev](https://pub.dev/packages/video_compress)
- [Firebase Storage | Flutter](https://firebase.google.com/docs/storage/flutter/upload-files)
- [Firebase Storage - Monitor Upload Progress](https://firebase.google.com/docs/storage/flutter/upload-files#monitor_upload_progress)

### 相关文档
- [Exercise Record Page 架构](./student/exercise_record_page_architecture.md)
- [Backend APIs and DB Schemas](./backend_apis_and_document_db_schemas.md)
- [JSON Parsing Fix](./json_parsing_fix.md)

### 代码规范
- [CLAUDE.md](../CLAUDE.md) - 项目编码规范
- [Features Implementation Rules](../lib/features/CLAUDE.md) - 功能实现规范

---

## 技术约束

### 配置常量

```dart
// lib/core/constants/app_constants.dart
class AppConstants {
  /// 视频时长限制（秒）
  static const int maxVideoSeconds = 60;

  /// 视频压缩阈值（MB）
  static const int videoCompressionThresholdMB = 50;

  /// 每个动作最多上传媒体数量
  static const int maxMediaPerExercise = 3;
}
```

### Firebase Storage 安全规则

**路径**: `storage.rules`

```javascript
// 学生训练媒体（图片 + 视频 + 缩略图）
match /students/trainings/{userId}/{fileName} {
  // 允许学生本人上传
  allow write: if isOwner(userId) && (isValidVideo() || isValidImage());
  // 允许任何已认证用户读取
  allow read: if isAuthenticated();
}

// 验证函数
function isValidVideo() {
  return request.resource.contentType.matches('video/.*');
}

function isValidImage() {
  return request.resource.contentType.matches('image/.*')
      && request.resource.size < 10 * 1024 * 1024; // 图片最大 10MB
}
```

### 压缩参数

**当前配置**: `VideoQuality.MediumQuality`

**压缩效果**:
- 1080p 60秒视频: ~100MB → ~25MB (75% 压缩)
- 720p 60秒视频: ~50MB → ~15MB (70% 压缩)

---

## 未来扩展建议

### 1. 优化建议

**短期**:
- [ ] 实现 `deleteMedia` 功能（包含取消上传任务）
- [ ] 添加网络状态检测（WiFi/4G 提示）
- [ ] 支持上传队列优先级

**中期**:
- [ ] 支持断点续传
- [ ] 支持后台上传（iOS Background Upload）
- [ ] 添加上传速度限制（避免占用所有带宽）

**长期**:
- [ ] 云端压缩（Cloud Functions）
- [ ] 多视频批量上传
- [ ] P2P 加速上传

### 2. 性能优化

- [ ] 缩略图缓存策略优化
- [ ] 大文件分片上传
- [ ] 上传失败自动重试（指数退避）

---

**文档维护**: 此文档应随代码更新保持同步。如有实现变更，请及时更新相应章节。

**贡献者**: Claude Code
**最后更新**: 2025-11-30
**当前版本**: v4.0 - 后台上传架构
