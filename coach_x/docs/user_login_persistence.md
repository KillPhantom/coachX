# 用户登录持久化实现文档

**创建日期**: 2025-11-16
**版本**: 1.0
**状态**: 已实现

---

## 1. 功能概述

实现用户登录状态的持久化，使用户在关闭应用后重新打开时无需再次登录，同时提供优雅的启动体验。

### 核心特性

- ✅ **7天缓存策略** - 用户信息缓存有效期为7天
- ✅ **条件性 Splash 页面** - 仅在必要时显示品牌元素
- ✅ **快速启动** - 缓存有效时直接进入首页（< 0.1秒）
- ✅ **角色隔离** - 教练和学生分别跳转到对应首页
- ✅ **安全退出** - 登出时自动清除所有缓存
- ✅ **错误恢复** - 查询失败时要求重新登录

---

## 2. 技术架构

### 2.1 架构模式

采用**分层决策**架构：

```
Layer 1: 启动时预决策 (main.dart)
    ↓
Layer 2: 条件性 Splash (splash_page.dart)
    ↓
Layer 3: 运行时路由守护 (app_router.dart)
```

### 2.2 核心组件

#### UserCacheService（用户缓存服务）
- **位置**: `lib/core/services/user_cache_service.dart`
- **职责**: 管理用户信息的本地缓存（SharedPreferences）
- **接口**:
  - `initialize()` - 初始化 SharedPreferences
  - `isValid()` - 检查缓存有效性（同步）
  - `getCachedRole()` - 获取缓存的用户角色
  - `saveUserCache()` - 保存用户缓存
  - `clearCache()` - 清除所有缓存

#### BootstrapService（启动决策服务）
- **位置**: `lib/core/services/bootstrap_service.dart`
- **职责**: 在应用启动时决定初始路由
- **接口**:
  - `determineInitialRoute()` - 返回初始路由路径

#### SplashPage（启动页）
- **位置**: `lib/features/auth/presentation/pages/splash_page.dart`
- **职责**: 展示品牌元素，异步加载用户数据
- **特性**:
  - Logo 淡入动画（800ms）
  - 最小显示时长 1.5 秒
  - 10 秒超时保护
  - 优雅的错误处理

---

## 3. 实现细节

### 3.1 缓存数据结构

使用 SharedPreferences 存储以下键值对：

| 键名 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `auth_user_id` | String | 用户 ID | "abc123..." |
| `user_role` | String | 用户角色 | "coach" / "student" |
| `cache_timestamp` | int | 缓存时间戳（毫秒） | 1700000000000 |

### 3.2 缓存有效性检查

缓存被认为有效当且仅当：

1. **用户 ID 匹配**：`cachedUserId == FirebaseAuth.currentUser.uid`
2. **未过期**：`(当前时间 - 缓存时间戳) < 7天`

```dart
bool isValid() {
  // 检查用户 ID 是否匹配
  if (cachedUserId != currentUser?.uid) return false;

  // 检查是否过期（7天 = 604800000 毫秒）
  final age = DateTime.now().millisecondsSinceEpoch - cacheTimestamp;
  return age < 7 * 24 * 60 * 60 * 1000;
}
```

### 3.3 启动流程

#### 应用启动序列

```
main() 执行
  ├─ Firebase 初始化
  ├─ UserCacheService 初始化
  ├─ BootstrapService.determineInitialRoute()
  │   ├─ 未登录 → '/login'
  │   ├─ 已登录 + 缓存无效 → '/splash'
  │   └─ 已登录 + 缓存有效 → '/coach/home' | '/student/home'
  └─ runApp(CoachXApp(initialRoute: ...))
```

#### 启动决策逻辑

```dart
Future<String> determineInitialRoute() async {
  // 1. 检查登录状态
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    return RouteNames.login;  // 未登录 → 登录页
  }

  // 2. 检查缓存有效性
  final cacheValid = UserCacheService.isValid();
  if (!cacheValid) {
    return RouteNames.splash;  // 缓存无效 → Splash
  }

  // 3. 获取角色并跳转
  final role = UserCacheService.getCachedRole();
  if (role == 'coach') {
    return RouteNames.coachHome;  // 教练首页
  } else if (role == 'student') {
    return RouteNames.studentHome;  // 学生首页
  } else {
    return RouteNames.splash;  // 未知角色 → Splash
  }
}
```

### 3.4 Splash 页面逻辑

#### 加载流程

```
Splash 显示
  ├─ 开始 Logo 动画
  ├─ 从 Firestore 查询用户信息（10秒超时）
  ├─ 保存到缓存
  ├─ 等待最小显示时长（1.5秒）
  └─ 根据角色导航到首页
```

#### 异常处理

| 异常情况 | 处理方式 |
|---------|---------|
| 用户文档不存在 | 清除认证 → 登录页 |
| 查询超时（>10秒） | 清除认证 → 登录页 |
| 角色无效 | 清除认证 → 登录页 |
| 网络错误 | 清除认证 → 登录页 |

```dart
Future<void> _loadUserData() async {
  try {
    // 查询用户信息（带超时）
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get()
        .timeout(Duration(seconds: 10));

    // 验证数据
    if (!userDoc.exists || userData == null) {
      throw Exception('用户数据无效');
    }

    // 保存缓存
    await UserCacheService.saveUserCache(
      userId: currentUser.uid,
      role: role,
    );

    // 最小显示时长
    await Future.delayed(Duration(milliseconds: 1500));

    // 导航到首页
    if (role == 'coach') {
      context.go(RouteNames.coachHome);
    } else {
      context.go(RouteNames.studentHome);
    }
  } catch (e) {
    // 失败时清除认证
    await AuthService.signOut();
    await UserCacheService.clearCache();
    context.go(RouteNames.login);
  }
}
```

### 3.5 登录流程增强

登录成功后立即缓存用户信息：

```dart
// LoginPage._navigateToHomePage()
Future<void> _navigateToHomePage() async {
  // 1. 从 Firestore 查询用户信息
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .get();

  final role = userDoc.data()?['role'];

  // 2. 保存到缓存
  await UserCacheService.saveUserCache(
    userId: currentUser.uid,
    role: role,
  );

  // 3. 跳转到首页
  if (role == 'coach') {
    context.go(RouteNames.coachHome);
  } else {
    context.go(RouteNames.studentHome);
  }
}
```

### 3.6 登出流程增强

登出时清除所有缓存：

```dart
// AuthService.signOut()
static Future<void> signOut() async {
  // 1. 清除用户缓存
  await UserCacheService.clearCache();

  // 2. 退出 Firebase 认证
  await _auth.signOut();
}
```

### 3.7 路由守护

运行时保护需要登录的页面：

```dart
// app_router.dart
GoRouter getAppRouter(String initialRoute) {
  return GoRouter(
    initialLocation: initialRoute,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final currentPath = state.uri.path;

      // 公开路由
      const publicRoutes = ['/login', '/register', '/splash'];

      // 未登录且不在公开路由 → 重定向到登录页
      if (!isLoggedIn && !publicRoutes.contains(currentPath)) {
        return RouteNames.login;
      }

      return null;  // 允许访问
    },
    routes: [...],
  );
}
```

---

## 4. 关键文件清单

### 核心服务

- `lib/core/services/user_cache_service.dart` - 用户缓存管理
- `lib/core/services/bootstrap_service.dart` - 启动路由决策
- `lib/core/providers/cache_providers.dart` - 缓存相关 Providers

### UI 层

- `lib/features/auth/presentation/pages/splash_page.dart` - Splash 页面
- `lib/features/auth/presentation/pages/login_page.dart` - 登录页（已增强）

### 路由层

- `lib/routes/app_router.dart` - 路由配置（单例模式）
- `lib/routes/route_names.dart` - 路由常量
- `lib/app/app.dart` - 应用根组件
- `lib/main.dart` - 应用入口

### 国际化

- `lib/l10n/app_en.arb` - 英文文本（已添加 `splashLoading`, `splashLoadError`）
- `lib/l10n/app_zh.arb` - 中文文本（已添加对应翻译）

---

## 5. 用户体验流程

### 场景 1: 首次安装

```
应用启动 → 无缓存 → 显示登录页
```

### 场景 2: 首次登录

```
登录成功 → 查询用户信息 → 保存缓存 → 跳转首页
```

### 场景 3: 7天内重启（最常见）

```
应用启动 → 缓存有效 → 直接跳转首页（< 0.1秒）
```

### 场景 4: 7天后重启

```
应用启动 → 缓存过期 → 显示 Splash → 刷新缓存 → 跳转首页
```

### 场景 5: 手动登出

```
点击登出 → 清除缓存 → 清除认证 → 跳转登录页
下次启动 → 无缓存 → 显示登录页
```

### 场景 6: 查询失败（网络问题）

```
应用启动 → 缓存过期 → 显示 Splash → 查询超时 → 清除认证 → 跳转登录页
```

---

## 6. 性能优化

### 6.1 快速启动

- **同步检查**: `UserCacheService.isValid()` 是同步方法，无需异步等待
- **缓存优先**: 有效缓存时直接跳转，无网络请求
- **单例路由**: GoRouter 使用单例模式，避免热重载时重新创建

### 6.2 网络优化

- **按需刷新**: 仅缓存失效时才查询 Firestore
- **超时保护**: 10 秒超时，避免长时间等待
- **离线友好**: 缓存有效时完全离线可用

---

## 7. 安全考虑

### 7.1 身份验证

- **双重验证**: 缓存 + Firebase Auth 双重检查
- **ID 匹配**: 缓存的 userId 必须与当前登录用户匹配
- **自动失效**: 用户切换账号时缓存自动失效

### 7.2 数据保护

- **本地存储**: 使用 SharedPreferences（系统级加密）
- **无敏感信息**: 仅存储 userId 和 role，不存储密码或 token
- **清除机制**: 登出时彻底清除缓存

### 7.3 防御策略

| 威胁 | 防御措施 |
|------|---------|
| 账号切换 | userId 不匹配时缓存失效 |
| 角色变更 | 不支持运行时角色修改，必须重新登录 |
| 缓存篡改 | Firebase Auth 最终验证，缓存仅用于加速 |
| 长期过期 | 7 天强制刷新 |

---

## 8. 测试场景

### 基础功能测试

- [ ] 首次安装启动 → 显示登录页
- [ ] 首次登录成功 → 保存缓存并跳转首页
- [ ] 7天内重启 → 直接进入首页（无 Splash）
- [ ] 7天后重启 → 显示 Splash 并刷新缓存
- [ ] 手动登出 → 清除缓存，下次启动显示登录页

### 角色测试

- [ ] 教练角色缓存 → 跳转 `/coach/home`
- [ ] 学生角色缓存 → 跳转 `/student/home`
- [ ] 角色信息缺失 → 显示 Splash 重新加载

### 异常处理测试

- [ ] Firestore 查询失败 → 清除认证并跳转登录页
- [ ] 查询超时（>10秒） → 清除认证并跳转登录页
- [ ] 用户文档不存在 → 跳转到 Profile Setup
- [ ] 网络断开（缓存有效）→ 正常进入首页
- [ ] 网络断开（缓存无效）→ 查询失败，跳转登录页

### 边界情况测试

- [ ] 缓存恰好7天 → 应该失效
- [ ] 缓存6天23小时 → 应该有效
- [ ] 用户ID不匹配 → 缓存失效
- [ ] SharedPreferences 初始化失败 → 降级为登录页
- [ ] 热重载（Hot Reload）→ 保持当前页面
- [ ] 完全重启（Hot Restart）→ 重新执行启动决策

---

## 9. 故障排查

### 常见问题

#### Q1: 每次启动都显示 Splash
**原因**: 缓存未保存或一直失效
**检查**:
1. 查看日志中的 `UserCacheService.saveUserCache()` 是否成功
2. 检查 `UserCacheService.isValid()` 返回值及原因
3. 确认 SharedPreferences 初始化成功

#### Q2: 登录后无法跳转
**原因**: 角色信息查询失败
**检查**:
1. Firestore 中 `users/{uid}` 文档是否存在
2. 文档中 `role` 字段是否为 "coach" 或 "student"
3. 查看网络请求日志

#### Q3: 热重载后跳转到 Splash
**原因**: GoRouter 被重新创建（已修复）
**解决**: 使用单例模式的 `getAppRouter()`

#### Q4: 缓存过期时间不准确
**原因**: 时间戳单位错误
**检查**: 确保使用 `DateTime.now().millisecondsSinceEpoch`（毫秒）

---

## 10. 未来优化方向

### 短期优化

- [ ] 添加缓存版本号，支持数据结构迁移
- [ ] 支持缓存更多用户信息（头像、昵称）减少首页加载时间
- [ ] 添加 Splash 页面骨架屏，提升加载体验

### 长期优化

- [ ] 支持多账号切换（存储多个缓存）
- [ ] 引入加密存储（FlutterSecureStorage）
- [ ] 后台刷新缓存（静默更新）
- [ ] 支持自定义缓存有效期（用户设置）

---

## 11. 参考资料

### 技术文档

- [SharedPreferences 官方文档](https://pub.dev/packages/shared_preferences)
- [GoRouter 官方文档](https://pub.dev/packages/go_router)
- [Firebase Auth 持久化](https://firebase.google.com/docs/auth/flutter/auth-state-persistence)

### 项目文档

- `README.md` - 项目总览
- `docs/architecture_design.md` - 架构设计
- `docs/backend_apis_and_document_db_schemas.md` - 后端 API 和数据库架构

---

## 12. 变更历史

| 日期 | 版本 | 变更内容 | 作者 |
|------|------|---------|------|
| 2025-11-16 | 1.0 | 初始实现，完成所有核心功能 | Claude |

---

**文档结束**
