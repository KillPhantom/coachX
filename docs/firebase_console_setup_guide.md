# Firebase Console 配置指南

> **适用阶段**: 阶段二开始前  
> **预估时间**: 30-60分钟  
> **前置条件**: Google账号  
> **目标**: 完成Firebase项目的基础配置

---

## 一、创建Firebase项目

### 1.1 访问Firebase Console

**步骤**:
1. 打开浏览器，访问: https://console.firebase.google.com/
2. 使用您的Google账号登录
3. 点击「添加项目」或「Create a project」

### 1.2 配置项目基本信息

**第一步 - 项目名称**:
```
项目名称: coachx-dev
```
- 注意: 项目ID会自动生成（如 `coachx-dev-xxxxx`）
- 建议: 开发环境用 `-dev` 后缀，生产环境用 `-prod`

**第二步 - Google Analytics**:
- 建议: 先启用Google Analytics（可以后期再详细配置）
- 选择或创建Analytics账号

**第三步 - 确认并创建**:
- 阅读并接受条款
- 点击「创建项目」
- 等待项目创建完成（约30秒-1分钟）

---

## 二、配置Authentication

### 2.1 启用Authentication服务

**步骤**:
1. 在左侧菜单找到「构建」→「Authentication」
2. 点击「开始使用」按钮
3. 等待服务初始化

### 2.2 配置登录方式

**启用邮箱/密码登录**:
1. 在「Sign-in method」标签页
2. 找到「电子邮件地址/密码」（Email/Password）
3. 点击进入
4. 启用「电子邮件地址/密码」开关
5. **不要**启用「电子邮件链接（无密码登录）」（暂时不需要）
6. 点击「保存」

### 2.3 配置项目设置（可选但推荐）

**在「Settings」→「Authorized domains」中**:
- 默认已添加：`localhost` 和 `*.firebaseapp.com`
- 生产环境时需要添加您的域名

---

## 三、配置Cloud Firestore

### 3.1 启用Firestore服务

**步骤**:
1. 左侧菜单「构建」→「Firestore Database」
2. 点击「创建数据库」
3. 选择模式：
   - **开发阶段建议**: 「测试模式」（Test mode）
     - 30天后自动禁用写入
     - 可以快速测试
   - **或者**: 「生产模式」（Production mode）
     - 需要立即配置Security Rules
     - 更安全但需要配置

4. 选择Firestore位置：
   - **推荐**: `asia-east1` (台湾) 或 `asia-northeast1` (东京)
   - **重要**: 位置一旦选定**无法更改**
   - 考虑：用户地理位置、延迟、成本

5. 点击「启用」

### 3.2 初始化集合结构（可选）

**现在暂时不需要手动创建集合**，代码运行时会自动创建，但您可以了解即将使用的集合：

```
firestore/
├── users/                    # 用户信息
├── exercisePlans/            # 训练计划
├── dietPlans/                # 饮食计划
├── supplementPlans/          # 补剂计划
├── dailyTrainings/           # 每日训练记录
├── exerciseFeedback/         # 动作反馈
├── bodyMeasurements/         # 身体测量
├── mealRecords/              # 饮食记录
├── supplementRecords/        # 补剂记录
└── invitationCodes/          # 邀请码
```

---

## 四、配置Storage

### 4.1 启用Storage服务

**步骤**:
1. 左侧菜单「构建」→「Storage」
2. 点击「开始使用」
3. 选择规则模式：
   - **开发阶段建议**: 「测试模式」
   - 允许所有读写（30天有效期）
4. 选择Storage位置：
   - **重要**: 建议选择与Firestore相同的位置
   - 推荐：`asia-east1` 或 `asia-northeast1`
5. 点击「完成」

### 4.2 了解Storage结构

**即将使用的目录结构**：
```
storage/
├── avatars/                  # 用户头像
├── training_videos/          # 训练视频
├── training_images/          # 训练图片
├── body_stats/               # 身体测量照片
└── diet_images/              # 饮食照片
```

---

## 五、配置Cloud Functions

### 5.1 升级到Blaze计划（按量付费）

**重要**: Cloud Functions需要Blaze计划才能使用

**步骤**:
1. 左侧菜单底部「升级」或右上角「Upgrade」
2. 选择「Blaze」计划
3. 设置预算提醒（建议）：
   - 金额: $10-20/月（开发阶段）
   - 达到阈值时接收邮件提醒
4. 添加付款方式
5. 确认升级

**费用说明**:
- **免费额度**（每月）：
  - Functions调用: 200万次
  - 外网出口流量: 5GB
  - 构建时间: 120分钟
- **开发阶段预估**: $0-5/月
- **小规模生产**: $10-50/月

### 5.2 启用Functions服务

**步骤**:
1. 左侧菜单「构建」→「Functions」
2. 点击「开始使用」
3. 等待服务初始化
4. **暂时不需要创建函数**，这将在代码中完成

---

## 六、添加应用配置

### 6.1 添加iOS应用

**步骤**:
1. 在项目概览页面，点击「iOS」图标
2. 填写应用信息：
   ```
   iOS Bundle ID: com.coachx.app
   应用昵称（可选）: CoachX iOS
   App Store ID（可选）: 留空
   ```
3. 点击「注册应用」
4. **下载配置文件**: `GoogleService-Info.plist`
   - ⚠️ **重要**: 立即下载并保存到安全位置
   - 稍后需要放到: `coach_x/ios/Runner/GoogleService-Info.plist`
5. 点击「下一步」（后续配置步骤可以跳过，代码中会处理）
6. 点击「继续访问控制台」

### 6.2 添加Android应用

**步骤**:
1. 在项目概览页面，点击「Android」图标
2. 填写应用信息：
   ```
   Android Package Name: com.coachx.app
   应用昵称（可选）: CoachX Android
   调试签名证书SHA-1（可选）: 留空（开发阶段）
   ```
3. 点击「注册应用」
4. **下载配置文件**: `google-services.json`
   - ⚠️ **重要**: 立即下载并保存到安全位置
   - 稍后需要放到: `coach_x/android/app/google-services.json`
5. 点击「下一步」（后续配置步骤可以跳过）
6. 点击「继续访问控制台」

---

## 七、配置项目设置

### 7.1 项目基本设置

**步骤**:
1. 点击左上角「⚙️ 项目设置」
2. 在「常规」标签页中：
   - **项目名称**: `coachx-dev`（已设置）
   - **项目ID**: 记录下来（如 `coachx-dev-xxxxx`）
   - **公开项目名称**: 可以修改为 `CoachX`

### 7.2 启用Google Cloud API（可选但推荐）

**为了后续使用AI功能，建议提前启用**:

1. 在「项目设置」→「集成」→「Google Cloud」
2. 点击「在Google Cloud Console中打开」
3. 在Google Cloud Console中启用以下API（可以后续再做）：
   - Cloud Vision API（图片识别）
   - Cloud Translation API（翻译，如果需要）
   - Vertex AI API（AI功能，如果需要）

---

## 八、安全检查清单

### 8.1 权限和规则检查

在开发初期，请确认：

**Authentication**:
- ✅ 已启用邮箱/密码登录
- ✅ 未启用其他不需要的登录方式

**Firestore**:
- ✅ 数据库已创建
- ✅ 位置已选择（无法更改）
- ⚠️ 如果选择了「测试模式」，记得**30天后**需要更新规则

**Storage**:
- ✅ Storage已启用
- ✅ 位置与Firestore一致
- ⚠️ 如果选择了「测试模式」，记得**30天后**需要更新规则

**Functions**:
- ✅ 已升级到Blaze计划
- ✅ 已设置预算提醒

### 8.2 配置文件确认

**请确认您已下载并保存**:
- ✅ `GoogleService-Info.plist` (iOS)
- ✅ `google-services.json` (Android)

**文件保存位置建议**:
```
~/Downloads/
├── GoogleService-Info.plist
└── google-services.json
```

---

## 九、记录重要信息

**请在安全的地方记录以下信息**（建议使用密码管理器或加密文档）：

```
# Firebase项目信息
项目名称: coachx-dev
项目ID: coachx-dev-xxxxx（从控制台复制）
项目编号: 123456789（从项目设置中获取）

# 地区选择
Firestore位置: asia-east1
Storage位置: asia-east1

# 配置文件
iOS配置文件: GoogleService-Info.plist ✓ 已下载
Android配置文件: google-services.json ✓ 已下载

# Web控制台链接
项目控制台: https://console.firebase.google.com/project/coachx-dev-xxxxx
Authentication: https://console.firebase.google.com/project/coachx-dev-xxxxx/authentication
Firestore: https://console.firebase.google.com/project/coachx-dev-xxxxx/firestore
Storage: https://console.firebase.google.com/project/coachx-dev-xxxxx/storage
Functions: https://console.firebase.google.com/project/coachx-dev-xxxxx/functions
```

---

## 十、验证配置完成

### 10.1 Firebase Console检查

在项目概览页面，确认：
- ✅ 显示1个iOS应用
- ✅ 显示1个Android应用
- ✅ Authentication服务已启用
- ✅ Firestore已创建
- ✅ Storage已启用
- ✅ Functions已启用（显示Blaze计划）

### 10.2 配置文件检查

**GoogleService-Info.plist** 应包含：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>xxxxx.apps.googleusercontent.com</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>com.googleusercontent.apps.xxxxx</string>
    <key>API_KEY</key>
    <string>xxxxx</string>
    <key>GCM_SENDER_ID</key>
    <string>xxxxx</string>
    <key>PROJECT_ID</key>
    <string>coachx-dev-xxxxx</string>
    ...
</dict>
</plist>
```

**google-services.json** 应包含：
```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "coachx-dev-xxxxx",
    ...
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:xxxxx:android:xxxxx",
        "android_client_info": {
          "package_name": "com.coachx.app"
        }
      },
      ...
    }
  ],
  ...
}
```

---

## 十一、常见问题

### Q1: 项目ID已存在怎么办？
**A**: 项目ID必须全球唯一，尝试：
- `coachx-dev-2024`
- `coachx-dev-yourname`
- `coachx-app-dev`

### Q2: 无法升级到Blaze计划？
**A**: 可能原因：
- 需要绑定信用卡/借记卡
- 账号所在地区限制
- Google Cloud账号未激活

**解决方案**: 暂时可以不使用Cloud Functions，先完成其他功能

### Q3: 选择哪个地区最好？
**A**: 考虑因素：
- **用户位置**: 中国大陆用户建议 `asia-east1` (台湾)
- **延迟**: 越近越好
- **成本**: 不同地区价格略有差异
- **重要**: 一旦选择无法更改！

### Q4: 测试模式的30天限制怎么办？
**A**: 两个选择：
1. **推荐**: 在30天内部署正式的Security Rules（阶段二会实现）
2. 30天后手动延长测试模式（不建议，仅用于开发）

### Q5: 下载的配置文件丢了怎么办？
**A**: 可以重新下载：
1. 进入「项目设置」
2. 找到对应的应用（iOS/Android）
3. 点击「下载 GoogleService-Info.plist」或「下载 google-services.json」

### Q6: 需要立即配置Security Rules吗？
**A**: 
- **开发阶段**: 使用测试模式即可
- **阶段二执行时**: 会部署完整的Security Rules
- **生产环境**: 必须配置严格的Rules

---

## 十二、下一步行动

### ✅ 配置完成后

**您已准备好开始阶段二的代码实施！**

**下一步命令**:
```
进入执行模式
```

**或者确认配置**:
```
我已完成Firebase Console配置，确认信息：
- 项目ID: [您的项目ID]
- 配置文件已下载: ✓
- Firestore位置: [您选择的位置]
```

---

## 十三、安全提醒

⚠️ **重要安全提示**:

1. **配置文件安全**:
   - ❌ 不要将配置文件提交到公开的Git仓库
   - ✅ 配置文件应该在 `.gitignore` 中
   - ✅ 团队成员需要各自配置

2. **API密钥安全**:
   - Firebase配置文件中的API密钥是受限制的
   - 可以安全地包含在客户端应用中
   - 但Security Rules必须配置正确

3. **预算控制**:
   - 定期检查Firebase使用量
   - 设置合理的预算提醒
   - 监控异常流量

---

**文档版本**: v1.0  
**创建日期**: 2025-10-19  
**适用项目**: CoachX  
**下一步**: 完成配置后开始阶段二代码实施

