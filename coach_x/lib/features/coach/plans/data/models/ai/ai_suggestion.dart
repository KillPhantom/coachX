import '../../../../../../core/enums/ai_status.dart';

/// AI 建议数据模型
class AISuggestion {
  final String id;
  final AISuggestionType type;
  final String title;
  final String content;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const AISuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.data,
    required this.createdAt,
  });

  /// 从 JSON 创建
  factory AISuggestion.fromJson(Map<String, dynamic> json) {
    return AISuggestion(
      id: json['id'] as String? ?? '',
      type: aiSuggestionTypeFromString(json['type'] as String? ?? 'full_plan'),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJsonString(),
      'title': title,
      'content': content,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改部分字段
  AISuggestion copyWith({
    String? id,
    AISuggestionType? type,
    String? title,
    String? content,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return AISuggestion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AISuggestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AISuggestion(id: $id, type: $type, title: $title)';
  }
}


