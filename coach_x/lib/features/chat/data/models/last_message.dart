/// 最后一条消息模型（嵌套在Conversation中）
class LastMessage {
  final String id;
  final String content;
  final String type; // 'text' | 'image' | 'video' | 'voice'
  final String senderId;
  final int timestamp;
  final String? mediaUrl;

  const LastMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.senderId,
    required this.timestamp,
    this.mediaUrl,
  });

  /// 从JSON创建
  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      senderId: json['senderId'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'content': content,
      'type': type,
      'senderId': senderId,
      'timestamp': timestamp,
    };
    if (mediaUrl != null) {
      json['mediaUrl'] = mediaUrl!;
    }
    return json;
  }

  /// 复制并修改
  LastMessage copyWith({
    String? id,
    String? content,
    String? type,
    String? senderId,
    int? timestamp,
    String? mediaUrl,
  }) {
    return LastMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      timestamp: timestamp ?? this.timestamp,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }
}
