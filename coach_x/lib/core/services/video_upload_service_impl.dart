import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/services/video_upload_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 视频上传服务实现
///
/// 使用 Firebase Storage 上传视频和缩略图
class VideoUploadServiceImpl implements VideoUploadService {
  @override
  Stream<double> uploadVideoWithProgress(File videoFile, String path) {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref(path);
    final uploadTask = ref.putFile(videoFile);

    return uploadTask.snapshotEvents.map((snapshot) {
      if (snapshot.state == TaskState.running) {
        // 安全检查：避免除以0导致 NaN 或 Infinity
        if (snapshot.totalBytes == 0) {
          return 0.0;
        }
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        // 确保进度在 0.0 到 1.0 之间
        return progress.clamp(0.0, 1.0);
      } else if (snapshot.state == TaskState.success) {
        // 上传成功，返回 100%
        return 1.0;
      } else if (snapshot.state == TaskState.paused) {
        // 暂停时保持当前进度
        if (snapshot.totalBytes == 0) {
          return 0.0;
        }
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        return progress.clamp(0.0, 1.0);
      }
      // 其他状态（canceled, error）返回 0.0
      return 0.0;
    });
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref(path);
    return await ref.getDownloadURL();
  }

  @override
  Future<String> uploadThumbnail(File thumbnailFile, String path) async {
    try {
      AppLogger.info('上传视频缩略图: $path');

      final downloadUrl = await StorageService.uploadFile(thumbnailFile, path);

      AppLogger.info('上传视频缩略图成功: $downloadUrl');

      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传视频缩略图失败', e, stackTrace);
      rethrow;
    }
  }
}
