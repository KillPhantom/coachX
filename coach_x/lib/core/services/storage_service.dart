import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/core/constants/media_compression_config.dart';

/// Firebase Storage服务
///
/// 封装文件上传、下载和管理功能
class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// 上传文件到Storage
  ///
  /// [file] 要上传的文件
  /// [path] Storage中的路径
  /// [metadata] 自定义元数据
  /// [onProgress] 上传进度回调
  /// 返回文件的下载URL
  static Future<String> uploadFile({
    required File file,
    required String storagePath,
    Map<String, String>? metadata,
    Function(double)? onProgress,
  }) async {
    try {
      AppLogger.info('开始上传文件: $storagePath');

      final ref = _storage.ref().child(storagePath);
      final settableMetadata =
          metadata != null ? SettableMetadata(customMetadata: metadata) : null;

      final uploadTask = ref.putFile(file, settableMetadata);

      // 监听上传进度
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // 等待上传完成
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('文件上传成功: $storagePath');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('文件上传失败: $storagePath', e, stackTrace);
      rethrow;
    }
  }

  /// 上传数据到Storage
  ///
  /// [data] 要上传的二进制数据
  /// [storagePath] Storage中的路径
  /// [metadata] 自定义元数据
  /// [onProgress] 上传进度回调
  /// 返回文件的下载URL
  static Future<String> uploadData({
    required Uint8List data,
    required String storagePath,
    Map<String, String>? metadata,
    Function(double)? onProgress,
  }) async {
    try {
      AppLogger.info('开始上传数据: $storagePath');

      final ref = _storage.ref().child(storagePath);
      final settableMetadata =
          metadata != null ? SettableMetadata(customMetadata: metadata) : null;

      final uploadTask = ref.putData(data, settableMetadata);

      // 监听上传进度
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // 等待上传完成
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('数据上传成功: $storagePath');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('数据上传失败: $storagePath', e, stackTrace);
      rethrow;
    }
  }

  /// 上传文件到Storage（带重试和超时检测）
  ///
  /// [file] 要上传的文件
  /// [path] Storage中的路径
  /// [onProgress] 上传进度回调
  /// [maxRetries] 最大重试次数，默认使用配置值
  /// 返回文件的下载URL
  static Future<String> uploadFileWithRetry(
    File file,
    String path, {
    Function(double)? onProgress,
    int? maxRetries,
  }) async {
    final retries = maxRetries ?? MediaCompressionConfig.maxUploadRetries;
    int attempt = 0;
    Exception? lastException;

    while (attempt < retries) {
      try {
        attempt++;
        AppLogger.info('上传文件 (尝试 $attempt/$retries): $path');

        return await _uploadWithProgressMonitoring(
          file,
          path,
          onProgress: onProgress,
        );
      } on TimeoutException catch (e) {
        lastException = e;
        AppLogger.warning('⚠️ 上传超时，准备重试 (尝试 $attempt/$retries)');

        if (attempt >= retries) {
          AppLogger.error('❌ 上传失败，已达最大重试次数', e);
          rethrow;
        }

        // 指数退避：等待 2^(attempt-1) 秒
        final delaySeconds =
            MediaCompressionConfig.retryDelayBase << (attempt - 1);
        await Future.delayed(Duration(seconds: delaySeconds));
      } catch (e, stackTrace) {
        AppLogger.error(
          '文件上传失败: $path (尝试 $attempt/$retries)',
          e,
          stackTrace,
        );

        if (attempt >= retries) {
          rethrow;
        }

        lastException = e as Exception;
        final delaySeconds =
            MediaCompressionConfig.retryDelayBase << (attempt - 1);
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    throw lastException ?? Exception('Upload failed after $retries attempts');
  }

  /// 上传文件并监控进度停滞（私有方法）
  static Future<String> _uploadWithProgressMonitoring(
    File file,
    String path, {
    Function(double)? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);

    double lastProgress = 0;
    DateTime lastProgressTime = DateTime.now();
    Timer? progressTimer;
    StreamSubscription? progressSubscription;

    try {
      // 监听进度
      progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes == 0) {
          return;
        }

        final progress = snapshot.bytesTransferred / snapshot.totalBytes;

        // 只有进度增加时才更新
        if (progress > lastProgress) {
          lastProgress = progress;
          lastProgressTime = DateTime.now();
          onProgress?.call(progress);
        }
      });

      // 启动进度停滞检测定时器
      progressTimer = Timer.periodic(
        MediaCompressionConfig.progressStaleTimeout,
        (timer) {
          final timeSinceLastProgress =
              DateTime.now().difference(lastProgressTime);

          if (timeSinceLastProgress >=
              MediaCompressionConfig.progressStaleTimeout) {
            AppLogger.warning(
              '⚠️ 进度停滞超过 ${MediaCompressionConfig.progressStaleTimeout.inSeconds}s，取消上传',
            );
            timer.cancel();
            uploadTask.cancel();
            throw TimeoutException('Upload progress stalled');
          }
        },
      );

      // 等待上传完成（带总超时）
      final snapshot = await uploadTask.timeout(
        MediaCompressionConfig.uploadTimeout,
        onTimeout: () {
          AppLogger.warning('⚠️ 上传总超时，取消任务');
          uploadTask.cancel();
          throw TimeoutException('Upload timeout');
        },
      );

      progressTimer.cancel();
      await progressSubscription.cancel();

      final downloadUrl = await snapshot.ref.getDownloadURL();
      AppLogger.info('✅ 文件上传成功: $path');

      return downloadUrl;
    } catch (e) {
      progressTimer?.cancel();
      await progressSubscription?.cancel();
      rethrow;
    }
  }

  /// 上传图片（从相机或相册选择）
  static Future<String?> uploadImage({
    required ImageSource source,
    required String folder,
    Function(double)? onProgress,
  }) async {
    try {
      // 选择图片
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        AppLogger.info('用户取消选择图片');
        return null;
      }

      final file = File(pickedFile.path);

      // 生成文件路径
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = pickedFile.path.split('.').last;
      final path = '$folder/$userId/$timestamp.$extension';

      // 上传文件
      return await uploadFile(file: file, storagePath: path, onProgress: onProgress);
    } catch (e, stackTrace) {
      AppLogger.error('上传图片失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传头像
  static Future<String?> uploadAvatar({
    required ImageSource source,
    Function(double)? onProgress,
  }) async {
    return uploadImage(
      source: source,
      folder: 'avatars',
      onProgress: onProgress,
    );
  }

  /// 上传训练图片
  static Future<String?> uploadTrainingImage({
    required ImageSource source,
    Function(double)? onProgress,
  }) async {
    return uploadImage(
      source: source,
      folder: 'training_images',
      onProgress: onProgress,
    );
  }

  /// 上传饮食图片
  static Future<String?> uploadDietImage({
    required ImageSource source,
    Function(double)? onProgress,
  }) async {
    return uploadImage(
      source: source,
      folder: 'diet_images',
      onProgress: onProgress,
    );
  }

  /// 上传训练计划图片
  static Future<String?> uploadTrainingPlanImage({
    required ImageSource source,
    Function(double)? onProgress,
  }) async {
    return uploadImage(
      source: source,
      folder: 'training_plan_images',
      onProgress: onProgress,
    );
  }

  /// 上传训练计划文件（通用）
  static Future<String> uploadTrainingPlanFile({
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final path = 'training_plan_images/$userId/$timestamp.$extension';

      return await uploadFile(file: file, storagePath: path, onProgress: onProgress);
    } catch (e, stackTrace) {
      AppLogger.error('上传训练计划文件失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传补剂计划文件
  static Future<String> uploadSupplementPlanFile({
    required File file,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final path = 'supplement_plan_images/$userId/$timestamp.$extension';

      return await uploadFile(file: file, storagePath: path, onProgress: onProgress);
    } catch (e, stackTrace) {
      AppLogger.error('上传补剂计划文件失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传身体测量图片
  static Future<String?> uploadBodyStatsImage({
    required ImageSource source,
    Function(double)? onProgress,
  }) async {
    return uploadImage(
      source: source,
      folder: 'body_stats',
      onProgress: onProgress,
    );
  }

  /// 上传聊天图片
  static Future<String> uploadChatImage({
    required File file,
    required String conversationId,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final randomId = DateTime.now().microsecondsSinceEpoch.toString();
      final path =
          'chat_images/$userId/$conversationId/${timestamp}_$randomId.$extension';

      return await uploadFile(file: file, storagePath: path, onProgress: onProgress);
    } catch (e, stackTrace) {
      AppLogger.error('上传聊天图片失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传聊天视频
  static Future<String> uploadChatVideo({
    required File file,
    required String conversationId,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final randomId = DateTime.now().microsecondsSinceEpoch.toString();
      final path =
          'chat_videos/$userId/$conversationId/${timestamp}_$randomId.$extension';

      return await uploadFile(file: file, storagePath: path, onProgress: onProgress);
    } catch (e, stackTrace) {
      AppLogger.error('上传聊天视频失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传聊天语音
  static Future<String> uploadChatVoice({
    required File file,
    required String conversationId,
    Function(double)? onProgress,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final randomId = DateTime.now().microsecondsSinceEpoch.toString();
      final path =
          'chat_voices/$userId/$conversationId/${timestamp}_$randomId.$extension';

      return await uploadFile(file: file, storagePath: path, onProgress: onProgress);
    } catch (e, stackTrace) {
      AppLogger.error('上传聊天语音失败', e, stackTrace);
      rethrow;
    }
  }

  /// 删除文件
  static Future<void> deleteFile(String path) async {
    try {
      AppLogger.info('删除文件: $path');
      await _storage.ref().child(path).delete();
      AppLogger.info('文件删除成功: $path');
    } catch (e, stackTrace) {
      AppLogger.error('删除文件失败: $path', e, stackTrace);
      rethrow;
    }
  }

  /// 从URL删除文件
  static Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      AppLogger.info('文件删除成功: $url');
    } catch (e, stackTrace) {
      AppLogger.error('删除文件失败: $url', e, stackTrace);
      rethrow;
    }
  }

  /// 获取文件元数据
  static Future<FullMetadata> getMetadata(String path) async {
    try {
      return await _storage.ref().child(path).getMetadata();
    } catch (e, stackTrace) {
      AppLogger.error('获取文件元数据失败: $path', e, stackTrace);
      rethrow;
    }
  }

  /// 获取下载URL
  static Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e, stackTrace) {
      AppLogger.error('获取下载URL失败: $path', e, stackTrace);
      rethrow;
    }
  }

  /// 列出文件夹中的文件
  static Future<ListResult> listFiles(String path, {int? maxResults}) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.list(ListOptions(maxResults: maxResults));
    } catch (e, stackTrace) {
      AppLogger.error('列出文件失败: $path', e, stackTrace);
      rethrow;
    }
  }
}
