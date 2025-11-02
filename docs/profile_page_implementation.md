# Profile Page Implementation Summary

**创建日期**: 2025-10-31
**状态**: 🚧 进行中
**预估工作量**: 5天
**实际工作量**: TBD

---

## 实施目标

实现教练和学生的 Profile 页面，支持：
- 显示用户基本信息
- 学生：显示教练信息和合约有效期
- 教练：显示认证标签和订阅信息（placeholder）
- Settings：通知开关、单位切换、登出功能

---

## UI 设计参考

- 设计文件: `/Users/ivan/coachX/commonUI/ProfilePage/`
  - `student.png` - 学生 Profile 设计
  - `coach.png` - 教练 Profile 设计
  - `code.html` - HTML 参考代码

---

## 数据模型变更

### UserModel 新增字段

| 字段 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `tags` | `List<String>?` | 认证标签（如 "IFFF Pro", "Certified"） | null |
| `contractExpiresAt` | `DateTime?` | 学生与教练的合约有效期 | null |
| `subscriptionPlan` | `String?` | 订阅计划类型 (free/pro) | null |
| `subscriptionRenewsAt` | `DateTime?` | 订阅续费日期 | null |
| `notificationsEnabled` | `bool` | 是否启用通知 | true |
| `unitPreference` | `String?` | 单位偏好 (metric/imperial) | 'imperial' |

### Firestore Schema 更新

```
users/{userId}
  ...existing fields...
  tags: string[]
  contractExpiresAt: timestamp
  subscriptionPlan: string
  subscriptionRenewsAt: timestamp
  notificationsEnabled: boolean
  unitPreference: string
```

---

## 新增文件清单

### 工具类
- `lib/core/utils/unit_converter.dart` - 单位转换工具

### 共享组件
- `lib/features/shared/profile/presentation/widgets/profile_header.dart`
- `lib/features/shared/profile/presentation/widgets/info_card.dart`
- `lib/features/shared/profile/presentation/widgets/info_row.dart`
- `lib/features/shared/profile/presentation/widgets/badge_chip.dart`
- `lib/features/shared/profile/presentation/widgets/settings_row.dart`

### 学生端
- `lib/features/student/profile/presentation/widgets/coach_info_card.dart`
- `lib/features/student/profile/presentation/providers/student_profile_providers.dart`
- `lib/features/student/profile/presentation/pages/student_profile_page.dart` (更新)

### 教练端
- `lib/features/coach/profile/presentation/widgets/subscription_card.dart`
- `lib/features/coach/profile/presentation/providers/coach_profile_providers.dart`
- `lib/features/coach/profile/presentation/pages/coach_profile_page.dart` (更新)

### Settings 相关
- `lib/features/shared/profile/presentation/pages/unit_preference_page.dart`
- `lib/features/shared/profile/presentation/pages/privacy_settings_placeholder_page.dart`
- `lib/features/shared/profile/presentation/pages/account_settings_placeholder_page.dart`
- `lib/features/shared/profile/presentation/pages/help_center_placeholder_page.dart`

---

## 功能特性

### 学生 Profile
- ✅ 显示头像和姓名
- ✅ 显示 "Student" 角色标签
- ✅ Personal Information: Age, Height, Weight (支持单位切换)
- ✅ Coach Info: 教练头像、姓名、认证标签、合约有效期
- ✅ Settings: Notifications, Unit Preference, Privacy Settings, Log Out

### 教练 Profile
- ✅ 显示头像和姓名
- ✅ 显示认证标签（IFFF Pro, Certified）
- ✅ Subscription (Placeholder): Pro Plan, Renews on date, Manage 按钮
- ✅ Settings: Notifications, Unit Preference, Account Settings, Help Center, Log Out

### 单位转换
- ✅ 身高: cm ↔ ft'in"
- ✅ 体重: kg ↔ lbs
- ✅ 用户可切换偏好设置

### Settings 功能
- ✅ Notifications Toggle: 更新到 Firestore
- ✅ Unit Preference: 切换单位偏好
- ✅ Log Out: 登出并跳转到登录页
- ✅ 占位页面: Privacy Settings, Account Settings, Help Center

---

## 技术实现要点

### 1. 认证标签显示
- 从 `UserModel.tags` 读取
- 使用 BadgeChip 组件
- 颜色映射:
  - "IFFF Pro" → `AppColors.infoBlue`
  - "Certified" → `AppColors.successGreen`

### 2. 年龄计算
```dart
int? calculateAge(DateTime? bornDate) {
  if (bornDate == null) return null;
  final now = DateTime.now();
  int age = now.year - bornDate.year;
  if (now.month < bornDate.month ||
      (now.month == bornDate.month && now.day < bornDate.day)) {
    age--;
  }
  return age;
}
```

### 3. 单位转换
```dart
// cm → ft'in"
String formatHeight(double? cm, String preference) {
  if (cm == null) return '--';
  if (preference == 'metric') return '${cm.toStringAsFixed(0)} cm';

  final totalInches = cm / 2.54;
  final feet = totalInches ~/ 12;
  final inches = (totalInches % 12).round();
  return '$feet\'$inches"';
}

// kg → lbs
String formatWeight(double? kg, String preference) {
  if (kg == null) return '--';
  if (preference == 'metric') return '${kg.toStringAsFixed(1)} kg';

  final lbs = (kg * 2.20462).round();
  return '$lbs lbs';
}
```

### 4. 教练信息获取
```dart
final coachInfoProvider = FutureProvider<UserModel?>((ref) async {
  final currentUser = ref.watch(currentUserDataProvider).value;
  if (currentUser?.coachId == null) return null;

  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getUser(currentUser!.coachId!);
});
```

---

## UI 规范遵守

### Typography
- ✅ 所有文字使用 `AppTextStyles.*`
- ❌ 禁止硬编码 fontSize

### Colors
- ✅ 使用 `AppColors.*` 定义的颜色
- 主要颜色: `primaryColor`, `textPrimary`, `backgroundLight`

### Spacing & Dimensions
- ✅ 使用 `AppDimensions.*` 定义的间距
- 卡片间距: `spacingL` (16.0)
- 卡片圆角: `radiusL` (12.0)
- 头像尺寸: 128.0 (需添加 `avatarXXL` 到 AppDimensions)

### Components
- ✅ 优先使用 Cupertino 组件
- CupertinoPageScaffold, CupertinoButton, CupertinoSwitch

---

## 边界情况处理

- 无头像: 显示默认头像图标
- 无出生日期: Age 显示 "--"
- 无身高/体重: 显示 "--"
- 无认证标签: 不显示标签区域
- 学生无教练: 不显示 Coach Info Card
- 教练无订阅信息: 显示 placeholder

---

## 已知限制

1. **Subscription Card**: 当前为 placeholder，Manage 按钮不可用
2. **头像编辑**: 暂未实现上传功能，仅显示编辑按钮
3. **认证标签**: 数据需要后端支持，前端从 Firestore 读取
4. **单位切换**: 仅影响当前显示，需要后端同步偏好设置

---

## 实施进度

### ✅ 已完成
- [ ] 创建实施文档

### 🚧 进行中
- [ ] 扩展 UserModel

### ⏳ 待开始
- [ ] 创建工具类和共享组件
- [ ] 实现学生 Profile 页面
- [ ] 实现教练 Profile 页面
- [ ] Settings 功能实现

---

## 后续优化

1. 头像上传功能 (Firebase Storage)
2. 编辑个人信息功能
3. Subscription 真实数据集成
4. Account Settings 详细页面
5. Help Center 内容
6. Privacy Settings 详细页面

---

## 更新日志

| 日期 | 更新内容 | 更新人 |
|------|---------|--------|
| 2025-10-31 | 初始文档创建 | Claude |
