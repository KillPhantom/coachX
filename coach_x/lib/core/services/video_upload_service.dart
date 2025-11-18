import 'dart:io';

/// 视频上传服务接口
///
/// 提供视频和缩略图上传功能，支持进度监听
abstract class VideoUploadService {
  /// 上传视频到 Firebase Storage（带进度）
  ///
  /// [videoFile] - 视频文件
  /// [path] - 存储路径
  /// 返回: 上传进度流 (0.0 - 1.0)
  Stream<double> uploadVideoWithProgress(File videoFile, String path);

  /// 获取 Firebase Storage 文件的下载 URL
  ///
  /// [path] - 存储路径
  /// 返回: 下载 URL
  Future<String> getDownloadUrl(String path);

  /// 上传视频缩略图到 Firebase Storage
  ///
  /// [thumbnailFile] - 缩略图文件
  /// [path] - 存储路径
  /// 返回: 下载 URL
  Future<String> uploadThumbnail(File thumbnailFile, String path);
}
