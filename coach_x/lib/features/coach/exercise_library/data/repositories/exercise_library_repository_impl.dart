import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/exercise_template_model.dart';
import '../models/exercise_tag_model.dart';
import 'exercise_library_repository.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/services/auth_service.dart';
import '../../../../../core/services/cloud_functions_service.dart';
import '../../../../../core/exceptions/template_in_use_exception.dart';
import '../../../plans/data/models/exercise_plan_model.dart';

/// Exercise Library Repository Implementation
///
/// 动作库数据仓储实现
class ExerciseLibraryRepositoryImpl implements ExerciseLibraryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ExerciseLibraryRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<List<ExerciseTemplateModel>> getTemplates(
    String coachId, {
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('exerciseTemplates')
          .where('ownerId', isEqualTo: coachId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // 如果有分页游标，从该位置继续查询
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ExerciseTemplateModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('获取动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> createTemplate(ExerciseTemplateModel template) async {
    try {
      final docRef = await _firestore
          .collection('exerciseTemplates')
          .add(template.toFirestore());

      AppLogger.info('创建动作模板成功: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('创建动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> quickCreateTemplate(String coachId, String name) async {
    try {
      // 创建只有名称和默认标签的模板
      final template = ExerciseTemplateModel(
        id: '', // Firestore 会自动生成
        name: name,
        tags: ['strength'], // 默认标签
        ownerId: coachId,
        videoUrls: [], // 空视频列表
        thumbnailUrls: [], // 空缩略图列表
        textGuidance: null, // 无文字说明
        imageUrls: [], // 空图片列表
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('exerciseTemplates')
          .add(template.toFirestore());

      AppLogger.info('快捷创建动作模板成功: ${template.name} (${docRef.id})');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('快捷创建动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, String>> batchCreateTemplates(
    List<String> exerciseNames,
  ) async {
    try {
      AppLogger.info('📦 Repository: 批量创建 ${exerciseNames.length} 个模板');

      final templateIdMap = await CloudFunctionsService.createExerciseTemplatesBatch(
        exerciseNames,
      );

      AppLogger.info('✅ Repository: 批量创建完成');
      return templateIdMap;
    } catch (e) {
      AppLogger.error('❌ Repository: 批量创建失败', e);
      rethrow;
    }
  }

  @override
  Future<void> updateTemplate(String id, Map<String, dynamic> data) async {
    try {
      // 确保包含 updatedAt 字段
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('exerciseTemplates').doc(id).update(data);

      AppLogger.info('更新动作模板成功: $id');
    } catch (e, stackTrace) {
      AppLogger.error('更新动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteTemplate(String id, String coachId) async {
    try {
      // 1. 查询所有训练计划
      final plansSnapshot = await _firestore
          .collection('exercisePlans')
          .where('ownerId', isEqualTo: coachId)
          .get();

      // 2. 检查引用
      int refCount = 0;
      for (final planDoc in plansSnapshot.docs) {
        final plan = ExercisePlanModel.fromFirestore(planDoc);
        for (final day in plan.days) {
          for (final exercise in day.exercises) {
            if (exercise.exerciseTemplateId == id) {
              refCount++;
            }
          }
        }
      }

      // 3. 如果有引用，抛出异常
      if (refCount > 0) {
        throw TemplateInUseException(refCount);
      }

      // 4. 无引用，执行删除
      await _firestore.collection('exerciseTemplates').doc(id).delete();
      AppLogger.info('删除动作模板成功: $id');
    } catch (e, stackTrace) {
      AppLogger.error('删除动作模板失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<ExerciseTagModel>> getTags(String coachId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(coachId)
          .collection('exerciseTags')
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ExerciseTagModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error('获取标签失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> createTag(String coachId, String name) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(coachId)
          .collection('exerciseTags')
          .add({'name': name, 'createdAt': FieldValue.serverTimestamp()});

      AppLogger.info('创建标签成功: $name');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('创建标签失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteTag(String coachId, String tagId) async {
    try {
      await _firestore
          .collection('users')
          .doc(coachId)
          .collection('exerciseTags')
          .doc(tagId)
          .delete();

      AppLogger.info('删除标签成功: $tagId');
    } catch (e, stackTrace) {
      AppLogger.error('删除标签失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadExerciseVideo(
    File file, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'exercise_videos/$userId/$timestamp.mp4';
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(file);

      // 监听上传进度
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('上传动作库视频成功: $path');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传动作库视频失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadExerciseImage(File file) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final path = 'exercise_images/$userId/$timestamp.$extension';
      final ref = _storage.ref().child(path);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('上传动作库图片成功: $path');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传动作库图片失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadExerciseThumbnail(File file) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'exercise_thumbnails/$userId/$timestamp.jpg';
      final ref = _storage.ref().child(path);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('上传视频缩略图成功: $path');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传视频缩略图失败', e, stackTrace);
      rethrow;
    }
  }
}
