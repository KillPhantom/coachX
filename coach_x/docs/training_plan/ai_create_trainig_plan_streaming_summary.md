
## 🔧 要求：在主页面显示思考过程（待实现）

### 实现方案

#### 1. 修改 `guided_creation_sheet.dart` 的 `_generatePlanStreaming()`

**当前逻辑:**
- 弹窗内显示思考面板
- 完成后关闭弹窗

**新逻辑:**
```dart
Future<void> _generatePlanStreaming() async {
  // ... 参数准备 ...
  
  // 立即关闭弹窗
  if (mounted) {
    Navigator.of(context).pop();
  }
  
  // 调用 notifier（不传递回调）
  await notifier.generateFromParamsStreaming(params);
  
  // 主页面的思考面板会自动响应状态变化
}
```

#### 2. 在 `create_training_plan_page.dart` 底部添加思考面板

**位置:** 在 `Content Area` 的 `Expanded` widget 后，底部按钮栏之前

**代码结构:**
```dart
Column(
  children: [
    // 左侧天数列表
    // 右侧内容区域
    
    // 新增：AI思考面板（仅在生成时显示）
    if (state.aiStatus == AIGenerationStatus.generating)
      _buildAIThinkingPanel(state),
    
    // 底部按钮
    _buildBottomButtons(context, notifier, state),
  ],
)
```

#### 3. 实现 `_buildAIThinkingPanel()` 方法

```dart
Widget _buildAIThinkingPanel(CreateTrainingPlanState state) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      border: Border(
        top: BorderSide(color: AppColors.divider, width: 1),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Row(
          children: [
            CupertinoActivityIndicator(),
            const SizedBox(width: 12),
            Text(
              'AI 正在生成训练计划...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 进度
        if (state.days.isNotEmpty) ...[
          Text(
            '进度: ${state.days.length} 天已完成',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          
          // 已生成的天数列表
          ...state.days.map((day) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.check_mark_circled_solid,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${day.name} (${day.exercises.length}个动作)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )),
        ],
      ],
    ),
  );
}
```

#### 4. 修改 `CreateTrainingPlanNotifier` 移除回调

**当前代码:**
```dart
Future<void> generateFromParamsStreaming(
  PlanGenerationParams params, {
  Function(String thinking)? onThinking,
  Function(ExerciseTrainingDay day)? onDayComplete,
}) async {
  // ... 内部使用回调更新状态 ...
}
```

**修改为:**
```dart
Future<void> generateFromParamsStreaming(
  PlanGenerationParams params,
) async {
  try {
    state = state.copyWith(
      days: [],
      aiStatus: AIGenerationStatus.generating,
      errorMessage: '',
    );

    await for (final event in AIService.generatePlanStreaming(params: params)) {
      if (event.isDayComplete && event.dayData != null) {
        final updatedDays = [...state.days, event.dayData!];
        state = state.copyWith(days: updatedDays);
        AppLogger.info('✅ 第 ${event.day} 天已添加');
      } else if (event.isComplete) {
        state = state.copyWith(aiStatus: AIGenerationStatus.success);
        AppLogger.info('🎉 流式生成完成 - 共 ${state.days.length} 天');
        break;
      } else if (event.isError) {
        state = state.copyWith(
          aiStatus: AIGenerationStatus.error,
          errorMessage: event.error ?? '生成失败',
        );
        AppLogger.error('❌ 流式生成失败: ${event.error}');
        break;
      }
    }
  } catch (e, stackTrace) {
    AppLogger.error('❌ 流式生成异常', e, stackTrace);
    state = state.copyWith(
      aiStatus: AIGenerationStatus.error,
      errorMessage: '生成失败: $e',
    );
  }
}
```

### 工作流程

1. 用户点击"生成计划" → 弹窗立即关闭
2. `createTrainingPlanNotifierProvider` 状态变为 `generating`
3. 主页面底部显示思考面板
4. 每生成一天 → 状态更新 → 思考面板刷新
5. 生成完成 → 思考面板消失

### 优势

- ✅ 用户可以在生成过程中看到主页面
- ✅ 实时看到计划一天天被添加
- ✅ 思考过程清晰可见
- ✅ 不阻塞UI，用户体验更好

---