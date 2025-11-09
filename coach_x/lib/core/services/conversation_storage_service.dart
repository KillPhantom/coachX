import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coach_x/features/coach/plans/data/models/llm_chat_message.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 对话历史存储服务
///
/// 使用 SharedPreferences 持久化 AI 编辑对话历史
/// 按 planId 作为 key 存储，支持加载、保存、清除操作
class ConversationStorageService {
  static const String _keyPrefix = 'conversation_edit_';

  /// 保存对话历史
  ///
  /// [planId] 训练计划 ID
  /// [messages] 消息列表
  static Future<void> saveConversation(
    String planId,
    List<LLMChatMessage> messages,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + planId;

      // 过滤掉加载中的消息（不需要持久化）
      final messagesToSave = messages.where((m) => !m.isLoading).toList();

      final data = {
        'planId': planId,
        'messages': messagesToSave.map((m) => m.toJson()).toList(),
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      final jsonString = json.encode(data);
      await prefs.setString(key, jsonString);

      AppLogger.debug(
        '💾 保存对话历史: planId=$planId, 消息数=${messagesToSave.length}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('❌ 保存对话历史失败', e, stackTrace);
    }
  }

  /// 加载对话历史
  ///
  /// [planId] 训练计划 ID
  /// 返回消息列表，如果不存在则返回空列表
  static Future<List<LLMChatMessage>> loadConversation(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + planId;

      final jsonString = prefs.getString(key);
      if (jsonString == null) {
        AppLogger.debug('📭 没有找到对话历史: planId=$planId');
        return [];
      }

      final data = json.decode(jsonString) as Map<String, dynamic>;
      final messagesJson = data['messages'] as List<dynamic>;

      final messages = messagesJson
          .map((m) => LLMChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();

      AppLogger.info('📂 加载对话历史: planId=$planId, 消息数=${messages.length}');
      return messages;
    } catch (e, stackTrace) {
      AppLogger.error('❌ 加载对话历史失败', e, stackTrace);
      return [];
    }
  }

  /// 清除单个计划的对话历史
  ///
  /// [planId] 训练计划 ID
  static Future<void> clearConversation(String planId) async {
    try {
      AppLogger.debug('🗑️ 开始清除对话历史: planId=$planId');
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + planId;

      final existed = prefs.containsKey(key);
      await prefs.remove(key);

      if (existed) {
        AppLogger.info('✅ 成功清除对话历史: planId=$planId');
      } else {
        AppLogger.debug('⚠️ 对话历史不存在，无需清除: planId=$planId');
      }
    } catch (e, stackTrace) {
      // 捕获异常但不抛出，确保清除流程不会中断应用
      AppLogger.error('❌ 清除对话历史失败: planId=$planId', e, stackTrace);
    }
  }

  /// 清除所有对话历史（可选，用于清理）
  static Future<void> clearAllConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final conversationKeys = keys.where((k) => k.startsWith(_keyPrefix));

      for (final key in conversationKeys) {
        await prefs.remove(key);
      }

      AppLogger.info('🗑️ 清除所有对话历史: 数量=${conversationKeys.length}');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除所有对话历史失败', e, stackTrace);
    }
  }

  /// 检查是否存在对话历史
  ///
  /// [planId] 训练计划 ID
  static Future<bool> hasConversation(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + planId;
      return prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  /// 获取对话历史的最后更新时间
  ///
  /// [planId] 训练计划 ID
  /// 返回时间戳，如果不存在则返回 null
  static Future<DateTime?> getLastUpdated(String planId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + planId;

      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;

      final data = json.decode(jsonString) as Map<String, dynamic>;
      final timestamp = data['lastUpdated'] as int?;

      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      return null;
    }
  }
}
