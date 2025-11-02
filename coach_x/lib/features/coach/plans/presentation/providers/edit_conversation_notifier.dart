import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/core/services/conversation_storage_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/edit_conversation_state.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';
import 'package:coach_x/features/coach/plans/data/models/exercise_plan_model.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/suggestion_review_notifier.dart';

/// 编辑对话状态管理
class EditConversationNotifier extends StateNotifier<EditConversationState> {
  EditConversationNotifier() : super(const EditConversationState());

  // 当前编辑的计划 ID（用于保存对话历史）
  String? _currentPlanId;

  // 标记 notifier 是否已被 dispose
  bool _isMounted = true;

  /// 初始化对话（设置当前计划）
  Future<void> initConversation(
    ExercisePlanModel currentPlan,
    String planId,
  ) async {
    // 存储当前计划 ID
    _currentPlanId = planId;
    AppLogger.info('🆕 初始化编辑对话 - 计划: ${currentPlan.name}');

    // 尝试加载历史对话
    final savedMessages = await ConversationStorageService.loadConversation(planId);

    if (savedMessages.isNotEmpty) {
      // 有历史对话，恢复状态
      AppLogger.info('📂 恢复历史对话 - 消息数: ${savedMessages.length}');
      state = EditConversationState(
        currentPlan: currentPlan,
        messages: savedMessages,
        isAIResponding: false,
      );
    } else {
      // 没有历史对话，初始化新对话
      state = EditConversationState.initial(currentPlan: currentPlan);
      AppLogger.info('🆕 开始新对话');
    }
  }

  /// 发送用户消息
  Future<void> sendMessage(
    String message,
    String planId,
  ) async {
    if (!_isMounted) return;

    if (state.currentPlan == null) {
      AppLogger.error('❌ 当前计划为空，无法发送消息');
      if (_isMounted) {
        state = state.copyWith(error: '当前计划为空');
      }
      return;
    }

    if (!state.canSendMessage) {
      AppLogger.warning('⚠️ 无法发送消息：AI 正在响应中');
      return;
    }

    try {
      AppLogger.info('📤 发送用户消息: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');

      // 1. 添加用户消息到对话
      final userMessage = LLMChatMessage.user(content: message);
      if (!_isMounted) return;
      state = state.addMessage(userMessage).copyWith(
        isAIResponding: true,
        clearError: true,
      );

      // 2. 添加 AI 加载消息
      final loadingMessage = LLMChatMessage.aiLoading();
      if (!_isMounted) return;
      state = state.addMessage(loadingMessage);

      // 3. 调用 AI Service 流式生成
      String analysisContent = '';
      List<PlanChange>? changes;
      String? summary;

      await for (final event in AIService.editPlanConversation(
        planId: planId,
        userMessage: message,
        currentPlan: state.currentPlan!,
      )) {
        if (!_isMounted) return;

        if (event.isThinking) {
          // 思考过程 - 追加到最后一条消息
          if (event.content != null) {
            if (!_isMounted) return;
            state = state.appendToLastMessage(event.content!);
          }
        } else if (event.isAnalysis) {
          // 分析结果
          if (event.content != null) {
            analysisContent = event.content!;
            // 更新最后一条消息为分析内容
            if (!_isMounted) return;
            state = state.updateLastMessage(
              LLMChatMessage.ai(content: analysisContent),
            );
          }
        } else if (event.isSuggestion) {
          // 修改建议
          if (event.data != null) {
            final data = event.data!;
            if (data['changes'] != null) {
              changes = (data['changes'] as List<dynamic>)
                  .map((c) => PlanChange.fromJson(c as Map<String, dynamic>))
                  .toList();
            }
            if (data['summary'] != null) {
              summary = data['summary'] as String;
            }
          }
        } else if (event.isComplete) {
          // 完成 - 组合所有数据创建建议
          // 如果analysisContent为空，尝试从最后一条消息获取内容
          final lastMessage = state.messages.isNotEmpty ? state.messages.last : null;
          final finalAnalysisContent = analysisContent.isNotEmpty
              ? analysisContent
              : (lastMessage?.content ?? '');

          // 诊断日志
          AppLogger.debug('📊 Complete 事件数据检查:');
          AppLogger.debug('  - changes: ${changes != null ? '✅ ${changes!.length} 项' : '❌ null'}');
          AppLogger.debug('  - summary: ${summary != null && summary!.isNotEmpty ? '✅ 有' : '⚠️ 空/null'}');
          AppLogger.debug('  - analysisContent: ${analysisContent.isNotEmpty ? '✅ ${analysisContent.length} 字符' : '❌ 空'}');

          if (changes != null && changes.isNotEmpty) {
            // 有修改建议 - 创建编辑建议（主流程）
            AppLogger.info('📝 检测到 ${changes.length} 处修改，创建编辑建议');

            // 为缺失字段提供默认值
            final finalSummary = summary?.trim().isNotEmpty == true
                ? summary!
                : '已生成 ${changes.length} 处修改';

            AppLogger.debug('  - 使用 summary: ${summary != null ? '原值' : '默认值'}');

            final suggestion = PlanEditSuggestion(
              analysis: finalAnalysisContent,
              changes: changes,
              summary: finalSummary,
            );

            // 更新最后一条 AI 消息，添加建议
            if (!_isMounted) return;
            state = state.updateLastMessage(
              lastMessage!.copyWith(
                content: '$finalAnalysisContent\n\n$finalSummary',
                suggestion: suggestion,
                isLoading: false,
              ),
            ).copyWith(
              pendingSuggestion: suggestion,
              isAIResponding: false,
            );

            AppLogger.info('✅ AI 响应完成（编辑建议，${changes.length} 处修改）');
          } else if (finalAnalysisContent.isNotEmpty) {
            // 纯文本响应（没有tool调用，如总结请求）
            AppLogger.info('✅ AI 响应完成（纯文本总结，无修改建议）');
            if (!_isMounted) return;
            state = state.updateLastMessage(
              LLMChatMessage.ai(content: finalAnalysisContent),
            ).copyWith(
              isAIResponding: false,
            );
          } else {
            // 真正的错误：既没有 changes 也没有 analysis
            AppLogger.warning('⚠️ AI 响应数据不完整（无 changes 且无 analysis）');
            if (!_isMounted) return;
            state = state.updateLastMessage(
              LLMChatMessage.ai(content: '抱歉，未能生成有效的响应'),
            ).copyWith(
              isAIResponding: false,
              error: '响应数据不完整',
            );
          }
        } else if (event.isError) {
          // 错误
          AppLogger.error('❌ AI 响应错误: ${event.error}');
          if (!_isMounted) return;
          state = state.updateLastMessage(
            LLMChatMessage.ai(content: '抱歉，处理您的请求时出现错误：${event.error}'),
          ).copyWith(
            isAIResponding: false,
            error: event.error,
          );
        }
      }

      // 保存对话历史
      if (_isMounted) {
        await _saveConversationHistory(planId);
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 发送消息异常', e, stackTrace);
      if (!_isMounted) return;
      state = state.updateLastMessage(
        LLMChatMessage.ai(content: '抱歉，发生了意外错误'),
      ).copyWith(
        isAIResponding: false,
        error: '发生意外错误: $e',
      );

      // 即使出错也保存对话历史
      if (_isMounted) {
        await _saveConversationHistory(planId);
      }
    }
  }

  /// 应用 AI 建议
  Future<void> applySuggestion() async {
    if (!_isMounted) return;

    if (state.pendingSuggestion == null) {
      AppLogger.warning('⚠️ 没有待应用的建议');
      return;
    }

    AppLogger.info('✅ 应用 AI 建议');

    final suggestion = state.pendingSuggestion!;
    ExercisePlanModel finalPlan;

    // 通过 changes 应用修改（source of truth）
    if (suggestion.changes.isNotEmpty && state.currentPlan != null) {
      AppLogger.info('📝 通过 changes 应用修改 (${suggestion.changes.length} 处)');

      // 创建临时的 SuggestionReviewNotifier 来应用所有 changes
      final reviewNotifier = SuggestionReviewNotifier();
      reviewNotifier.startReview(suggestion, state.currentPlan!);

      // 自动接受所有修改
      await reviewNotifier.acceptAll();

      // 获取最终计划
      finalPlan = reviewNotifier.finishReview() ?? state.currentPlan!;

      AppLogger.info('✅ 已通过 changes 生成新计划');
    } else {
      AppLogger.warning('⚠️ 没有 changes，使用当前计划');
      finalPlan = state.currentPlan!;
    }

    // 更新当前计划为修改后的计划
    if (!_isMounted) return;
    state = state.copyWith(
      currentPlan: finalPlan,
      clearPendingSuggestion: true,
      clearPreviewPlan: true,
      isPreviewMode: false,
    );

    // 添加系统消息
    final systemMessage = LLMChatMessage.system(
      content: '已应用修改建议',
    );
    if (!_isMounted) return;
    state = state.addMessage(systemMessage);

    // 保存对话历史
    if (_isMounted) {
      await _saveConversationHistory(_currentPlanId);
    }
  }

  /// 拒绝 AI 建议
  Future<void> rejectSuggestion() async {
    if (!_isMounted) return;

    if (state.pendingSuggestion == null) {
      AppLogger.warning('⚠️ 没有待拒绝的建议');
      return;
    }

    AppLogger.info('❌ 拒绝 AI 建议');

    if (!_isMounted) return;
    state = state.copyWith(
      clearPendingSuggestion: true,
      clearPreviewPlan: true,
      isPreviewMode: false,
    );

    // 添加系统消息
    final systemMessage = LLMChatMessage.system(
      content: '已拒绝修改建议',
    );
    if (!_isMounted) return;
    state = state.addMessage(systemMessage);

    // 保存对话历史
    if (_isMounted) {
      await _saveConversationHistory(_currentPlanId);
    }
  }

  /// 预览修改
  Future<void> previewChanges() async {
    if (!_isMounted) return;

    if (state.pendingSuggestion == null) {
      AppLogger.warning('⚠️ 没有可预览的建议');
      return;
    }

    AppLogger.info('👁️ 预览修改');

    final suggestion = state.pendingSuggestion!;

    // 通过 changes 生成预览计划
    if (suggestion.changes.isNotEmpty && state.currentPlan != null) {
      final reviewNotifier = SuggestionReviewNotifier();
      reviewNotifier.startReview(suggestion, state.currentPlan!);
      await reviewNotifier.acceptAll();
      final previewPlan = reviewNotifier.finishReview() ?? state.currentPlan!;

      if (!_isMounted) return;
      state = state.copyWith(
        previewPlan: previewPlan,
        isPreviewMode: true,
      );
    } else {
      // 如果没有 changes，使用当前计划作为预览
      if (!_isMounted) return;
      state = state.copyWith(
        previewPlan: state.currentPlan,
        isPreviewMode: true,
      );
    }
  }

  /// 退出预览模式
  void exitPreview() {
    if (!_isMounted) return;

    AppLogger.info('🚪 退出预览模式');

    state = state.copyWith(
      clearPreviewPlan: true,
      isPreviewMode: false,
    );
  }

  /// 清空对话
  void clearConversation() {
    if (!_isMounted) return;

    AppLogger.info('🗑️ 清空对话');
    state = state.clearConversation();
  }

  /// 清空错误
  void clearError() {
    if (!_isMounted) return;

    state = state.copyWith(clearError: true);
  }

  /// 更新当前计划（外部修改）
  void updateCurrentPlan(ExercisePlanModel plan) {
    if (!_isMounted) return;

    state = state.copyWith(currentPlan: plan);
  }

  /// 清除对话存储（离开编辑页面时调用）
  ///
  /// [planId] 可选的计划 ID，如果未提供则使用内部的 _currentPlanId
  void clearConversationStorage([String? planId]) {
    // 优先使用传入的 planId，否则使用内部的 _currentPlanId
    final idToUse = planId ?? _currentPlanId;

    if (idToUse != null && idToUse.isNotEmpty) {
      AppLogger.info('🗑️ 触发清除对话历史: planId=$idToUse');
      // 使用 unawaited 触发异步清除，不等待结果
      unawaited(ConversationStorageService.clearConversation(idToUse));
      _currentPlanId = null;
    } else {
      AppLogger.debug('⚠️ planId 为空，跳过清除对话历史');
    }
  }

  /// 保存对话历史（私有辅助方法）
  Future<void> _saveConversationHistory(String? planId) async {
    if (planId == null) {
      AppLogger.warning('⚠️ planId 为空，无法保存对话历史');
      return;
    }

    await ConversationStorageService.saveConversation(
      planId,
      state.messages,
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    AppLogger.debug('🔚 EditConversationNotifier disposed');
    super.dispose();
  }
}

