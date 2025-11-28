import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_template_model.dart';
import '../models/exercise_tag_model.dart';

/// Exercise Library Repository Interface
///
/// 动作库数据仓储接口
abstract class ExerciseLibraryRepository {
  /// 获取教练的动作模板（支持分页）
  ///
  /// [coachId] 教练ID
  /// [limit] 每页数量（默认50）
  /// [startAfter] 分页游标（上一批最后一个文档）
  Future<List<ExerciseTemplateModel>> getTemplates(
    String coachId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  });

  /// 创建动作模板
  ///
  /// Returns: 新创建的模板 ID
  Future<String> createTemplate(ExerciseTemplateModel template);

  /// 快捷创建动作模板（仅名称 + 默认标签）
  ///
  /// 用于在创建训练计划时快速创建新动作
  /// [coachId] 教练ID
  /// [name] 动作名称
  /// Returns: 新创建的模板 ID
  Future<String> quickCreateTemplate(String coachId, String name);

  /// 批量创建动作模板
  ///
  /// [exerciseNames] 动作名称列表
  ///
  /// Returns: Map<exerciseName, templateId>
  Future<Map<String, String>> batchCreateTemplates(List<String> exerciseNames);

  /// 更新动作模板
  Future<void> updateTemplate(String id, Map<String, dynamic> data);

  /// 删除动作模板
  ///
  /// 同时清除所有训练计划中对该模板的引用
  Future<void> deleteTemplate(String id, String coachId);

  /// 获取教练的所有标签
  Future<List<ExerciseTagModel>> getTags(String coachId);

  /// 创建标签
  ///
  /// Returns: 新创建的标签 ID
  Future<String> createTag(String coachId, String name);

  /// 删除标签
  Future<void> deleteTag(String coachId, String tagId);

  /// 上传动作库视频
  ///
  /// [onProgress] 上传进度回调 (0.0 - 1.0)
  /// Returns: 视频下载 URL
  Future<String> uploadExerciseVideo(
    File file, {
    Function(double progress)? onProgress,
  });

  /// 上传动作库图片
  ///
  /// Returns: 图片下载 URL
  Future<String> uploadExerciseImage(File file);

  /// 上传视频缩略图
  ///
  /// Returns: 缩略图下载 URL
  Future<String> uploadExerciseThumbnail(File file);
}
