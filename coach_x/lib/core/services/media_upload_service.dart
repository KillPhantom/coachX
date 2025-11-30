import 'dart:io';

/// 媒体上传服务接口
///
/// 提供媒体（视频、图片）上传功能，支持进度监听
abstract class MediaUploadService {
  /// 上传文件到 Firebase Storage（带进度）
  ///
  /// [file] - 文件
  /// [path] - 存储路径
  /// [contentType] - 文件类型 (e.g. 'video/mp4', 'image/jpeg')
  /// 返回: 上传进度流 (0.0 - 1.0)
  Stream<double> uploadFileWithProgress(File file, String path, {String? contentType});

  /// 获取 Firebase Storage 文件的下载 URL
  ///
  /// [path] - 存储路径
  /// 返回: 下载 URL
  Future<String> getDownloadUrl(String path);

  /// 上传缩略图到 Firebase Storage (便捷方法)
  ///
  /// [thumbnailFile] - 缩略图文件
  /// [path] - 存储路径
  /// 返回: 下载 URL
  Future<String> uploadThumbnail(File thumbnailFile, String path);
}

