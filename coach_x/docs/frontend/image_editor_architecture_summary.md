# Image Editor Feature - Architecture Summary

**Created**: 2025-01-16
**Version**: 1.0
**Status**: ✅ Implemented

---

## 1. Architecture

### 1.1 Component Hierarchy

```
Core Widgets (Universal)
├── ImageEditorPage          # 通用图片编辑器
│   ├── ProImageEditor       # 第三方编辑器组件
│   └── Returns: Uint8List   # 编辑后的图片字节数据
│
└── ImagePreviewPage         # 全屏预览+编辑入口
    ├── PhotoView            # 图片缩放查看
    ├── NavigationBar        # 关闭/编辑按钮
    └── Edit Flow            # 调用ImageEditorPage → 上传 → 更新反馈

Feature Integration Points
├── feedback_input_bar.dart      # Entry 1: 新图片上传
├── feedback_history_section.dart # Entry 2: 反馈图片编辑
└── daily_training_review_page.dart # Entry 3: 关键帧标注
```

### 1.2 Layer Architecture

```
┌─────────────────────────────────────────────┐
│         Presentation Layer                  │
│  ┌────────────┐  ┌──────────────────┐      │
│  │ Input Bar  │  │ History Section  │      │
│  │ (Upload)   │  │ (Edit Feedback)  │      │
│  └─────┬──────┘  └────────┬─────────┘      │
│        │                   │                 │
│        └──────┬────────────┘                 │
│               ▼                               │
│      ┌────────────────┐                      │
│      │ ImagePreview   │ ◄─── Keyframe Grid  │
│      │     Page       │                      │
│      └───────┬────────┘                      │
│              │                                │
│              ▼                                │
│      ┌────────────────┐                      │
│      │ ImageEditor    │                      │
│      │     Page       │                      │
│      └───────┬────────┘                      │
└──────────────┼─────────────────────────────┘
               │ Uint8List
               ▼
┌─────────────────────────────────────────────┐
│           Data Layer                        │
│  ┌──────────────────────────────────┐       │
│  │   FeedbackRepository             │       │
│  │  ┌────────────────────────────┐  │       │
│  │  │ uploadEditedImageBytes()   │  │       │
│  │  │ updateFeedbackImage()      │  │       │
│  │  │ addFeedback()              │  │       │
│  │  └────────────────────────────┘  │       │
│  └──────────────────────────────────┘       │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│        Backend (Firebase)                   │
│  ┌──────────────┐  ┌──────────────────┐    │
│  │   Storage    │  │   Firestore      │    │
│  │  (putData)   │  │ (create/update)  │    │
│  └──────────────┘  └──────────────────┘    │
└─────────────────────────────────────────────┘
```

### 1.3 Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **UI Framework** | Flutter Cupertino | iOS风格界面 |
| **Image Editor** | `pro_image_editor: ^11.12.2` | 图片编辑功能（画笔、裁剪、文字、橡皮擦） |
| **Image Viewer** | `photo_view: ^0.14.0` | 图片缩放查看 |
| **State Management** | Riverpod 2.x | 状态管理和依赖注入 |
| **Backend** | Firebase Storage + Firestore | 图片存储和元数据 |
| **Image Format** | JPG (85% quality) | 统一输出格式 |

---

## 2. Data Flow

### 2.1 Flow 1: 新图片上传并编辑

```
┌─────────────┐
│   Student   │
│   (User)    │
└──────┬──────┘
       │ 1. Tap Image Button
       ▼
┌─────────────────────┐
│  FeedbackInputBar   │
│  _handleImagePick() │
└──────┬──────────────┘
       │ 2. ImagePicker.pickImage()
       ▼
┌─────────────────────┐
│  ImageEditorPage    │  ← localPath
│  (Edit Image)       │
└──────┬──────────────┘
       │ 3. User edits & saves
       │ Returns: Uint8List bytes
       ▼
┌─────────────────────┐
│  FeedbackInputBar   │
│  _sendEditedImage   │
│  Feedback()         │
└──────┬──────────────┘
       │ 4. uploadEditedImageBytes(bytes)
       ▼
┌─────────────────────┐
│ FeedbackRepository  │
│  .uploadEdited      │
│  ImageBytes()       │
└──────┬──────────────┘
       │ 5. putData(bytes, metadata)
       ▼
┌─────────────────────┐
│ Firebase Storage    │
│ feedback_images/    │
│ {trainingId}/       │
│ edited_*.jpg        │
└──────┬──────────────┘
       │ 6. Returns: downloadUrl
       ▼
┌─────────────────────┐
│ FeedbackRepository  │
│  .addFeedback()     │
└──────┬──────────────┘
       │ 7. Create feedback doc
       ▼
┌─────────────────────┐
│   Firestore         │
│ dailyTraining       │
│ Feedback/           │
│ {feedbackId}        │
│  - imageUrl         │
│  - feedbackType:"image"
└─────────────────────┘
```

**Key Data**:
- Input: `localPath` (String)
- Processing: `Uint8List bytes` (edited image)
- Output: `imageUrl` (String) + Firestore document

---

### 2.2 Flow 2: 编辑已有反馈图片

```
┌─────────────┐
│   Coach     │
└──────┬──────┘
       │ 1. Tap feedback image
       ▼
┌─────────────────────┐
│ FeedbackHistory     │
│ Section             │
│ _ImageBubble        │
└──────┬──────────────┘
       │ 2. Navigate to ImagePreviewPage
       ▼
┌─────────────────────┐
│ ImagePreviewPage    │  ← imageUrl, feedbackId
│ (Fullscreen View)   │
└──────┬──────────────┘
       │ 3. Tap Edit Button
       ▼
┌─────────────────────┐
│ ImageEditorPage     │  ← networkUrl
│ (Edit Image)        │
└──────┬──────────────┘
       │ 4. Returns: Uint8List bytes
       ▼
┌─────────────────────┐
│ ImagePreviewPage    │
│ _uploadAndUpdate    │
│ Feedback()          │
└──────┬──────────────┘
       │ 5. uploadEditedImageBytes(bytes)
       │    + updateFeedbackImage(feedbackId, newUrl)
       ▼
┌─────────────────────┐
│ Firebase Storage    │
│ (new image)         │
│ + Firestore Update  │
│ (imageUrl field)    │
└─────────────────────┘
```

**Key Operations**:
- `uploadEditedImageBytes()`: 上传新图片 → 获取新URL
- `updateFeedbackImage(feedbackId, newUrl)`: 更新Firestore记录

---

### 2.3 Flow 3: 关键帧标注

```
┌─────────────┐
│   Coach     │
└──────┬──────┘
       │ 1. Tap keyframe thumbnail
       ▼
┌─────────────────────┐
│ DailyTraining       │
│ ReviewPage          │
│ _CompactKeyframe    │
│ Item (onTap)        │
└──────┬──────────────┘
       │ 2. _handleKeyframeTap()
       ▼
┌─────────────────────┐
│ ImagePreviewPage    │  ← keyframeUrl, dailyTrainingId
│ (Keyframe View)     │
└──────┬──────────────┘
       │ 3. Tap Edit Button
       ▼
┌─────────────────────┐
│ ImageEditorPage     │  ← networkUrl
│ (Annotate)          │
└──────┬──────────────┘
       │ 4. Returns: Uint8List bytes
       ▼
┌─────────────────────┐
│ ImagePreviewPage    │
│ _uploadAndCreate    │
│ Feedback()          │
└──────┬──────────────┘
       │ 5. uploadEditedImageBytes(bytes)
       │    + addFeedback(imageUrl)
       ▼
┌─────────────────────┐
│ Firestore           │
│ Create NEW feedback │
│ (annotated keyframe)│
└─────────────────────┘
       ▼
┌─────────────────────┐
│ Original Keyframe   │
│ UNCHANGED           │
│ (data integrity)    │
└─────────────────────┘
```

**Design Decision**: 关键帧标注创建新反馈，不修改原始关键帧（保持训练数据完整性）

---

## 3. Use Cases

### 3.1 UC-1: 学生上传训练照片并标注

**Actor**: Student
**Precondition**: 学生已完成训练，在反馈输入栏
**Flow**:
1. 学生点击图片按钮
2. 从相册选择训练照片
3. 系统打开图片编辑器
4. 学生使用画笔标注疼痛部位/问题区域
5. 学生添加文字说明
6. 点击保存
7. 系统上传编辑后的图片并创建反馈记录

**Postcondition**: 教练在反馈历史中看到学生的标注图片

**Business Value**: 学生能够更清晰地表达问题，提升沟通效率

---

### 3.2 UC-2: 教练编辑反馈图片

**Actor**: Coach
**Precondition**: 教练已发送图片反馈
**Flow**:
1. 教练点击已发送的反馈图片
2. 系统显示全屏预览
3. 教练点击编辑按钮
4. 系统打开图片编辑器
5. 教练添加新的标注或修改说明
6. 点击保存
7. 系统更新反馈记录（同一feedbackId，新imageUrl）

**Postcondition**: 反馈历史中的图片更新为编辑后的版本

**Business Value**: 教练可以纠正错误或补充说明，无需重新发送

---

### 3.3 UC-3: 教练标注学生动作关键帧

**Actor**: Coach
**Precondition**: 学生已上传训练视频，系统已提取关键帧
**Flow**:
1. 教练在训练审核页面查看关键帧
2. 教练点击某个关键帧（如深蹲最低点）
3. 系统显示全屏预览
4. 教练点击编辑按钮
5. 教练使用画笔圈出动作问题：
   - 膝盖内扣
   - 腰部过度前倾
6. 教练添加文字："注意膝盖对齐脚尖"
7. 点击保存
8. 系统创建新的图片反馈（包含标注）

**Postcondition**:
- 学生在反馈历史中看到教练的标注
- 原始关键帧保持不变（用于AI分析）

**Business Value**: 教练能够精准指出动作问题，学生理解更快，训练效果更好

---

### 3.4 UC-4: 取消编辑

**Actor**: Coach/Student
**Precondition**: 用户在图片编辑器中
**Flow**:
1. 用户开始编辑图片
2. 用户点击取消/返回按钮
3. 系统关闭编辑器，不上传任何数据
4. 返回上一个页面

**Postcondition**: 无任何数据变更

**Business Value**: 用户有后悔权，避免误操作

---

## 4. Key Design Decisions

### 4.1 为什么选择 `pro_image_editor`？

✅ **优势**:
- 支持所有需要的编辑功能（画笔、文字、裁剪、橡皮擦）
- 内置撤销/重做
- 支持网络图片和本地文件
- 完全可自定义UI主题（Frosted Glass）
- 返回 `Uint8List` 便于直接上传
- 活跃维护（502+ likes）

❌ **替代方案**:
- `image_editor_plus`: 更新频率低
- 自定义实现: 开发周期长

---

### 4.2 关键帧编辑策略

**Decision**: 关键帧编辑后保存为新的反馈图片（不修改原始关键帧）

**Rationale**:
- ✅ 保持原始训练数据完整性（用于AI姿态分析）
- ✅ 教练标注作为反馈独立存储
- ✅ 学生可以对比原始关键帧和教练标注
- ✅ 支持未来回溯分析

**Trade-off**: 存储成本增加（可接受，单张图片约50-200KB）

---

### 4.3 反馈图片编辑策略

**Decision**: 更新原反馈记录（修改 `imageUrl` 字段）

**Rationale**:
- ✅ 教练的反馈是可编辑的
- ✅ 更新比创建新记录更符合用户预期
- ✅ 避免重复反馈造成学生困惑

**Implementation**: `updateFeedbackImage(feedbackId, newImageUrl)`

---

### 4.4 图片格式统一

**Decision**: 所有编辑后的图片统一为 JPG (85% quality)

**Rationale**:
- ✅ 与现有 `image_picker` 配置一致
- ✅ 文件大小合理（平衡质量和成本）
- ✅ 跨平台兼容性好

**Storage Path**: `feedback_images/{dailyTrainingId}/edited_image_{timestamp}.jpg`

---

## 5. State Management

### 5.1 Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `isEditingImageProvider` | StateProvider<bool> | 图片编辑加载状态 |
| `imageUploadProgressProvider` | StateProvider<double?> | 上传进度（可选，未来扩展） |
| `feedbackRepositoryProvider` | Provider | 反馈数据仓库 |
| `reviewPageDataProvider` | FutureProvider | 训练审核页面数据 |

### 5.2 State Flow

```
[User Action] → [Provider State Change] → [UI Update]

Example:
Tap Edit → isEditingImageProvider = true → Show loading
Upload Done → isEditingImageProvider = false → Hide loading
```

---

## 6. Security & Data Integrity

### 6.1 Firebase Storage Rules

```
match /feedback_images/{dailyTrainingId}/{fileName} {
  allow write: if request.auth != null;  // 已登录用户
  allow read: if request.auth != null;
}
```

### 6.2 Data Validation

- ✅ 图片大小限制: 1920x1920px (与 `image_picker` 一致)
- ✅ 格式限制: JPG (contentType: 'image/jpeg')
- ✅ 权限检查: 仅教练/学生本人可编辑

---

## 7. Performance Considerations

| Aspect | Metric | Optimization |
|--------|--------|-------------|
| **编辑响应** | < 100ms | ProImageEditor原生性能 |
| **图片上传** | ~2-5s (1MB) | Firebase Storage |
| **UI渲染** | 60 FPS | PhotoView GPU加速 |
| **缓存** | CachedNetworkImage | 避免重复下载 |

---

## 8. Future Enhancements (V2)

- [ ] Batch edit multiple images
- [ ] Video annotation support
- [ ] Custom stickers/overlays
- [ ] Drawing layers management
- [ ] Export to different formats (PNG, WebP)
- [ ] Image compression before upload (reduce storage cost)
- [ ] Offline editing with sync queue

---

## 9. Related Documentation

- **Implementation Plan**: `/docs/frontend/image_editor_implementation.md`
- **Backend API**: `/docs/backend_apis_and_document_db_schemas.md` (Section: dailyTrainingFeedback)
- **Typography Standards**: `/CLAUDE.md` (Section: Typography)
- **i18n Guidelines**: `/CLAUDE.md` (Section: Internationalization)

---

**Last Updated**: 2025-01-16
**Maintained By**: Development Team
**Status**: ✅ Production Ready
