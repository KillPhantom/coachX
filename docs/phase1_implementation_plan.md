# CoachX - 阶段一：基础框架搭建 - 实施计划

> **阶段**: 阶段一 - 基础框架搭建  
> **状态**: 计划阶段  
> **创建日期**: 2025-10-19  
> **预估工作量**: 3-5个工作日

---

## 一、阶段目标

建立CoachX项目的基础架构，包括：
1. 完整的项目目录结构
2. 核心依赖包配置
3. Cupertino主题和样式系统
4. 路由框架和导航结构
5. 通用UI组件库
6. 基础工具类和常量定义

**验收标准**:
- 项目可以正常编译运行
- 能够在iOS和Android模拟器上启动
- 路由导航可以正常切换
- 主题色彩正确应用
- 基础组件可以正常展示

---

## 二、目录结构规划

### 2.1 完整目录树

```
coach_x/
├── lib/
│   ├── main.dart                          # 应用入口
│   │
│   ├── app/                               # 应用级配置
│   │   ├── app.dart                       # App根组件
│   │   └── providers.dart                 # 全局Providers
│   │
│   ├── core/                              # 核心共享代码
│   │   ├── theme/                         # 主题配置
│   │   │   ├── app_theme.dart            # 主题配置入口
│   │   │   ├── app_colors.dart           # 颜色定义
│   │   │   ├── app_text_styles.dart      # 文字样式
│   │   │   └── app_dimensions.dart       # 尺寸规范
│   │   │
│   │   ├── constants/                     # 常量定义
│   │   │   ├── app_constants.dart        # 通用常量
│   │   │   ├── storage_keys.dart         # 存储键名
│   │   │   └── api_constants.dart        # API常量
│   │   │
│   │   ├── widgets/                       # 通用组件
│   │   │   ├── cupertino_card.dart       # iOS风格卡片
│   │   │   ├── loading_indicator.dart    # 加载指示器
│   │   │   ├── empty_state.dart          # 空状态页
│   │   │   ├── error_view.dart           # 错误视图
│   │   │   ├── custom_button.dart        # 自定义按钮
│   │   │   └── custom_text_field.dart    # 自定义输入框
│   │   │
│   │   ├── utils/                         # 工具函数
│   │   │   ├── date_utils.dart           # 日期处理
│   │   │   ├── string_utils.dart         # 字符串处理
│   │   │   ├── validation_utils.dart     # 验证工具
│   │   │   └── logger.dart               # 日志工具
│   │   │
│   │   ├── enums/                         # 枚举定义
│   │   │   ├── user_role.dart            # 用户角色
│   │   │   └── app_status.dart           # 应用状态
│   │   │
│   │   └── extensions/                    # 扩展方法
│   │       ├── context_extensions.dart   # BuildContext扩展
│   │       ├── string_extensions.dart    # String扩展
│   │       └── date_extensions.dart      # DateTime扩展
│   │
│   ├── routes/                            # 路由配置
│   │   ├── app_router.dart               # 路由主配置
│   │   ├── route_names.dart              # 路由名称常量
│   │   └── route_guards.dart             # 路由守卫
│   │
│   └── features/                          # 功能模块（占位）
│       ├── auth/                          # 认证模块（后续阶段）
│       ├── student/                       # 学生端（后续阶段）
│       ├── coach/                         # 教练端（后续阶段）
│       └── shared/                        # 共享功能（后续阶段）
│
├── assets/                                # 资源文件
│   ├── fonts/                            # 字体文件
│   │   ├── Lexend-Regular.ttf
│   │   ├── Lexend-Medium.ttf
│   │   ├── Lexend-SemiBold.ttf
│   │   ├── Lexend-Bold.ttf
│   │   └── Lexend-Black.ttf
│   │
│   └── images/                           # 图片资源
│       └── placeholder/                  # 占位图
│           └── empty_state.png
│
├── test/                                 # 测试文件
│   └── widget_test.dart                 # 默认测试（保留）
│
├── pubspec.yaml                          # 依赖配置
├── analysis_options.yaml                 # 分析选项
└── README.md                             # 项目说明
```

### 2.2 目录职责说明

**app/**: 应用级别的配置和初始化
- `app.dart`: CupertinoApp根组件，配置主题、路由等
- `providers.dart`: 全局Riverpod Providers的统一注册

**core/theme/**: 主题和样式系统
- `app_theme.dart`: 导出所有主题相关配置
- `app_colors.dart`: 颜色常量定义（#f2e8cf及配色）
- `app_text_styles.dart`: 文字样式定义（Lexend字体）
- `app_dimensions.dart`: 间距、圆角等尺寸规范

**core/constants/**: 常量管理
- `app_constants.dart`: 应用级常量（名称、版本等）
- `storage_keys.dart`: 本地存储的键名
- `api_constants.dart`: API相关常量（URL、超时等）

**core/widgets/**: 可复用的通用组件
- 所有自定义的iOS风格组件
- 统一的视觉风格

**core/utils/**: 工具函数集合
- 日期、字符串、验证等通用功能
- 日志工具

**core/enums/**: 枚举类型定义
- 用户角色（学生/教练）
- 各种状态枚举

**core/extensions/**: Dart扩展方法
- 简化常用操作
- 增强代码可读性

**routes/**: 路由系统
- `app_router.dart`: go_router配置
- `route_names.dart`: 路由路径常量
- `route_guards.dart`: 权限守卫逻辑

**features/**: 功能模块（本阶段仅创建占位目录）

---

## 三、依赖包配置

### 3.1 pubspec.yaml 修改规格

**需要添加的dependencies**:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI组件
  cupertino_icons: ^1.0.8
  
  # 状态管理
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # 路由导航
  go_router: ^13.0.0
  
  # 本地存储
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # 网络请求（为后续准备）
  dio: ^5.4.0
  
  # 工具类
  intl: ^0.19.0          # 日期格式化
  logger: ^2.0.2         # 日志
  
  # Firebase（本阶段仅添加，不配置）
  firebase_core: ^2.24.2
```

**需要添加的dev_dependencies**:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  
  # 代码生成
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  hive_generator: ^2.0.1
  
  # 测试相关
  mockito: ^5.4.4
```

**需要配置的fonts**:

```yaml
flutter:
  uses-material-design: true
  
  fonts:
    - family: Lexend
      fonts:
        - asset: assets/fonts/Lexend-Regular.ttf
          weight: 400
        - asset: assets/fonts/Lexend-Medium.ttf
          weight: 500
        - asset: assets/fonts/Lexend-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Lexend-Bold.ttf
          weight: 700
        - asset: assets/fonts/Lexend-Black.ttf
          weight: 900
```

### 3.2 字体文件准备

需要下载Lexend字体文件并放置到 `assets/fonts/` 目录：
- 来源: Google Fonts (https://fonts.google.com/specimen/Lexend)
- 格式: TTF
- 字重: 400, 500, 600, 700, 900

---

## 四、主题系统规格

### 4.1 颜色系统 (app_colors.dart)

**需要定义的颜色常量**:

```
主色系:
- primaryColor: Color(0xFFF2E8CF)           # 主色调
- primaryText: Color(0xFF8C7A51)            # 主色文字
- primaryLight: Color(0xFFFDFAF3)           # 主色浅色背景
- primaryAction: Color(0xFFE6D7B4)          # 主色交互

辅助色系:
- secondaryBlue: Color(0xFFA8C0D0)          # 辅助蓝
- secondaryGrey: Color(0xFFC0C0C0)          # 辅助灰
- secondaryDarkGrey: Color(0xFF7F8C8D)      # 深灰蓝
- secondaryMediumGrey: Color(0xFF95A5A6)    # 中灰

文字颜色:
- textPrimary: Color(0xFF1F2937)            # 主要文字
- textSecondary: Color(0xFF6B7280)          # 次要文字
- textTertiary: Color(0xFF9CA3AF)           # 三级文字
- textWhite: Color(0xFFFFFFFF)              # 白色文字

背景颜色:
- backgroundLight: Color(0xFFF7F7F7)        # 浅色背景
- backgroundWhite: Color(0xFFFFFFFF)        # 白色背景
- backgroundCard: Color(0xFFFFFFFF)         # 卡片背景

功能色:
- successGreen: Color(0xFF10B981)           # 成功/完成
- warningYellow: Color(0xFFF59E0B)          # 警告
- errorRed: Color(0xFFEF4444)               # 错误
- infoBlue: Color(0xFF3B82F6)               # 信息

分割线:
- dividerLight: Color(0xFFE5E7EB)           # 浅色分割线
- dividerMedium: Color(0xFFD1D5DB)          # 中度分割线
```

**组织方式**:
- 使用类常量管理
- 分组注释清晰
- 提供语义化的命名

### 4.2 文字样式系统 (app_text_styles.dart)

**需要定义的文字样式**:

```
标题样式:
- largeTitle: 34px, Bold (700), textPrimary
- title1: 28px, Bold (700), textPrimary
- title2: 22px, Bold (700), textPrimary
- title3: 20px, SemiBold (600), textPrimary

正文样式:
- body: 17px, Regular (400), textPrimary
- bodyMedium: 17px, Medium (500), textPrimary
- bodySemiBold: 17px, SemiBold (600), textPrimary
- callout: 16px, Regular (400), textPrimary

辅助样式:
- subhead: 15px, Regular (400), textSecondary
- footnote: 13px, Regular (400), textSecondary
- caption1: 12px, Regular (400), textTertiary
- caption2: 11px, Regular (400), textTertiary

按钮样式:
- buttonLarge: 17px, SemiBold (600)
- buttonMedium: 15px, SemiBold (600)
- buttonSmall: 13px, Medium (500)
```

**实现要求**:
- 使用TextStyle定义
- 统一使用Lexend字体
- 提供便捷的访问方法

### 4.3 尺寸规范 (app_dimensions.dart)

**需要定义的尺寸常量**:

```
间距:
- spacingXS: 4.0
- spacingS: 8.0
- spacingM: 12.0
- spacingL: 16.0
- spacingXL: 20.0
- spacingXXL: 24.0
- spacingXXXL: 32.0

圆角:
- radiusS: 4.0       # 小圆角
- radiusM: 8.0       # 中圆角
- radiusL: 12.0      # 大圆角
- radiusXL: 16.0     # 超大圆角
- radiusFull: 999.0  # 完全圆角

阴影:
- elevationS: 2.0
- elevationM: 4.0
- elevationL: 8.0

图标大小:
- iconS: 16.0
- iconM: 20.0
- iconL: 24.0
- iconXL: 32.0

按钮高度:
- buttonHeightS: 36.0
- buttonHeightM: 44.0
- buttonHeightL: 52.0

导航栏高度:
- navBarHeight: 44.0
- tabBarHeight: 50.0
```

### 4.4 主题配置 (app_theme.dart)

**CupertinoThemeData配置规格**:

```
需要配置的属性:
- primaryColor: AppColors.primaryColor
- primaryContrastingColor: AppColors.primaryText
- scaffoldBackgroundColor: AppColors.backgroundLight
- barBackgroundColor: AppColors.backgroundWhite.withOpacity(0.9)

textTheme配置:
- textStyle: 使用Lexend字体
- actionTextStyle: 按钮文字样式
- navTitleTextStyle: 导航栏标题样式
- navLargeTitleTextStyle: 大标题样式
- tabLabelTextStyle: Tab标签样式

其他配置:
- 导航栏样式
- Tab栏样式
- 按钮样式
```

**导出结构**:
- 提供统一的主题获取方法
- 支持后期扩展深色模式

---

## 五、路由系统规格

### 5.1 路由名称定义 (route_names.dart)

**需要定义的路由常量**:

```
根路由:
- splash: '/'
- login: '/login'

学生端路由:
- studentHome: '/student/home'
- studentPlan: '/student/plan'
- studentTraining: '/student/training'
- studentChat: '/student/chat'
- studentProfile: '/student/profile'

教练端路由:
- coachHome: '/coach/home'
- coachStudents: '/coach/students'
- coachPlans: '/coach/plans'
- coachChat: '/coach/chat'
- coachProfile: '/coach/profile'

共享路由:
- planDetail: '/plan/:id'
- trainingDetail: '/training/:id'
```

### 5.2 路由配置 (app_router.dart)

**go_router配置规格**:

```
需要配置的路由表:
1. 根路由配置
   - path: '/'
   - 重定向到login或对应首页（根据登录状态）

2. 登录路由
   - path: '/login'
   - 展示登录页面（占位页）

3. 学生端路由组
   - 父路由: '/student'
   - 子路由: home, plan, training, chat, profile
   - 使用CupertinoTabScaffold

4. 教练端路由组
   - 父路由: '/coach'
   - 子路由: home, students, plans, chat, profile
   - 使用CupertinoTabScaffold

5. 共享路由
   - 动态路由参数处理
   - 页面过渡动画
```

**路由配置选项**:
- initialLocation: '/'
- debugLogDiagnostics: true (开发模式)
- errorBuilder: 统一错误页面
- redirect: 重定向逻辑

### 5.3 路由守卫 (route_guards.dart)

**需要实现的守卫逻辑**:

```
认证守卫:
- 检查用户是否登录
- 未登录重定向到登录页

角色守卫:
- 检查用户角色
- 学生只能访问学生端路由
- 教练只能访问教练端路由

路由拦截器:
- before: 路由跳转前的检查
- after: 路由跳转后的处理
```

**本阶段实现**:
- 提供守卫框架结构
- 实现基础的路由拦截逻辑
- 认证逻辑留空（返回true），待后续实现

---

## 六、通用组件规格

### 6.1 CupertinoCard (cupertino_card.dart)

**组件功能**:
- iOS风格的卡片容器
- 白色背景、圆角、轻微阴影
- 可配置的padding和margin

**属性规格**:
- child: Widget（必需）
- padding: EdgeInsets（默认16.0）
- margin: EdgeInsets（默认0）
- borderRadius: double（默认12.0）
- backgroundColor: Color（默认白色）
- onTap: VoidCallback?（可选，点击事件）

**视觉规格**:
- 背景色: AppColors.backgroundCard
- 圆角: AppDimensions.radiusL
- 阴影: 轻微灰色阴影，offset(0, 2)，blur 8

### 6.2 LoadingIndicator (loading_indicator.dart)

**组件功能**:
- iOS风格的加载指示器
- 居中显示
- 可配置颜色和大小

**属性规格**:
- color: Color（默认primaryColor）
- size: double（默认32.0）
- text: String?（可选加载文字）

**实现要求**:
- 使用CupertinoActivityIndicator
- 文字显示在指示器下方
- 整体垂直居中

### 6.3 EmptyState (empty_state.dart)

**组件功能**:
- 空状态展示
- 图标、文字、按钮组合

**属性规格**:
- icon: IconData（必需）
- title: String（必需）
- message: String?（可选）
- actionText: String?（可选按钮文字）
- onAction: VoidCallback?（可选按钮回调）

**视觉规格**:
- 垂直居中布局
- 图标大小: 64.0
- 标题: title2样式
- 描述: subhead样式
- 按钮: 主色调按钮

### 6.4 ErrorView (error_view.dart)

**组件功能**:
- 错误状态展示
- 提供重试功能

**属性规格**:
- error: String（必需）
- onRetry: VoidCallback（必需）
- icon: IconData（默认错误图标）

**视觉规格**:
- 红色图标
- 错误信息文字
- 重试按钮

### 6.5 CustomButton (custom_button.dart)

**组件功能**:
- 统一样式的按钮组件
- 支持主要、次要、文字按钮

**属性规格**:
- text: String（必需）
- onPressed: VoidCallback（必需）
- type: ButtonType枚举（primary/secondary/text）
- size: ButtonSize枚举（small/medium/large）
- isLoading: bool（默认false）
- fullWidth: bool（默认false）

**ButtonType样式**:
- primary: 主色背景，白色文字
- secondary: 白色背景，主色边框和文字
- text: 透明背景，主色文字

**ButtonSize尺寸**:
- small: height 36.0, fontSize 13
- medium: height 44.0, fontSize 15
- large: height 52.0, fontSize 17

### 6.6 CustomTextField (custom_text_field.dart)

**组件功能**:
- iOS风格的输入框
- 统一的样式和验证

**属性规格**:
- controller: TextEditingController（必需）
- placeholder: String（必需）
- prefix: Widget?（可选前缀图标）
- suffix: Widget?（可选后缀图标）
- isPassword: bool（默认false）
- keyboardType: TextInputType（默认text）
- validator: String? Function(String?)?（可选验证）
- maxLines: int（默认1）

**视觉规格**:
- 背景色: 白色
- 边框: 浅灰色，1px
- 圆角: radiusM
- padding: 垂直12，水平16
- 聚焦时边框: 主色调

---

## 七、工具类规格

### 7.1 DateUtils (date_utils.dart)

**需要实现的方法**:
```
- formatDate(DateTime): String           # 格式化日期 yyyy-MM-dd
- formatTime(DateTime): String           # 格式化时间 HH:mm
- formatDateTime(DateTime): String       # 格式化日期时间
- isToday(DateTime): bool                # 判断是否今天
- isYesterday(DateTime): bool            # 判断是否昨天
- getWeekday(DateTime): String           # 获取星期几
- getDaysDifference(DateTime, DateTime): int  # 计算天数差
```

### 7.2 StringUtils (string_utils.dart)

**需要实现的方法**:
```
- isEmpty(String?): bool                 # 判断字符串为空
- isEmail(String): bool                  # 验证邮箱格式
- isPhoneNumber(String): bool            # 验证手机号
- truncate(String, int): String          # 截断字符串
- capitalize(String): String             # 首字母大写
```

### 7.3 ValidationUtils (validation_utils.dart)

**需要实现的方法**:
```
- validateEmail(String?): String?        # 邮箱验证
- validatePhone(String?): String?        # 手机号验证
- validatePassword(String?): String?     # 密码强度验证
- validateRequired(String?): String?     # 必填验证
- validateLength(String?, int, int): String?  # 长度验证
```

### 7.4 Logger (logger.dart)

**需要实现的功能**:
```
- debug(String message): void            # 调试日志
- info(String message): void             # 信息日志
- warning(String message): void          # 警告日志
- error(String message, [error, stackTrace]): void  # 错误日志
```

**实现要求**:
- 使用logger包
- Debug模式显示详细日志
- Release模式仅记录错误
- 格式化输出便于阅读

---

## 八、枚举定义规格

### 8.1 UserRole (user_role.dart)

**枚举值**:
```
enum UserRole {
  student,   // 学生
  coach,     // 教练
}

扩展方法:
- displayName: String         # 显示名称（中文）
- isStudent: bool            # 是否学生
- isCoach: bool              # 是否教练
```

### 8.2 AppStatus (app_status.dart)

**枚举值**:
```
enum LoadingStatus {
  initial,    // 初始状态
  loading,    // 加载中
  success,    // 成功
  error,      # 错误
}

enum NetworkStatus {
  online,     // 在线
  offline,    // 离线
}
```

---

## 九、扩展方法规格

### 9.1 ContextExtensions (context_extensions.dart)

**需要实现的扩展**:
```
- mediaQuery: MediaQueryData           # 快速访问MediaQuery
- screenWidth: double                  # 屏幕宽度
- screenHeight: double                 # 屏幕高度
- theme: CupertinoThemeData           # 快速访问主题
- textTheme: CupertinoTextThemeData   # 快速访问文字主题
- showSnackBar(String): void          # 显示提示
- push(Widget): void                  # 页面跳转
- pop(): void                         # 返回
```

### 9.2 StringExtensions (string_extensions.dart)

**需要实现的扩展**:
```
- isNotNullOrEmpty: bool              # 非空判断
- capitalize: String                  # 首字母大写
- toDate(): DateTime?                 # 转换为日期
```

### 9.3 DateExtensions (date_extensions.dart)

**需要实现的扩展**:
```
- format(String pattern): String      # 格式化
- isToday: bool                       # 是否今天
- isSameDay(DateTime): bool          # 是否同一天
```

---

## 十、应用入口配置

### 10.1 main.dart 规格

**主要职责**:
1. 初始化Riverpod（ProviderScope）
2. 初始化Hive
3. 初始化SharedPreferences
4. 初始化Logger
5. 运行App

**结构**:
```
main() async:
  - WidgetsFlutterBinding.ensureInitialized()
  - 初始化Hive
  - 初始化SharedPreferences
  - 初始化Logger
  - runApp(ProviderScope(child: CoachXApp()))
```

### 10.2 app/app.dart 规格

**CoachXApp组件配置**:
```
使用CupertinoApp.router:
- title: 'CoachX'
- theme: AppTheme.lightTheme
- routerConfig: appRouter
- locale: Locale('zh', 'CN')
- debugShowCheckedModeBanner: false
```

### 10.3 app/providers.dart 规格

**本阶段Providers**:
```
- routerProvider: go_router实例
- themeProvider: 主题配置（预留）
- loggerProvider: 日志实例
```

---

## 十一、占位页面

为了验证路由系统，需要创建简单的占位页面：

### 11.1 需要创建的占位页面

**登录页占位**:
- 路径: features/auth/presentation/pages/login_page.dart
- 内容: 简单文字"登录页面 - 待实现"

**学生端占位页面**:
- features/student/home/presentation/pages/student_home_page.dart
- features/student/training/presentation/pages/training_page.dart
- features/student/chat/presentation/pages/student_chat_page.dart
- features/student/profile/presentation/pages/student_profile_page.dart

**教练端占位页面**:
- features/coach/home/presentation/pages/coach_home_page.dart
- features/coach/students/presentation/pages/students_page.dart
- features/coach/plans/presentation/pages/plans_page.dart
- features/coach/chat/presentation/pages/coach_chat_page.dart
- features/coach/profile/presentation/pages/coach_profile_page.dart

**占位页面规格**:
- 使用CupertinoPageScaffold
- 显示页面标题
- 显示"待实现"提示
- 包含简单的导航栏

---

## 十二、测试验证

### 12.1 编译测试

**验证项**:
- iOS模拟器编译通过
- Android模拟器编译通过
- 无编译错误和警告

### 12.2 功能测试

**验证项**:
- 应用可以正常启动
- 主题颜色正确显示
- 字体正确应用
- 路由可以正常跳转（手动修改initialLocation测试）
- 各占位页面可以正常显示

### 12.3 组件测试

**验证项**:
- CupertinoCard正常显示
- LoadingIndicator动画正常
- EmptyState布局正确
- CustomButton各种类型正常
- CustomTextField输入正常

---

## 十三、文档更新

### 13.1 需要更新的文档

**README.md更新**:
- 添加项目结构说明
- 添加开发环境配置步骤
- 添加运行说明

**创建新文档**:
- docs/coding_standards.md: 代码规范文档
- docs/component_guide.md: 组件使用指南

---

## 十四、实施检查清单

按顺序执行以下任务，每完成一项打勾：

### 第一步：环境准备
1. 备份当前项目代码
2. 创建新的Git分支 `feature/phase1-foundation`
3. 下载Lexend字体文件（5个字重）
4. 创建 `assets/fonts/` 目录
5. 放置字体文件到fonts目录

### 第二步：依赖配置
6. 修改 `pubspec.yaml` 添加所有依赖包
7. 配置字体资源
8. 运行 `flutter pub get` 安装依赖
9. 验证依赖安装成功

### 第三步：目录结构创建
10. 创建 `lib/app/` 目录及占位文件
11. 创建 `lib/core/theme/` 目录
12. 创建 `lib/core/constants/` 目录
13. 创建 `lib/core/widgets/` 目录
14. 创建 `lib/core/utils/` 目录
15. 创建 `lib/core/enums/` 目录
16. 创建 `lib/core/extensions/` 目录
17. 创建 `lib/routes/` 目录
18. 创建 `lib/features/auth/` 占位目录结构
19. 创建 `lib/features/student/` 占位目录结构
20. 创建 `lib/features/coach/` 占位目录结构
21. 创建 `lib/features/shared/` 占位目录

### 第四步：主题系统实现
22. 实现 `core/theme/app_colors.dart` 颜色定义
23. 实现 `core/theme/app_text_styles.dart` 文字样式
24. 实现 `core/theme/app_dimensions.dart` 尺寸规范
25. 实现 `core/theme/app_theme.dart` 主题配置
26. 验证主题导出正确

### 第五步：常量定义
27. 实现 `core/constants/app_constants.dart`
28. 实现 `core/constants/storage_keys.dart`
29. 实现 `core/constants/api_constants.dart`

### 第六步：枚举定义
30. 实现 `core/enums/user_role.dart`
31. 实现 `core/enums/app_status.dart`

### 第七步：工具类实现
32. 实现 `core/utils/date_utils.dart`
33. 实现 `core/utils/string_utils.dart`
34. 实现 `core/utils/validation_utils.dart`
35. 实现 `core/utils/logger.dart`

### 第八步：扩展方法实现
36. 实现 `core/extensions/context_extensions.dart`
37. 实现 `core/extensions/string_extensions.dart`
38. 实现 `core/extensions/date_extensions.dart`

### 第九步：路由系统实现
39. 实现 `routes/route_names.dart` 路由常量
40. 实现 `routes/route_guards.dart` 路由守卫框架
41. 实现 `routes/app_router.dart` 路由配置
42. 验证路由配置无语法错误

### 第十步：通用组件实现
43. 实现 `core/widgets/cupertino_card.dart`
44. 实现 `core/widgets/loading_indicator.dart`
45. 实现 `core/widgets/empty_state.dart`
46. 实现 `core/widgets/error_view.dart`
47. 实现 `core/widgets/custom_button.dart`
48. 实现 `core/widgets/custom_text_field.dart`

### 第十一步：占位页面创建
49. 创建登录页占位 `features/auth/presentation/pages/login_page.dart`
50. 创建学生首页占位 `features/student/home/presentation/pages/student_home_page.dart`
51. 创建训练页占位 `features/student/training/presentation/pages/training_page.dart`
52. 创建学生对话页占位 `features/student/chat/presentation/pages/student_chat_page.dart`
53. 创建学生资料页占位 `features/student/profile/presentation/pages/student_profile_page.dart`
54. 创建教练首页占位 `features/coach/home/presentation/pages/coach_home_page.dart`
55. 创建学生列表页占位 `features/coach/students/presentation/pages/students_page.dart`
56. 创建计划管理页占位 `features/coach/plans/presentation/pages/plans_page.dart`
57. 创建教练对话页占位 `features/coach/chat/presentation/pages/coach_chat_page.dart`
58. 创建教练资料页占位 `features/coach/profile/presentation/pages/coach_profile_page.dart`

### 第十二步：应用入口配置
59. 实现 `app/providers.dart` 全局Providers
60. 实现 `app/app.dart` App根组件
61. 修改 `main.dart` 应用入口
62. 配置Hive初始化
63. 配置Logger初始化

### 第十三步：编译测试
64. 运行 `flutter analyze` 检查代码
65. 修复所有lint警告和错误
66. iOS模拟器编译测试
67. Android模拟器编译测试
68. 修复编译错误

### 第十四步：功能验证
69. 启动应用验证首页显示
70. 验证主题颜色正确应用
71. 验证Lexend字体正确显示
72. 测试路由跳转（手动修改initialLocation）
73. 验证各占位页面正确显示
74. 测试通用组件显示（创建测试页面）
75. 验证CupertinoCard样式
76. 验证LoadingIndicator动画
77. 验证CustomButton各种状态
78. 验证CustomTextField输入

### 第十五步：代码优化
79. 代码格式化 `flutter format .`
80. 添加必要的代码注释
81. 检查所有导入语句
82. 移除未使用的导入
83. 统一命名规范

### 第十六步：文档更新
84. 更新 `README.md` 项目说明
85. 创建 `docs/coding_standards.md`
86. 创建 `docs/component_guide.md`
87. 更新架构设计文档状态

### 第十七步：Git提交
88. 检查Git状态
89. 添加所有新文件到Git
90. 提交代码到feature分支
91. 推送到远程仓库

### 第十八步：最终验证
92. 完整的启动流程测试
93. 热重载功能测试
94. 内存泄漏初步检查
95. 验收标准检查

---

## 十五、预估工作量

**总工作量**: 3-5个工作日

**详细分解**:
- 环境准备和依赖配置: 0.5天
- 目录结构和框架搭建: 0.5天
- 主题系统实现: 1天
- 路由系统实现: 0.5天
- 通用组件实现: 1.5天
- 工具类和扩展实现: 0.5天
- 占位页面创建: 0.5天
- 测试和验证: 0.5天
- 文档整理: 0.5天

**风险缓冲**: 1天

---

## 十六、验收标准

### 16.1 功能验收

- [x] 应用可以在iOS模拟器正常启动
- [x] 应用可以在Android模拟器正常启动
- [x] 主题颜色#f2e8cf正确应用
- [x] Lexend字体正确显示
- [x] 路由系统可以正常工作
- [x] 所有占位页面可以访问
- [x] 通用组件可以正常使用

### 16.2 代码质量
- [x] 无编译错误
- [x] 无lint警告
- [x] 代码格式规范
- [x] 注释完整清晰
- [x] 文件组织合理

### 16.3 文档完整
- [x] README更新完整
- [x] 代码规范文档创建
- [x] 组件使用指南创建

---

## 十七、下一步计划

阶段一完成后，进入**阶段二：Firebase集成**：
- Firebase项目创建和配置
- Authentication集成
- Firestore数据库设计
- Storage配置
- Cloud Functions框架搭建

---

**文档状态**: 待执行  
**负责人**: 待分配  
**开始日期**: 待定  
**预计完成**: 待定

