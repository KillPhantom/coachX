/// Feed Item 类型枚举
enum FeedItemType {
  /// 视频项：学生上传的训练视频
  video,

  /// 图文项：无视频的 Exercise（汇总显示）
  textCard,

  /// 完成项：所有内容已批阅完成的占位符
  completion,
}

/// FeedItemType 扩展
extension FeedItemTypeExtension on FeedItemType {
  /// 是否是内容项（排除 completion）
  bool get isContentItem =>
      this == FeedItemType.video || this == FeedItemType.textCard;

  /// 是否需要 exerciseTemplateId
  bool get requiresExerciseId =>
      this == FeedItemType.video || this == FeedItemType.textCard;
}
