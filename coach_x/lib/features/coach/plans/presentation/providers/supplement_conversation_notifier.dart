import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_creation_state.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/repositories/supplement_plan_repository.dart';
import 'package:coach_x/features/coach/plans/data/repositories/plan_repository.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_supplement_plan_notifier.dart';

/// 补剂对话状态管理
class SupplementConversationNotifier extends StateNotifier<SupplementCreationState> {
  final SupplementPlanRepository _supplementPlanRepository;
  final PlanRepository _planRepository;
  final CreateSupplementPlanNotifier _createNotifier;

  // 私有字段
  List<ExercisePlanModel> _exercisePlans = [];
  List<DietPlanModel> _dietPlans = [];

  SupplementConversationNotifier(
    this._supplementPlanRepository,
    this._planRepository,
    this._createNotifier,
  ) : super(const SupplementCreationState());

  /// 初始化对话
  Future<void> initConversation() async {
    AppLogger.info('💬 初始化补剂计划对话');

    try {
      // 加载教练的计划列表
      await _loadUserPlans();

      // 添加AI欢迎消息
      final welcomeMessage = LLMChatMessage.ai(
        content: '您好！我是您的补剂推荐助手。我可以根据您的训练和饮食计划，为您推荐科学合理的补剂方案。请选择下方的选项开始：',
        options: [
          InteractiveOption(
            id: 'two_step',
            label: '根据训练和饮食计划推荐',
            subtitle: '综合分析训练强度和营养摄入',
            type: 'two_step',
          ),
          InteractiveOption(
            id: 'basic',
            label: '基础套餐',
            subtitle: '通用补剂推荐方案',
            type: 'basic',
          ),
        ],
        interactionType: 'quick_action',
      );

      state = state.copyWith(
        messages: [welcomeMessage],
        canSendMessage: true,
      );

      AppLogger.info('✅ 对话初始化完成');
    } catch (e) {
      AppLogger.error('❌ 初始化对话失败', e);
      state = state.copyWith(
        errorMessage: '初始化失败：$e',
      );
    }
  }

  /// 加载用户的计划列表
  Future<void> _loadUserPlans() async {
    try {
      AppLogger.debug('📋 加载用户计划列表');

      // 调用 repository 获取所有计划
      final plansData = await _planRepository.fetchAllPlans();

      _exercisePlans = List<ExercisePlanModel>.from(plansData.exercisePlans);
      _dietPlans = List<DietPlanModel>.from(plansData.dietPlans);

      AppLogger.debug('✅ 计划加载完成：训练${_exercisePlans.length}个，饮食${_dietPlans.length}个');
    } catch (e) {
      AppLogger.warning('⚠️ 加载计划失败: $e');
      _exercisePlans = <ExercisePlanModel>[];
      _dietPlans = <DietPlanModel>[];
    }
  }

  /// 发送消息
  Future<void> sendMessage(String userMessage, {String? optionType}) async {
    if (userMessage.trim().isEmpty && optionType == null) return;

    AppLogger.info('📤 发送消息: $userMessage, 类型: $optionType');

    // 添加用户消息到历史
    final newMessages = List<LLMChatMessage>.from(state.messages);
    if (userMessage.isNotEmpty) {
      newMessages.add(LLMChatMessage.user(content: userMessage));
    }

    state = state.copyWith(
      messages: newMessages,
      canSendMessage: false,
    );

    // 根据选项类型处理
    if (optionType == 'basic') {
      // 基础套餐：直接生成
      await _generateSupplementRecommendation(userMessage, null, null);
    } else if (optionType == 'two_step') {
      // 两步选择：先选训练计划
      _showPlanSelectionMessage('training');
      state = state.copyWith(
        currentSelectionStep: SelectionStep.training,
        canSendMessage: true,
      );
    } else {
      // 普通消息：根据当前步骤处理
      if (state.currentSelectionStep != null) {
        // 正在选择过程中，忽略普通消息
        state = state.copyWith(canSendMessage: true);
      } else {
        // 直接生成
        await _generateSupplementRecommendation(userMessage, null, null);
      }
    }
  }

  /// 显示计划选择消息
  void _showPlanSelectionMessage(String planType, {bool isFinal = false}) {
    final newMessages = List<LLMChatMessage>.from(state.messages);

    if (planType == 'training') {
      // 训练计划选择
      final options = _exercisePlans.map((plan) {
        return InteractiveOption(
          id: plan.id,
          label: plan.name,
          subtitle: '${plan.days.length}天',
          type: 'training_plan',
        );
      }).toList();

      if (options.isEmpty) {
        newMessages.add(LLMChatMessage.ai(
          content: '暂无可用的训练计划，请先创建训练计划。',
        ));
      } else {
        newMessages.add(LLMChatMessage.ai(
          content: '请选择训练计划：',
          options: options,
          interactionType: 'plan_selection',
        ));
      }
    } else if (planType == 'diet') {
      // 饮食计划选择
      final options = _dietPlans.map((plan) {
        return InteractiveOption(
          id: plan.id,
          label: plan.name,
          subtitle: '${plan.days.length}天',
          type: 'diet_plan',
        );
      }).toList();

      if (options.isEmpty) {
        newMessages.add(LLMChatMessage.ai(
          content: '暂无可用的饮食计划，请先创建饮食计划。',
        ));
      } else {
        newMessages.add(LLMChatMessage.ai(
          content: '接下来请选择饮食计划：',
          options: options,
          interactionType: 'plan_selection',
        ));
      }
    }

    state = state.copyWith(messages: newMessages);
  }

  /// 处理选项选择
  Future<void> handleOptionSelected(InteractiveOption option) async {
    AppLogger.info('🎯 选择选项: ${option.label} (${option.type})');

    // 添加用户选择消息
    final newMessages = List<LLMChatMessage>.from(state.messages);

    state = state.copyWith(
      messages: newMessages,
      canSendMessage: false,
    );

    if (option.type == 'training_plan') {
      // 选择了训练计划
      state = state.copyWith(
        selectedTrainingPlanId: option.id,
        selectedTrainingPlanName: option.label,
      );

      // 判断是否需要第二步
      if (state.currentSelectionStep == SelectionStep.training) {
        // 两步选择，继续选择饮食计划
        _showPlanSelectionMessage('diet');
        state = state.copyWith(
          currentSelectionStep: SelectionStep.diet,
          canSendMessage: true,
        );
      } else {
        // 单步选择，直接生成
        await _generateSupplementRecommendation(
          '请根据我的训练计划推荐补剂',
          state.selectedTrainingPlanId,
          null,
        );
      }
    } else if (option.type == 'diet_plan') {
      // 选择了饮食计划
      state = state.copyWith(
        selectedDietPlanId: option.id,
        selectedDietPlanName: option.label,
      );

      // 生成推荐
      await _generateSupplementRecommendation(
        '请根据我的计划推荐补剂',
        state.selectedTrainingPlanId,
        state.selectedDietPlanId,
      );
    } else {
      // 快捷选项
      await sendMessage(option.label, optionType: option.type);
    }
  }

  /// 生成补剂推荐
  Future<void> _generateSupplementRecommendation(
    String userMessage,
    String? trainingPlanId,
    String? dietPlanId,
  ) async {
    AppLogger.info('🤖 开始生成补剂推荐');

    state = state.copyWith(
      isAIResponding: true,
      canSendMessage: false,
    );

    // 添加思考消息
    final newMessages = List<LLMChatMessage>.from(state.messages);
    final loadingMessage = LLMChatMessage.aiLoading(content: '正在生成补剂方案...');
    newMessages.add(loadingMessage);
    state = state.copyWith(messages: newMessages);

    try {
      // 调用 AI 服务
      final stream = AIService.generateSupplementPlanConversation(
        userMessage: userMessage,
        trainingPlanId: trainingPlanId,
        dietPlanId: dietPlanId,
        conversationHistory: [],
      );

      await for (final event in stream) {
        final eventType = event['type'] as String?;

        if (eventType == 'thinking') {
          // 更新思考内容
          final content = event['content'] as String?;
          if (content != null) {
            final updatedMessages = List<LLMChatMessage>.from(state.messages);
            final lastIndex = updatedMessages.length - 1;
            if (lastIndex >= 0) {
              final lastMessage = updatedMessages[lastIndex];
              updatedMessages[lastIndex] = lastMessage.copyWith(
                content: lastMessage.content + content,
              );
              state = state.copyWith(messages: updatedMessages);
            }
          }
        } else if (eventType == 'analysis') {
          // 添加分析消息
          final content = event['content'] as String?;
          if (content != null) {
            final updatedMessages = List<LLMChatMessage>.from(state.messages);
            updatedMessages.add(LLMChatMessage.ai(content: content));
            state = state.copyWith(messages: updatedMessages);
          }
        } else if (eventType == 'suggestion') {
          // 接收补剂建议
          final data = event['data'] as Map<String, dynamic>?;
          if (data != null) {
            final supplementDayData = data['supplement_day'] as Map<String, dynamic>?;
            if (supplementDayData != null) {
              final supplementDay = SupplementDay.fromJson(supplementDayData);
              state = state.copyWith(
                pendingSuggestion: supplementDay,
              );

              // 添加建议消息
              final summary = data['summary'] as String? ?? '已生成补剂方案';
              final updatedMessages = List<LLMChatMessage>.from(state.messages);
              updatedMessages.add(LLMChatMessage.ai(content: summary));
              state = state.copyWith(messages: updatedMessages);
            }
          }
        } else if (eventType == 'complete') {
          // 完成
          state = state.copyWith(
            isAIResponding: false,
            canSendMessage: true,
          );
        } else if (eventType == 'error') {
          // 错误
          final error = event['error'] as String? ?? '生成失败';
          final updatedMessages = List<LLMChatMessage>.from(state.messages);
          updatedMessages.add(LLMChatMessage.ai(content: '抱歉，生成失败：$error'));
          state = state.copyWith(
            messages: updatedMessages,
            isAIResponding: false,
            canSendMessage: true,
            errorMessage: error,
          );
        }
      }
    } catch (e) {
      AppLogger.error('❌ 生成补剂推荐失败', e);
      final updatedMessages = List<LLMChatMessage>.from(state.messages);
      updatedMessages.add(LLMChatMessage.ai(content: '抱歉，生成失败：$e'));
      state = state.copyWith(
        messages: updatedMessages,
        isAIResponding: false,
        canSendMessage: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// 应用建议
  void applySuggestion() {
    if (state.pendingSuggestion == null) return;

    AppLogger.info('✅ 应用补剂建议');

    // 获取当前已有的天数，如果没有则默认创建7天
    final existingDayCount = _createNotifier.state.days.length;
    final dayCount = existingDayCount > 0 ? existingDayCount : 7;

    // 调用 CreateSupplementPlanNotifier 应用
    _createNotifier.applyAIGeneratedDay(state.pendingSuggestion!, dayCount: dayCount);

    // 添加成功消息
    final newMessages = List<LLMChatMessage>.from(state.messages);
    newMessages.add(LLMChatMessage.system(content: '✅ 已应用补剂方案到${dayCount}天计划'));

    // 清空建议并更新消息
    state = state.copyWith(
      clearPendingSuggestion: true,
      messages: newMessages,
      canSendMessage: true,
    );
  }

  /// 拒绝建议
  void rejectSuggestion() {
    AppLogger.info('❌ 拒绝补剂建议');

    // 添加简单的问询消息
    final newMessages = List<LLMChatMessage>.from(state.messages);
    newMessages.add(LLMChatMessage.ai(
      content: '好的，我来重新为您推荐。请告诉我您希望如何调整补剂方案？',
    ));

    // 清空建议并更新消息
    state = state.copyWith(
      clearPendingSuggestion: true,
      messages: newMessages,
      canSendMessage: true,
    );

    AppLogger.info('✅ 已拒绝建议，pendingSuggestion = ${state.pendingSuggestion}');
  }
}
