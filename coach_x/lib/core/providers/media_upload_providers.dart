import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/media_upload_service.dart';
import 'package:coach_x/core/services/media_upload_service_impl.dart';

/// 媒体上传服务 Provider
final mediaUploadServiceProvider = Provider<MediaUploadService>((ref) {
  return MediaUploadServiceImpl();
});

