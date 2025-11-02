import 'package:coach_x/features/coach/plans/data/models/plan_edit_suggestion.dart';

/// 编辑流式事件模型
class EditStreamEvent {
  final String type;
  final String? content;
  final Map<String, dynamic>? data;
  final String? error;

  const EditStreamEvent({
    required this.type,
    this.content,
    this.data,
    this.error,
  });

  /// 是否是思考事件
  bool get isThinking => type == 'thinking';

  /// 是否是分析事件
  bool get isAnalysis => type == 'analysis';

  /// 是否是修改建议事件
  bool get isSuggestion => type == 'suggestion';

  /// 是否是完成事件
  bool get isComplete => type == 'complete';

  /// 是否是错误事件
  bool get isError => type == 'error';

  /// 获取修改建议数据
  PlanEditSuggestion? get suggestion {
    if (!isSuggestion || data == null) return null;
    
    try {
      // 提取 changes 和 summary
      final changes = data!['changes'] as List<dynamic>?;
      final summary = data!['summary'] as String?;
      
      if (changes == null || summary == null) return null;
      
      return null; // 在 Notifier 中组合两个事件的数据
    } catch (e) {
      return null;
    }
  }

  /// 从 JSON 创建
  factory EditStreamEvent.fromJson(Map<String, dynamic> json) {
    // 🆕 处理两种数据格式：
    // 1. 标准格式: {type: 'suggestion', data: {changes, ...}}
    // 2. 非标准格式: {type: 'complete', changes: [...], analysis: '...', ...}

    Map<String, dynamic>? data = json['data'] as Map<String, dynamic>?;

    // 如果没有 data 字段，但包含 changes 或 analysis 字段，
    // 说明数据直接在顶层，需要提取到 data 中
    if (data == null &&
        (json.containsKey('changes') ||
         json.containsKey('analysis') ||
         json.containsKey('summary'))) {
      // 将顶层的修改相关字段提取到 data 中
      data = Map<String, dynamic>.from(json)..remove('type')..remove('content')..remove('error');
    }

    return EditStreamEvent(
      type: json['type'] as String,
      content: json['content'] as String?,
      data: data,
      error: json['error'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (content != null) 'content': content,
      if (data != null) 'data': data,
      if (error != null) 'error': error,
    };
  }

  @override
  String toString() {
    if (error != null) {
      return 'EditStreamEvent(type: $type, error: $error)';
    }
    if (content != null) {
      return 'EditStreamEvent(type: $type, content: ${content!.substring(0, content!.length > 30 ? 30 : content!.length)}...)';
    }
    return 'EditStreamEvent(type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditStreamEvent &&
        other.type == type &&
        other.content == content &&
        other.error == error;
  }

  @override
  int get hashCode {
    return type.hashCode ^ content.hashCode ^ error.hashCode;
  }
}

