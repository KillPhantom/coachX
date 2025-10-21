import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/auth_service.dart';

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
  /// [onProgress] 上传进度回调
  /// 返回文件的下载URL
  static Future<String> uploadFile(
    File file,
    String path, {
    Function(double)? onProgress,
  }) async {
    try {
      AppLogger.info('开始上传文件: $path');

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

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

      AppLogger.info('文件上传成功: $path');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('文件上传失败: $path', e, stackTrace);
      rethrow;
    }
  }

  /// 上传图片（从相机或相册选择）
  ///
  /// [source] 图片来源（相机或相册）
  /// [folder] 存储文件夹
  /// [onProgress] 上传进度回调
  /// 返回图片的下载URL
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
      return await uploadFile(file, path, onProgress: onProgress);
    } catch (e, stackTrace) {
      AppLogger.error('上传图片失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传头像
  ///
  /// [source] 图片来源
  /// [onProgress] 上传进度回调
  /// 返回头像URL
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
  ///
  /// [source] 图片来源
  /// [onProgress] 上传进度回调
  /// 返回图片URL
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
  ///
  /// [source] 图片来源
  /// [onProgress] 上传进度回调
  /// 返回图片URL
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

  /// 上传身体测量图片
  ///
  /// [source] 图片来源
  /// [onProgress] 上传进度回调
  /// 返回图片URL
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

  /// 删除文件
  ///
  /// [path] Storage中的文件路径
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
  ///
  /// [url] 文件的下载URL
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
  ///
  /// [path] Storage中的文件路径
  /// 返回文件元数据
  static Future<FullMetadata> getMetadata(String path) async {
    try {
      return await _storage.ref().child(path).getMetadata();
    } catch (e, stackTrace) {
      AppLogger.error('获取文件元数据失败: $path', e, stackTrace);
      rethrow;
    }
  }

  /// 获取下载URL
  ///
  /// [path] Storage中的文件路径
  /// 返回下载URL
  static Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e, stackTrace) {
      AppLogger.error('获取下载URL失败: $path', e, stackTrace);
      rethrow;
    }
  }

  /// 列出文件夹中的文件
  ///
  /// [path] 文件夹路径
  /// [maxResults] 最大结果数
  /// 返回文件引用列表
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
