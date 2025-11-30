# Chat Detail Page 功能文档

## 功能概述
CoachX 平台的聊天详情页面（Chat Detail Page）实现了教练和学生之间的一对一实时聊天。核心功能包括文本、多媒体（图片/视频/语音）消息发送，消息引用与回复，消息删除（仅限己方消息），以及 AI 辅助回复助手。界面模仿微信风格，提供直观的交互体验。

## 用户流程

### 消息发送与查看
```
用户进入详情页
  ↓
加载历史消息 (分页) & 监听实时流
  ↓
输入内容 / 选择媒体 (MediaPicker)
  ↓
点击发送
  ↓
上传媒体 (Storage) & 调用 API (sendMessage)
  ↓
Firestore 存储 & 实时推送更新 UI
```

### 消息引用 (Quote)
```
长按消息气泡
  ↓
弹出菜单 (MessagePopupMenu - 覆盖层)
  ↓
选择 "引用"
  ↓
输入栏上方显示引用预览 (QuoteTile)
  ↓
发送新消息 (自动附带引用数据)
  ↓
新消息气泡显示引用内容
```

### 消息删除 (Delete)
```
长按己方消息
  ↓
弹出菜单
  ↓
选择 "删除"
  ↓
调用 API (deleteMessage)
  ↓
Firestore 标记 isDeleted
  ↓
UI 隐藏该消息
```

## 技术架构

### 核心组件
| 组件 | 功能 |
|------|------|
| `ChatDetailPage` | 页面容器，管理 Tab 和 NavigationBar |
| `ChatTabContent` | 消息列表容器，处理滚动和分页 |
| `MessageBubble` | 消息气泡，处理布局、长按菜单和引用展示 |
| `MediaMessageWidget` | 媒体内容渲染 (图片/视频/语音) |
| `CommonInputBar` | 统一输入栏 (文本/语音/媒体) |
| `QuoteTile` | 输入栏上方的引用消息预览 |
| `MessagePopupMenu` | 自定义长按弹出菜单 (Overlay 实现) |
| `ChatAIPanel` | AI 回复建议面板 |

### 状态管理 (Riverpod)
- `messagesStreamProvider`: 实时消息流
- `quotedMessageProvider`: 当前正在引用的消息状态
- `mediaUploadProgressProvider`: 媒体上传进度
- `isSendingMessageProvider`: 消息发送状态

## API / 数据接口

### 消息模型 (MessageModel)
```dart
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType type; // text, image, video, voice
  final String content;
  final String? mediaUrl;
  final MessageMetadata? mediaMetadata; // duration, size, etc.
  final bool isDeleted;
  final DateTime createdAt;
  
  // 引用字段
  final String? quotedMessageId;
  final String? quotedMessageContent;
  final String? quotedMessageSenderName;
}
```

### ChatRepository 接口
- `sendMessage(...)`: 发送消息 (支持引用字段)
- `deleteMessage(...)`: 软删除消息
- `watchMessages(...)`: 监听消息流
- `uploadMediaFile(...)`: 上传媒体文件

## 数据流
1. **发送**: UI -> Repository -> Cloud Function (send_message) -> Firestore (messages collection).
   * *注意*: 引用字段在 CF 返回后若缺失，Repository 会进行一次 Patch 更新。
2. **接收**: Firestore Listener -> StreamProvider -> UI Rebuild.
3. **删除**: UI -> Repository -> Cloud Function (delete_message) -> Firestore Update (isDeleted=true).

## 错误处理
| 错误类型 | 处理方式 |
|---------|---------|
| 发送失败 | 弹出 Alert Dialog 提示用户，状态重置 |
| 上传失败 | 终止发送流程，保留输入内容 |
| 权限不足 | (如删除他人消息) 菜单选项不显示或 API 拒绝 |
| 网络异常 | Firestore 离线支持，重连后同步 |

---
**最后更新**: 2025-11-30
