# Firebase Functions Secrets 配置指南

本文档说明如何为 CoachX 后端配置 Firebase Functions Secrets，以安全地管理敏感信息（如 API Keys）。

---

## 📋 概述

从 Firebase Functions 2.0 开始，推荐使用 **Secrets Manager** 来管理敏感信息，而不是使用传统的环境变量配置方式。

**优势**：
- ✅ 更安全：Secrets 存储在 Google Secret Manager 中
- ✅ 版本控制：支持 Secrets 版本管理
- ✅ 访问控制：细粒度的 IAM 权限控制
- ✅ 自动注入：Secrets 会自动作为环境变量注入到 Functions 中

---

## 🔐 当前使用的 Secrets

### 1. ANTHROPIC_API_KEY

**用途**：Claude AI API 访问密钥

**使用的 Functions**：
- `generate_ai_training_plan` - AI 训练计划生成

**设置方法**：
```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

执行后会提示输入 Secret 值。

### 2. Claude Skills 自动管理

**用途**：Nutrition Calculator Skill 自动上传和管理

**工作原理**：
- ✅ **首次运行时自动上传**：系统检测到 `skill_constants.py` 中的 `NUTRITION_CALCULATOR_SKILL_ID` 为 `None` 时，自动上传 skill 到 Anthropic
- ✅ **自动保存 Skill ID**：上传成功后自动更新 `skill_constants.py` 文件
- ✅ **后续运行直接使用**：已有 Skill ID 时直接验证并使用，无需重复上传
- ✅ **自动重新上传**：如果检测到 skill 被删除或不可用，自动重新上传

**无需手动配置**：
- ❌ 不需要设置 `NUTRITION_SKILL_ID` 环境变量
- ❌ 不需要手动上传 skill 文件
- ❌ 不需要手动管理 skill_id

**相关文件**：
- `functions/ai/claude_skills/skill_constants.py` - 存储 skill_id（自动维护）
- `functions/ai/claude_skills/skill_manager.py` - Skill 管理逻辑
- `functions/ai/claude_skills/diet_plan_calculation/nutrition-calculator.skill` - Skill 文件

**注意事项**：
- 仅需确保 `ANTHROPIC_API_KEY` 已配置
- 首次运行可能需要几秒钟上传 skill
- 如需重新上传，将 `skill_constants.py` 中的 `NUTRITION_CALCULATOR_SKILL_ID` 改为 `None`

---

## 🚀 快速开始

### 初次设置

1. **安装 Firebase CLI**（如果还没有）：
   ```bash
   npm install -g firebase-tools
   ```

2. **登录 Firebase**：
   ```bash
   firebase login
   ```

3. **切换到项目目录**：
   ```bash
   cd /path/to/coachX/coach_x/functions
   ```

4. **设置 ANTHROPIC_API_KEY**：
   ```bash
   firebase functions:secrets:set ANTHROPIC_API_KEY
   ```
   
   提示输入时，粘贴您的 Anthropic API Key：
   ```
   ? Enter a value for ANTHROPIC_API_KEY: [hidden]
   ✔ Created a new secret version projects/YOUR_PROJECT/secrets/ANTHROPIC_API_KEY/versions/1
   ```

5. **部署 Functions**：
   ```bash
   firebase deploy --only functions
   ```

---

## 📝 管理 Secrets

### 查看所有 Secrets

```bash
firebase functions:secrets:list
```

**输出示例**：
```
┌─────────────────────┬──────────┬────────────────────┐
│ Name                │ Version  │ Last Modified      │
├─────────────────────┼──────────┼────────────────────┤
│ ANTHROPIC_API_KEY   │ 1        │ 2025-10-23         │
└─────────────────────┴──────────┴────────────────────┘
```

### 更新 Secret

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
```

这会创建一个新版本，旧版本会被保留。

### 删除 Secret

```bash
firebase functions:secrets:destroy ANTHROPIC_API_KEY
```

⚠️ **警告**：删除后需要重新设置才能使用。

### 查看 Secret 值（仅限本地测试）

Secrets 的值在生产环境中是加密的，无法直接查看。仅在本地测试时可以通过 `functions:secrets:access` 查看：

```bash
firebase functions:secrets:access ANTHROPIC_API_KEY
```

---

## 🧪 本地开发与测试

### 方法 1: 使用本地环境变量（推荐）

在本地开发时，可以创建 `.env` 文件（**不要提交到 Git**）：

```bash
# functions/.env
ANTHROPIC_API_KEY=your-api-key-here
ANTHROPIC_MODEL=claude-sonnet-4-20250514
ANTHROPIC_MAX_TOKENS=4096
ANTHROPIC_TEMPERATURE=0.7
```

然后在启动 Emulator 前加载：
```bash
export $(cat .env | xargs) && firebase emulators:start --only functions
```

### 方法 2: 直接导出环境变量

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
firebase emulators:start --only functions
```

### 方法 3: 使用 Firebase Secrets（本地）

Firebase Emulator 会自动从 Secret Manager 拉取 Secrets（需要有权限）：

```bash
firebase emulators:start --only functions
```

---

## 🔧 代码使用示例

### 在 Cloud Function 中使用 Secrets

```python
from firebase_functions import https_fn
import os

@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])
def generate_ai_training_plan(req: https_fn.CallableRequest):
    """
    使用 Secrets 的 Cloud Function
    
    注意：
    1. 在装饰器中声明需要使用的 secrets
    2. Secret 会自动作为环境变量加载
    3. 使用 os.environ.get() 获取值
    """
    api_key = os.environ.get('ANTHROPIC_API_KEY')
    
    if not api_key:
        raise https_fn.HttpsError(
            'internal',
            '未配置 ANTHROPIC_API_KEY'
        )
    
    # 使用 api_key...
    return {'status': 'success'}
```

### 声明多个 Secrets

```python
@https_fn.on_call(secrets=["ANTHROPIC_API_KEY", "OTHER_SECRET"])
def my_function(req: https_fn.CallableRequest):
    api_key = os.environ.get('ANTHROPIC_API_KEY')
    other = os.environ.get('OTHER_SECRET')
    # ...
```

---

## 🏗️ 部署注意事项

### 首次部署

如果 Secret 还未设置就部署 Functions，会出现错误：

```
❌ Error: Secret ANTHROPIC_API_KEY not found
```

**解决方法**：先设置 Secret，再部署：
```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
firebase deploy --only functions
```

### 更新 Secret 后

更新 Secret 后需要重新部署 Functions 才能使其生效：

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
firebase deploy --only functions
```

### CI/CD 环境

在 CI/CD 环境中，需要确保 Service Account 有以下权限：
- `secretmanager.secrets.get`
- `secretmanager.versions.access`

---

## 🔍 故障排查

### 问题 1: Secret 未找到

**错误**：
```
ValueError: 未配置 ANTHROPIC_API_KEY
```

**解决方法**：
```bash
# 检查 Secret 是否存在
firebase functions:secrets:list

# 如果不存在，设置它
firebase functions:secrets:set ANTHROPIC_API_KEY

# 重新部署
firebase deploy --only functions
```

### 问题 2: 本地 Emulator 无法访问 Secret

**错误**：
```
Error: Unable to access secret ANTHROPIC_API_KEY
```

**解决方法**：
1. 确保已登录正确的 Firebase 账号
2. 确保有 Secret Manager 访问权限
3. 或者使用本地环境变量替代

### 问题 3: Functions 部署失败

**错误**：
```
Error deploying Cloud Functions: Missing required secret
```

**解决方法**：
在 `functions/main.py` 中确保所有使用 Secrets 的函数都在装饰器中声明：

```python
@https_fn.on_call(secrets=["ANTHROPIC_API_KEY"])  # ✅
def my_function(req):
    pass
```

---

## 📚 延伸阅读

- [Firebase Functions Secrets 官方文档](https://firebase.google.com/docs/functions/config-env#secret-manager)
- [Google Secret Manager 文档](https://cloud.google.com/secret-manager/docs)
- [Anthropic API 文档](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)

---

## ✅ 检查清单

部署前确保：

- [ ] 已设置 `ANTHROPIC_API_KEY` Secret
- [ ] 在所有使用 Claude API 的 Functions 装饰器中声明 `secrets=["ANTHROPIC_API_KEY"]`
- [ ] 本地测试通过（使用环境变量或 Secrets）
- [ ] CI/CD Service Account 有 Secret Manager 访问权限
- [ ] `.env` 文件已添加到 `.gitignore`

---

**最后更新**: 2025-10-23  
**维护者**: CoachX Team

