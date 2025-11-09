# AI食物识别与营养估算功能 - 实施进度

## 功能概述
通过Claude Vision API实现拍照识别食物并估算营养成分（卡路里+三大宏量营养素），集成到学生饮食记录流程中。

**创建时间**: 2025-11-04
**项目**: CoachX
**负责模块**: Student Diet Recording

---

## 用户流程
1. 点击"记录饮食"选项
2. 进入AI相机页面（live preview + focus area）
3. 拍照或上传图片
4. 显示分析进度（progress bar）
5. 展示识别结果（多食物 + 营养数据）
6. 手动调整数值（可选）
7. 选择保存到的meal
8. 保存并关闭

---

## 技术栈
- **Frontend**: Flutter + Riverpod 2.x
- **Backend**: Python Cloud Functions (Firebase)
- **AI**: Claude Vision API (Anthropic)
- **Storage**: Firebase Storage
- **Camera**: Flutter `camera` plugin
- **Permissions**: `permission_handler` plugin

---

## 实施检查清单

### Phase 1: Backend基础设施
- [ ] 1. 创建 `functions/ai/food_nutrition/__init__.py`
- [ ] 2. 创建 `functions/ai/food_nutrition/prompts.py` 并实现prompt构建函数
- [ ] 3. 创建 `functions/ai/food_nutrition/handlers.py` 并实现 `analyze_food_nutrition` Cloud Function
- [ ] 4. 在 `functions/main.py` 中导出新函数
- [ ] 5. 本地测试Cloud Function（使用firebase emulators）
- [ ] 6. 验证Claude Vision API调用正常返回食物识别结果

### Phase 2: Flutter数据层
- [ ] 7. 创建 `lib/features/student/diet/data/models/ai_food_analysis_state.dart` 数据模型
- [ ] 8. 创建 `lib/features/student/diet/data/models/recognized_food.dart` 模型
- [ ] 9. 创建 `lib/features/student/diet/data/repositories/ai_food_repository.dart` 接口
- [ ] 10. 创建 `lib/features/student/diet/data/repositories/ai_food_repository_impl.dart` 实现
- [ ] 11. 在 `lib/core/services/ai_service.dart` 中添加 `analyzeFoodNutrition()` 方法

### Phase 3: 状态管理
- [ ] 12. 创建 `lib/features/student/diet/presentation/providers/ai_food_scanner_notifier.dart`
- [ ] 13. 创建 `lib/features/student/diet/presentation/providers/ai_food_scanner_providers.dart`
- [ ] 14. 实现状态更新逻辑（analyzing, results, error handling）

### Phase 4: UI组件 - Camera页面
- [ ] 15. 更新 `pubspec.yaml` 添加 `camera` 和 `permission_handler` 依赖
- [ ] 16. 运行 `flutter pub get`
- [ ] 17. 创建 `lib/features/student/diet/presentation/widgets/camera_focus_overlay.dart`
- [ ] 18. 创建 `lib/features/student/diet/presentation/pages/ai_food_scanner_page.dart`
- [ ] 19. 实现camera初始化和preview
- [ ] 20. 实现拍照按钮UI和功能
- [ ] 21. 实现上传按钮UI和功能（调用image_picker）
- [ ] 22. 实现focus area覆盖层

### Phase 5: UI组件 - 分析结果Sheet
- [ ] 23. 创建 `lib/features/student/diet/presentation/widgets/food_item_editor.dart`
- [ ] 24. 创建 `lib/features/student/diet/presentation/widgets/food_analysis_bottom_sheet.dart`
- [ ] 25. 实现progress bar状态UI
- [ ] 26. 实现结果显示UI（食物列表）
- [ ] 27. 实现数值编辑功能
- [ ] 28. 实现Meal选择下拉
- [ ] 29. 实现Save按钮和保存逻辑

### Phase 6: 国际化
- [ ] 30. 更新 `lib/l10n/app_en.arb` 添加所有新文案
- [ ] 31. 更新 `lib/l10n/app_zh.arb` 添加中文翻译
- [ ] 32. 运行 `flutter gen-l10n` 生成本地化代码

### Phase 7: 路由和集成
- [ ] 33. 在 `lib/routes/route_names.dart` 添加 `studentAIFoodScanner` 路由名称
- [ ] 34. 在 `lib/routes/app_router.dart` 添加AI扫描页面路由配置
- [ ] 35. 修改 `lib/features/student/presentation/widgets/record_activity_bottom_sheet.dart` 饮食记录入口跳转

### Phase 8: iOS配置
- [ ] 36. 更新 `ios/Runner/Info.plist` 添加相机和相册权限描述

### Phase 9: 测试和调试
- [ ] 37. 测试完整用户流程（拍照 → 分析 → 编辑 → 保存）
- [ ] 38. 测试上传图片流程
- [ ] 39. 测试多食物识别准确性
- [ ] 40. 测试错误处理（权限拒绝、网络错误、AI失败）
- [ ] 41. 测试数据保存到Firestore正确性
- [ ] 42. UI/UX细节调整

### Phase 10: 部署
- [ ] 43. 部署Cloud Functions到生产环境：`firebase deploy --only functions`
- [ ] 44. 验证生产环境AI分析功能正常
- [ ] 45. 进行端到端测试

---

## 文件结构

### Backend (Python)
```
functions/
├── ai/
│   └── food_nutrition/
│       ├── __init__.py
│       ├── handlers.py          # analyze_food_nutrition Cloud Function
│       └── prompts.py           # AI prompt构建
└── main.py                      # 导出函数
```

### Frontend (Flutter)
```
lib/
├── features/student/diet/
│   ├── data/
│   │   ├── models/
│   │   │   ├── ai_food_analysis_state.dart
│   │   │   └── recognized_food.dart
│   │   └── repositories/
│   │       ├── ai_food_repository.dart
│   │       └── ai_food_repository_impl.dart
│   └── presentation/
│       ├── pages/
│       │   └── ai_food_scanner_page.dart
│       ├── providers/
│       │   ├── ai_food_scanner_notifier.dart
│       │   └── ai_food_scanner_providers.dart
│       └── widgets/
│           ├── camera_focus_overlay.dart
│           ├── food_analysis_bottom_sheet.dart
│           └── food_item_editor.dart
├── core/services/
│   └── ai_service.dart          # 添加 analyzeFoodNutrition()
└── routes/
    ├── route_names.dart
    └── app_router.dart
```

---

## API接口设计

### Cloud Function: `analyze_food_nutrition`

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

## 开发备注

### Prompt工程要点
- **System Prompt**: 定义为营养分析专家角色
- **User Prompt**: 要求识别所有食物、估算重量、计算营养成分
- **输出格式**: 严格JSON Schema
- **估算基准**: 基于标准份量和常见食物数据库

### 相机实现注意事项
- 需要异步初始化 CameraController
- 必须在 dispose 时释放资源
- iOS需要Info.plist权限配置
- 使用 permission_handler 统一管理权限

### 数据流
1. 用户拍照 → 本地文件
2. 上传到 Firebase Storage → 获取公开URL
3. 调用 Cloud Function（传入URL）
4. Claude Vision API 分析 → 返回食物列表
5. 显示结果 → 用户编辑 → 保存到Firestore

---

## 进度更新日志

### 2025-11-04
- ✅ 需求调研完成
- ✅ 技术方案确定（纯视觉方案，不使用LiDAR）
- ✅ 详细规划文档创建
- ✅ **Phase 1-8 全部完成**
- ✅ Backend基础设施（Python Cloud Functions）
- ✅ Flutter数据层和Repository
- ✅ Riverpod状态管理
- ✅ Camera UI页面实现
- ✅ 分析结果Bottom Sheet
- ✅ 国际化文案（中英文）
- ✅ 路由集成
- ✅ iOS权限配置
- ✅ 代码检查和格式化
- ✅ **功能实施完成，准备测试**

---

## 相关文档
- [项目主README](../coach_x/README.md)
- [Backend API文档](./backend_apis_and_document_db_schemas.md)
- [JSON解析修复指南](./json_parsing_fix.md)

---

**最后更新**: 2025-11-04
