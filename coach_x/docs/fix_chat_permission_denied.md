# 修复 Chat 页面 Permission Denied 错误

## 问题描述

新注册用户打开 Chat 页面时出现 `[cloud_firestore/permission-denied]` 错误。

## 根因分析

`firestore.rules` 中 `messages` 集合的 read 规则依赖于 `conversations` 文档存在：

```javascript
allow read: if isSignedIn() && (
  get(/databases/$(database)/documents/conversations/$(resource.data.conversationId)).data.coachId == request.auth.uid ||
  get(/databases/$(database)/documents/conversations/$(resource.data.conversationId)).data.studentId == request.auth.uid
);
```

当 conversation 文档不存在时，`get()` 调用失败，导致权限拒绝。

## 修复计划

### 1. 修改 `firestore.rules` 中 messages 规则

**文件**: `firestore.rules`

**修改内容**: 在 messages 的 read 规则中添加对 conversation 不存在情况的处理

```javascript
match /messages/{messageId} {
  // 添加 helper function 检查是否为对话参与者
  function isConversationParticipant(convId) {
    let conv = get(/databases/$(database)/documents/conversations/$(convId));
    return conv != null && (
      conv.data.coachId == request.auth.uid ||
      conv.data.studentId == request.auth.uid
    );
  }

  // 修改 read 规则：conversation 不存在时返回空结果（不报错）
  allow read: if isSignedIn() && (
    !exists(/databases/$(database)/documents/conversations/$(resource.data.conversationId)) ||
    isConversationParticipant(resource.data.conversationId)
  );
  ...
}
```

### 2. 部署更新后的规则

```bash
firebase deploy --only firestore:rules
```

## 实施检查清单

1. [ ] 修改 `firestore.rules` 中 messages 集合的 read 规则
2. [ ] 修改 `firestore.rules` 中 messages 集合的 create 规则（同样问题）
3. [ ] 修改 `firestore.rules` 中 messages 集合的 update 规则（同样问题）
4. [ ] 执行 `firebase deploy --only firestore:rules` 部署规则
5. [ ] 验证：新注册用户打开 Chat 页面不再报错

---
**最后更新**: 2025-12-11
