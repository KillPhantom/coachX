# 本地关键帧提取 - 技术文档

**最后更新**: 2025-11-16
**状态**: ✅ 已实现并优化
**版本**: 2.0

---

## 📋 概述

### 目标
将训练视频关键帧提取从Backend (Python Cloud Functions)迁移到Frontend (Flutter教练端本地处理)。

### 优势
- ✅ **成本降低**: 免费（原~$126/月）
- ✅ **速度提升**: <30秒（原10-20秒，且无Cloud Function冷启动）
- ✅ **用户体验**: 实时进度反馈，无server glitch
- ✅ **数据隐私**: 本地处理，无需上传原视频

---

## 🛠️ 技术栈

### 核心依赖

| 包名 | 版本 | 用途 |
|------|------|------|
| `google_mlkit_pose_detection` | ^0.13.0 | 姿态检测 |
| `video_snapshot_generator` | ^0.0.2 | 视频帧提取 |
| `scidart` | ^0.0.2-dev.12 | 峰值检测算法 |

### 平台要求
- **iOS**: 15.5+
- **Android**: API 24+

---

## 🏗️ 架构设计

### 系统架构

```
┌──────────────────────────────────────────────────────┐
│          DailyTrainingReviewPage (UI)                │
│  ┌────────────────────────────────────────────────┐  │
│  │  LinearProgressBar (实时进度显示)              │  │
│  │  - 0.0-1.0 进度值                              │  │
│  │  - Info text (当前步骤描述)                    │  │
│  └────────────────────────────────────────────────┘  │
└────────────────┬─────────────────────────────────────┘
                 │ onProgress(progress, infoText)
                 ▼
┌──────────────────────────────────────────────────────┐
│         LocalKeyframeExtractor (核心服务)            │
│                                                      │
│  extractKeyframes(videoUrl, trainingId, index,       │
│                   onProgress: callback)              │
└──┬────┬────┬────┬────┬────────────────────────────────┘
   │    │    │    │    │
   │    │    │    │    └─ StorageService (上传)
   │    │    │    └────── PoseAngleCalculator (角度计算)
   │    │    └─────────── KeyframeSelector (智能选择)
   │    └──────────────── VideoFrameExtractor (提取帧)
   └───────────────────── VideoDownloader (下载)
```

### 关键组件

#### 1. UI层

**LinearProgressBar** (`lib/core/widgets/linear_progress_bar.dart`)
```dart
LinearProgressBar(
  progress: 0.6,           // 0.0-1.0
  infoText: 'Detecting poses...',  // 当前步骤
)
```

**按钮禁用逻辑**
- 点击后立即禁用（变灰）
- 提取完成或失败后恢复

#### 2. 核心服务

**LocalKeyframeExtractor** (`lib/core/services/local_keyframe_extractor.dart`)
```dart
await extractor.extractKeyframes(
  videoUrl,
  trainingId,
  exerciseIndex,
  onProgress: (progress, infoText) {
    // 更新UI进度
    // progress: 0.0 → 0.2 → 0.4 → 0.6 → 0.8 → 1.0
  },
);
```

**进度回调时间点**:
- 0.0: 开始
- 0.2: 视频下载完成
- 0.4: 帧提取完成
- 0.6: 姿态检测完成
- 0.8: 关键帧选择完成
- 1.0: Firestore更新完成

#### 3. 数据模型

**KeyframeExtractionProgress** (`lib/features/chat/presentation/providers/`)
```dart
class KeyframeExtractionProgress {
  final double progress;    // 0.0-1.0
  final String? infoText;   // "Downloading video..."
}
```

**Firestore数据结构** (`dailyTrainings/{id}`)
```json
{
  "extractedKeyFrames": {
    "0": {
      "exerciseName": "Squat",
      "keyframes": [
        {
          "localPath": "/path/to/frame.jpg",  // 本地路径（优先）
          "url": "https://...",                // 网络URL（降级）
          "timestamp": 2.5,
          "uploadStatus": "uploaded"
        }
      ],
      "method": "mlkit_pose"
    }
  }
}
```

---

## 🔄 用户流程

### 完整流程（含进度反馈）

```
用户操作
   │
   ├─ 1. 点击"提取关键帧"按钮
   │     ├─ 按钮立即禁用（变灰）
   │     ├─ 显示进度条（0%）
   │     └─ onProgress(0.0, "Starting...")
   │
   ├─ 2. 下载视频 (0% → 20%)
   │     ├─ VideoDownloader.downloadVideo()
   │     ├─ onProgress(0.0, "Downloading video...")
   │     ├─ 保存到临时目录
   │     └─ onProgress(0.2, "Video downloaded")
   │
   ├─ 3. 提取视频帧 (20% → 40%)
   │     ├─ VideoFrameExtractor.extractFrames(fps=1)
   │     ├─ onProgress(0.2, "Extracting frames...")
   │     ├─ 输出到临时目录
   │     └─ onProgress(0.4, "Frames extracted")
   │
   ├─ 4. 姿态检测 (40% → 60%)
   │     ├─ 遍历所有帧
   │     │   ├─ PoseDetector.processImage()
   │     │   ├─ PoseAngleCalculator.getJointAngles()
   │     │   └─ 收集FrameData (angles, timestamp)
   │     ├─ onProgress(0.4, "Detecting poses...")
   │     ├─ 每10帧清理图像缓存（内存管理）
   │     └─ onProgress(0.6, "Poses detected")
   │
   ├─ 5. 选择关键帧 (60% → 80%)
   │     ├─ KeyframeSelector.selectKeyframesByAngleChange()
   │     │   ├─ 提取角度时间序列
   │     │   ├─ 检测峰谷值（角度变化显著点）
   │     │   └─ 均匀分布筛选（贪心算法）
   │     ├─ onProgress(0.6, "Selecting keyframes...")
   │     └─ onProgress(0.8, "Keyframes selected")
   │
   ├─ 6. 更新Firestore (80% → 100%)
   │     ├─ 存储本地路径（立即可用）
   │     ├─ onProgress(0.8, "Saving keyframes...")
   │     └─ onProgress(1.0, "Completed")
   │
   ├─ 7. 后台上传（不阻塞UI）
   │     ├─ 异步上传关键帧到Storage
   │     ├─ 更新uploadStatus: pending → uploading → uploaded
   │     └─ 更新url字段
   │
   ├─ 8. 清理临时文件
   │     ├─ 删除视频文件
   │     ├─ 删除非关键帧图片
   │     └─ 保留关键帧（用户可点击查看）
   │
   └─ 9. UI更新
         ├─ 清除进度状态
         ├─ 按钮恢复可用
         └─ 显示关键帧缩略图（可点击编辑）
```

### 本地文件优先策略

**问题**: 上传完成后切换到网络文件会导致闪烁（server glitch）

**解决**: 优先使用本地文件，直到本地文件被清理

```dart
ImageProvider _getImageProvider() {
  // 1. 优先本地文件（更快，无闪烁）
  if (localPath != null && File(localPath).existsSync()) {
    return FileImage(File(localPath));
  }
  // 2. 降级网络文件（本地清理后）
  if (imageUrl != null) {
    return CachedNetworkImageProvider(imageUrl);
  }
}
```

**时间线**:
```
提取完成 → 本地文件可用 → 后台上传 → 继续显示本地 → 本地清理 → 自动降级网络
    ↓           ↓              ↓            ↓             ↓            ↓
  秒开      用户可点击      无感知      无闪烁        平滑过渡    持久化
```

---

## 🔧 关键实现细节

### 1. 进度管理

**Provider状态**
```dart
// Map<exerciseIndex, ProgressData>
final keyframeExtractionProgressProvider =
    StateProvider<Map<int, KeyframeExtractionProgress>>();

final keyframeExtractionLoadingProvider =
    StateProvider<Map<int, bool>>();
```

**按钮禁用逻辑**
```dart
CupertinoButton(
  onPressed: isLoading ? null : onExtract,
  color: isLoading ? AppColors.backgroundSecondary : AppColors.primary,
  child: Text(
    l10n.extractKeyframes,
    style: AppTextStyles.caption1.copyWith(
      color: isLoading ? AppColors.textSecondary : AppColors.textPrimary,
    ),
  ),
)
```

### 2. 内存管理

**问题**: 长视频可能导致OOM

**解决**:
```dart
// 每处理10帧清理图像缓存
if (frameNumber % 10 == 0) {
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();
}
```

### 3. 关键帧选择算法

**核心逻辑**:
1. 提取8个关节角度的时间序列
2. 检测每个角度的峰值和谷值（显著变化点）
3. 汇总候选帧（去重）
4. 分布均匀化筛选（贪心算法，最大化帧间距离）
5. 降级方案：姿态检测失败时均匀采样

**参数**:
- `minDistance`: 5帧（避免相邻帧）
- `prominence`: 5.0度（过滤小幅度变化）
- `maxFrames`: 5个关键帧

### 4. 错误处理

**降级策略**:
- 姿态检测失败 → 均匀采样
- 单帧检测失败 → 跳过该帧，继续处理
- 提取失败 → 显示错误，允许重试

**清理保证**:
```dart
try {
  await extractKeyframes(...);
} catch (e) {
  // 设置错误状态
} finally {
  // 确保清理临时文件
  await _cleanup(videoPath, framesDir, selectedKeyframePaths);
  _poseDetector.close();
}
```

---

## 📊 性能指标

### 实测数据（预期）

| 视频长度 | 帧数 | 处理时间 | 内存峰值 |
|---------|------|---------|---------|
| 10秒 | ~100帧 | <30秒 | <300MB |
| 30秒 | ~300帧 | <60秒 | <400MB |

### 性能优化

**已实现**:
- ✅ 实时进度反馈（用户体验）
- ✅ 内存缓存清理（每10帧）
- ✅ 本地文件优先（避免网络延迟）
- ✅ 后台异步上传（不阻塞UI）

**未来优化**:
- ⚠️ Dart Isolate并行处理（性能提升）
- ⚠️ 流式处理（进一步降低内存）

---

## 🚀 最近更新

### v2.0.0 (2025-11-16)

**新增功能**:
- ✅ LinearProgressBar widget（实时进度显示）
- ✅ 进度回调机制（5个步骤，0%-100%）
- ✅ 按钮禁用逻辑（防止重复点击）
- ✅ 本地文件优先策略（无server glitch）
- ✅ ImagePreviewPage支持localPath

**架构优化**:
- ✅ LocalKeyframeExtractor新增onProgress参数
- ✅ 新增KeyframeExtractionProgress数据模型
- ✅ 优化图像加载优先级（本地→网络）

**用户体验改进**:
- ✅ 实时进度反馈（从"Starting..."到"Completed"）
- ✅ 按钮状态视觉反馈（禁用时变灰）
- ✅ 无缝切换本地/网络图片（无闪烁）

### v1.0.0 (2025-11-15)

- ✅ 完成Frontend基础实现
- ✅ MLKit姿态检测集成
- ✅ 关键帧智能选择算法

---

## 📚 相关文档

### 代码位置
- **核心服务**: `lib/core/services/local_keyframe_extractor.dart`
- **UI集成**: `lib/features/chat/presentation/pages/daily_training_review_page.dart`
- **进度组件**: `lib/core/widgets/linear_progress_bar.dart`
- **工具函数**: `lib/core/utils/pose_angle_calculator.dart`

### 参考资料
- [Google MLKit Pose Detection](https://developers.google.com/ml-kit/vision/pose-detection)
- [video_snapshot_generator](https://pub.dev/packages/video_snapshot_generator)

---

**维护者**: Claude Code
**文档版本**: 2.0.0
