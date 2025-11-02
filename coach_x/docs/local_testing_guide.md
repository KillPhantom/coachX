# 本地测试 Firebase Functions 指南

## 🚀 快速开始

### 1. 启动 Firebase Emulator

在一个终端窗口中运行：

```bash
cd /Users/ivan/coachX/coach_x
firebase emulators:start --only functions
```

你会看到类似输出：
```
✔  functions[us-central1-stream_training_plan]: http function initialized (http://127.0.0.1:5001/coachx-9d219/us-central1/stream_training_plan).
```

### 2. Flutter 应用已自动配置使用本地模拟器

已修改的文件：
- ✅ `lib/core/services/cloud_functions_service.dart` - SSE URL 指向本地
- ✅ `lib/core/services/firebase_init_service.dart` - Firebase Functions 使用本地模拟器

### 3. 运行 Flutter 应用

```bash
flutter run
```

## 📝 查看实时日志

### 方式1：终端直接查看
Functions emulator 会在启动它的终端窗口中实时显示所有日志

### 方式2：使用 Firebase CLI
```bash
firebase emulators:log --only functions
```

### 方式3：Python 直接打印
所有 `logger.info()` 和 `logger.error()` 都会显示在 emulator 终端

## 🔧 本地测试的优势

1. **即时反馈** - 代码修改后自动重载，无需部署
2. **详细日志** - 所有 print/logger 输出都在终端可见
3. **快速迭代** - 修改 → 测试 → 修改，几秒内完成
4. **调试方便** - 可以添加 `print()` 语句随意调试

## 🐛 Debug 步骤

### 查看详细的 Tool Input

由于已添加详细日志，你会看到：

```python
📦 [Stream Day 1] Tool Input 类型: <class 'dict'>
📦 [Stream Day 1] Tool Input Keys: ['day_name', 'exercises', 'duration_minutes', 'notes']
📦 [Stream Day 1] Tool Input 完整内容: {
  "day_name": "胸部训练日",
  "exercises": [...],
  ...
}
```

如果看到：
```python
❌ [Stream Day 1] Tool Input 不是字典类型！实际类型: <class 'int'>, 值: 1
```

这样就能准确定位问题！

## 🔄 切换回生产环境

### 方法1：修改代码
将以下文件中的 `useLocalEmulator` 改为 `false`:
- `lib/core/services/cloud_functions_service.dart`
- `lib/core/services/firebase_init_service.dart`

### 方法2：使用环境变量（推荐）
```dart
const bool useLocalEmulator = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
```

运行时：
```bash
# 本地测试
flutter run --dart-define=USE_EMULATOR=true

# 生产环境
flutter run
```

## 📊 当前配置状态

- ✅ Emulator URL: `http://127.0.0.1:5001/coachx-9d219/us-central1`
- ✅ SSE Endpoint: `http://127.0.0.1:5001/coachx-9d219/us-central1/stream_training_plan`
- ✅ 详细日志已启用

## 🎯 测试流程

1. **启动 Emulator** → 看到函数已初始化
2. **运行 Flutter 应用** → 连接到本地
3. **触发 AI 生成** → 终端实时显示所有日志
4. **定位问题** → 根据详细日志修复
5. **保存代码** → Emulator 自动重载
6. **再次测试** → 立即看到结果

不需要每次都 `firebase deploy`！

