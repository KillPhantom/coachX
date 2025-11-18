import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/user_cache_service.dart';
import 'package:coach_x/core/services/video_cache_service.dart';
import 'package:coach_x/core/services/video_downloader.dart';

/// 缓存有效性Provider
///
/// 提供当前缓存是否有效的状态
final cacheValidityProvider = Provider<bool>((ref) {
  return UserCacheService.isValid();
});

/// 缓存的用户角色Provider
///
/// 提供缓存中的用户角色（coach/student）
final cachedUserRoleProvider = Provider<String?>((ref) {
  return UserCacheService.getCachedRole();
});

/// 缓存的用户IDProvider
///
/// 提供缓存中的用户ID
final cachedUserIdProvider = Provider<String?>((ref) {
  return UserCacheService.getCachedUserId();
});

/// 视频缓存服务Provider
///
/// 提供视频缓存管理服务的单例
final videoCacheServiceProvider = Provider<VideoCacheService>((ref) {
  return VideoCacheService();
});

/// 视频下载服务Provider
///
/// 提供视频下载服务，并注入视频缓存服务
final videoDownloaderProvider = Provider<VideoDownloader>((ref) {
  final cacheService = ref.watch(videoCacheServiceProvider);
  return VideoDownloader(cacheService: cacheService);
});
