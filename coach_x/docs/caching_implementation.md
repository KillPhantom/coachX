# 客户端缓存实现文档

## 📋 概述

本文档记录 CoachX 客户端缓存系统的实现细节，使用 Hive 作为本地存储方案，减少 Cloud Function 调用次数，提升应用性能。

---

## 🎯 目标

- **性能优化**: 减少 Cloud Function 调用，提升页面加载速度
- **用户体验**: 降低网络延迟，提供更流畅的交互
- **成本控制**: 减少 Firebase Cloud Functions 调用次数，降低费用

---

## 🏗️ 技术架构

### 缓存方案选择

| 方案 | 性能 | 适用场景 | 选择 |
|------|------|---------|------|
| **SharedPreferences** | 写入慢(~160ms/20条) | 简单配置数据 | ✅ User role/ID |
| **Hive** | 写入快(~40ms/20条) | 复杂对象、大数据量 | ✅ Plans, Students |
| **SQLite** | 中等 | 关系型数据 | ❌ 不需要 |

**结论**: 使用 Hive + SharedPreferences 混合方案

---

## 📦 Hive TypeId 分配表

| TypeId | 模型 | 用途 | 文件路径 |
|--------|------|------|---------|
| **10-19** | **Exercise Library** | | |
| 10 | ExerciseTemplateModel | 动作模板 | `lib/features/coach/exercise_library/data/models/exercise_template_model.dart` |
| 11 | ExerciseTagModel | 动作标签 | `lib/features/coach/exercise_library/data/models/exercise_tag_model.dart` |
| 12-19 | - | 预留 | - |
| **20-24** | **Students** | | |
| 20 | StudentListItemModel | 学生列表项 | `lib/features/coach/students/data/models/student_list_item_model.dart` |
| 21 | PlanSummary | 计划摘要 | `lib/features/coach/students/data/models/plan_summary.dart` |
| 22-24 | - | 预留 | - |
| **25-34** | **Plans** | | |
| 25 | ExercisePlanModel | 训练计划 | `lib/features/coach/plans/data/models/exercise_plan_model.dart` |
| 26 | DietPlanModel | 饮食计划 | `lib/features/coach/plans/data/models/diet_plan_model.dart` |
| 27 | SupplementPlanModel | 补剂计划 | `lib/features/coach/plans/data/models/supplement_plan_model.dart` |
| 28 | Exercise | 训练动作 | `lib/features/coach/plans/data/models/exercise.dart` |
| 29 | SetModel | 组数模型 | `lib/features/coach/plans/data/models/set_model.dart` |
| 30 | DayModel | 训练日模型 | `lib/features/coach/plans/data/models/day_model.dart` |
| 31 | MealModel | 餐食模型 | `lib/features/coach/plans/data/models/meal_model.dart` |
| 32 | FoodModel | 食物模型 | `lib/features/coach/plans/data/models/food_model.dart` |
| 33 | SupplementTimingModel | 补剂时间 | `lib/features/coach/plans/data/models/supplement_timing_model.dart` |
| 34 | SupplementItemModel | 补剂项目 | `lib/features/coach/plans/data/models/supplement_item_model.dart` |
| **35-39** | **Cache Infrastructure** | | |
| 35 | CacheMetadata | 缓存元数据 | `lib/core/services/cache/cache_metadata.dart` |
| 36-39 | - | 预留 | - |
| **40-49** | **预留** | 用于未来功能 | - |

---

## 🗂️ 缓存策略详解

### 1. Student Lists 缓存

#### 缓存内容
- **数据**: 当前页学生列表（20条）
- **Box名称**: `students_cache`
- **缓存键格式**: `students_page_{pageNumber}_{searchQuery}_{filterPlanId}`
- **有效期**: 7天

#### 缓存逻辑
```
加载学生列表:
1. 生成缓存键(pageNumber, searchQuery, filterPlanId)
2. 尝试从 Box 读取缓存
3. 检查缓存元数据是否有效(未过期)
4. 如果有效 → 返回缓存数据
5. 如果无效 → 调用 Cloud Function
6. 将新数据写入缓存(附带元数据)
7. 返回数据
```

#### 缓存失效时机
- ✅ **删除学生**: 调用 `invalidateCache()` 清除所有学生缓存
- ✅ **手动刷新**: 调用 `invalidateCache()` 强制重新加载
- ✅ **搜索/筛选改变**: 自动生成新的缓存键，旧缓存自然失效
- ✅ **7天过期**: 元数据检查时自动判断

#### 文件位置
```
lib/features/coach/students/data/cache/
└── students_cache_service.dart

主要方法:
- getCachedStudents(page, search, filter)
- cacheStudents(students, page, search, filter)
- invalidateCache()
- invalidateStudentCache(studentId)
```

---

### 2. Plans 缓存

#### 缓存内容
- **列表缓存**: 三类计划列表(Exercise, Diet, Supplement)
- **详情缓存**: 单个计划的完整详情
- **Box名称**: `plans_cache`
- **有效期**: 7天

#### 缓存键格式
| 类型 | 缓存键格式 | 示例 |
|------|----------|------|
| 训练计划列表 | `plans_list_exercise` | `plans_list_exercise` |
| 饮食计划列表 | `plans_list_diet` | `plans_list_diet` |
| 补剂计划列表 | `plans_list_supplement` | `plans_list_supplement` |
| 计划详情 | `plan_detail_{planId}` | `plan_detail_abc123` |

#### 缓存逻辑

##### 列表缓存
```
加载计划列表(fetchAllPlans):
1. 尝试从缓存读取三类计划列表
2. 如果所有列表缓存都有效 → 返回缓存数据
3. 如果任一列表缓存无效 → 调用 Cloud Function
4. 将新数据分别写入三个列表缓存
5. 返回数据
```

##### 详情缓存
```
加载计划详情(getPlanDetail):
1. 尝试从详情缓存读取
2. 如果缓存有效 → 返回缓存数据
3. 如果缓存无效 → 调用 Cloud Function
4. 将新数据写入详情缓存
5. 返回数据
```

#### 缓存失效规则

| 操作 | 失效范围 | 调用方法 |
|------|---------|---------|
| **创建计划** | 列表缓存 | `invalidateListCache(planType)` |
| **更新计划** | 列表缓存 + 详情缓存 | `invalidatePlanDetail(planId)` + `invalidateListCache(planType)` |
| **删除计划** | 列表缓存 + 详情缓存 | `invalidatePlanDetail(planId)` + `invalidateListCache(planType)` |
| **复制计划** | 列表缓存 | `invalidateListCache(planType)` |
| **分配计划** | 列表缓存 | `invalidateListCache(planType)` (studentIds改变) |
| **手动刷新** | 所有缓存 | `invalidateAllPlansCache()` |

#### 文件位置
```
lib/features/coach/plans/data/cache/
└── plans_cache_service.dart

主要方法:
- getCachedExercisePlans()
- getCachedDietPlans()
- getCachedSupplementPlans()
- cacheExercisePlans(plans)
- cacheDietPlans(plans)
- cacheSupplementPlans(plans)
- getCachedPlanDetail(planId)
- cachePlanDetail(plan)
- invalidateListCache(planType)
- invalidatePlanDetail(planId)
- invalidateAllPlansCache()
```

---

### 3. Student Home Plans 缓存（学生端）

#### 缓存内容
- **数据**: 学生的所有计划（教练分配 + 自己创建）
- **Box名称**: 复用 `plans_cache`
- **缓存键格式**: `student_plans_{userId}`
- **有效期**: 7天

#### 缓存逻辑
```
学生端加载计划:
1. 使用学生UserId生成缓存键
2. 复用PlansCacheService的逻辑
3. 缓存失效规则与教练端相同
```

#### 文件位置
```
lib/features/student/home/data/repositories/
└── student_home_repository_impl.dart

集成PlansCacheService
```

---

### 4. Profile 缓存（可选，暂不实施）

**当前方案**: 使用 `StreamProvider` 从 Firestore 实时获取数据，无需额外缓存

**未来优化**: 可添加 Hive 作为离线备份（优先级低）

---

### 5. Chat 缓存（不实施）

**原因**: 聊天列表需要实时性，使用 `FutureProvider.autoDispose` 每次进入页面重新加载

**不缓存的好处**:
- 确保消息实时性
- 避免未读数错误
- 用户行为符合预期

---

## 🔧 通用缓存工具

### CacheMetadata (缓存元数据)

**文件**: `lib/core/services/cache/cache_metadata.dart`

**字段**:
```dart
@HiveType(typeId: 35)
class CacheMetadata {
  @HiveField(0)
  final String key;          // 缓存键

  @HiveField(1)
  final DateTime cachedAt;   // 缓存时间

  @HiveField(2)
  final DateTime expiresAt;  // 过期时间

  bool isValid() {
    return DateTime.now().isBefore(expiresAt);
  }
}
```

**用途**:
- 记录每条缓存的时间信息
- 检查缓存是否过期
- 统一的缓存有效性验证

---

### CacheHelper (通用缓存辅助工具)

**文件**: `lib/core/services/cache/cache_helper.dart`

**主要方法**:

| 方法 | 功能 | 使用场景 |
|------|------|---------|
| `initializeHive()` | 初始化 Hive | 应用启动时 |
| `openBox<T>(String boxName)` | 打开 Box | 获取缓存容器 |
| `clearExpiredCache(Box box, Duration validity)` | 清除过期缓存 | 定期清理 |
| `createMetadata(String key, Duration validity)` | 创建元数据 | 写入缓存时 |
| `isMetadataValid(CacheMetadata? metadata)` | 检查有效性 | 读取缓存时 |

---

## 📝 使用示例

### 1. 添加新的缓存模型

#### Step 1: 定义模型并添加 Hive 注解
```dart
import 'package:hive/hive.dart';

part 'my_model.g.dart';

@HiveType(typeId: 40) // 使用未占用的 TypeId
class MyModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime createdAt;

  MyModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });
}
```

#### Step 2: 运行代码生成
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Step 3: 注册 TypeAdapter
```dart
// lib/main.dart
void main() async {
  // ...
  await Hive.initFlutter();

  Hive.registerAdapter(MyModelAdapter()); // 注册新的 Adapter

  // ...
}
```

#### Step 4: 创建缓存服务
```dart
class MyCacheService {
  static const String _boxName = 'my_cache';
  static const Duration _validity = Duration(days: 7);

  static Future<Box> _getBox() async {
    return await CacheHelper.openBox<MyModel>(_boxName);
  }

  static Future<MyModel?> getCached(String key) async {
    final box = await _getBox();
    final metadata = box.get('${key}_metadata') as CacheMetadata?;

    if (CacheHelper.isMetadataValid(metadata)) {
      return box.get(key) as MyModel?;
    }
    return null;
  }

  static Future<void> cache(String key, MyModel data) async {
    final box = await _getBox();
    final metadata = CacheHelper.createMetadata(key, _validity);

    await box.put(key, data);
    await box.put('${key}_metadata', metadata);
  }

  static Future<void> invalidate(String key) async {
    final box = await _getBox();
    await box.delete(key);
    await box.delete('${key}_metadata');
  }
}
```

---

### 2. 在 Repository 中集成缓存

```dart
class MyRepositoryImpl implements MyRepository {
  @override
  Future<List<MyModel>> fetchData() async {
    // 1. 尝试从缓存读取
    final cached = await MyCacheService.getCached('my_data_list');
    if (cached != null) {
      AppLogger.info('✅ 从缓存读取数据');
      return cached;
    }

    // 2. 缓存无效，调用 Cloud Function
    AppLogger.info('❌ 缓存无效，调用 Cloud Function');
    final response = await CloudFunctionsService.call('fetch_my_data');
    final data = parseResponse(response);

    // 3. 写入缓存
    await MyCacheService.cache('my_data_list', data);

    return data;
  }

  @override
  Future<void> createData(MyModel model) async {
    // 创建数据
    await CloudFunctionsService.call('create_my_data', model.toJson());

    // 创建成功后失效缓存
    await MyCacheService.invalidate('my_data_list');
  }
}
```

---

## 🧪 测试和验证

### 测试检查清单

#### 功能测试
- [ ] **缓存写入**: 首次加载数据后，Box 中存在对应的缓存和元数据
- [ ] **缓存读取**: 第二次加载时从缓存读取，不调用 Cloud Function
- [ ] **缓存失效 - CRUD**: 创建/更新/删除操作后缓存正确清除
- [ ] **缓存失效 - 刷新**: 手动刷新时缓存清除
- [ ] **缓存过期**: 修改系统时间到7天后，缓存自动失效

#### 性能测试
- [ ] **首次加载**: 记录调用 Cloud Function 的时间
- [ ] **缓存命中**: 记录从缓存读取的时间（应显著快于首次加载）
- [ ] **缓存对比**: 对比缓存前后的页面加载时间，验证性能提升

#### 日志验证
使用 `AppLogger` 记录关键节点：
```dart
AppLogger.info('✅ 缓存命中: students_page_1');
AppLogger.info('❌ 缓存无效，调用 Cloud Function: fetch_students');
AppLogger.info('💾 写入缓存: students_page_1');
AppLogger.info('🗑️ 清除缓存: plan_detail_abc123');
```

---

## 📊 性能指标

### 预期性能提升

| 场景 | 缓存前 | 缓存后 | 提升 |
|------|--------|--------|------|
| **学生列表加载** | ~500-1000ms | ~50-100ms | **5-10倍** |
| **Plans列表加载** | ~800-1500ms | ~80-150ms | **10倍** |
| **Plan详情加载** | ~600-1200ms | ~60-120ms | **10倍** |
| **Cloud Function调用** | 每次加载 | 仅首次+失效时 | **减少80-90%** |

### 监控指标
- **缓存命中率**: 目标 > 70%
- **平均加载时间**: 目标 < 200ms
- **Cloud Function调用次数**: 目标减少 80%

---

## 🔒 安全和隐私

### 数据安全
- ✅ **本地存储**: Hive 数据存储在应用沙盒，其他应用无法访问
- ✅ **无敏感数据**: 缓存的 Plans 和 Students 数据不包含密码等敏感信息
- ⚠️ **加密**: Hive 支持加密，如需缓存敏感数据可启用 `encryptionCipher`

### 数据清理
- **退出登录**: 调用 `Hive.deleteFromDisk()` 清除所有缓存
- **切换用户**: 清除旧用户的所有缓存 Box
- **应用卸载**: 操作系统自动清理应用沙盒数据

---

## 🚀 未来优化方向

### 1. 离线支持（Phase 2）
- 支持完全离线浏览已缓存的 Plans
- 离线创建/编辑，联网后同步

### 2. 智能缓存（Phase 3）
- 根据用户使用频率调整缓存策略
- 预加载用户可能访问的数据

### 3. 缓存压缩（Phase 4）
- 对大型 Plans 数据进行压缩存储
- 减少存储空间占用

### 4. 增量更新（Phase 5）
- 仅同步变更的数据，而非全量刷新
- 需要后端支持增量 API

---

## 📚 参考资料

- [Hive 官方文档](https://docs.hivedb.dev/)
- [Flutter 性能优化最佳实践](https://flutter.dev/docs/perf/best-practices)
- [Firebase Cloud Functions 定价](https://firebase.google.com/pricing)

---

## 📞 联系和支持

如有问题或建议，请联系开发团队或在项目 Issue 中提出。

---

## 📝 实施状态

### ✅ 已实施功能

| 功能 | 状态 | 实施日期 | 说明 |
|------|------|---------|------|
| **基础设施** | ✅ 完成 | 2025-11-16 | CacheHelper, CacheMetadata |
| **Student Lists 缓存** | ✅ 完成 | 2025-11-16 | 分页缓存，7天有效期 |
| **Plans 缓存（列表）** | ✅ 完成 | 2025-11-16 | 三类计划列表缓存，JSON格式 |
| **Plans 手动刷新缓存失效** | ✅ 完成 | 2025-11-17 | 下拉刷新强制清除缓存 |
| **Avatar URL 缓存** | ✅ 完成 | 2025-11-29 | 用户头像URL缓存，1天有效期 |
| **Plans 缓存（详情）** | ❌ 未实施 | - | 用户要求仅缓存列表 |
| **Profile 缓存** | ❌ 未实施 | - | 使用StreamProvider实时数据 |
| **Chat 缓存** | ❌ 未实施 | - | 需要实时性 |

### 🎯 实施方案调整

**Plans 缓存方案**：采用 **JSON 缓存方案**，不使用 Hive TypeAdapter
- ✅ 优点：无需为所有嵌套模型添加 Hive 注解
- ✅ 简化：只需 toJson/fromJson 序列化
- ✅ 灵活：支持复杂嵌套结构
- ℹ️ 说明：使用 Hive 缓存 `List<Map<String, dynamic>>`，读取时转换回 Model

---

## 🖼️ Avatar URL 缓存

### 缓存内容
- **数据**: 用户头像 URL 字符串
- **Box名称**: `user_avatars_cache`
- **缓存键格式**: `avatar_{userId}`
- **有效期**: 1天

### 缓存逻辑
```
获取用户头像URL:
1. 生成缓存键(userId)
2. 尝试从 Box 读取缓存
3. 检查缓存元数据是否有效(未过期)
4. 如果有效 → 返回缓存的 avatarUrl
5. 如果无效 → 从 Firestore 获取
6. 将新 URL 写入缓存(附带元数据)
7. 返回 avatarUrl
```

### 缓存失效时机
| 触发场景 | 实现方式 |
|---------|---------|
| 用户更新自己头像 | `UserRepositoryImpl.updateUser()` 自动检测并调用 `invalidateAvatar(userId)` |
| 1天过期 | CacheMetadata 自动判断 |
| 下拉刷新 | 调用 `forceRefreshAvatar(userId)` |
| 退出登录 | `AuthService.signOut()` 调用 `invalidateAllAvatars()` |

### 使用场景
| 场景 | Provider | 说明 |
|------|----------|------|
| 学生端教练头像 | `coachAvatarUrlProvider` | 学生Profile页面显示教练头像 |
| 聊天对方头像 | `otherUserAvatarUrlProvider` | 聊天页面显示对方头像 |

### 文件位置
```
lib/core/services/cache/
└── user_avatar_cache_service.dart

主要方法:
- getAvatarUrl(userId)        # 获取头像URL（带缓存）
- cacheAvatarUrl(userId, url) # 写入缓存
- invalidateAvatar(userId)    # 失效单个用户
- invalidateAllAvatars()      # 失效所有（登出时）
- forceRefreshAvatar(userId)  # 强制刷新（下拉刷新）
```

### 网络图片缓存
所有头像图片组件已统一使用 `CachedNetworkImage`：
- `coach_info_card.dart` - 教练信息卡片
- `profile_header.dart` - 个人资料页头部
- `student_profile_section.dart` - 学生资料区块
- `message_bubble.dart` - 聊天消息气泡
- `student_card.dart` - 学生列表卡片

---

**文档版本**: v1.3
**最后更新**: 2025-11-29
**维护者**: CoachX 开发团队
