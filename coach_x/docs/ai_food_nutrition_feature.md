# AI食物识别与营养估算功能

## 功能概述

通过Claude Vision API实现拍照识别食物并估算营养成分（卡路里+三大宏量营养素），集成到学生饮食记录流程中。

**项目**: CoachX
**负责模块**: Student Diet Recording

---

## 用户流程

### 完整流程

```
1. 点击"记录饮食"
   ↓
2. 进入相机页面（live preview + focus area）
   ↓
3. 拍照或从相册选择图片
   ↓
4. 📸 图片预览页面
   ├─ 按钮1: [AI 分析]
   │   ↓
   │   上传图片 → AI 分析中 → 显示识别结果
   │   ↓
   │   选择餐次 → 保存
   │
   └─ 按钮2: [手动记录]
       ↓
       选择餐次 → 输入营养数据 → 保存（触发上传）
```

### 两种记录模式

| 模式 | 拍照后 | 用户操作 | 保存时 |
|------|--------|----------|--------|
| **AI 分析** | 立即上传 → 自动 AI 分析 | 查看结果、选择餐次 | 直接保存（已有数据） |
| **手动记录** | 仅本地预览 | 选择餐次、输入营养 | 开始上传 → 完成后保存 |

---

## 技术栈

- **Frontend**: Flutter + Riverpod 2.x
- **Backend**: Python Cloud Functions (Firebase)
- **AI**: Claude Vision API (Anthropic)
- **Storage**: Firebase Storage
- **Camera**: Flutter `camera` plugin
- **Permissions**: `permission_handler` plugin
- **Image Compression**: `flutter_image_compress` (质量 85%, 最大分辨率 1920x1920)

---

## 核心组件

### Backend
- **Cloud Function**: `analyze_food_nutrition` - 接收图片 URL，调用 Claude Vision API 返回营养分析

### Frontend
- **页面**: `FoodImagePreviewPage` - 图片预览和模式选择
- **状态管理**: `AIFoodScannerNotifier` - 管理上传、分析、保存流程
- **工具**: `ImageCompressor` - 图片压缩优化
- **Repository**: `AIFoodRepository` / `DietRecordRepository` - 数据访问层

---

## 状态管理

**核心状态**: `AIFoodAnalysisState`
- 上传/分析状态（`isUploading`, `isAnalyzing`）
- AI 识别结果（`foods`, `imageUrl`）
- 用户输入（`selectedMealName`, 营养数据）
- 记录模式（`aiScanner` / `simpleRecord`）

**数据结构优化**:
- `StudentDietRecordModel.meals` 初始为空列表，按需创建
- `Meal` 不存在时从计划创建（保留 name/note）
- `StudentDietRecordModel.macros` 为 getter（自动计算）

---

## API 接口

### Cloud Function: `analyze_food_nutrition`

**端点**: `https://us-central1-{project}.cloudfunctions.net/analyze_food_nutrition`

**请求**:
```json
{
  "image_url": "https://firebasestorage.googleapis.com/...",
  "language": "中文"
}
```

**响应**:
```json
{
  "status": "success",
  "data": {
    "foods": [
      {
        "name": "米饭",
        "estimated_weight": "150g",
        "macros": {
          "protein": 4.0,
          "carbs": 45.0,
          "fat": 0.5,
          "calories": 200
        }
      }
    ]
  }
}
```

---

## 数据流

### AI Scanner 模式

1. 用户拍照 → 本地文件
2. 进入图片预览页面 → 点击"AI 分析"
3. **图片压缩** (质量 85%, 1920x1920) → 减少 70-90% 文件大小
4. **上传压缩后的图片**到 Firebase Storage → 获取公开 URL
5. 调用 Cloud Function（传入 URL）
6. Claude Vision API 分析 → 返回食物列表
7. 显示结果（食物 + 营养数据）
8. 用户选择餐次 → 保存到 Firestore
   - 如果该餐次不存在，创建新 Meal（保留 name 和 note，items 只包含用户添加的）
   - 如果该餐次已存在，追加 FoodItem 到该 meal
9. **清理临时压缩文件**

### Simple Record 模式

1. 用户拍照 → 本地文件
2. 进入图片预览页面 → 点击"手动记录"
3. 选择餐次 + 输入营养数据
4. 点击保存 → **图片压缩** → **开始上传**到 Firebase Storage
5. 上传完成 → 保存到 Firestore（包含图片 URL + 营养数据）
   - 如果该餐次不存在，创建新 Meal
   - 如果该餐次已存在，追加 FoodItem
6. **清理临时压缩文件**

---

## 权限配置

### iOS (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机拍摄食物照片以记录饮食</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择食物照片</string>
```

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

---

## AI Prompt 设计

**System Prompt**: 营养分析专家角色，识别食物、估算重量、计算营养成分

**输出 Schema**:
```json
{
  "foods": [
    { "name": "string", "estimated_weight": "string",
      "macros": { "protein": "number", "carbs": "number", "fat": "number", "calories": "number" }
    }
  ]
}
```

---

## 错误处理

| 错误类型 | 处理方式 |
|---------|---------|
| 相机权限拒绝 | 显示权限说明，引导用户到设置页面 |
| 网络错误 | 显示错误提示，允许重试 |
| AI 分析失败 | 显示错误消息，可切换到手动记录模式 |
| 图片上传失败 | 显示"图片上传失败，请重试" |
| 用户未绑定教练 | "未绑定教练，请先绑定教练后再记录饮食" |

---

## 相关文档

- [项目主 README](../README.md)
- [Backend API 文档](./backend_apis_and_document_db_schemas.md)
- [学生端首页实现](./student/student_home_implementation_progress.md)

---

## 性能优化

**图片压缩** (`ImageCompressor`):
- 质量: 85% (JPEG), 最大分辨率: 1920x1920
- 效果: 文件减少 70-90%，上传提速 5-10 倍（5-15s → 1-3s）
- 自动清理临时文件（成功/失败都会清理）

---

**最后更新**: 2025-11-16
