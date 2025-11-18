import 'package:hive/hive.dart';
import 'package:coach_x/core/services/cache/cache_helper.dart';
import 'package:coach_x/core/services/cache/cache_metadata.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/student_list_item_model.dart';

/// 学生列表缓存服务
///
/// 负责管理学生列表的本地缓存
class StudentsCacheService {
  StudentsCacheService._();

  static const String _boxName = 'students_cache';
  static const Duration _cacheValidity = Duration(days: 7);

  /// 获取 Box
  static Future<Box> _getBox() async {
    return await CacheHelper.openBox(_boxName);
  }

  /// 生成缓存键
  ///
  /// [pageNumber] 页码
  /// [searchQuery] 搜索关键词
  /// [filterPlanId] 计划筛选ID
  static String _buildCacheKey(
    int pageNumber,
    String? searchQuery,
    String? filterPlanId,
  ) {
    final parts = ['students_page_$pageNumber'];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      parts.add('search_$searchQuery');
    }

    if (filterPlanId != null && filterPlanId.isNotEmpty) {
      parts.add('filter_$filterPlanId');
    }

    return parts.join('_');
  }

  /// 获取缓存的学生列表
  ///
  /// [pageNumber] 页码
  /// [searchQuery] 搜索关键词
  /// [filterPlanId] 计划筛选ID
  /// 返回缓存的学生列表，如果缓存无效或不存在则返回 null
  static Future<List<StudentListItemModel>?> getCachedStudents(
    int pageNumber,
    String? searchQuery,
    String? filterPlanId,
  ) async {
    try {
      final box = await _getBox();
      final key = _buildCacheKey(pageNumber, searchQuery, filterPlanId);
      final metadataKey = '${key}_metadata';

      // 检查元数据
      final metadata = box.get(metadataKey) as CacheMetadata?;
      if (!CacheHelper.isMetadataValid(metadata)) {
        AppLogger.info('❌ 学生列表缓存无效或不存在: $key');
        return null;
      }

      // 读取缓存数据
      final cachedData = box.get(key);
      if (cachedData == null) {
        AppLogger.info('❌ 学生列表缓存数据不存在: $key');
        return null;
      }

      // 转换为 List<StudentListItemModel>
      final students = (cachedData as List)
          .map((item) => item as StudentListItemModel)
          .toList();

      AppLogger.info('✅ 学生列表缓存命中: $key (${students.length} 个学生)');
      return students;
    } catch (e, stackTrace) {
      AppLogger.error('❌ 读取学生列表缓存失败', e, stackTrace);
      return null;
    }
  }

  /// 缓存学生列表
  ///
  /// [students] 学生列表
  /// [pageNumber] 页码
  /// [searchQuery] 搜索关键词
  /// [filterPlanId] 计划筛选ID
  static Future<void> cacheStudents(
    List<StudentListItemModel> students,
    int pageNumber,
    String? searchQuery,
    String? filterPlanId,
  ) async {
    try {
      final box = await _getBox();
      final key = _buildCacheKey(pageNumber, searchQuery, filterPlanId);
      final metadataKey = '${key}_metadata';

      // 创建元数据
      final metadata = CacheHelper.createMetadata(key, _cacheValidity);

      // 写入缓存
      await box.put(key, students);
      await box.put(metadataKey, metadata);

      AppLogger.info('💾 学生列表已缓存: $key (${students.length} 个学生)');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 缓存学生列表失败', e, stackTrace);
    }
  }

  /// 清除所有学生列表缓存
  static Future<void> invalidateCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      AppLogger.info('🗑️ 已清除所有学生列表缓存');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除学生列表缓存失败', e, stackTrace);
    }
  }

  /// 清除单个学生相关的缓存
  ///
  /// [studentId] 学生ID
  /// 注意：此方法会清除所有缓存，因为无法精确定位包含该学生的所有缓存键
  static Future<void> invalidateStudentCache(String studentId) async {
    try {
      // 由于缓存键包含多个参数，无法精确定位
      // 简单起见，清除所有缓存
      await invalidateCache();
      AppLogger.info('🗑️ 已清除学生 $studentId 相关的缓存（清除所有）');
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除学生缓存失败', e, stackTrace);
    }
  }

  /// 清除过期缓存
  ///
  /// 定期调用此方法以清理过期的缓存数据
  static Future<void> clearExpiredCache() async {
    try {
      final box = await _getBox();
      await CacheHelper.clearExpiredCache(box, _cacheValidity);
    } catch (e, stackTrace) {
      AppLogger.error('❌ 清除过期学生缓存失败', e, stackTrace);
    }
  }
}
