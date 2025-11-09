/// 补剂计划流式生成事件
class SupplementStreamEvent {
  final String
  type; // 'thinking' | 'analysis' | 'suggestion' | 'complete' | 'error'
  final String? content;
  final Map<String, dynamic>? data;
  final String? error;

  const SupplementStreamEvent({
    required this.type,
    this.content,
    this.data,
    this.error,
  });

  factory SupplementStreamEvent.fromJson(Map<String, dynamic> json) {
    return SupplementStreamEvent(
      type: json['type'] as String,
      content: json['content'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
    );
  }

  bool get isThinking => type == 'thinking';
  bool get isAnalysis => type == 'analysis';
  bool get isSuggestion => type == 'suggestion';
  bool get isComplete => type == 'complete';
  bool get isError => type == 'error';

  @override
  String toString() {
    return 'SupplementStreamEvent(type: $type, hasContent: ${content != null}, hasData: ${data != null})';
  }
}
