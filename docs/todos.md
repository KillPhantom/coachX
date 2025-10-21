# CoachX - TODO汇总文档

> **创建日期**: 2025-10-21  
> **最后更新**: 2025-10-21  
> **用途**: 汇总项目中所有待实现的功能和改进点

---

## 一、数据层TODO

### 1.1 Coach Summary Provider

**位置**: `lib/features/coach/home/presentation/providers/coach_home_providers.dart`

**TODO内容**:
```dart
// TODO: 替换为真实API调用
// 调用 Cloud Function: fetchStudentsStats()
// 整合未读消息统计和待审核训练数
```

**实现细节**:
- API: `fetchStudentsStats()` (Cloud Function)
- 返回数据结构: 
  ```json
  {
    "studentsCompletedToday": int,
    "totalStudents": int,
    "unreadMessages": int,
    "unreviewedTrainings": int,
    "lastUpdated": string (ISO 8601)
  }
  ```
- 需要聚合多个数据源：
  1. 学生完成训练统计（dailyTraining collection）
  2. 未读消息统计（messages collection）
  3. 待审核训练记录（dailyTraining collection, status: pending_review）

**优先级**: 🔴 高  
**预估工作量**: 0.5天（包含API实现）

---

### 1.2 Event Reminders Provider

**位置**: `lib/features/coach/home/presentation/providers/coach_home_providers.dart`

**TODO内容**:
```dart
// TODO: 替换为Firestore实时监听
// Collection: eventReminders
// Query: where('coachId', '==', currentCoachId)
//        .where('isCompleted', '==', false)
//        .orderBy('scheduledTime')
//        .limit(3)
```

**实现细节**:
- Collection: `eventReminders`
- 字段结构: 参考 `EventReminderModel`
- 监听方式: Firestore Stream
- 需要实现的功能:
  1. 实时监听未完成的事件
  2. 按时间排序
  3. 只显示最近3条
  4. 支持事件CRUD（后续迭代）

**Firestore实现示例**:
```dart
return FirebaseFirestore.instance
    .collection('eventReminders')
    .where('coachId', isEqualTo: coachId)
    .where('isCompleted', isEqualTo: false)
    .orderBy('scheduledTime')
    .limit(3)
    .snapshots()
    .map((snapshot) => snapshot.docs
        .map((doc) => EventReminderModel.fromFirestore(doc))
        .toList());
```

**优先级**: 🟡 中  
**预估工作量**: 0.3天

---

### 1.3 Recent Activities Provider

**位置**: `lib/features/coach/home/presentation/providers/coach_home_providers.dart`

**TODO内容**:
```dart
// TODO: 替换为真实数据查询
// 需要聚合多个数据源:
// 1. 最近训练记录 (dailyTraining)
// 2. 最近消息 (messages)
// 3. 最近打卡 (checkIns)
// 按时间排序，取最近3条
```

**实现细节**:
- 需要查询教练的所有学生
- 聚合多个数据源：
  1. `dailyTraining` - 学生训练记录（最近完成/提交的）
  2. `messages` - 学生发送的消息
  3. 可能的其他活动类型
- 按 `lastActiveTime` 排序
- 取最新的3条

**实现思路**:
1. 查询 `users` collection，获取当前教练的所有学生
2. 对每个学生，查询其最近的活动
3. 聚合所有学生的活动
4. 按时间排序
5. 取前3条

**优先级**: 🟡 中  
**预估工作量**: 0.5天

---

### 1.4 Chat未读消息Provider

**位置**: `lib/features/chat/presentation/providers/chat_providers.dart` (待创建)

**TODO内容**:
```dart
// TODO: 实现Firestore实时监听
// Collection: messages
// 优化: 使用单独的 unreadCounts 文档避免全量查询
```

**实现细节**:
- Provider: `unreadMessageCountProvider`
- 类型: `StreamProvider<int>`
- Collection: `messages`
- Query: `where('receiverId', '==', currentUserId).where('isRead', '==', false)`
- 优化方案: 在 `users` collection中添加 `unreadMessageCount` 字段

**优先级**: 🟡 中（依赖Chat功能）  
**预估工作量**: 0.2天

---

## 二、UI层TODO

### 2.1 Summary区域跳转

**位置**: `lib/features/coach/home/presentation/widgets/summary_section.dart`

#### 2.1.1 跳转到学生列表（已完成训练）

**TODO内容**:
```dart
// TODO: 跳转到学生列表（筛选已完成）
// 路由: /coach/students?filter=completed_today
```

**实现细节**:
- 导航到Students Tab
- 预设筛选条件：今天完成训练的学生
- 需要在Students页面实现筛选功能

**优先级**: 🟢 低  
**预估工作量**: 0.2天（依赖Students页面实现）

#### 2.1.2 跳转到Chat Tab

**TODO内容**:
```dart
// TODO: 跳转到Chat Tab
// 可以通过改变Tab索引或使用go_router导航
```

**实现细节**:
- 方案A: 使用 `context.go('/coach/chat')`
- 方案B: 通过CupertinoTabController切换Tab

**优先级**: 🟢 低  
**预估工作量**: 0.1天

#### 2.1.3 跳转到待审核训练列表

**TODO内容**:
```dart
// TODO: 跳转到待审核训练记录列表
// 路由: /coach/training-reviews
```

**实现细节**:
- 需要创建训练记录审核页面
- 显示所有status为pending_review的训练记录
- 提供审核功能（通过/拒绝/评论）

**优先级**: 🟡 中  
**预估工作量**: 1天（包含页面实现）

---

### 2.2 设置按钮

**位置**: `lib/features/coach/home/presentation/pages/coach_home_page.dart`

**TODO内容**:
```dart
// TODO: 打开设置页面
// 路由: /coach/settings
```

**实现细节**:
- 创建Settings页面
- 包含功能：
  1. 账号设置
  2. 通知设置
  3. 隐私设置
  4. 关于页面
  5. 登出

**优先级**: 🟢 低  
**预估工作量**: 0.5天

---

### 2.3 学生详情页面

**位置**: `lib/routes/app_router.dart`

**TODO内容**:
```dart
// TODO: 实现StudentDetailPage
// 当前显示占位页面
```

**实现细节**:
- 创建 `StudentDetailPage`
- 显示学生完整信息：
  1. 基本信息（姓名、头像、联系方式）
  2. 身体数据（身高、体重、体脂率等）
  3. 分配的计划（训练、饮食、补剂）
  4. 训练历史
  5. 聊天入口
- 提供操作：编辑信息、分配计划、查看记录

**优先级**: 🔴 高  
**预估工作量**: 2天

---

### 2.4 学生端Add按钮跳转

**位置**: `lib/features/student/presentation/widgets/student_tab_scaffold.dart`

#### 2.4.1 训练记录添加

**TODO内容**:
```dart
// TODO: 跳转到训练记录页面
// 路由: /student/training/add
```

**优先级**: 🔴 高  
**预估工作量**: 2天

#### 2.4.2 饮食记录添加

**TODO内容**:
```dart
// TODO: 跳转到饮食记录页面
// 路由: /student/diet/add
```

**优先级**: 🔴 高  
**预估工作量**: 2天

#### 2.4.3 补剂记录添加

**TODO内容**:
```dart
// TODO: 跳转到补剂记录页面
// 路由: /student/supplement/add
```

**优先级**: 🟡 中  
**预估工作量**: 1.5天

#### 2.4.4 身体测量添加

**TODO内容**:
```dart
// TODO: 跳转到身体测量页面
// 路由: /student/body-stats/add
```

**优先级**: 🟡 中  
**预估工作量**: 1.5天

---

### 2.5 Chat Tab Badge

**位置**: 
- `lib/features/coach/presentation/widgets/coach_tab_scaffold.dart`
- `lib/features/student/presentation/widgets/student_tab_scaffold.dart`

**TODO内容**:
```dart
// TODO: 添加未读消息Badge
// 实现方式: 使用Badge widget包裹图标
// Provider: unreadMessageCountProvider (StreamProvider<int>)
```

**实现细节**:
- 使用 `ref.watch(unreadMessageCountProvider)` 获取未读数
- 在Chat Tab的图标上显示Badge
- Badge样式：
  - 小于99：显示具体数字
  - 大于等于99：显示"99+"
  - 为0：不显示Badge

**优先级**: 🟡 中（依赖Chat功能）  
**预估工作量**: 0.2天

---

## 三、后端API TODO

### 3.1 Event Reminder CRUD

**功能**: Event Reminder的创建、读取、更新、删除

**Collection**: `eventReminders`

**需要的API**:
1. `createEventReminder(eventData)` - 创建事件
2. `updateEventReminder(eventId, eventData)` - 更新事件
3. `deleteEventReminder(eventId)` - 删除事件
4. `markEventComplete(eventId)` - 标记完成
5. `getUpcomingEvents(coachId, limit)` - 获取即将到来的事件

**优先级**: 🟢 低（当前仅显示）  
**预估工作量**: 0.5天

---

### 3.2 学生统计API

**功能**: 教练首页Summary数据

**API**: `fetchStudentsStats(coachId)`

**返回数据**:
```json
{
  "studentsCompletedToday": 15,
  "totalStudents": 25,
  "unreadMessages": 20,
  "unreviewedTrainings": 14,
  "lastUpdated": "2025-10-21T10:30:00Z"
}
```

**实现逻辑**:
1. 查询教练的所有学生
2. 统计今天完成训练的学生数
3. 统计未读消息数（可能从单独的aggregation collection读取）
4. 统计待审核训练数

**优先级**: 🔴 高  
**预估工作量**: 0.5天

---

### 3.3 Recent Activity聚合API

**功能**: 获取学生最近活动

**API**: `getRecentActivities(coachId, limit)`

**返回数据**:
```json
[
  {
    "studentId": "s1",
    "studentName": "Liam Carter",
    "avatarUrl": "...",
    "lastActiveTime": "2025-10-21T08:30:00Z",
    "activityType": "training",
    "activityDescription": "Completed training"
  }
]
```

**实现逻辑**:
1. 查询教练的所有学生
2. 对每个学生，获取最近的活动（训练/消息/打卡）
3. 聚合并按时间排序
4. 返回最新的N条

**优先级**: 🟡 中  
**预估工作量**: 0.5天

---

## 四、实时更新TODO

### 4.1 Event Reminder实时监听

**实现方式**: 将 `eventRemindersProvider` 从 `FutureProvider` 改为 `StreamProvider`

**Firestore Stream**:
- Collection: `eventReminders`
- 实时监听变化
- 自动更新UI

**优先级**: 🟡 中  
**预估工作量**: 0.2天

---

### 4.2 Chat消息实时监听

**实现方式**: `StreamProvider<List<Message>>`

**Collection**: `messages`

**监听逻辑**:
- 监听当前对话的所有消息
- 按时间排序
- 自动标记已读

**优先级**: 🔴 高（Chat功能核心）  
**预估工作量**: 包含在Chat功能实现中

---

### 4.3 Recent Activity实时更新

**当前方案**: 下拉刷新

**未来优化**:
- 考虑轮询（每30秒）
- 或Firestore聚合监听
- 或使用Cloud Functions + FCM推送更新

**优先级**: 🟢 低  
**预估工作量**: 0.3天

---

## 五、页面实现TODO

### 5.1 教练端

| 页面 | 状态 | 优先级 | 预估工作量 |
|------|------|--------|-----------|
| 教练首页 | ✅ 完成 | - | - |
| 学生列表 | ⏸️ 占位 | 🔴 高 | 2天 |
| 计划管理 | ⏸️ 占位 | 🔴 高 | 3天 |
| Chat列表 | ⏸️ 占位 | 🔴 高 | 2天 |
| 个人资料 | ⏸️ 占位 | 🟡 中 | 1天 |
| 学生详情 | ⏸️ 占位 | 🔴 高 | 2天 |
| 训练审核 | ❌ 未实现 | 🟡 中 | 1.5天 |
| 设置页面 | ❌ 未实现 | 🟢 低 | 0.5天 |

**总工作量**: ~14天

---

### 5.2 学生端

| 页面 | 状态 | 优先级 | 预估工作量 |
|------|------|--------|-----------|
| 学生首页 | ⏸️ 占位 | 🔴 高 | 2天 |
| 计划页面 | ⏸️ 占位 | 🔴 高 | 2天 |
| Chat页面 | ⏸️ 占位 | 🔴 高 | 2天 |
| 个人资料 | ⏸️ 占位 | 🟡 中 | 1天 |
| 训练记录添加 | ❌ 未实现 | 🔴 高 | 2天 |
| 饮食记录添加 | ❌ 未实现 | 🔴 高 | 2天 |
| 补剂记录添加 | ❌ 未实现 | 🟡 中 | 1.5天 |
| 身体测量添加 | ❌ 未实现 | 🟡 中 | 1.5天 |

**总工作量**: ~14天

---

## 六、功能模块TODO

### 6.1 Chat功能（完整实现）

**包含**:
- Chat列表页面
- Chat详情页面
- 消息发送/接收
- 实时消息监听
- 未读消息标记
- 图片/视频发送
- 消息通知

**优先级**: 🔴 高  
**预估工作量**: 5天

---

### 6.2 计划管理功能

**包含**:
- 训练计划CRUD
- 饮食计划CRUD
- 补剂计划CRUD
- 计划分配给学生
- 计划模板功能
- AI生成计划

**优先级**: 🔴 高  
**预估工作量**: 8天

---

### 6.3 训练记录功能

**包含**:
- 训练记录上传
- 图片/视频上传
- 数据填写（重量、次数等）
- 历史记录查看
- 教练审核反馈

**优先级**: 🔴 高  
**预估工作量**: 5天

---

## 七、优化TODO

### 7.1 性能优化

- [ ] 图片懒加载和缓存优化
- [ ] 列表分页加载
- [ ] Firestore查询优化（索引）
- [ ] 启动速度优化
- [ ] 内存占用优化

**优先级**: 🟡 中  
**预估工作量**: 2天

---

### 7.2 用户体验优化

- [ ] 加载动画优化
- [ ] 错误提示优化
- [ ] 空状态设计
- [ ] 骨架屏实现
- [ ] 下拉刷新动画

**优先级**: 🟢 低  
**预估工作量**: 1天

---

## 八、TODO优先级总结

### 🔴 高优先级（近期必须实现）

1. 教练首页数据API对接（0.5天）
2. 学生详情页面（2天）
3. Chat功能完整实现（5天）
4. 学生列表页面（2天）
5. 计划管理功能（8天）
6. 训练记录功能（5天）

**小计**: ~22.5天

---

### 🟡 中优先级（中期规划）

1. Event Reminder实时监听（0.2天）
2. Recent Activity数据API（0.5天）
3. 训练审核页面（1.5天）
4. 学生端记录添加功能（6天）
5. Chat Badge实现（0.2天）
6. 性能优化（2天）

**小计**: ~10.4天

---

### 🟢 低优先级（后期优化）

1. Summary跳转功能（0.5天）
2. 设置页面（0.5天）
3. Event Reminder CRUD（0.5天）
4. Recent Activity实时更新（0.3天）
5. 用户体验优化（1天）

**小计**: ~2.8天

---

## 九、里程碑规划

### Milestone 1: 核心功能完成（8周）
- ✅ 教练首页和底部导航（Week 1）
- ⏳ 学生详情和列表（Week 2）
- ⏳ Chat功能（Week 3-4）
- ⏳ 计划管理（Week 5-6）
- ⏳ 训练记录（Week 7-8）

### Milestone 2: 完整功能（12周）
- ⏳ 学生端完整实现（Week 9-10）
- ⏳ 数据API对接（Week 11）
- ⏳ 测试和优化（Week 12）

### Milestone 3: 优化和发布（14周）
- ⏳ 性能优化（Week 13）
- ⏳ 用户体验优化（Week 14）
- ⏳ App Store发布准备（Week 14）

---

## 十、更新日志

| 日期 | 更新内容 | 更新人 |
|------|---------|--------|
| 2025-10-21 | 初始版本，汇总所有TODO | Agent |

---

**注意事项**:
1. 本文档应随着项目进展持续更新
2. 完成的TODO应标记✅并更新状态
3. 新增的TODO应及时添加到本文档
4. 预估工作量仅供参考，实际可能有偏差
5. 优先级可能根据业务需求调整

