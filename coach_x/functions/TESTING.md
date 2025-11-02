# 云函数测试模式说明

## 概述

为了方便前端开发和测试，我们在学生列表相关的云函数中添加了测试模式开关。当测试模式开启时，云函数会返回预设的假数据，无需连接真实数据库。

## 测试模式开关

在以下文件中设置 `USE_FAKE_DATA` 变量：

### 学生管理模块
**文件**: `functions/students/handlers.py`

```python
# 测试模式开关 - 设为True返回假数据，方便前端测试
USE_FAKE_DATA = True  # 改为 False 切换到生产模式
```

### 邀请码模块
**文件**: `functions/invitations/handlers.py`

```python
# 测试模式开关 - 设为True返回假数据，方便前端测试
USE_FAKE_DATA = True  # 改为 False 切换到生产模式
```

## 测试模式下的云函数

### 1. `fetch_students` - 获取学生列表

**返回数据**:
- 25个假学生
- 包含不同的训练、饮食、补剂计划组合
- 支持分页测试（page_size, page_number）
- 支持搜索测试（search_name）
- 随机的头像URL
- 随机创建时间

**假数据特点**:
- 学生姓名: 张三、李四、王五等25个中文名字
- 头像: 使用 pravatar.cc 提供的随机头像
- 计划分配: 随机分配（约70%有训练计划，50%有饮食计划，40%有补剂计划）
- 计划类型:
  - 训练计划: 增肌训练计划A、减脂训练计划B、塑形训练计划C、力量提升计划
  - 饮食计划: 高蛋白饮食计划、低碳水饮食计划、均衡营养计划
  - 补剂计划: 增肌补剂方案、减脂补剂方案

### 2. `delete_student` - 删除学生

**测试行为**:
- 直接返回成功消息
- 不执行任何数据库操作
- 记录日志以便调试

### 3. `fetch_available_plans` - 获取可用计划

**返回数据**:
- 4个训练计划
- 3个饮食计划
- 2个补剂计划

### 4. `fetch_invitation_codes` - 获取邀请码列表

**返回数据**:
- 8个假邀请码
- 不同状态: 未使用、已使用、即将过期
- 不同签约时长: 90天、180天
- 不同备注: 新学员专用、春季促销等

**假数据特点**:
- 代码格式: XXXX-XXXX-XXXX（12位）
- 剩余天数: 0-30天不等
- 总时长: 90天或180天
- 状态混合: 已使用和未使用

### 5. `generate_invitation_codes` - 生成邀请码

**测试行为**:
- 返回随机生成的邀请码字符串
- 不执行数据库写入
- 支持自定义参数测试（count, total_days, note）

### 6. `mark_invitation_code_used` - 标记邀请码已使用

**测试行为**:
- 直接返回成功消息
- 不执行任何数据库操作

## 使用建议

### 前端开发阶段
1. 保持 `USE_FAKE_DATA = True`
2. 专注于UI交互和状态管理
3. 测试分页、搜索、筛选等功能
4. 无需部署云函数即可开发

### 集成测试阶段
1. 设置 `USE_FAKE_DATA = False`
2. 部署云函数到 Firebase
3. 准备真实测试数据
4. 测试端到端流程

### 生产环境
1. **必须**设置 `USE_FAKE_DATA = False`
2. 确保所有认证和权限检查生效
3. 使用真实数据库

## 注意事项

⚠️ **重要**: 在部署到生产环境前，务必确认所有 `USE_FAKE_DATA` 标志都已设置为 `False`

⚠️ **安全**: 测试模式会跳过身份认证检查，仅用于开发环境

⚠️ **数据一致性**: 测试模式下的"删除"操作不会真正删除数据，刷新页面后数据会重新出现

## 查看日志

测试模式下的操作都会在日志中标记 `[测试模式]`，方便区分：

```
[测试模式] 返回假数据: page=1, count=20
[测试模式] 模拟删除学生: student_5
[测试模式] 返回假计划列表
[测试模式] 返回假邀请码列表
```

## 切换步骤

### 开启测试模式 → 关闭测试模式

1. 编辑 `functions/students/handlers.py`:
   ```python
   USE_FAKE_DATA = False
   ```

2. 编辑 `functions/invitations/handlers.py`:
   ```python
   USE_FAKE_DATA = False
   ```

3. 重新部署云函数:
   ```bash
   cd coach_x
   firebase deploy --only functions
   ```

4. 确认日志中不再出现 `[测试模式]` 标记

---

## AI 编辑对话模块

### 文件位置
**文件**: `functions/ai/streaming.py`

**开关位置**: 第 18 行

```python
# 测试模式开关 - 设为True返回假数据，方便前端测试
USE_FAKE_DATA = False  # 改为 True 开启测试模式
```

### 测试模式下的功能
**流式事件序列**:
```
1. thinking → "正在分析您的修改请求..."
2. analysis → 分析内容（描述发现的问题）
3. suggestion → 修改建议列表 + 摘要
5. complete → "修改建议已生成"
```

**测试用途**:
- 测试前端 Review Mode 逐步审查 UI
- 验证修改建议卡片的显示
- 测试自动滚动到目标动作
- 验证接受/拒绝修改的流程
- 测试进度显示（1/10, 2/10...）

**日志标识**:
```
[测试模式] 使用假数据生成编辑建议
[测试模式] 生成假编辑建议
[测试模式] 生成了X个假修改建议
[测试模式] 开始流式返回假编辑响应
[测试模式] 假编辑响应流式返回完成
```

### 使用建议

#### 前端开发阶段
1. 设置 `USE_FAKE_DATA = True`
2. 在前端打开任意训练计划
3. 点击 Sparkle ✨ 按钮进入编辑对话
4. 发送任意修改请求（如"优化一下"）
5. 立即收到假的修改建议，无需等待 AI 响应
6. 测试 Review Mode 的各种交互

#### 集成测试阶段
1. 设置 `USE_FAKE_DATA = False`
2. 确保 Claude API Key 已配置
3. 测试真实的 AI 编辑对话流程

#### 切换步骤

**开启测试模式**:
```bash
# 编辑 functions/ai/streaming.py 第 18 行
USE_FAKE_DATA = True
```

**关闭测试模式**:
```bash
# 编辑 functions/ai/streaming.py 第 18 行
USE_FAKE_DATA = False

# 重新部署（如果已部署）
cd coach_x
firebase deploy --only functions
```

### 注意事项

⚠️ **生产环境**: 必须设置 `USE_FAKE_DATA = False`，否则所有编辑请求都会返回假数据

⚠️ **数据一致性**: 假数据基于传入的 `current_plan` 动态生成，确保索引有效

---

## 参数解析最佳实践

### 问题背景

Firebase Cloud Functions 2nd gen Python SDK 使用 gRPC/Protobuf 与客户端通信。当 Flutter 客户端发送整数参数时，会被序列化为 Protobuf `Int64Value` 格式：

```python
# 客户端发送: {'page_size': 20}
# 后端接收: {'page_size': {'value': '20', '@type': 'type.googleapis.com/google.protobuf.Int64Value'}}
```

直接使用 `req.data.get('page_size')` 会返回字典而非整数，导致类型错误。

### 解决方案：使用参数解析工具

我们提供了 `utils/param_parser.py` 模块来处理 Protobuf 包装：

#### 导入工具函数

```python
from utils.param_parser import parse_int_param, parse_float_param, parse_bool_param
```

#### 使用示例

```python
@https_fn.on_call()
def my_function(req: https_fn.CallableRequest):
    # ❌ 错误方式（会导致类型错误）
    page_size = req.data.get('page_size', 20)
    count = req.data.get('count', 1)

    # ✅ 正确方式（使用解析工具）
    page_size = parse_int_param(req.data.get('page_size'), 20)
    count = parse_int_param(req.data.get('count'), 1)
    height = parse_float_param(req.data.get('height'), 170.0)
    enabled = parse_bool_param(req.data.get('enabled'), False)

    # 现在可以安全地进行数值比较
    if page_size < 1 or page_size > 100:
        raise https_fn.HttpsError('invalid-argument', '页面大小无效')
```

### 工具函数说明

#### `parse_int_param(value, default=None)`

解析整数参数，处理 Protobuf Int64Value 格式。

**参数**:
- `value`: 参数值（可能是 int, dict, None）
- `default`: 默认值

**返回**: 整数或默认值

#### `parse_float_param(value, default=None)`

解析浮点数参数，处理 Protobuf DoubleValue 格式。

#### `parse_bool_param(value, default=None)`

解析布尔参数（为 API 一致性提供）。

#### `parse_string_param(value, default=None)`

解析字符串参数。

### 受影响的数据类型

| Dart 类型 | Protobuf 包装 | 是否需要解析 |
|-----------|--------------|-------------|
| `int` | `Int64Value` | ✅ 需要 |
| `double` | `DoubleValue` | ✅ 需要 |
| `bool` | 直接传递 | ⚠️ 建议使用（一致性） |
| `String` | 直接传递 | ⚠️ 建议使用（一致性） |

### 常见错误

#### 错误 1: 类型比较失败

```python
# ❌ 错误
page_size = req.data.get('page_size', 20)
if page_size < 1:  # TypeError: '<' not supported between instances of 'dict' and 'int'
    raise https_fn.HttpsError(...)
```

#### 错误 2: 算术运算失败

```python
# ❌ 错误
count = req.data.get('count', 1)
total = count * 2  # TypeError: can't multiply sequence by non-int of type 'dict'
```

#### 错误 3: 字符串格式化失败

```python
# ❌ 错误
age = req.data.get('age')
message = f'年龄: {age}岁'  # 输出: "年龄: {'value': '25'}岁"
```

### 最佳实践

1. **所有整数/浮点参数都使用解析工具**
   ```python
   page_size = parse_int_param(req.data.get('page_size'), 20)
   height = parse_float_param(req.data.get('height'))
   ```

2. **为保持 API 一致性，建议所有类型都使用解析工具**
   ```python
   enabled = parse_bool_param(req.data.get('enabled'), False)
   name = parse_string_param(req.data.get('name'), '')
   ```

3. **始终提供合理的默认值**
   ```python
   # ✅ 推荐
   page_size = parse_int_param(req.data.get('page_size'), 20)

   # ⚠️ 谨慎使用 None 作为默认值
   age = parse_int_param(req.data.get('age'))  # 可能返回 None
   if age is not None and age < 18:
       # 处理逻辑
   ```

4. **参数验证应在解析后进行**
   ```python
   page_size = parse_int_param(req.data.get('page_size'), 20)

   # 验证
   if page_size < 1 or page_size > 100:
       raise https_fn.HttpsError('invalid-argument', '页面大小必须在1-100之间')
   ```

### 迁移指南

如果现有代码没有使用参数解析工具，按以下步骤迁移：

1. **导入工具函数**
   ```python
   from utils.param_parser import parse_int_param, parse_float_param
   ```

2. **识别整数/浮点参数**
   查找所有 `req.data.get()` 调用，找出期望数值类型的参数。

3. **替换为解析工具**
   ```python
   # 迁移前
   count = req.data.get('count', 1)

   # 迁移后
   count = parse_int_param(req.data.get('count'), 1)
   ```

4. **测试验证**
   确保所有数值比较和运算正常工作。

### 参考实现

查看以下文件了解完整示例：

- `functions/students/handlers.py::fetch_students` - 整数参数解析
- `functions/invitations/handlers.py::generate_invitation_codes` - 整数参数解析
- `functions/users/handlers.py::update_user_info` - 浮点数参数解析
- `functions/chat/handlers.py::fetch_messages` - 混合类型参数解析

