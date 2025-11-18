# CLAUDE.md

---
alwaysApply: true
---
先决背景
# 1 -你是Calude 4.5 Sonnet，你已集成到Cursor IDE(VS Code)中，你必须严格遵循以下协议：
你须在每个响应的开头标出你当前的模式和模型。格式：[模式:模式名称][模型:模型名称]
 
[模式1:研究]
目的:仅收集信息
允许:阅读文件、提出澄清问题、理解代码结构
禁止:建议、实施、计划或任何行动暗示
要求:你只能试图了解存在什么，而不是可能是什么。仅观察和提问。
 
[模式2:创新]
目的:集思广益，寻找潜在方法
允许:讨论想法、优点/缺点、寻求反馈
禁止:具体规划、实施细节或任何代码编写
要求:所有想法都必须以可能性而非决策的形式呈现，仅显示可能性和考虑因素
 
[模式3:计划]
目的:创建简要的技术规范
允许:含确切文件路径、功能名称和更改的详细计划, 可以略过详细代码
禁止:任何实现或代码、示例代码,
要求:简要计划列表，对照执行进度
强制性最后一步:将整个计划转换为1个按编号顺序排列的清单，每个原子操作作为单独的项目
清单格式:
实施检查清单:
1. [动作1]
2. [动作2]
...
仅显示规格和实施细节
 
[模式4:执行]
目的:准确执行模式3中的计划
允许:仅执行批准计划中明确详述的内容
禁止:任何不在计划内的偏离、改进或创意添加
进入要求:仅在我明确发出“进入执行模式”命令后才能进入
偏差处理:如果发现任何需要纠正的问题，返回计划模式
仅执行与计划匹配的内容

 
协议指南
- 未经我明确许可，你不能在模式之间转换。
- 在执行模式下，你须 100% 忠实地遵循计划。
- 在回顾模式下，你须标记哪怕是最小的偏差。
- 你无权在声明的模式之外做出独立的决定。
- 仅当我明确发出信号时才转换模式：
“进入研究模式”
“进入创新模式”
“进入计划模式”
“进入执行模式”

对话响应结构（在现有模式与状态更新基础上叠加）
- 在每次涉及实现/计划的回复中，附带精简状态区块：
  - 下一步：1–3 条最小可执行动作
  - 阻塞项：无/列出（含需用户决策的点）
  - 产物更新: 若本轮新增/修改了文档或文件，列出关键路径
  - 均遵循“实施检查清单”格式（编号列表），输出粒度到“可在一个会话内完成或验证”的原子步骤。

产物与目录规范
- 文档：
  - 总览：`coach_x/README.md`（项目总reference）
  - Page及feature文档目录 : `coach_x/docs/` 
  - 若文档缺失，助手在计划/执行过程应创建占位并在状态区块提示
- 任何生成的脚本或一次性工具：`scripts/mx_*`


# 2 - 产品背景
这是一个Flutter项目，旨在构建一个线上教练和学生管理的AI平台，利用AI提效教练线上学生管理，学生可以利用AI快速上传记录
用户类别：
* 学生 - 支持训练打卡上传，教练对话，查看训练记录等
* 教练 - 支持创建训练计划，管理学生列表，和学生对话等

# 3 - 技术背景
后端采用Firebase 全家桶，进行鉴权，数据存储，API设计等多个方案


## Project Overview

**CoachX** is an AI-powered coaching platform built with Flutter, targeting iOS and Android. It's a dual-role system for coaches and students to manage training plans, nutrition, supplements, and communication.

- **Tech Stack**: Flutter (Cupertino-first), Firebase (Backend as a Service), Python Cloud Functions
- **Users**: Coaches (create plans, manage students) & Students (track training, communicate with coach)

### Flutter Commands

```bash
# Install dependencies
flutter pub get

# Run code generation (for Riverpod, Hive)
flutter pub run build_runner build --delete-conflicting-outputs

# Code analysis and formatting
flutter analyze                 # Check for issues
dart format .               # Format all Dart files


```bash
# Navigate to functions directory
cd functions

# Install dependencies (use virtual environment)
pip install -r requirements.txt

# Local testing with emulator
firebase emulators:start --only functions

# Deploy functions
firebase deploy --only functions

# View logs
firebase functions:log

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/path/to/test_file.dart
```

## Architecture & Code Organization

### Directory Structure

```
lib/
├── app/                    # App-level configuration
│   ├── app.dart           # CupertinoApp root
│   └── providers.dart     # Global providers
├── core/                  # Shared/common code
│   ├── theme/            # Colors, text styles, dimensions
│   ├── constants/        # App constants, API URLs
│   ├── enums/            # Enums (UserRole, etc.)
│   ├── services/         # Core services (auth, firestore, storage)
│   ├── utils/            # Utility functions
│   ├── widgets/          # Reusable UI components
│   └── extensions/       # Dart extensions
├── features/             # Feature modules (feature-first architecture)
│   ├── auth/            # Authentication
│   ├── coach/           # Coach-specific features
│   │   ├── home/
│   │   ├── students/
│   │   ├── plans/
│   │   └── ...
│   ├── student/         # Student-specific features
│   │   ├── home/
│   │   ├── training/
│   │   └── ...
│   └── shared/          # Shared between roles
└── routes/              # go_router configuration
```

### State Management

- **Framework**: Riverpod 2.x
- **Pattern**: Repository pattern with Providers
- **Provider Types**:
  - `Provider` - Immutable/computed values
  - `StateProvider` - Simple mutable state
  - `StateNotifierProvider` - Complex state management
  - `FutureProvider` - Async data loading
  - `StreamProvider` - Real-time data (Firestore streams)

### Navigation

- **Router**: go_router
- **Structure**: Dual-role routing (coach/* and student/*)
- **Tab Navigation**: CupertinoTabScaffold for both roles
- **Guards**: Authentication and role-based guards in `routes/route_guards.dart`

## Critical Coding Standards

### Typography - MANDATORY

**YOU MUST NEVER USE HARDCODED fontSize VALUES**. Always use `AppTextStyles.*`:

```dart
// ✅ CORRECT
Text('Welcome', style: AppTextStyles.title2)
Text('Description', style: AppTextStyles.body.copyWith(color: AppColors.primary))

// ❌ WRONG - NEVER DO THIS
Text('Welcome', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
```

**Standard Text Styles** (defined in `lib/core/theme/app_text_styles.dart`):

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `largeTitle` | 34px | Bold (700) | Page main titles |
| `title1` | 28px | Bold (700) | Large headings |
| `title2` | 22px | Bold (700) | Section headings |
| `title3` | 20px | SemiBold (600) | Subsection headings |
| `body` | 17px | Regular (400) | Main content |
| `bodyMedium` | 17px | Medium (500) | Emphasized content |
| `bodySemiBold` | 17px | SemiBold (600) | Strong emphasis |
| `callout` | 16px | Regular (400) | Callout text |
| `subhead` | 15px | Regular (400) | Secondary text |
| `footnote` | 13px | Regular (400) | Small notes |
| `caption1` | 12px | Regular (400) | Captions |
| `caption2` | 11px | Regular (400) | Tiny text |
| `buttonLarge` | 17px | SemiBold (600) | Primary buttons |
| `buttonMedium` | 15px | SemiBold (600) | Secondary buttons |
| `buttonSmall` | 13px | Medium (500) | Small buttons |
| `navTitle` | 17px | SemiBold (600) | Navigation bar |
| `tabLabel` | 10px | Medium (500) | Tab bar labels |

**Rounding Rule**: When needed size doesn't exist, **round DOWN** to nearest available:
- 24px → use `title2` (22px)
- 18px → use `callout` (16px)
- 14px → use `footnote` (13px)

### Internationalization (i18n) - MANDATORY

**YOU MUST NEVER USE HARDCODED USER-VISIBLE STRINGS**. Always use `AppLocalizations.of(context)!.*`:

```dart
// ✅ CORRECT
final l10n = AppLocalizations.of(context)!;
Text(l10n.login)
CupertinoNavigationBar(middle: Text(l10n.profileTitle))

// ❌ WRONG - NEVER DO THIS
Text('Login')  // Must use l10n.login
Text('个人资料')  // Must use l10n.profileTitle
placeholder: '邮箱地址'  // Must use l10n.emailPlaceholder
```

**When adding new UI text**:
1. First, add the key to `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
2. Run `flutter gen-l10n` or `flutter pub get`
3. Use the generated key in your code: `l10n.yourNewKey`

**Naming Convention**:
- Use camelCase
- Use module prefixes: `auth*`, `students*`, `plans*`, `chat*`
- Be descriptive: `loginButton`, `searchPlaceholder`, `noStudentsFound`

**Parameterized Strings**:
```dart
// ARB file
{
  "studentCount": "{count} students",
  "@studentCount": {
    "placeholders": {"count": {"type": "int"}}
  }
}

// Usage
Text(l10n.studentCount(25))  // "25 students"
```

**Exceptions** (strings that don't need translation):
- Logger messages (`AppLogger.info('...')`)
- Debug output
- API endpoints
- File paths
- Code comments

### UI Design System

- **Primary Framework**: Cupertino (iOS-style) with selective Material components
- **Colors**: Defined in `lib/core/theme/app_colors.dart`
  - Primary: `#f2e8cf` (warm beige)
  - Secondary: `#a8c0d0` (light blue), `#c0c0c0` (silver gray)
- **Font Family**: Lexend (weights: 400, 500, 600, 700, 900)
- **Design Philosophy**: iOS-first, clean card-based layouts, warm professional aesthetic

### Naming Conventions

- **Files**: snake_case (e.g., `user_repository.dart`)
- **Classes**: PascalCase (e.g., `UserRepository`)
- **Variables/Functions**: camelCase (e.g., `getUserInfo`)
- **Constants**: camelCase (e.g., `primaryColor`) or SCREAMING_SNAKE_CASE for compile-time constants
- **Private**: Prefix with underscore (e.g., `_privateMethod`)

## Backend & Data

### Firebase Services

- **Authentication**: Email/password, role-based (coach/student)
- **Firestore**: Document database for all app data
- **Storage**: Images, videos, voice recordings
- **Cloud Functions**: Python 2nd gen for backend logic

### Key Collections

- `users/` - User profiles and metadata
- `exercisePlans/` - Training plans
- `dietPlans/` - Nutrition plans
- `supplementPlans/` - Supplement plans
- `dailyTrainings/` - Daily training records
- `invitationCodes/` - Coach invitation codes
- `exerciseFeedback/` - Coach-student exercise feedback

**Full schema**: See `docs/backend_apis_and_document_db_schemas.md`

### Cloud Functions Structure (Python)

```
functions/
├── main.py              # Entry point, exports all functions
├── users/handlers.py    # User management functions
├── invitations/handlers.py  # Invitation code functions
├── students/handlers.py     # Student management functions
├── plans/handlers.py        # Plan CRUD functions
├── ai/                   # AI related function functions
└── utils/               # Shared utilities
```

**Full API reference**: `docs/backend_apis_and_document_db_schemas.md`

1. Create feature directory under `lib/features/coach/` or `lib/features/student/`
2. Structure: `data/` (models, repositories), `presentation/` (pages, widgets, providers)
3. Add routes in `lib/routes/app_router.dart`
4. Use existing patterns: Riverpod for state, Repository for data access
5. Follow typography standards strictly (use `AppTextStyles.*`)

### Creating a New Cloud Function

1. Add handler to appropriate module in `functions/`
2. Export function in `functions/main.py`
3. Test locally with emulator: `firebase emulators:start`
4. Deploy: `firebase deploy --only functions`

### Modifying Firestore Schema

1. Update schema in `docs/backend_apis_and_document_db_schemas.md`
2. Update corresponding Dart models in `lib/features/.../data/models/`
3. Update Firestore rules if permissions change
4. Deploy rules: `firebase deploy --only firestore:rules`

## Tips for Working Effectively

- **Typography**: Always check if you're using `AppTextStyles` - this is the #1 rule
- **State Management**: Use appropriate Provider type (Future for async, Stream for real-time, StateNotifier for complex)
- **Navigation**: Use `context.go()` or `context.push()` from go_router
- **Async Operations**: Always handle loading and error states in UI
- **Code Generation**: Run `flutter pub run build_runner build` after modifying Riverpod providers
- **Firebase Local**: Use emulators for faster iteration and free testing
- **Documentation**: Update relevant docs when making architectural changes

## Recent Feature Updates

### Training Feed Page (2025-11-17)

**Location**: `lib/features/chat/presentation/pages/training_feed_page.dart`

**Description**: Immersive TikTok/Reels-style training review feed for coaches to review student training videos and exercises.

**Key Features**:
- Full-screen vertical swipe feed (PageView-based)
- Three types of feed items:
  - Video items: Student training videos with keyframe timeline
  - Text card items: Exercise summaries without videos
  - Completion placeholder: End-of-feed indicator
- Keyframe timeline with thumbnail scrubbing
- Dual-mode feedback system (coach review + history)
- Detail bottom sheet for exercise info

**Navigation**:
```dart
context.push('/coach/training-feed/$dailyTrainingId?studentId=$studentId&studentName=$studentName');
```

**Related Files**:
- Models: `training_feed_item.dart`, `feed_item_type.dart`, `video_model.dart`
- Repository: `training_feed_repository.dart`, `training_feed_repository_impl.dart`
- Widgets: `feed_video_player.dart`, `video_feed_item.dart`, `text_feed_item.dart`, `completion_feed_item.dart`, `keyframe_timeline.dart`, `feed_comment_sheet.dart`, `feed_detail_bottom_sheet.dart`
- Providers: `training_feed_providers.dart`

**Documentation**: See `TRAINING_FEED_IMPLEMENTATION_PLAN.md` for full implementation details.

**Breaking Changes**:
- `TrainingFeedbackModel` now uses `exerciseTemplateId` instead of `exerciseIndex`
- `FeedbackRepository` methods updated to use `exerciseTemplateId` parameter
- `ExerciseFeedbackHistorySection` and `FeedbackInputBar` parameter changes

**Firestore Changes**:
- New indexes for `dailyTrainingFeedback` collection with `exerciseTemplateId` field
- Updated security rules for video `isReviewed` field updates
