# 国际化快速参考指南

## 🚀 3步快速上手

### 1. 在文件顶部添加 import
```dart
import 'package:coach_x/l10n/app_localizations.dart';
```

### 2. 在 build 方法中获取 l10n
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  // ... 其余代码
}
```

### 3. 替换硬编码字符串
```dart
// ❌ 错误
Text('登录')

// ✅ 正确
Text(l10n.login)
```

---

## 📋 常用翻译 Key 速查表

### 通用 (Common)
| Key | 中文 | 英文 |
|-----|------|------|
| `l10n.confirm` | 确定 | Confirm |
| `l10n.cancel` | 取消 | Cancel |
| `l10n.delete` | 删除 | Delete |
| `l10n.copy` | 复制 | Copy |
| `l10n.close` | 关闭 | Close |
| `l10n.all` | 全部 | All |
| `l10n.search` | 搜索 | Search |
| `l10n.retry` | 重试 | Retry |
| `l10n.loading` | 加载中... | Loading... |
| `l10n.success` | 成功 | Success |
| `l10n.error` | 错误 | Error |
| `l10n.alert` | 提示 | Alert |

### 认证 (Auth)
| Key | 中文 | 英文 |
|-----|------|------|
| `l10n.appName` | CoachX | CoachX |
| `l10n.appTagline` | AI教练学生管理平台 | AI Coaching Platform |
| `l10n.login` | 登录 | Login |
| `l10n.register` | 注册 | Register |
| `l10n.emailPlaceholder` | 邮箱地址 | Email address |
| `l10n.passwordPlaceholder` | 密码 | Password |
| `l10n.forgotPassword` | 忘记密码？ | Forgot password? |
| `l10n.loginFailed` | 登录失败 | Login failed |

### Tab 导航
| Key | 中文 | 英文 |
|-----|------|------|
| `l10n.tabHome` | 首页 | Home |
| `l10n.tabStudents` | 学生 | Students |
| `l10n.tabPlans` | 计划 | Plans |
| `l10n.tabChat` | 聊天 | Chat |
| `l10n.tabProfile` | 资料 | Profile |

### 学生管理 (Students)
| Key | 中文 | 英文 |
|-----|------|------|
| `l10n.noStudents` | 暂无学生 | No students |
| `l10n.inviteStudents` | 邀请学生 | Invite students |
| `l10n.deleteStudent` | 删除学生 | Delete student |
| `l10n.studentDeleted` | 学生已删除 | Student deleted |

### 计划管理 (Plans)
| Key | 中文 | 英文 |
|-----|------|------|
| `l10n.plansTitle` | 计划 | Plans |
| `l10n.createPlan` | 创建计划 | Create plan |
| `l10n.copyPlan` | 复制计划 | Copy plan |
| `l10n.deletePlan` | 删除计划 | Delete plan |
| `l10n.noPlansYet` | 暂无计划 | No plans yet |

### Profile 相关
| Key | 中文 | 英文 |
|-----|------|------|
| `l10n.profile` | 个人资料 | Profile |
| `l10n.settings` | 设置 | Settings |
| `l10n.language` | 语言 | Language |
| `l10n.logOut` | 退出登录 | Log Out |
| `l10n.personalInformation` | 个人信息 | Personal Information |

---

## 🔧 常见场景示例

### 场景 1：简单文本
```dart
Text(l10n.login)  // "登录" / "Login"
```

### 场景 2：带参数的文本
```dart
// ARB文件中定义
"studentCount": "{count} students"

// 使用
Text(l10n.studentCount(25))  // "25 students"
```

### 场景 3：输入框占位符
```dart
CustomTextField(
  placeholder: l10n.emailPlaceholder,  // "邮箱地址" / "Email address"
)
```

### 场景 4：导航栏标题
```dart
CupertinoNavigationBar(
  middle: Text(l10n.plansTitle),  // "计划" / "Plans"
)
```

### 场景 5：对话框
```dart
showCupertinoDialog(
  context: context,
  builder: (context) {
    final l10n = AppLocalizations.of(context)!;
    return CupertinoAlertDialog(
      title: Text(l10n.confirmDelete),
      content: Text(l10n.confirmDeleteStudent('张三')),
      actions: [
        CupertinoDialogAction(
          child: Text(l10n.cancel),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          child: Text(l10n.delete),
          onPressed: () {
            // 删除逻辑
            Navigator.pop(context);
          },
        ),
      ],
    );
  },
);
```

### 场景 6：按钮文字
```dart
CustomButton(
  text: l10n.login,  // "登录" / "Login"
  onPressed: _handleLogin,
)
```

### 场景 7：Validator 错误消息
```dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return l10n.passwordRequired;  // "请输入密码" / "Please enter password"
  }
  return null;
}
```

---

## ⚠️ 常见错误

### 错误 1：忘记移除 const
```dart
// ❌ 错误
const Text(l10n.login)

// ✅ 正确
Text(l10n.login)
```

### 错误 2：在非 Widget 方法中没有获取 l10n
```dart
// ❌ 错误
void _showDialog() {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.alert),  // l10n 未定义
    ),
  );
}

// ✅ 正确
void _showDialog() {
  final l10n = AppLocalizations.of(context)!;  // 在方法中获取
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.alert),
    ),
  );
}
```

### 错误 3：参数化字符串使用错误
```dart
// ❌ 错误
Text('${l10n.studentCount} 25')

// ✅ 正确
Text(l10n.studentCount(25))
```

---

## 📝 添加新翻译的快速步骤

### Step 1: 编辑 app_en.arb
```json
{
  "yourNewKey": "Your English Text",
  "@yourNewKey": {
    "description": "Description of this key"
  }
}
```

### Step 2: 编辑 app_zh.arb
```json
{
  "yourNewKey": "你的中文文字"
}
```

### Step 3: 生成代码
```bash
flutter gen-l10n
```

### Step 4: 使用新 Key
```dart
Text(l10n.yourNewKey)
```

---

## 🔍 快速查找硬编码字符串

### 查找中文字符串
```bash
grep -r "Text('[^']*[\u4e00-\u9fa5]" lib/ --include="*.dart" | grep -v "// "
```

### 查找硬编码占位符
```bash
grep -r "placeholder: '" lib/ --include="*.dart" | grep -v "l10n."
```

### 查找 const Text
```bash
grep -r "const Text(" lib/ --include="*.dart"
```

---

## 📚 完整文档链接

- **详细实施指南**：[docs/i18n_implementation_guide.md](i18n_implementation_guide.md)
- **README.md 国际化章节**：[../README.md#国际化-internationalization---mandatory-️](../README.md)
- **CLAUDE.md 规范**：[../CLAUDE.md#internationalization-i18n---mandatory](../CLAUDE.md)

---

**快速问答**：

**Q: 何时需要移除 const？**
A: 当 Text 的内容从字面量变为变量（如 `l10n.login`）时。

**Q: 如何处理带变量的字符串？**
A: 在 ARB 文件中定义占位符，使用函数式调用：`l10n.studentCount(25)`

**Q: 对话框中如何使用 l10n？**
A: 在 builder 函数内部获取：`final l10n = AppLocalizations.of(context)!;`

**Q: 忘记运行 gen-l10n 会怎样？**
A: 编译错误，提示找不到新添加的 key。运行 `flutter gen-l10n` 或 `flutter pub get` 即可。

---

**最后更新**：2025-11-01
**版本**：1.0
