# CoachX 架构设计文档

> **文档状态**: 架构设计方案（创新阶段产出）  
> **创建日期**: 2025-10-19  
> **最后更新**: 2025-10-19

## 一、项目概览

### 1.1 项目定位
- **项目名称**: CoachX - AI教练学生管理平台
- **项目类型**: Flutter跨平台移动应用
- **目标平台**: iOS、Android
- **用户角色**: 双角色系统（学生端 + 教练端）
- **开发模式**: 全新构建（非迁移项目）

### 1.2 核心功能
- 学生端: 训练打卡、饮食记录、补剂跟踪、与教练对话、查看计划
- 教练端: 学生管理、创建计划、查看记录、提供反馈、对话管理
- AI功能: 智能生成训练计划、饮食计划

### 1.3 项目规模评估
- **页面数量**: 约18个主要页面
- **数据模型**: 10+个复杂数据结构
- **API接口**: 50+个Cloud Functions
- **项目复杂度**: 中大型应用

---

## 二、核心技术栈

### 2.1 前端技术栈

| 技术领域 | 选型方案 | 理由 |
|---------|---------|------|
| **框架** | Flutter (Dart ^3.9.2) | 跨平台、性能优秀、生态成熟 |
| **UI库** | **Cupertino为主 + Material补充** | 设计稿偏iOS风格、精致体验、品牌定位 |
| **状态管理** | Riverpod | 编译时安全、依赖追踪、适合复杂场景 |
| **路由导航** | go_router | 声明式路由、守卫功能、适合双角色系统 |
| **网络请求** | dio + Repository模式 | 功能强大、统一抽象、易于测试 |
| **本地存储** | shared_preferences + Hive | 简单配置用SP、复杂对象用Hive |
| **图片处理** | cached_network_image | 自动缓存、性能优秀 |
| **错误追踪** | Firebase Crashlytics | 与Firebase生态集成、免费额度充足 |

### 2.2 后端技术栈

| 技术领域 | 选型方案 | 理由 |
|---------|---------|------|
| **后端架构** | Firebase全家桶 | Serverless、快速开发、降低运维成本 |
| **数据库** | Cloud Firestore | 文档型数据库、实时同步、适合本项目数据结构 |
| **API层** | Cloud Functions | 按需付费、自动扩展、与Firebase深度集成 |
| **认证** | Firebase Authentication | 成熟可靠、支持多种登录方式 |
| **存储** | Firebase Storage | 图片视频存储、CDN加速 |
| **推送通知** | Firebase Cloud Messaging | 跨平台推送、与Firebase生态集成 |
| **AI服务** | Cloud Functions调用外部API | 保护密钥安全、便于控制和监控 |

---

## 三、架构设计方案

### 3.1 整体架构模式

**选型**: **Feature-First + Clean Architecture混合**

```
coach_x/
├── lib/
│   ├── core/                    # 核心共享代码
│   │   ├── theme/              # 主题配置（Cupertino主题）
│   │   ├── constants/          # 常量定义
│   │   ├── utils/              # 工具函数
│   │   ├── widgets/            # 通用组件（iOS风格卡片等）
│   │   ├── errors/             # 错误处理
│   │   └── network/            # 网络配置
│   │
│   ├── features/               # 功能模块（Feature-First）
│   │   ├── auth/              # 认证模块
│   │   │   ├── data/          # 数据层
│   │   │   ├── domain/        # 业务逻辑
│   │   │   └── presentation/  # UI层
│   │   │
│   │   ├── student/           # 学生端功能
│   │   │   ├── home/
│   │   │   ├── training/
│   │   │   ├── diet/
│   │   │   ├── supplement/
│   │   │   ├── body_stats/
│   │   │   └── chat/
│   │   │
│   │   ├── coach/             # 教练端功能
│   │   │   ├── home/
│   │   │   ├── students/
│   │   │   ├── plans/
│   │   │   └── chat/
│   │   │
│   │   └── shared/            # 双角色共享功能
│   │       ├── profile/
│   │       ├── plan_detail/
│   │       └── training_detail/
│   │
│   ├── routes/                # 路由配置
│   └── main.dart              # 应用入口
```

**设计理由**:
- Feature-First便于团队协作和模块化开发
- 每个feature内部采用分层架构保证代码质量
- 清晰的学生/教练功能分离
- 共享代码统一管理

### 3.2 数据流架构

```
UI Layer (Cupertino Widgets)
    ↓ 触发事件
State Management (Riverpod Providers)
    ↓ 调用业务逻辑
Repository Layer (抽象接口)
    ↓ 实现
Data Source Layer
    ├── Remote (Firebase/Cloud Functions)
    └── Local (Hive/SharedPreferences)
```

**关键点**:
- UI层只依赖Provider，不直接访问数据源
- Repository提供统一接口，隔离具体实现
- 支持离线优先策略
- 易于单元测试和Mock

### 3.3 状态管理策略

**Riverpod使用模式**:

1. **Provider类型选择**:
   - StateProvider: 简单状态（当前tab索引等）
   - StateNotifierProvider: 复杂状态管理
   - FutureProvider: 异步数据加载
   - StreamProvider: 实时数据流（聊天消息）

2. **状态作用域**:
   - 全局状态: 用户信息、认证状态
   - Feature状态: 各功能模块独立管理
   - 临时状态: Widget内部状态

3. **依赖注入**:
   - Repository通过Provider提供
   - 便于测试时Mock替换

---

## 四、UI/UX设计方案

### 4.1 设计系统

**UI库选型**: **Cupertino为主 + Material补充**

**配色方案**:
```
主色调: #f2e8cf (温暖米黄色)
辅助色:
  - #a8c0d0 (浅蓝色)
  - #c0c0c0 (银灰色)
  - #7f8c8d (深灰蓝)
  - #95a5a6 (灰色)
```

**字体**: Lexend (400/500/600/700/900)

**设计原则**:
- iOS风格为主（毛玻璃效果、精致圆角、弹簧动画）
- 卡片式布局
- 清晰的信息层次
- 温暖专业的视觉风格

### 4.2 组件库规划

**需要自定义的iOS风格组件**:
- CupertinoCard: 卡片容器
- CustomBottomSheet: 底部弹窗
- TrainingCard: 训练卡片
- PlanCard: 计划卡片
- StatCard: 统计卡片
- ChatBubble: 聊天气泡
- MediaUploader: 媒体上传组件

**直接使用Cupertino组件**:
- CupertinoNavigationBar
- CupertinoTabScaffold
- CupertinoButton
- CupertinoTextField
- CupertinoAlertDialog
- CupertinoActionSheet
- CupertinoDatePicker

**借用Material组件**:
- 复杂表单（必要时）
- 数据表格（如果需要）

### 4.3 图标方案

**策略**: Cupertino Icons为主 + Material Symbols补充
- 系统UI用Cupertino Icons
- 特殊功能图标用Material Icons或自定义SVG

---

## 五、路由与导航

### 5.1 路由架构

**go_router配置**:

```
路由结构:
/splash              # 启动页
/login               # 登录页
/role-select         # 角色选择（如需要）

学生端路由:
/student/home        # 学生首页
/student/plan        # 计划查看
/student/training    # 训练记录
/student/chat        # 对话
/student/profile     # 个人信息

教练端路由:
/coach/home          # 教练首页
/coach/students      # 学生列表
/coach/plans         # 计划管理
/coach/chat          # 对话列表
/coach/profile       # 个人信息

共享路由:
/plan/:id            # 计划详情
/training/:id        # 训练详情
```

**路由守卫**:
- 认证守卫: 未登录重定向到登录页
- 角色守卫: 根据用户角色重定向到对应首页
- 权限守卫: 防止越权访问

### 5.2 底部导航

**学生端Tab**:
- Home（首页）
- Plan（计划）
- Add（快速添加 - 中间突出按钮）
- Chat（对话）
- Profile（我的）

**教练端Tab**:
- Home（首页）
- Students（学生）
- Plans（计划）
- Chat（对话）
- Profile（我的）

---

## 六、数据层设计

### 6.1 Repository模式

**抽象层设计**:
```
Repository接口 (抽象)
    ↓ 实现
RepositoryImpl (具体实现)
    ↓ 依赖
DataSource (Remote + Local)
```

**主要Repository**:
- AuthRepository: 认证相关
- UserRepository: 用户信息
- PlanRepository: 计划管理（训练/饮食/补剂）
- TrainingRepository: 训练记录
- ChatRepository: 对话消息
- BodyStatsRepository: 身体数据

### 6.2 数据持久化策略

**SharedPreferences用途**:
- 用户Token
- 用户角色
- 简单配置项
- 首次启动标记

**Hive用途**:
- 训练计划缓存
- 训练历史记录
- 离线消息队列
- 用户信息缓存

**缓存策略**:
- 优先显示缓存数据
- 后台异步更新
- 定期清理过期缓存

### 6.3 实时数据处理

**Firestore实时监听**:
- 聊天消息（StreamProvider）
- 训练反馈更新
- 计划分配通知

**Firebase Cloud Messaging**:
- 后台消息推送
- 新消息通知
- 训练提醒

**组合策略**:
- 应用在前台: Firestore监听
- 应用在后台: FCM推送
- 应用打开后: 同步未读消息

---

## 七、网络层设计

### 7.1 Dio配置

**拦截器**:
- AuthInterceptor: 自动添加Token
- LogInterceptor: 请求日志
- ErrorInterceptor: 统一错误处理
- RetryInterceptor: 请求重试

**错误处理**:
- 网络错误: 提示用户检查网络
- 认证错误: 自动跳转登录
- 服务器错误: 友好提示
- 超时处理: 重试机制

### 7.2 Cloud Functions调用

**统一封装**:
- 基础URL配置
- 请求方法封装
- 响应数据解析
- 错误统一处理

**请求优化**:
- 请求合并（避免短时间重复请求）
- 数据预加载
- 分页加载

---

## 八、媒体处理方案

### 8.1 图片处理

**上传流程**:
1. 使用image_picker选择图片
2. 压缩处理（控制质量和大小）
3. 上传到Firebase Storage
4. 获取下载URL
5. 保存URL到Firestore

**展示优化**:
- cached_network_image缓存
- 缩略图优先加载
- 图片懒加载

### 8.2 视频处理

**上传流程**:
1. image_picker选择视频
2. 视频压缩（可选，使用flutter_ffmpeg）
3. 限制大小和时长
4. 后台上传队列
5. 显示上传进度
6. 生成缩略图

**播放优化**:
- video_player播放
- 缓存机制
- 流量提醒（WiFi/移动网络）

---

## 九、AI集成方案

### 9.1 架构设计

**流程**:
```
Flutter App
    ↓ 发送prompt
Cloud Function
    ↓ 调用AI API
OpenAI / Vertex AI
    ↓ 返回结果
Cloud Function (处理格式化)
    ↓ 返回给App
Flutter App展示
```

### 9.2 功能设计

**AI生成训练计划**:
- 用户输入目标和需求
- AI生成完整训练计划
- 支持教练编辑和调整
- 保存为模板

**AI生成饮食计划**:
- 基于目标和身体数据
- 生成营养配比建议
- 具体餐食推荐

**成本控制**:
- 根据用户等级限制使用次数
- 缓存常见结果
- 优化prompt长度

---

## 十、安全性设计

### 10.1 认证授权

**Firebase Authentication**:
- 支持邮箱/手机号登录
- Token自动刷新
- 安全的会话管理

**邀请码系统**:
- 防止恶意注册
- 控制用户增长
- 区分教练/学生类型

### 10.2 数据安全

**Firestore Security Rules**:
- 学生只能访问自己的数据
- 教练只能访问自己的学生数据
- 计划创建者才能修改计划
- 对话双方才能访问消息

**敏感数据处理**:
- Token存储加密
- API密钥在服务端
- 图片URL带签名有效期

### 10.3 输入验证

**客户端验证**:
- 表单输入格式检查
- 文件大小限制
- 恶意内容过滤

**服务端验证**:
- Cloud Functions中再次验证
- SQL注入防护（虽然用NoSQL）
- XSS防护

---

## 十一、性能优化策略

### 11.1 列表优化

- ListView.builder懒加载
- 分页加载（每页20-50条）
- 虚拟滚动
- 上拉加载更多

### 11.2 图片优化

- 图片缓存策略
- 懒加载
- 占位图
- 渐进式加载

### 11.3 状态优化

- 避免不必要的rebuild
- 使用const构造函数
- 合理的Provider作用域
- 细粒度状态管理

### 11.4 网络优化

- 请求合并
- 数据预加载
- 缓存优先
- 离线模式

### 11.5 启动优化

- 延迟初始化
- 异步加载非关键资源
- SplashScreen过渡
- 减少首屏依赖

---

## 十二、测试策略

### 12.1 测试层级

**单元测试**:
- Repository层
- 业务逻辑层
- 工具函数
- 数据模型

**Widget测试**:
- 核心UI组件
- 自定义组件
- 交互逻辑

**集成测试**:
- 关键用户流程
- 登录流程
- 训练记录流程
- 聊天功能

### 12.2 Mock策略

- mockito: Mock依赖
- fake Firebase: 测试Firebase交互
- Golden测试: UI截图对比（可选）

### 12.3 测试覆盖率目标

- 核心业务逻辑: 80%+
- Repository层: 70%+
- UI层: 关键流程覆盖

---

## 十三、国际化与主题

### 13.1 国际化

**初期方案**: 暂不实现，硬编码中文文本
**后期扩展**: 保留使用flutter_localizations的可能性

**预留考虑**:
- 文本使用变量而非硬编码常量
- UI设计考虑文本长度变化
- 日期时间格式使用intl包

### 13.2 主题模式

**初期方案**: 仅支持浅色模式
**可能扩展**: 深色模式（根据用户需求）

**主题配置**:
- 统一的CupertinoThemeData
- 颜色常量统一管理
- 便于后期添加深色主题

---

## 十四、错误处理与日志

### 14.1 错误处理

**分层错误处理**:
- UI层: 用户友好提示
- Repository层: 错误转换和封装
- DataSource层: 原始错误捕获

**错误类型**:
- NetworkError: 网络错误
- AuthError: 认证错误
- ValidationError: 验证错误
- ServerError: 服务器错误
- UnknownError: 未知错误

### 14.2 日志系统

**Firebase Crashlytics**:
- 崩溃报告
- 非致命错误记录
- 自定义日志

**Firebase Analytics**:
- 用户行为分析
- 功能使用统计
- 转化漏斗分析

**开发日志**:
- Debug模式详细日志
- Release模式关键日志
- 性能监控日志

---

## 十五、开发流程与规范

### 15.1 Git分支策略

```
master/main          # 生产环境
  ├── develop        # 开发主分支
  │   ├── feature/* # 功能分支
  │   ├── bugfix/*  # 修复分支
  │   └── hotfix/*  # 紧急修复
```

### 15.2 代码规范

- 遵循Dart官方代码风格
- 使用flutter_lints
- 统一的命名规范
- 充分的代码注释
- 提交前运行flutter analyze

### 15.3 版本管理

- 语义化版本号: major.minor.patch
- CHANGELOG记录变更
- Tag标记发布版本

---

## 十六、部署与CI/CD

### 16.1 环境配置

**开发环境**: 
- Firebase测试项目
- 测试数据

**生产环境**:
- Firebase生产项目
- 真实数据
- 监控告警

### 16.2 构建流程

**iOS**:
- Xcode Archive
- TestFlight内测
- App Store发布

**Android**:
- Android Studio构建
- 内测分发
- Google Play发布

### 16.3 CI/CD（可选）

- GitHub Actions / GitLab CI
- 自动化测试
- 自动化构建
- 自动化部署到测试环境

---

## 十七、项目里程碑规划

### 阶段一: 基础框架搭建
- [ ] 项目结构创建
- [ ] 核心依赖配置
- [ ] 主题和样式系统
- [ ] 路由配置
- [ ] 通用组件库

### 阶段二: Firebase集成
- [ ] Firebase项目创建
- [ ] Authentication配置
- [ ] Firestore数据库设计
- [ ] Storage配置
- [ ] Cloud Functions基础框架

### 阶段三: 认证模块
- [ ] 登录页面
- [ ] 注册流程
- [ ] 邀请码验证
- [ ] 用户信息初始化

### 阶段四: 学生端核心功能
- [ ] 学生首页
- [ ] 训练记录上传
- [ ] 饮食记录
- [ ] 计划查看
- [ ] 对话功能

### 阶段五: 教练端核心功能
- [ ] 教练首页
- [ ] 学生管理
- [ ] 计划创建
- [ ] 训练审核
- [ ] 反馈功能

### 阶段六: AI功能集成
- [ ] AI生成训练计划
- [ ] AI生成饮食建议
- [ ] 智能推荐

### 阶段七: 优化与测试
- [ ] 性能优化
- [ ] 用户体验优化
- [ ] 全面测试
- [ ] Bug修复

### 阶段八: 发布准备
- [ ] 应用商店素材
- [ ] 隐私政策
- [ ] 用户协议
- [ ] 上线发布

---

## 十八、技术风险与挑战

### 18.1 已识别风险

**技术风险**:
- Firebase成本可能随用户增长快速上升
- 视频上传和存储可能成为性能瓶颈
- AI API调用成本需要控制
- 实时消息在弱网环境可能不稳定

**业务风险**:
- 双角色系统的权限控制复杂
- 训练计划的数据结构可能需要迭代
- 用户期望可能超出MVP范围

### 18.2 应对策略

**技术应对**:
- 实现成本监控和告警
- 视频压缩和大小限制
- AI功能按用户等级限制
- 离线优先策略保证可用性

**业务应对**:
- 明确MVP范围
- 分阶段迭代
- 持续用户反馈
- 灵活调整优先级

---

## 十九、关键决策记录

### 19.1 UI库选择: Cupertino为主

**决策**: 使用Cupertino为主 + Material补充  
**理由**: 设计稿偏iOS风格，目标用户群匹配，品牌定位需要精致体验  
**权衡**: Android用户体验可能稍弱，但整体一致性更强  
**日期**: 2025-10-19

### 19.2 状态管理: Riverpod

**决策**: 使用Riverpod作为状态管理方案  
**理由**: 适合复杂应用、编译时安全、依赖管理清晰  
**权衡**: 学习曲线相对陡峭  
**日期**: 2025-10-19

### 19.3 架构模式: Feature-First + Clean

**决策**: Feature-First组织代码，内部分层  
**理由**: 便于团队协作、模块化清晰、代码质量可控  
**权衡**: 初期文件结构较多  
**日期**: 2025-10-19

### 19.4 后端方案: Firebase全家桶

**决策**: 使用Firebase作为完整后端解决方案  
**理由**: 快速开发、降低运维成本、功能完整  
**权衡**: 供应商锁定、后期迁移成本高  
**日期**: 2025-10-19

---

## 二十、参考资料

### 20.1 设计资源
- UI设计稿: `/studentUI/`, `/coachUI/`, `/commonUI/`
- 颜色方案: 主色#f2e8cf及配色
- 字体: Lexend (400/500/600/700/900)

### 20.2 API文档
- 后端API与数据库Schema: `/docs/backend_apis_and_document_db_schemas.md`
- Google Docs: https://docs.google.com/document/d/1yKQgZWjdeALkwrl2SHf6RjUnsCmeLxtoWFrv0Epr7SQ

### 20.3 技术文档
- Flutter官方文档: https://flutter.dev
- Cupertino组件: https://docs.flutter.dev/ui/widgets/cupertino
- Riverpod文档: https://riverpod.dev
- Firebase文档: https://firebase.google.com/docs

---

## 附录: 待决策事项

以下事项需要在计划阶段或执行过程中进一步确定:

1. **AI服务提供商**: OpenAI vs Google Vertex AI vs 其他
2. **视频压缩方案**: 是否使用flutter_ffmpeg，压缩参数
3. **测试覆盖率目标**: 具体的百分比要求
4. **性能基准**: 启动时间、页面切换时间等具体指标
5. **发布时间表**: 具体的里程碑日期
6. **团队分工**: 如果是团队开发，模块分配方案
7. **深色模式**: 是否在MVP阶段实现

---

**文档版本**: v1.0  
**下一步**: 进入计划模式，制定详细的实施计划

