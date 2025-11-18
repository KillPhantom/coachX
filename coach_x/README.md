# CoachX - AI教练学生管理平台

## 项目概述

CoachX是一个基于Flutter开发的跨平台移动应用，旨在构建线上教练和学生管理的AI平台。利用AI技术提升教练的线上学生管理效率，同时让学生能够快速上传训练记录。

### 用户角色

- **学生端**: 支持训练打卡上传、与教练对话、查看训练记录等功能
- **教练端**: 支持创建训练计划、管理学生列表、与学生对话等功能

## 技术栈

### 前端
- **框架**: Flutter
- **Dart SDK**: ^3.9.2
- **支持平台**: iOS、Android

### 后端
- **架构**: Firebase全家桶
  - **Cloud Functions**: Python (2nd gen)
  - **Cloud Firestore**: NoSQL文档数据库
  - **Firebase Storage**: 文件存储
  - **Firebase Authentication**: 用户认证（邮箱/密码）
- **功能**: 用户鉴权、数据存储、Serverless API等

## 设计规范

### 颜色方案 (Color Palette)

- **主色调**: `#f2e8cf`
- **辅助色**:
  - `#a8c0d0` (浅蓝色)
  - `#c0c0c0` (银灰色)
  - `#7f8c8d` (深灰蓝)
  - `#95a5a6` (灰色)

### 字体 (Typography)

**字体家族**: Lexend

```html
<link href="https://fonts.googleapis.com/css2?family=Lexend:wght@400;500;600;700;900&display=swap" rel="stylesheet"/>
```

**字重**:
- Regular: 400
- Medium: 500
- Semi-Bold: 600
- Bold: 700
- Black: 900

### Typography 使用规范 ⚠️ 强制要求

**核心原则**:
- ✅ **必须使用** `AppTextStyles.*` 中定义的标准字体样式
- ❌ **禁止使用** 自定义 `fontSize` 硬编码
- 📏 **向下靠拢原则**: 当需要的字体大小在标准中不存在时，使用最接近的较小尺寸

**标准 fontSize 映射表**:

| 场景 | 推荐样式 | fontSize | fontWeight | 说明 |
|------|---------|----------|------------|------|
| 超大标题 | `AppTextStyles.largeTitle` | 34px | Bold (700) | 页面主标题 |
| 大标题 | `AppTextStyles.title1` | 28px | Bold (700) | - |
| 标题 | `AppTextStyles.title2` | 22px | Bold (700) | ⚠️ 24px向下靠拢 |
| 中标题 | `AppTextStyles.title3` | 20px | SemiBold (600) | - |
| 正文 | `AppTextStyles.body` | 17px | Regular (400) | 主要内容文字 |
| 正文中等 | `AppTextStyles.bodyMedium` | 17px | Medium (500) | - |
| 正文加粗 | `AppTextStyles.bodySemiBold` | 17px | SemiBold (600) | - |
| 突出显示 | `AppTextStyles.callout` | 16px | Regular (400) | ⚠️ 18px向下靠拢 |
| 副标题 | `AppTextStyles.subhead` | 15px | Regular (400) | - |
| 脚注 | `AppTextStyles.footnote` | 13px | Regular (400) | ⚠️ 14px向下靠拢 |
| 说明文字1 | `AppTextStyles.caption1` | 12px | Regular (400) | 次要信息 |
| 说明文字2 | `AppTextStyles.caption2` | 11px | Regular (400) | - |
| Tab标签 | `AppTextStyles.tabLabel` | 10px | Medium (500) | 底部Tab文字 |
| 大按钮 | `AppTextStyles.buttonLarge` | 17px | SemiBold (600) | 主要操作按钮 |
| 中按钮 | `AppTextStyles.buttonMedium` | 15px | SemiBold (600) | 次要操作按钮 |
| 小按钮 | `AppTextStyles.buttonSmall` | 13px | Medium (500) | 辅助按钮 |
| 导航栏标题 | `AppTextStyles.navTitle` | 17px | SemiBold (600) | - |
| 导航栏大标题 | `AppTextStyles.navLargeTitle` | 34px | Bold (700) | - |

**向下靠拢规则**:
- `fontSize: 24` → 使用 `AppTextStyles.title2` (22px)
- `fontSize: 18` → 使用 `AppTextStyles.callout` (16px)
- `fontSize: 14` → 使用 `AppTextStyles.footnote` (13px)

**代码示例**:

✅ **正确做法**:
```dart
Text(
  'Welcome',
  style: AppTextStyles.title2,  // 使用标准样式
)

// 需要修改颜色时
Text(
  'Username',
  style: AppTextStyles.body.copyWith(
    color: AppColors.primary,
  ),
)
```

❌ **错误做法**:
```dart
// 禁止使用硬编码 fontSize
Text(
  'Welcome',
  style: TextStyle(
    fontSize: 24,  // ❌ 应使用 AppTextStyles.title2
    fontWeight: FontWeight.bold,
  ),
)
```

**AI 开发注意事项**:
> 在使用 AI 工具（如 Cursor、GitHub Copilot）生成代码时，必须严格遵守以上规范。AI 生成的代码如包含自定义 fontSize，必须替换为标准 AppTextStyles。

### 国际化 (Internationalization) - MANDATORY ⚠️

**核心原则**:
- ✅ **必须使用** `AppLocalizations.of(context)!.*` 获取所有用户可见文字
- ❌ **禁止使用** 硬编码字符串 (如 `Text('Login')`)
- 📝 **新增文字** 必须先在 ARB 文件中定义，再使用

#### 支持的语言
- 中文 (zh_CN)
- English (en_US)

#### 使用方法

**基本用法**:
```dart
// ✅ 正确 - 使用 AppLocalizations
final l10n = AppLocalizations.of(context)!;
Text(l10n.login)
```

**错误示例**:
```dart
// ❌ 错误 - 禁止硬编码
Text('Login')  // 应使用 l10n.login
Text('个人资料')  // 应使用 l10n.profile
```

#### 添加新翻译的流程

1. **编辑 ARB 文件**
   - 打开 `lib/l10n/app_en.arb`
   - 添加新的 key-value 对和描述
   - 打开 `lib/l10n/app_zh.arb`
   - 添加对应的中文翻译

2. **生成翻译代码**
   ```bash
   flutter gen-l10n
   # 或运行
   flutter pub get
   ```

3. **在代码中使用**
   ```dart
   final l10n = AppLocalizations.of(context)!;
   Text(l10n.yourNewKey)
   ```

#### 命名规范

**Key 命名规则**:
- 使用 camelCase
- 使用功能前缀 (如 `auth*`, `students*`, `plans*`)
- 描述性且简洁 (2-4 words)

**示例**:
- 页面标题: `plansTitle`, `studentsTitle`
- 按钮: `loginButton`, `cancel`, `confirm`
- 错误消息: `loginFailed`, `loadFailed`
- 占位符: `emailPlaceholder`, `searchPlaceholder`

#### 参数化字符串

当需要动态内容时:
```dart
// ARB 文件定义
{
  "studentCount": "{count} students",
  "@studentCount": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
}

// 代码使用
Text(l10n.studentCount(25))  // "25 students"
```

#### AI 开发注意事项
> 使用 AI 工具生成代码时，必须检查并替换所有硬编码字符串为 `AppLocalizations` 调用。

#### 详细实施指南
完整的国际化实施步骤和文件修改清单请参考：[国际化实施指南](docs/i18n_implementation_guide.md)

### UI组件

组件规范文档待建立。

## 项目结构

```
coachX/
├── coach_x/              # Flutter应用主目录
│   ├── lib/             # Dart源代码
│   ├── android/         # Android平台配置
│   ├── ios/             # iOS平台配置
│   ├── docs/             # 项目文档
│   └── pubspec.yaml     # 依赖配置

## 开发环境设置

### 前置要求
- Flutter SDK (最新稳定版)
- Dart SDK ^3.9.2
- iOS开发: Xcode 14+, CocoaPods
- Android开发: Android Studio, Android SDK

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android
```

## Firebase配置

### 配置文件位置

- **iOS**: `ios/Runner/GoogleService-Info.plist`
- **Android**: `android/app/google-services.json`

⚠️ **注意**: 配置文件包含敏感信息，已在`.gitignore`中排除，请勿提交到公开仓库。

### Firebase服务

| 服务 | 状态 | 说明 |
|------|------|------|
| Authentication | ✅ 已配置 | 邮箱/密码登录 |
| Cloud Firestore | ✅ 已配置 | 测试模式（30天） |
| Firebase Storage | ✅ 已配置 | 测试模式（30天） |
| Cloud Functions | ✅ 已配置 | Python 2nd gen |

### Cloud Functions语言选择

本项目使用 **Python** 作为Cloud Functions的开发语言（Firebase Functions 2nd gen）。

**选择原因**:
- AI集成更便捷（丰富的Python AI库）
- 数据处理能力强
- 团队技术栈匹配

**Functions目录结构实例**:
```
/functions
├── main.py             # 入口文件：导入并暴露所有函数
├── requirements.txt    # 依赖项
├── users/              # 专门处理用户相关的逻辑
│   ├── handlers.py     # 包含用户相关的 Cloud Functions (e.g. `on_user_create`)
│   └── models.py       # 用户数据模型或辅助类
├── payments/           # 专门处理支付相关的逻辑
│   ├── handlers.py     # 包含支付相关的 Cloud Functions (e.g. `on_checkout`)
│   └── services.py     # 支付 API 交互等业务逻辑
└── utils/              # 通用辅助工具
    └── db_helper.py    # 数据库连接、常用查询等
```
