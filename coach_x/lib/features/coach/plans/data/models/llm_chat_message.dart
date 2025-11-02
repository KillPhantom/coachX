import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';

/// 交互式选项
class InteractiveOption {
  final String id;           // plan_id 或 option_id
  final String label;        // "增肌训练计划 A"
  final String? subtitle;    // "5天 · 创建于2025-01-15"
  final String type;         // 'training_plan' | 'diet_plan' | 'two_step' | 'training_only' | 'diet_only' | 'basic'
  final Map<String, dynamic>? metadata;

  const InteractiveOption({
    required this.id,
    required this.label,
    this.subtitle,
    required this.type,
    this.metadata,
  });

  factory InteractiveOption.fromJson(Map<String, dynamic> json) {
    return InteractiveOption(
      id: json['id'] as String,
      label: json['label'] as String,
      subtitle: json['subtitle'] as String?,
      type: json['type'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'subtitle': subtitle,
      'type': type,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'InteractiveOption(id: $id, label: $label, type: $type)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InteractiveOption &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ label.hashCode ^ type.hashCode;
}

/// LLM 聊天消息类型
enum LLMMessageType {
  user,    // 用户消息
  ai,      // AI 消息
  system,  // 系统消息
}

/// LLM 聊天消息模型
///
/// 用于 AI 对话式编辑，与教练学生之间的对话区分
class LLMChatMessage {
  final String id;
  final String content;
  final LLMMessageType type;
  final DateTime timestamp;
  final dynamic suggestion; // AI 的修改建议（可以是 PlanEditSuggestion 或 DietPlanEditSuggestion，仅 AI 消息有）
  final bool isLoading; // 是否正在加载中（AI 思考中）
  final List<InteractiveOption>? options; // 交互式选项列表
  final String? interactionType; // 交互类型，如 'plan_selection'

  const LLMChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.suggestion,
    this.isLoading = false,
    this.options,
    this.interactionType,
  });

  /// 创建用户消息
  factory LLMChatMessage.user({
    required String content,
  }) {
    return LLMChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: LLMMessageType.user,
      timestamp: DateTime.now(),
    );
  }

  /// 创建 AI 消息
  factory LLMChatMessage.ai({
    required String content,
    dynamic suggestion,
    List<InteractiveOption>? options,
    String? interactionType,
  }) {
    return LLMChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: LLMMessageType.ai,
      timestamp: DateTime.now(),
      suggestion: suggestion,
      options: options,
      interactionType: interactionType,
    );
  }

  /// 创建系统消息
  factory LLMChatMessage.system({
    required String content,
  }) {
    return LLMChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: LLMMessageType.system,
      timestamp: DateTime.now(),
    );
  }

  /// 创建加载中的 AI 消息
  factory LLMChatMessage.aiLoading({
    String content = '思考中...',
  }) {
    return LLMChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: LLMMessageType.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }

  /// 复制并修改
  LLMChatMessage copyWith({
    String? id,
    String? content,
    LLMMessageType? type,
    DateTime? timestamp,
    dynamic suggestion,
    bool? isLoading,
    List<InteractiveOption>? options,
    String? interactionType,
  }) {
    return LLMChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      suggestion: suggestion ?? this.suggestion,
      isLoading: isLoading ?? this.isLoading,
      options: options ?? this.options,
      interactionType: interactionType ?? this.interactionType,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'suggestion': suggestion?.toJson(),
      'isLoading': isLoading,
      'options': options?.map((o) => o.toJson()).toList(),
      'interactionType': interactionType,
    };
  }

  /// 从 JSON 创建
  factory LLMChatMessage.fromJson(Map<String, dynamic> json) {
    final optionsJson = json['options'] as List<dynamic>?;
    final options = optionsJson?.map((o) =>
      InteractiveOption.fromJson(o as Map<String, dynamic>)
    ).toList();

    return LLMChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: LLMMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LLMMessageType.system,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      suggestion: json['suggestion'] != null
          ? PlanEditSuggestion.fromJson(json['suggestion'] as Map<String, dynamic>)
          : null,
      isLoading: json['isLoading'] as bool? ?? false,
      options: options,
      interactionType: json['interactionType'] as String?,
    );
  }

  @override
  String toString() {
    return 'LLMChatMessage(id: $id, type: ${type.name}, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LLMChatMessage &&
        other.id == id &&
        other.content == content &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        content.hashCode ^
        type.hashCode ^
        timestamp.hashCode ^
        isLoading.hashCode;
  }
}

