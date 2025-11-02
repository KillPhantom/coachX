# CoachX - 阶段二：Firebase集成 - 实施计划

> **阶段**: 阶段二 - Firebase集成  
> **状态**: 计划阶段  
> **创建日期**: 2025-10-19  
> **预估工作量**: 5-7个工作日  
> **前置条件**: 阶段一基础框架已完成

---

## 一、阶段目标

完成Firebase后端服务的集成，包括：
1. Firebase项目创建和配置
2. Firebase Authentication集成
3. Firestore数据库设计和初始化
4. Firebase Storage配置
5. Cloud Functions项目搭建
6. 基础API实现和测试

**验收标准**:
- Firebase项目正常运行
- 用户可以注册和登录
- Firestore可以读写数据
- Storage可以上传文件
- Cloud Functions可以正常部署和调用
- 应用可以与Firebase完整通信

---

## 二、Firebase项目配置规格

### 2.1 Firebase Console配置

**步骤**:
1. 访问 https://console.firebase.google.com/
2. 创建新项目 `coachx-dev` (开发环境)
3. 启用以下服务：
   - Authentication (邮箱/密码登录)
   - Cloud Firestore
   - Storage
   - Cloud Functions
4. 创建iOS应用（Bundle ID: com.coachx.app）
5. 创建Android应用（Package name: com.coachx.app）
6. 下载配置文件：
   - iOS: GoogleService-Info.plist
   - Android: google-services.json

### 2.2 Flutter项目配置文件

**需要添加的配置文件**:

**iOS配置** (`ios/Runner/GoogleService-Info.plist`):
- 从Firebase Console下载
- 放置到 `ios/Runner/` 目录
- 在Xcode中添加到项目

**Android配置** (`android/app/google-services.json`):
- 从Firebase Console下载
- 放置到 `android/app/` 目录

**Android Gradle配置**:
```gradle
// android/build.gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}

// android/app/build.gradle
apply plugin: 'com.google.gms.google-services'

defaultConfig {
    applicationId "com.coachx.app"
    minSdkVersion 21  // Firebase需要
}
```

### 2.3 Flutter依赖配置

**需要添加的Firebase相关包**:
```yaml
dependencies:
  # Firebase核心
  firebase_core: ^2.24.2  # 已添加
  
  # Firebase服务
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  cloud_functions: ^4.5.12
  
  # Firebase UI (可选)
  firebase_ui_auth: ^1.10.0
  
  # 图片选择
  image_picker: ^1.0.5
```

---

## 三、Authentication实现规格

### 3.1 认证服务封装

**文件**: `lib/core/services/auth_service.dart`

**需要实现的方法**:
```dart
class AuthService {
  // 邮箱密码注册
  Future<UserCredential> signUpWithEmail(String email, String password);
  
  // 邮箱密码登录
  Future<UserCredential> signInWithEmail(String email, String password);
  
  // 退出登录
  Future<void> signOut();
  
  // 获取当前用户
  User? getCurrentUser();
  
  // 监听认证状态变化
  Stream<User?> authStateChanges();
  
  // 发送邮箱验证
  Future<void> sendEmailVerification();
  
  // 重置密码
  Future<void> resetPassword(String email);
  
  // 更新用户信息
  Future<void> updateProfile({String? displayName, String? photoURL});
}
```

### 3.2 用户状态管理

**文件**: `lib/features/auth/data/providers/auth_providers.dart`

**需要实现的Providers**:
```dart
// 认证状态Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 当前用户Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

// 是否已登录Provider
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
```

### 3.3 登录页面实现

**文件**: `lib/features/auth/presentation/pages/login_page.dart`

**需要实现的功能**:
- 邮箱输入框（带验证）
- 密码输入框（带验证）
- 登录按钮（带加载状态）
- 注册按钮（跳转到注册页）
- 忘记密码链接
- 错误提示显示

**文件**: `lib/features/auth/presentation/pages/register_page.dart`

**需要实现的功能**:
- 邮箱输入
- 密码输入
- 确认密码输入
- 用户名输入
- 角色选择（学生/教练）
- 邀请码输入（教练需要）
- 注册按钮
- 返回登录链接

### 3.4 路由守卫更新

**文件**: `lib/routes/route_guards.dart`

**更新内容**:
- 从Firebase Auth获取真实登录状态
- 从Firestore获取用户角色
- 实现完整的权限控制逻辑

---

## 四、Firestore数据库设计

### 4.1 数据库结构

**集合设计** (基于API文档):

```
firestore/
├── users/                          # 用户集合
│   └── {userId}/                   # 用户文档
│       ├── role: string
│       ├── name: string
│       ├── email: string
│       ├── avatarUrl: string
│       ├── coachId: string
│       ├── createdAt: timestamp
│       └── ...
│
├── exercisePlans/                  # 训练计划集合
│   └── {planId}/
│       ├── name: string
│       ├── ownerId: string
│       ├── days: array
│       └── ...
│
├── dietPlans/                      # 饮食计划集合
│   └── {planId}/
│
├── supplementPlans/                # 补剂计划集合
│   └── {planId}/
│
├── dailyTrainings/                 # 每日训练记录集合
│   └── {recordId}/
│
├── exerciseFeedback/               # 动作反馈集合
│   └── {feedbackId}/
│
├── bodyMeasurements/               # 身体测量集合
│   └── {measurementId}/
│
└── invitationCodes/                # 邀请码集合
    └── {codeId}/
```

### 4.2 Security Rules

**文件**: `firestore.rules`

**基础规则**:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 辅助函数
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function getUserRole() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role;
    }
    
    function isCoach() {
      return isAuthenticated() && getUserRole() == 'coach';
    }
    
    function isStudent() {
      return isAuthenticated() && getUserRole() == 'student';
    }
    
    // 用户集合规则
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false;
    }
    
    // 训练计划规则
    match /exercisePlans/{planId} {
      allow read: if isAuthenticated();
      allow create: if isCoach();
      allow update: if isCoach() && resource.data.ownerId == request.auth.uid;
      allow delete: if isCoach() && resource.data.ownerId == request.auth.uid;
    }
    
    // 每日训练记录规则
    match /dailyTrainings/{recordId} {
      allow read: if isAuthenticated();
      allow create, update: if isAuthenticated();
      allow delete: if false;
    }
    
    // 邀请码规则
    match /invitationCodes/{codeId} {
      allow read: if true;  // 任何人都可以读取（验证邀请码）
      allow create: if isCoach();
      allow update: if isCoach();
      allow delete: if false;
    }
  }
}
```

### 4.3 Firestore服务封装

**文件**: `lib/core/services/firestore_service.dart`

**基础CRUD方法**:
```dart
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 添加文档
  Future<String> addDocument(String collection, Map<String, dynamic> data);
  
  // 更新文档
  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data);
  
  // 删除文档
  Future<void> deleteDocument(String collection, String docId);
  
  // 获取文档
  Future<DocumentSnapshot> getDocument(String collection, String docId);
  
  // 查询文档列表
  Future<List<DocumentSnapshot>> queryDocuments(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    int? limit,
  });
  
  // 监听文档变化
  Stream<DocumentSnapshot> watchDocument(String collection, String docId);
  
  // 监听集合变化
  Stream<QuerySnapshot> watchCollection(String collection);
}
```

### 4.4 用户Repository实现

**文件**: `lib/features/auth/data/repositories/user_repository_impl.dart`

**实现接口**:
```dart
class UserRepositoryImpl implements UserRepository {
  final FirestoreService _firestore;
  
  @override
  Future<void> createUser(UserModel user);
  
  @override
  Future<UserModel?> getUser(String userId);
  
  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data);
  
  @override
  Stream<UserModel?> watchUser(String userId);
}
```

---

## 五、Firebase Storage配置

### 5.1 Storage结构设计

```
storage/
├── avatars/                        # 用户头像
│   └── {userId}/
│       └── avatar.jpg
│
├── training_videos/                # 训练视频
│   └── {userId}/
│       └── {timestamp}.mp4
│
├── training_images/                # 训练图片
│   └── {userId}/
│       └── {timestamp}.jpg
│
├── body_stats/                     # 身体测量图片
│   └── {userId}/
│       └── {timestamp}.jpg
│
└── diet_images/                    # 饮食图片
    └── {userId}/
        └── {timestamp}.jpg
```

### 5.2 Storage Rules

**文件**: `storage.rules`

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // 辅助函数
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isVideo() {
      return request.resource.contentType.matches('video/.*');
    }
    
    function isValidSize(maxSizeMB) {
      return request.resource.size < maxSizeMB * 1024 * 1024;
    }
    
    // 头像规则
    match /avatars/{userId}/{fileName} {
      allow read: if true;
      allow write: if isAuthenticated() 
                   && isOwner(userId) 
                   && isImage() 
                   && isValidSize(5);
    }
    
    // 训练视频规则
    match /training_videos/{userId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
                   && isOwner(userId) 
                   && isVideo() 
                   && isValidSize(50);
    }
    
    // 训练图片规则
    match /training_images/{userId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() 
                   && isOwner(userId) 
                   && isImage() 
                   && isValidSize(10);
    }
  }
}
```

### 5.3 Storage服务封装

**文件**: `lib/core/services/storage_service.dart`

**需要实现的方法**:
```dart
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // 上传文件
  Future<String> uploadFile(
    File file,
    String path, {
    Function(double)? onProgress,
  });
  
  // 上传图片（带压缩）
  Future<String> uploadImage(
    File image,
    String path, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
    Function(double)? onProgress,
  });
  
  // 删除文件
  Future<void> deleteFile(String path);
  
  // 获取下载URL
  Future<String> getDownloadURL(String path);
  
  // 获取文件元数据
  Future<FullMetadata> getMetadata(String path);
}
```

---

## 六、Cloud Functions搭建（Python）

### 6.1 Functions项目初始化

**项目配置**:
- **语言**: Python 3.11+
- **Framework**: Firebase Functions 2nd gen
- **优势**: 便于AI集成、数据处理能力强

**步骤**:
1. 创建 `functions` 目录
2. 初始化Firebase Functions (Python)
3. 配置虚拟环境
4. 安装Firebase Functions SDK

**目录结构**:
```
functions/
├── main.py                         # 函数入口
├── requirements.txt                # Python依赖
├── .gitignore
├── api/
│   ├── __init__.py
│   ├── auth/                       # 认证相关API
│   │   ├── __init__.py
│   │   └── handlers.py
│   ├── users/                      # 用户相关API
│   │   ├── __init__.py
│   │   └── handlers.py
│   ├── plans/                      # 计划相关API
│   │   ├── __init__.py
│   │   └── handlers.py
│   ├── training/                   # 训练相关API
│   │   ├── __init__.py
│   │   └── handlers.py
│   └── ai/                         # AI相关API
│       ├── __init__.py
│       └── handlers.py
├── utils/
│   ├── __init__.py
│   ├── validators.py               # 验证工具
│   ├── helpers.py                  # 辅助函数
│   └── firebase_admin.py           # Firebase Admin配置
└── models/
    ├── __init__.py
    └── schemas.py                  # 数据模型
```

### 6.2 基础Functions实现

**文件**: `functions/main.py`

**需要实现的基础API**:
```python
from firebase_functions import https_fn
from firebase_admin import initialize_app, firestore
import firebase_admin

# 初始化Firebase Admin
initialize_app()

# 用户相关
@https_fn.on_call()
def fetch_user_info(req: https_fn.CallableRequest):
    """获取用户信息"""
    user_id = req.auth.uid if req.auth else None
    if not user_id:
        raise https_fn.HttpsError('unauthenticated', '用户未登录')
    
    # 实现获取用户信息逻辑
    return {"status": "success", "data": {}}

@https_fn.on_call()
def update_user_info(req: https_fn.CallableRequest):
    """更新用户信息"""
    user_id = req.auth.uid if req.auth else None
    if not user_id:
        raise https_fn.HttpsError('unauthenticated', '用户未登录')
    
    # 实现更新用户信息逻辑
    return {"status": "success"}

# 邀请码相关
@https_fn.on_call()
def verify_invitation_code(req: https_fn.CallableRequest):
    """验证邀请码"""
    code = req.data.get('code')
    if not code:
        raise https_fn.HttpsError('invalid-argument', '邀请码不能为空')
    
    # 实现验证邀请码逻辑
    return {"status": "success", "valid": True}

@https_fn.on_call()
def generate_invitation_codes(req: https_fn.CallableRequest):
    """生成邀请码（教练专用）"""
    user_id = req.auth.uid if req.auth else None
    if not user_id:
        raise https_fn.HttpsError('unauthenticated', '用户未登录')
    
    # 验证教练身份
    # 实现生成邀请码逻辑
    return {"status": "success", "codes": []}
```

### 6.3 Functions部署配置

**文件**: `functions/requirements.txt`

```txt
firebase-functions>=0.4.0
firebase-admin>=6.3.0
google-cloud-firestore>=2.14.0
google-cloud-storage>=2.14.0
```

**本地开发命令**:
```bash
# 安装依赖
cd functions
pip install -r requirements.txt

# 本地测试
firebase emulators:start --only functions

# 部署函数
firebase deploy --only functions

# 查看日志
firebase functions:log
```

---

## 七、Flutter端集成

### 7.1 Firebase初始化

**文件**: `lib/core/services/firebase_init_service.dart`

```dart
class FirebaseInitService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 配置Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    // 配置Storage
    // ...
  }
}
```

**更新main.dart**:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Firebase
  await FirebaseInitService.initialize();
  
  // 其他初始化...
  
  runApp(const ProviderScope(child: CoachXApp()));
}
```

### 7.2 网络层集成

**文件**: `lib/core/services/cloud_functions_service.dart`

```dart
class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // 调用Cloud Function
  Future<T> call<T>(
    String functionName,
    Map<String, dynamic>? params,
  ) async {
    try {
      final result = await _functions
          .httpsCallable(functionName)
          .call(params);
      return result.data as T;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
```

---

## 八、实施检查清单

### 第一步：Firebase Console配置（1天）
1. 创建Firebase项目
2. 启用Authentication服务
3. 配置邮箱/密码登录
4. 启用Cloud Firestore
5. 启用Storage
6. 启用Cloud Functions
7. 创建iOS应用配置
8. 创建Android应用配置
9. 下载配置文件

### 第二步：Flutter项目配置（0.5天）
10. 安装Firebase CLI工具
11. 运行 `flutterfire configure`
12. 添加iOS配置文件
13. 添加Android配置文件
14. 更新Android Gradle配置
15. 添加Firebase相关依赖包
16. 运行 `flutter pub get`

### 第三步：Firebase初始化（0.5天）
17. 创建FirebaseInitService
18. 更新main.dart初始化逻辑
19. 配置Firestore设置
20. 配置Storage设置
21. 测试Firebase初始化

### 第四步：Authentication服务（1.5天）
22. 创建AuthService类
23. 实现邮箱密码注册
24. 实现邮箱密码登录
25. 实现退出登录
26. 实现获取当前用户
27. 实现认证状态监听
28. 创建AuthProviders
29. 更新路由守卫逻辑
30. 测试认证流程

### 第五步：登录注册页面（1天）
31. 实现登录页面UI
32. 实现登录表单验证
33. 实现登录逻辑
34. 实现加载状态
35. 实现错误提示
36. 创建注册页面
37. 实现注册表单
38. 实现角色选择
39. 实现邀请码验证
40. 测试登录注册流程

### 第六步：Firestore配置（1天）
41. 设计数据库集合结构
42. 编写Security Rules
43. 部署Security Rules
44. 创建FirestoreService
45. 实现基础CRUD方法
46. 创建UserRepository
47. 实现用户数据操作
48. 测试Firestore读写

### 第七步：Storage配置（0.5天）
49. 设计Storage目录结构
50. 编写Storage Rules
51. 部署Storage Rules
52. 创建StorageService
53. 实现文件上传方法
54. 实现图片压缩上传
55. 测试Storage上传

### 第八步：Cloud Functions搭建（Python）（1.5天）
56. 初始化Functions项目（Python）
57. 配置Python虚拟环境
58. 创建基础函数结构（main.py）
59. 实现fetchUserInfo函数
60. 实现updateUserInfo函数
61. 实现verifyInvitationCode函数
62. 实现generateInvitationCodes函数
63. 本地测试Functions（Firebase Emulator）
64. 部署Functions到Firebase

### 第九步：Flutter端集成（1天）
65. 创建CloudFunctionsService
66. 实现函数调用封装
67. 集成到Repository层
68. 实现错误处理
69. 添加重试机制
70. 测试端到端通信

### 第十步：邀请码系统（0.5天）
71. 实现邀请码生成页面（教练端）
72. 实现邀请码验证逻辑
73. 集成到注册流程
74. 测试邀请码功能

### 第十一步：用户资料管理（1天）
75. 实现用户资料展示页面
76. 实现头像上传功能
77. 实现资料编辑功能
78. 实现数据同步
79. 测试资料管理功能

### 第十二步：集成测试（1天）
80. 测试完整注册流程
81. 测试完整登录流程
82. 测试邀请码验证
83. 测试用户资料管理
84. 测试文件上传
85. 测试数据同步
86. 测试离线功能
87. 修复发现的问题

### 第十三步：代码优化（0.5天）
88. 代码格式化
89. 添加必要注释
90. 优化错误处理
91. 优化加载状态
92. 清理测试代码

### 第十四步：文档更新（0.5天）
93. 更新README
94. 创建Firebase配置文档
95. 创建API使用文档
96. 更新架构设计文档

### 第十五步：Git提交（0.5天）
97. Git add所有文件
98. 创建详细的commit信息
99. 推送到远程仓库
100. 创建Pull Request

---

## 九、验收标准

### 9.1 功能验收
- ✅ 用户可以通过邮箱密码注册
- ✅ 教练注册需要有效邀请码
- ✅ 用户可以登录和退出
- ✅ 登录状态持久化
- ✅ 用户资料可以查看和编辑
- ✅ 头像可以上传和显示
- ✅ Firestore数据正常读写
- ✅ Cloud Functions正常调用
- ✅ 离线模式基本可用

### 9.2 技术验收
- ✅ Firebase配置正确
- ✅ Security Rules部署成功
- ✅ Storage Rules部署成功
- ✅ Cloud Functions部署成功
- ✅ 无内存泄漏
- ✅ 错误处理完善
- ✅ 代码通过flutter analyze
- ✅ 关键流程有日志

### 9.3 文档验收
- ✅ Firebase配置文档完整
- ✅ API使用说明清晰
- ✅ 代码注释充分
- ✅ README更新

---

## 十、风险与应对

### 10.1 技术风险

**风险1**: Firebase配置复杂，可能配置错误
- **应对**: 使用flutterfire CLI自动配置
- **应对**: 详细记录每步配置

**风险2**: Security Rules编写错误导致安全问题
- **应对**: 从严格规则开始
- **应对**: 充分测试规则
- **应对**: 使用Firebase Rules Playground测试

**风险3**: Cloud Functions冷启动延迟
- **应对**: 实现客户端缓存
- **应对**: 优化函数代码
- **应对**: 考虑使用Cloud Run（后期）

### 10.2 开发风险

**风险1**: 邀请码系统设计不当
- **应对**: 参考API文档设计
- **应对**: 添加使用限制和过期机制

**风险2**: 文件上传失败率高
- **应对**: 实现断点续传
- **应对**: 添加重试机制
- **应对**: 压缩图片减小大小

---

## 十一、下一步展望

完成阶段二后，将进入**阶段三：核心功能实现**：
- 学生端训练记录功能
- 教练端计划管理功能
- 实时对话功能
- 数据同步和缓存优化

---

**文档版本**: v1.0  
**下一步**: 等待执行命令

