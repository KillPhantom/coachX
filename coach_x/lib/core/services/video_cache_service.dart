import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coach_x/core/models/video_cache_metadata.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 视频缓存服务
///
/// 管理视频文件的缓存元数据，提供缓存查询、保存、清理功能
class VideoCacheService {
  static const String _boxName = 'video_cache';

  // 单例模式
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  Box<VideoCacheMetadata>? _box;

  /// 初始化视频缓存
  ///
  /// 打开 Hive Box 用于存储视频缓存元数据
  Future<void> initializeCache() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box<VideoCacheMetadata>(_boxName);
        AppLogger.info('✅ 视频缓存 Box 已打开');
      } else {
        _box = await Hive.openBox<VideoCacheMetadata>(_boxName);
        AppLogger.info('✅ 视频缓存初始化成功');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 视频缓存初始化失败', e, stackTrace);
      rethrow;
    }
  }

  /// 获取缓存的视频路径
  ///
  /// [videoUrl] 视频 URL
  /// [trainingId] 训练记录 ID
  ///
  /// 返回本地视频路径（如果缓存有效），否则返回 null
  Future<String?> getCachedVideoPath(String videoUrl, String trainingId) async {
    try {
      if (_box == null) {
        AppLogger.warning('视频缓存 Box 未初始化');
        return null;
      }

      // 使用 trainingId 作为 key
      final metadata = _box!.get(trainingId);

      if (metadata == null) {
        AppLogger.debug('缓存未命中: $trainingId');
        return null;
      }

      // 检查缓存是否过期
      if (!metadata.isValid()) {
        AppLogger.debug('⏰ 缓存过期: $trainingId');
        // 删除过期的元数据
        await _box!.delete(trainingId);
        return null;
      }

      // 验证文件是否真实存在
      final file = File(metadata.localPath);
      if (!await file.exists()) {
        AppLogger.warning('缓存文件已被删除: ${metadata.localPath}');
        // 删除无效的元数据
        await _box!.delete(trainingId);
        return null;
      }

      AppLogger.info('✅ 缓存命中: $trainingId');
      return metadata.localPath;
    } catch (e, stackTrace) {
      AppLogger.error('获取缓存路径失败', e, stackTrace);
      return null;
    }
  }

  /// 保存缓存元数据
  ///
  /// [metadata] 视频缓存元数据
  Future<void> saveCacheMetadata(VideoCacheMetadata metadata) async {
    try {
      if (_box == null) {
        AppLogger.warning('视频缓存 Box 未初始化');
        return;
      }

      // 使用 trainingId 作为 key
      await _box!.put(metadata.trainingId, metadata);
      AppLogger.debug('缓存元数据已保存: ${metadata.trainingId}');
    } catch (e, stackTrace) {
      AppLogger.error('保存缓存元数据失败', e, stackTrace);
    }
  }

  /// 清理过期缓存
  ///
  /// 删除所有过期的缓存元数据和对应的视频文件
  Future<void> clearExpiredCache() async {
    try {
      if (_box == null) {
        AppLogger.warning('视频缓存 Box 未初始化');
        return;
      }

      final now = DateTime.now();
      final keysToDelete = <String>[];
      int deletedFiles = 0;

      // 遍历所有缓存元数据
      for (final key in _box!.keys) {
        final metadata = _box!.get(key);
        if (metadata != null && now.isAfter(metadata.expiresAt)) {
          // 过期了，标记删除
          keysToDelete.add(key as String);

          // 删除对应的视频文件
          try {
            final file = File(metadata.localPath);
            if (await file.exists()) {
              await file.delete();
              deletedFiles++;
            }
          } catch (e) {
            AppLogger.warning('删除视频文件失败: ${metadata.localPath}');
          }
        }
      }

      // 删除过期的元数据
      if (keysToDelete.isNotEmpty) {
        await _box!.deleteAll(keysToDelete);
        AppLogger.info(
          '🗑️ 清除过期缓存: ${keysToDelete.length} 条元数据，$deletedFiles 个文件',
        );
      } else {
        AppLogger.debug('无过期缓存需要清理');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除过期缓存失败', e, stackTrace);
    }
  }

  /// 清理所有视频缓存
  ///
  /// 删除所有缓存元数据和视频文件（用于下拉刷新或登出）
  Future<void> clearAllVideoCache() async {
    try {
      if (_box == null) {
        AppLogger.warning('视频缓存 Box 未初始化');
        return;
      }

      int deletedFiles = 0;

      // 删除所有视频文件
      for (final key in _box!.keys) {
        final metadata = _box!.get(key);
        if (metadata != null) {
          try {
            final file = File(metadata.localPath);
            if (await file.exists()) {
              await file.delete();
              deletedFiles++;
            }
          } catch (e) {
            AppLogger.warning('删除视频文件失败: ${metadata.localPath}');
          }
        }
      }

      // 清空所有元数据
      await _box!.clear();
      AppLogger.info('🗑️ 清除所有视频缓存: $deletedFiles 个文件');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除所有视频缓存失败', e, stackTrace);
    }
  }

  /// 删除特定训练的缓存
  ///
  /// [trainingId] 训练记录 ID
  Future<void> deleteCacheForTraining(String trainingId) async {
    try {
      if (_box == null) {
        AppLogger.warning('视频缓存 Box 未初始化');
        return;
      }

      final metadata = _box!.get(trainingId);
      if (metadata != null) {
        // 删除视频文件
        try {
          final file = File(metadata.localPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          AppLogger.warning('删除视频文件失败: ${metadata.localPath}');
        }

        // 删除元数据
        await _box!.delete(trainingId);
        AppLogger.debug('已删除训练缓存: $trainingId');
      }
    } catch (e, stackTrace) {
      AppLogger.error('删除训练缓存失败', e, stackTrace);
    }
  }

  /// 获取缓存总大小（字节）
  ///
  /// 返回所有缓存视频的总大小
  Future<int> getCacheSize() async {
    try {
      if (_box == null) {
        AppLogger.warning('视频缓存 Box 未初始化');
        return 0;
      }

      int totalSize = 0;

      for (final key in _box!.keys) {
        final metadata = _box!.get(key);
        if (metadata != null) {
          totalSize += metadata.fileSize;
        }
      }

      return totalSize;
    } catch (e, stackTrace) {
      AppLogger.error('获取缓存大小失败', e, stackTrace);
      return 0;
    }
  }

  /// 关闭缓存 Box
  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
        AppLogger.info('📦 视频缓存 Box 已关闭');
      }
    } catch (e, stackTrace) {
      AppLogger.error('关闭视频缓存 Box 失败', e, stackTrace);
    }
  }
}
