import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/media_upload_service.dart';
import 'package:coach_x/core/services/media_upload_service_impl.dart';
import 'package:coach_x/core/services/media_upload_manager.dart';

/// 媒体上传服务 Provider
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadServiceImpl();
});

/// 媒体上传管理器 Provider
final mediaUploadManagerProvider = Provider<MediaUploadManager>((ref) {
  final uploadService = ref.watch(mediaUploadServiceProvider);
  return MediaUploadManager(uploadService);
});

