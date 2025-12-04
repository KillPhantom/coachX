# AI Chat Implementation

## 功能概述
提供一个类似 ChatGPT 的 AI 对话界面，允许用户直接与 AI 教练对话。AI 具备上下文感知能力，能访问用户的个人资料、当前训练/饮食计划和对话历史，从而提供个性化的指导和反馈。

## 用户流程
1. **进入页面**：用户点击 AI 聊天入口，进入 `AIChatPage`。
2. **快捷指令（可选）**：用户点击输入框上方的快捷指令 Chips（如"分析训练历史"、"分析饮食计划"），直接发送预设指令。
3. **发送消息**：用户在底部输入栏输入文本并发送。
4. **即时反馈**：
   - 界面立即显示用户发送的消息。
   - 显示 AI 正在思考/生成的占位消息。
5. **流式响应**：AI 的回复通过打字机效果实时显示（SSE 流式传输）。
6. **历史记录**：对话历史被保存，用于后续对话的上下文。

## 技术架构

### 技术栈
- **Frontend**: Flutter, Riverpod (State Management)
- **Backend**: Python Cloud Functions (Flask), Firestore
- **AI**: Anthropic Claude API (Streaming)
- **Protocol**: HTTP Server-Sent Events (SSE)

### 组件结构
```
lib/features/student/chat/
├── presentation/
│   ├── pages/
│   │   └── ai_chat_page.dart           # 聊天主页面
│   ├── controllers/
│   │   └── ai_chat_controller.dart     # 状态管理 (Riverpod)
│   └── widgets/
│       └── ai_message_bubble.dart      # 消息气泡组件
lib/core/services/
└── ai_service.dart                     # AI 服务接口 (SSE 客户端)
functions/ai/chat/
├── handlers.py                         # Cloud Function 入口
├── streaming.py                        # 流式响应逻辑
└── prompts.py                          # Prompt 工程 (Context 注入)
```

### 状态管理 (`AIChatController`)
管理 `AIChatState`，包含：
- `messages`: 消息列表 (`List<MessageModel>`)
- `isGenerating`: 是否正在生成中
- `error`: 错误信息

## API / 数据接口

### Cloud Function: `chat_with_ai`
**Endpoint**: `POST /chat_with_ai`

**请求格式**:
```json
{
  "user_id": "uid_123",
  "message": "我今天的训练感觉很累"
}
```

**响应格式 (SSE Stream)**:
```text
data: {"type": "text_delta", "content": "这是"}
data: {"type": "text_delta", "content": "回复"}
data: {"type": "complete"}
// 或
data: {"type": "error", "error": "错误信息"}
```

### 数据模型 (`MessageModel`)
```dart
class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final MessageType type; // text, image, etc.
  final DateTime createdAt;
  final MessageStatus status; // sending, sent, delivered, failed
}
```

## 数据流
1. **User Action**: `AIChatPage` -> `AIChatController.sendMessage(text)`
2. **State Update**: Controller 添加用户消息 (本地显示) + AI 占位消息 (loading 状态)。
3. **API Call**: Controller 调用 `AIService.chatWithAI(text)`。
4. **Backend Processing**:
   - `chat_with_ai` 接收请求。
   - **Intent Detection**: 分析用户消息是否包含快捷指令关键词（如 "Analyze Training History"）。
   - **Context Fetching**: 
     - 获取基础上下文：User Profile, Active Plans, Conversation History。
     - 获取扩展上下文（若命中快捷指令）：Weight History (30天), Recent Trainings (30天)。
   - 构建 Prompt 并调用 Claude API (Streaming)。
5. **Streaming Response**:
   - Backend通过 SSE 推送 `text_delta` 事件。
   - Frontend `AIService` 监听流。
   - `AIChatController` 接收事件并实时更新 AI 消息内容 (`content += delta`)。
6. **Completion**: 收到 `complete` 事件，更新消息状态为 `delivered`。

## 错误处理

| 错误类型 | 处理方式 |
|---------|----------|
| 用户未登录 | 前端拦截，或是后端返回 `type: error`，提示用户登录 |
| 网络请求失败 | `AIService` 捕获异常，Controller 更新状态为 `error`，消息标记为 `failed` |
| SSE 解析错误 | `AIService` 记录日志并忽略损坏的 chunk，不中断流 |
| AI 生成失败 | 后端推送 `type: error` 事件，前端显示红色错误提示 |

## 相关文档
- [Backend APIs](backend_apis_and_document_db_schemas.md)

---
**最后更新**: 2025-12-04

