import 'package:hive/hive.dart';

part 'video_cache_metadata.g.dart';

/// 视频缓存元数据模型
///
/// 用于记录视频缓存的时间信息和路径，判断缓存是否有效
@HiveType(typeId: 36)
class VideoCacheMetadata {
  /// 视频 URL
  @HiveField(0)
  final String videoUrl;

  /// 本地文件路径
  @HiveField(1)
  final String localPath;

  /// 训练记录 ID
  @HiveField(2)
  final String trainingId;

  /// 文件大小（字节）
  @HiveField(3)
  final int fileSize;

  /// 缓存时间
  @HiveField(4)
  final DateTime cachedAt;

  /// 过期时间
  @HiveField(5)
  final DateTime expiresAt;

  VideoCacheMetadata({
    required this.videoUrl,
    required this.localPath,
    required this.trainingId,
    required this.fileSize,
    required this.cachedAt,
    required this.expiresAt,
  });

  /// 检查缓存是否有效（未过期）
  bool isValid() {
    return DateTime.now().isBefore(expiresAt);
  }

  /// 创建视频缓存元数据
  ///
  /// [videoUrl] 视频 URL
  /// [localPath] 本地文件路径
  /// [trainingId] 训练记录 ID
  /// [fileSize] 文件大小（字节）
  /// [validity] 有效期（从现在开始计算，默认1小时）
  factory VideoCacheMetadata.create({
    required String videoUrl,
    required String localPath,
    required String trainingId,
    required int fileSize,
    Duration validity = const Duration(hours: 1),
  }) {
    final now = DateTime.now();
    return VideoCacheMetadata(
      videoUrl: videoUrl,
      localPath: localPath,
      trainingId: trainingId,
      fileSize: fileSize,
      cachedAt: now,
      expiresAt: now.add(validity),
    );
  }

  @override
  String toString() {
    return 'VideoCacheMetadata(trainingId: $trainingId, localPath: $localPath, cachedAt: $cachedAt, expiresAt: $expiresAt, isValid: ${isValid()})';
  }
}
