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

### UI组件

组件规范文档待建立。

## 项目结构

```
coachX/
├── coach_x/              # Flutter应用主目录
│   ├── lib/             # Dart源代码
│   ├── android/         # Android平台配置
│   ├── ios/             # iOS平台配置
│   └── pubspec.yaml     # 依赖配置
├── docs/                # 项目文档
│   └── backend_apis_and_document_db_schemas.md  # 后端API与数据库Schema
├── studentUI/           # 学生端UI设计稿（HTML）
├── coachUI/             # 教练端UI设计稿（HTML）
└── commonUI/            # 通用UI设计稿（HTML）
```

## 功能模块

### 学生端功能
- 首页概览（每日打卡、训练计划）
- 训练记录上传
- 饮食记录管理
- 补剂记录跟踪
- 身体数据测量
- 与教练实时对话
- 查看训练计划

### 教练端功能
- 学生管理（列表、详情）
- 创建训练计划
- 创建饮食计划
- 创建补剂计划
- 查看学生训练记录
- 提供训练反馈
- 与学生对话

### AI功能
- AI生成训练计划
- 智能训练建议

## 开发环境设置

### 前置要求
- Flutter SDK (最新稳定版)
- Dart SDK ^3.9.2
- iOS开发: Xcode 14+, CocoaPods
- Android开发: Android Studio, Android SDK

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd coachX/coach_x
```

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

## 后端API

后端API基于Firebase Cloud Functions (Python)实现，详细的API接口和数据库Schema请参考：
- [后端API与数据库Schema文档](../docs/backend_apis_and_document_db_schemas.md)

## 参考资料

- **后端API文档**: [Google Docs](https://docs.google.com/document/d/1yKQgZWjdeALkwrl2SHf6RjUnsCmeLxtoWFrv0Epr7SQ/edit?tab=t.9cl42i828p31)
- **UI设计稿**: 位于 `studentUI/`、`coachUI/`、`commonUI/` 目录

## 项目状态

### 阶段一：基础框架搭建 ✅ 已完成
- ✅ Flutter项目结构搭建完成
- ✅ UI设计稿（HTML原型）已完成
- ✅ 后端API设计文档已完成
- ✅ 核心主题系统（颜色、字体、尺寸）
- ✅ 路由系统（go_router）
- ✅ 状态管理方案（Riverpod）
- ✅ 通用工具类和扩展方法
- ✅ 基础通用组件

### 阶段二：Firebase集成 ✅ 已完成
- ✅ Firebase项目创建和配置
  - 项目名称: coachx-9d219
  - Authentication: 邮箱/密码登录已启用
  - Firestore: 已创建（测试模式，30天有效期）
  - Storage: 已启用（测试模式，30天有效期）
  - Cloud Functions: Python 2nd gen (模块化架构)
  - 配置文件: 已放置到项目中
- ✅ Flutter端Firebase SDK集成
- ✅ Authentication实现
  - AuthService：完整的认证服务
  - Login/Register页面：Cupertino风格UI
  - Profile Setup页面：用户资料完善
  - 状态管理：Riverpod
- ✅ Firestore数据层实现
  - FirestoreService：基础CRUD服务
  - UserModel：扩展用户数据模型（gender, bornDate, height, initialWeight等）
  - UserRepository：仓库模式
  - Gender枚举：性别类型定义
- ✅ Storage文件上传实现
  - StorageService：文件上传服务
  - 图片选择和压缩
  - 分类存储（头像、训练、饮食等）
- ✅ Cloud Functions开发（模块化架构）
  - users/: 用户管理模块
  - invitations/: 邀请码系统模块
  - utils/: 通用工具模块
  - Firebase Auth触发器：自动创建Firestore用户文档
  - Firestore触发器：用户创建后续处理
- ✅ 完整用户注册流程
  - 注册 → Profile Setup → 角色选择 → 信息完善 → 对应首页
- ✅ 代码优化和格式化

### 阶段三：核心功能开发 🔄 进行中
- ✅ 教练首页完整实现
  - Summary统计信息展示
  - Event Reminder事件提醒
  - Recent Activity最近活跃学生
- ✅ 教练端底部导航（CupertinoTabScaffold）
  - 5个Tab: Home, Students, Plans, Chat, Profile
  - Tab状态保持
- ✅ 学生端底部导航（CupertinoTabScaffold）
  - 5个Tab: Home, Plan, Add(突出), Chat, Profile
  - Add按钮ActionSheet
- ✅ 路由架构调整（支持Tab导航）
- ✅ 数据模型设计
  - EventReminderModel
  - CoachSummaryModel
  - RecentActivityModel
- ✅ Mock数据Provider实现
- ⏳ 学生端训练记录功能
- ⏳ 教练端计划管理功能
- ⏳ 实时对话功能
- ⏳ 数据API对接

## 快速开始

### 前置要求
- Flutter SDK (3.19.0+)
- Dart SDK (3.9.2+)
- Firebase CLI (可选，用于Functions部署)
- iOS开发: Xcode 14+, CocoaPods
- Android开发: Android Studio, Android SDK (minSdk 21)

### 运行应用

1. **安装依赖**
```bash
flutter pub get
```

2. **运行应用**
```bash
# iOS模拟器
flutter run -d ios

# Android模拟器/设备
flutter run -d android
```

### 部署Cloud Functions

```bash
cd functions
pip install -r requirements.txt
firebase deploy --only functions
```

## 核心技术栈

### 前端
- **UI框架**: Flutter + Cupertino Design
- **状态管理**: Riverpod
- **路由**: go_router  
- **本地存储**: Hive + SharedPreferences
- **网络**: Dio

### 后端
- **云函数**: Firebase Cloud Functions (Python)
- **数据库**: Cloud Firestore
- **存储**: Firebase Storage
- **认证**: Firebase Authentication

## 项目统计

- **代码文件**: 70+ Dart files, 6 Python files
- **代码行数**: ~6500+ lines
- **Services**: 6个核心服务
- **Models**: 4个数据模型
- **Pages**: 11个页面（1个完整实现+10个占位）
- **Features**: 教练首页和Tab导航完整实现
- **Git提交**: 15+ commits

## 版本信息

- **当前版本**: 1.0.0+1
- **最后更新**: 2025-10-21

## TODO文档

所有待实现功能已汇总至 [docs/todos.md](../docs/todos.md)，包括：
- 数据层API对接
- UI层跳转实现
- Chat功能实现
- 计划管理功能
- 训练记录功能
- 性能和体验优化

详细请查阅TODO文档。

