import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/exercise_library_state.dart';
import '../../data/models/exercise_template_model.dart';
import '../../data/models/exercise_tag_model.dart';
import '../../data/repositories/exercise_library_repository.dart';
import '../../../../../core/utils/logger.dart';

/// Exercise Library Notifier - 动作库状态管理
class ExerciseLibraryNotifier extends StateNotifier<ExerciseLibraryState> {
  final ExerciseLibraryRepository _repository;
  final String _coachId;

  /// 分页游标（最后一个文档）
  DocumentSnapshot? _lastDocument;

  ExerciseLibraryNotifier(this._repository, this._coachId)
    : super(ExerciseLibraryState.initial());

  /// 从缓存/Firestore 加载数据
  Future<void> loadData() async {
    try {
      state = state.copyWith(loadingStatus: LoadingStatus.loading);

      // 1. 尝试从 Hive 读取缓存
      final templatesBox = await _openTemplatesBox();
      final tagsBox = await _openTagsBox();

      final cachedTemplates = templatesBox.get('templates') as List<dynamic>?;
      final cachedTags = tagsBox.get('tags') as List<dynamic>?;
      final lastSyncTime = templatesBox.get('lastSyncTime') as DateTime?;

      // 2. 如果有缓存，立即显示
      if (cachedTemplates != null && cachedTags != null) {
        state = state.copyWith(
          templates: cachedTemplates.cast<ExerciseTemplateModel>(),
          tags: cachedTags.cast<ExerciseTagModel>(),
          lastSyncTime: lastSyncTime,
          loadingStatus: LoadingStatus.success,
        );

        AppLogger.info('从缓存加载动作库数据');

        // 3. 检查缓存是否过期
        if (!state.isCacheExpired) {
          return; // 缓存未过期，直接返回
        }
      }

      // 4. 缓存过期或不存在，从 Firestore 同步
      await _syncFromFirestore(templatesBox, tagsBox);

      // 5. 检查标签是否为空，创建预设标签
      if (state.tags.isEmpty) {
        await ensureDefaultTags();
      }
    } catch (e, stackTrace) {
      AppLogger.error('加载动作库数据失败', e, stackTrace);
      state = state.copyWith(
        loadingStatus: LoadingStatus.error,
        error: e.toString(),
      );
    }
  }

  /// 强制刷新数据
  Future<void> refreshData() async {
    try {
      state = state.copyWith(loadingStatus: LoadingStatus.refreshing);

      final templatesBox = await _openTemplatesBox();
      final tagsBox = await _openTagsBox();

      await _syncFromFirestore(templatesBox, tagsBox);

      AppLogger.info('强制刷新动作库数据成功');
    } catch (e, stackTrace) {
      AppLogger.error('刷新动作库数据失败', e, stackTrace);
      state = state.copyWith(
        loadingStatus: LoadingStatus.error,
        error: e.toString(),
      );
    }
  }

  /// 从 Firestore 同步数据（首次加载，仅缓存第一页）
  Future<void> _syncFromFirestore(Box templatesBox, Box tagsBox) async {
    // 首次加载：limit 50，从头开始
    final querySnapshot = await FirebaseFirestore.instance
        .collection('exerciseTemplates')
        .where('ownerId', isEqualTo: _coachId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();

    final templates = querySnapshot.docs
        .map((doc) => ExerciseTemplateModel.fromFirestore(doc))
        .toList();

    // 保存分页游标
    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
    }

    final tags = await _repository.getTags(_coachId);

    final now = DateTime.now();

    // 仅缓存第一页（50个）
    await templatesBox.put('templates', templates);
    await templatesBox.put('lastSyncTime', now);
    await tagsBox.put('tags', tags);
    await tagsBox.put('lastSyncTime', now);

    state = state.copyWith(
      templates: templates,
      tags: tags,
      lastSyncTime: now,
      loadingStatus: LoadingStatus.success,
      hasMoreData: templates.length >= 50, // 如果返回50个，可能还有更多
    );

    AppLogger.info('从 Firestore 同步动作库数据成功: ${templates.length} 个');
  }

  /// 创建动作模板
  Future<void> createTemplate(ExerciseTemplateModel template) async {
    try {
      final id = await _repository.createTemplate(template);
      final newTemplate = template.copyWith(id: id);

      // 更新状态
      state = state.copyWith(templates: [newTemplate, ...state.templates]);

      // 更新缓存
      await _updateTemplatesCache();

      AppLogger.info('创建动作模板成功: ${newTemplate.name}');
    } catch (e, stackTrace) {
      AppLogger.error('创建动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  /// 更新动作模板
  Future<void> updateTemplate(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateTemplate(id, data);

      // 查找并更新本地状态
      final index = state.templates.indexWhere((t) => t.id == id);
      if (index != -1) {
        final oldTemplate = state.templates[index];
        final updatedTemplate = oldTemplate.copyWith(
          name: data['name'] ?? oldTemplate.name,
          tags: data['tags'] ?? oldTemplate.tags,
          videoUrls: data['videoUrls'] ?? oldTemplate.videoUrls,
          thumbnailUrls: data['thumbnailUrls'] ?? oldTemplate.thumbnailUrls,
          textGuidance: data['textGuidance'] ?? oldTemplate.textGuidance,
          imageUrls: data['imageUrls'] ?? oldTemplate.imageUrls,
          updatedAt: DateTime.now(),
        );

        final newTemplates = [...state.templates];
        newTemplates[index] = updatedTemplate;

        state = state.copyWith(templates: newTemplates);
        await _updateTemplatesCache();
      }

      AppLogger.info('更新动作模板成功: $id');
    } catch (e, stackTrace) {
      AppLogger.error('更新动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  /// 删除动作模板
  Future<void> deleteTemplate(String id) async {
    try {
      await _repository.deleteTemplate(id, _coachId);

      // 更新状态
      state = state.copyWith(
        templates: state.templates.where((t) => t.id != id).toList(),
      );

      // 更新缓存
      await _updateTemplatesCache();

      AppLogger.info('删除动作模板成功: $id');
    } catch (e, stackTrace) {
      AppLogger.error('删除动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  /// 搜索动作
  void searchTemplates(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 切换标签筛选
  void toggleTagFilter(String tag) {
    final currentTags = [...state.selectedTags];
    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      currentTags.add(tag);
    }
    state = state.copyWith(selectedTags: currentTags);
  }

  /// 创建标签
  Future<void> createTag(String name) async {
    try {
      final id = await _repository.createTag(_coachId, name);
      final newTag = ExerciseTagModel(
        id: id,
        name: name,
        createdAt: DateTime.now(),
      );

      // 更新状态
      state = state.copyWith(tags: [...state.tags, newTag]);

      // 更新缓存
      await _updateTagsCache();

      AppLogger.info('创建标签成功: $name');
    } catch (e, stackTrace) {
      AppLogger.error('创建标签失败', e, stackTrace);
      rethrow;
    }
  }

  /// 删除标签
  Future<void> deleteTag(String id) async {
    try {
      await _repository.deleteTag(_coachId, id);

      // 更新状态
      state = state.copyWith(
        tags: state.tags.where((t) => t.id != id).toList(),
      );

      // 更新缓存
      await _updateTagsCache();

      AppLogger.info('删除标签成功: $id');
    } catch (e, stackTrace) {
      AppLogger.error('删除标签失败', e, stackTrace);
      rethrow;
    }
  }

  /// 确保预设标签存在
  Future<void> ensureDefaultTags() async {
    try {
      // 预设标签
      final defaultTags = ['Strength', 'Cardio'];

      for (final tagName in defaultTags) {
        // 检查是否已存在
        if (!state.tags.any((t) => t.name == tagName)) {
          await createTag(tagName);
        }
      }

      AppLogger.info('预设标签初始化完成');
    } catch (e, stackTrace) {
      AppLogger.error('创建预设标签失败', e, stackTrace);
    }
  }

  /// 上传视频
  Future<String> uploadVideo(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    try {
      return await _repository.uploadExerciseVideo(
        file,
        onProgress: onProgress,
      );
    } catch (e, stackTrace) {
      AppLogger.error('上传视频失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传图片
  Future<String> uploadImage(File file) async {
    try {
      return await _repository.uploadExerciseImage(file);
    } catch (e, stackTrace) {
      AppLogger.error('上传图片失败', e, stackTrace);
      rethrow;
    }
  }

  /// 上传视频缩略图
  Future<String> uploadThumbnail(File file) async {
    try {
      return await _repository.uploadExerciseThumbnail(file);
    } catch (e, stackTrace) {
      AppLogger.error('上传缩略图失败', e, stackTrace);
      rethrow;
    }
  }

  /// 加载更多数据（分页）
  Future<void> loadMore() async {
    // 防止重复加载
    if (state.isLoadingMore || !state.hasMoreData) return;

    try {
      state = state.copyWith(isLoadingMore: true);

      final querySnapshot = await FirebaseFirestore.instance
          .collection('exerciseTemplates')
          .where('ownerId', isEqualTo: _coachId)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(50)
          .get();

      final moreTemplates = querySnapshot.docs
          .map((doc) => ExerciseTemplateModel.fromFirestore(doc))
          .toList();

      // 更新分页游标
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      state = state.copyWith(
        templates: [...state.templates, ...moreTemplates],
        isLoadingMore: false,
        hasMoreData: moreTemplates.length >= 50, // 是否还有下一页
      );

      AppLogger.info('加载更多动作: ${moreTemplates.length} 个');
    } catch (e, stackTrace) {
      AppLogger.error('加载更多失败', e, stackTrace);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// 打开模板缓存 Box
  Future<Box> _openTemplatesBox() async {
    final boxName = 'exerciseTemplates_$_coachId';
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// 打开标签缓存 Box
  Future<Box> _openTagsBox() async {
    final boxName = 'exerciseTags_$_coachId';
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  /// 更新模板缓存
  Future<void> _updateTemplatesCache() async {
    final box = await _openTemplatesBox();
    await box.put('templates', state.templates);
    await box.put('lastSyncTime', DateTime.now());
  }

  /// 更新标签缓存
  Future<void> _updateTagsCache() async {
    final box = await _openTagsBox();
    await box.put('tags', state.tags);
    await box.put('lastSyncTime', DateTime.now());
  }
}
