import 'package:hive/hive.dart';

part 'cache_metadata.g.dart';

/// 缓存元数据模型
///
/// 用于记录缓存的时间信息，判断缓存是否有效
@HiveType(typeId: 35)
class CacheMetadata {
  /// 缓存键
  @HiveField(0)
  final String key;

  /// 缓存时间
  @HiveField(1)
  final DateTime cachedAt;

  /// 过期时间
  @HiveField(2)
  final DateTime expiresAt;

  CacheMetadata({
    required this.key,
    required this.cachedAt,
    required this.expiresAt,
  });

  /// 检查缓存是否有效（未过期）
  bool isValid() {
    return DateTime.now().isBefore(expiresAt);
  }

  /// 创建缓存元数据
  ///
  /// [key] 缓存键
  /// [validity] 有效期（从现在开始计算）
  factory CacheMetadata.create(String key, Duration validity) {
    final now = DateTime.now();
    return CacheMetadata(key: key, cachedAt: now, expiresAt: now.add(validity));
  }

  @override
  String toString() {
    return 'CacheMetadata(key: $key, cachedAt: $cachedAt, expiresAt: $expiresAt, isValid: ${isValid()})';
  }
}
