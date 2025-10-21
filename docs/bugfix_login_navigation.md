# Bug修复：登录后导航错误

## 问题描述

**Bug**: Firebase Firestore中的用户`role`字段为`coach`，但登录后却导航到学生界面。

## 原因分析

在 `login_page.dart` 中，登录成功后的导航逻辑硬编码跳转到学生首页：

```dart
if (next.status == LoginStatus.success) {
  // 登录成功，导航到主页（临时跳转到学生首页）
  context.go(RouteNames.studentHome);  // ← 问题所在
}
```

这是一个临时实现，没有根据用户的实际角色（`UserRole.coach` 或 `UserRole.student`）来决定跳转路径。

## 解决方案

修改登录成功后的导航逻辑，根据用户在Firestore中的`role`字段来决定跳转：

1. **获取用户数据**: 使用 `currentUserDataProvider` 从Firestore获取用户数据
2. **解析角色**: 通过 `UserModel.role` 字段判断用户角色
3. **条件跳转**:
   - `UserRole.coach` → `/coach/home` (教练首页)
   - `UserRole.student` → `/student/home` (学生首页)
   - 角色未设置或数据不存在 → `/profile-setup` (完善资料页)

## 实现细节

### 修改文件
`/Users/ivan/coachX/coach_x/lib/features/auth/presentation/pages/login_page.dart`

### 核心代码

```dart
/// 根据用户角色导航到对应的首页
Future<void> _navigateToHomePage() async {
  // 等待用户数据加载完成（最多等待3秒）
  int attempts = 0;
  const maxAttempts = 30; // 30 * 100ms = 3秒
  
  while (attempts < maxAttempts) {
    final userData = ref.read(currentUserDataProvider);
    
    // 检查数据是否已加载
    if (userData is AsyncData) {
      final user = userData.value;
      
      if (user == null) {
        // 用户数据不存在，跳转到Profile Setup
        if (mounted) context.go(RouteNames.profileSetup);
        return;
      }

      // 根据用户角色跳转到对应的首页
      if (mounted) {
        if (user.role == UserRole.coach) {
          context.go(RouteNames.coachHome);        // 教练 → 教练首页
        } else if (user.role == UserRole.student) {
          context.go(RouteNames.studentHome);      // 学生 → 学生首页
        } else {
          context.go(RouteNames.profileSetup);     // 未知角色 → 完善资料
        }
      }
      return;
    }
    
    // 等待100ms后重试
    await Future.delayed(const Duration(milliseconds: 100));
    attempts++;
  }
  
  // 超时处理（3秒后）
  if (mounted) {
    showCupertinoDialog(...);
  }
}
```

### 数据流程

1. **Firebase Auth登录成功** → `LoginController` 状态变为 `LoginStatus.success`
2. **触发导航** → 调用 `_navigateToHomePage()` 方法
3. **读取Firestore数据** → `currentUserDataProvider` 监听 `users/{userId}` 文档
4. **解析用户角色** → `UserModel.fromFirestore()` 解析 `role` 字段
5. **条件跳转** → 根据 `UserRole` 枚举值跳转到对应页面

### Firestore数据结构

确保Firestore中用户文档的`role`字段值为以下之一：
- `"coach"` - 教练角色
- `"student"` - 学生角色

示例：
```json
{
  "users": {
    "userId123": {
      "email": "coach@example.com",
      "name": "张教练",
      "role": "coach",        ← 关键字段
      "isVerified": true,
      ...
    }
  }
}
```

## 测试验证

### 测试步骤

1. **确认Firestore数据**
   - 打开Firebase Console
   - 进入Firestore Database
   - 找到 `users` collection
   - 确认目标用户的 `role` 字段为 `"coach"`

2. **测试登录流程**
   - 清除应用缓存（或重新安装）
   - 使用教练账号登录
   - 验证是否跳转到教练首页（显示"Home", "Summary", "Event Reminder"等教练专属内容）

3. **测试学生账号**
   - 登出教练账号
   - 使用学生账号登录
   - 验证是否跳转到学生首页

### 预期结果

- ✅ 教练账号登录 → 教练首页 (`/coach/home`)，显示教练Tab导航
- ✅ 学生账号登录 → 学生首页 (`/student/home`)，显示学生Tab导航
- ✅ 数据加载失败 → 显示错误提示，返回登录页
- ✅ 超时（3秒） → 显示超时提示，返回登录页

## 边界情况处理

1. **用户数据不存在**: 跳转到 `/profile-setup` 让用户完善资料
2. **角色字段缺失或无效**: 默认为 `student`（在 `UserModel.fromFirestore` 中处理）
3. **数据加载超时**: 显示超时提示，用户可重试
4. **Firestore读取错误**: 显示错误提示，返回登录页

## 后续优化建议

1. **添加加载指示器**: 在等待用户数据加载期间，显示loading动画
2. **优化重试机制**: 使用 `ref.watch()` 监听数据变化，而不是轮询
3. **缓存用户角色**: 登录成功后缓存用户角色到本地，加快下次启动速度
4. **角色验证**: 定期验证用户角色是否变更（例如学生升级为教练）

## 相关文件

- `lib/features/auth/presentation/pages/login_page.dart` - 登录页面（已修复）
- `lib/features/auth/data/models/user_model.dart` - 用户数据模型
- `lib/features/auth/data/providers/user_providers.dart` - 用户数据Provider
- `lib/core/enums/user_role.dart` - 用户角色枚举
- `lib/routes/route_names.dart` - 路由常量定义
- `lib/routes/app_router.dart` - 路由配置

## 修复时间

- **发现**: 2025-10-21
- **修复**: 2025-10-21
- **验证**: 待用户测试

---

**修复状态**: ✅ 已完成，待验证

