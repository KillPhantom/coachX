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
- **架构**: Firebase全家桶（Cloud Functions + Firestore）
- **功能**: 用户鉴权、数据存储、API设计等

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

## 后端API

后端API基于Firebase Cloud Functions实现，详细的API接口和数据库Schema请参考：
- [后端API与数据库Schema文档](../docs/backend_apis_and_document_db_schemas.md)

## 参考资料

- **后端API文档**: [Google Docs](https://docs.google.com/document/d/1yKQgZWjdeALkwrl2SHf6RjUnsCmeLxtoWFrv0Epr7SQ/edit?tab=t.9cl42i828p31)
- **UI设计稿**: 位于 `studentUI/`、`coachUI/`、`commonUI/` 目录

## 项目状态

当前项目处于初始化阶段：
- ✅ Flutter项目结构搭建完成
- ✅ UI设计稿（HTML原型）已完成
- ✅ 后端API设计文档已完成
- 🚧 Flutter UI组件开发中
- 🚧 后端Cloud Functions实现中
- ⏳ Firebase集成待开始
- ⏳ 状态管理方案待确定
- ⏳ API集成待开始

## 版本信息

- **当前版本**: 1.0.0+1
- **最后更新**: 2025-10-19

