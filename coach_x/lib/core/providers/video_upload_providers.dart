import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/video_upload_service.dart';
import 'package:coach_x/core/services/video_upload_service_impl.dart';

/// 视频上传服务 Provider
final videoUploadServiceProvider = Provider<VideoUploadService>((ref) {
  return VideoUploadServiceImpl();
});
