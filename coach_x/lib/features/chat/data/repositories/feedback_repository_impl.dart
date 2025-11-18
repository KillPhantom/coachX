import 'dart:io';
import 'dart:typed_data';

import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'feedback_repository.dart';

/// Feedback Repository 实现类
class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl();

  @override
  Stream<List<TrainingFeedbackModel>> watchFeedbacks({
    required String studentId,
    required String coachId,
    String? startDate,
    String? endDate,
  }) {
    try {
      // 构建查询条件
      final where = <List<dynamic>>[
        ['studentId', '==', studentId],
        ['coachId', '==', coachId],
      ];

      // 添加日期范围筛选（如果提供）
      if (startDate != null) {
        where.add(['trainingDate', '>=', startDate]);
      }
      if (endDate != null) {
        where.add(['trainingDate', '<=', endDate]);
      }

      return FirestoreService.watchCollection(
        'dailyTrainingFeedback',
        where: where,
        orderBy: 'trainingDate',
        descending: true,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return TrainingFeedbackModel.fromJson(data);
        }).toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error('监听训练反馈列表失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<TrainingFeedbackModel?> getFeedback(String feedbackId) async {
    try {
      final doc = await FirestoreService.getDocument(
        'dailyTrainingFeedback',
        feedbackId,
      );

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return TrainingFeedbackModel.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.error('获取训练反馈失败: $feedbackId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<TrainingFeedbackModel?> getFeedbackByDailyTrainingId(
    String dailyTrainingId,
  ) async {
    try {
      AppLogger.info('通过 dailyTrainingId 查询反馈: $dailyTrainingId');

      final docs = await FirestoreService.queryDocuments(
        'dailyTrainingFeedback',
        where: [
          ['dailyTrainingId', '==', dailyTrainingId],
        ],
        limit: 1,
      );

      if (docs.isEmpty) {
        AppLogger.info('未找到反馈记录: $dailyTrainingId');
        return null;
      }

      final doc = docs.first;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      AppLogger.info('找到反馈记录: ${doc.id}');
      return TrainingFeedbackModel.fromJson(data);
    } catch (e, stackTrace) {
      AppLogger.error(
        '通过 dailyTrainingId 获取反馈失败: $dailyTrainingId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> markFeedbackAsRead(String feedbackId) async {
    try {
      await FirestoreService.updateDocument(
        'dailyTrainingFeedback',
        feedbackId,
        {'isRead': true},
      );
      AppLogger.info('标记反馈为已读: $feedbackId');
    } catch (e, stackTrace) {
      AppLogger.error('标记反馈为已读失败: $feedbackId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<TrainingFeedbackModel>> getFeedbackHistory(
    String dailyTrainingId,
  ) {
    try {
      AppLogger.info('监听反馈历史: $dailyTrainingId');

      return FirestoreService.watchCollection(
        'dailyTrainingFeedback',
        where: [
          ['dailyTrainingId', '==', dailyTrainingId],
        ],
        orderBy: 'createdAt',
        descending: true,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return TrainingFeedbackModel.fromJson(data);
        }).toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error('监听反馈历史失败: $dailyTrainingId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addFeedback({
    required String dailyTrainingId,
    required String studentId,
    required String coachId,
    required String trainingDate,
    String? exerciseTemplateId,
    String? exerciseName,
    required String feedbackType,
    String? textContent,
    String? voiceUrl,
    int? voiceDuration,
    String? imageUrl,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final data = <String, dynamic>{
        'dailyTrainingId': dailyTrainingId,
        'studentId': studentId,
        'coachId': coachId,
        'trainingDate': trainingDate,
        'exerciseTemplateId': exerciseTemplateId,
        'exerciseName': exerciseName,
        'feedbackType': feedbackType,
        'textContent': textContent,
        'voiceUrl': voiceUrl,
        'voiceDuration': voiceDuration,
        'imageUrl': imageUrl,
        'createdAt': now,
        'isRead': false,
      };

      await FirestoreService.addDocument('dailyTrainingFeedback', data);
      AppLogger.info('添加反馈成功: $dailyTrainingId, type: $feedbackType');
    } catch (e, stackTrace) {
      AppLogger.error(
        '添加反馈失败: $dailyTrainingId, type: $feedbackType',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<String> uploadVoiceFile(
    String filePath,
    String dailyTrainingId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_$timestamp.aac';
      final storagePath = 'feedback_voices/$dailyTrainingId/$fileName';

      AppLogger.info('上传语音文件: $storagePath');

      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putFile(File(filePath));
      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('语音文件上传成功: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传语音文件失败: $filePath', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadImageFile(
    String filePath,
    String dailyTrainingId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = filePath.split('.').last;
      final fileName = 'image_$timestamp.$fileExtension';
      final storagePath = 'feedback_images/$dailyTrainingId/$fileName';

      AppLogger.info('上传图片文件: $storagePath');

      final ref = FirebaseStorage.instance.ref(storagePath);
      await ref.putFile(File(filePath));
      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('图片文件上传成功: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传图片文件失败: $filePath', e, stackTrace);
      rethrow;
    }
  }

  @override
  Stream<List<TrainingFeedbackModel>> getExerciseHistoryFeedbacks({
    required String studentId,
    required String exerciseTemplateId,
    int? limit,
  }) {
    try {
      AppLogger.info('查询 exercise 历史反馈: $studentId, $exerciseTemplateId');

      // 构建查询条件
      final where = <List<dynamic>>[
        ['studentId', '==', studentId],
        ['exerciseTemplateId', '==', exerciseTemplateId],
      ];

      return FirestoreService.watchCollection(
        'dailyTrainingFeedback',
        where: where,
        orderBy: 'trainingDate',
        descending: true,
        limit: limit,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return TrainingFeedbackModel.fromJson(data);
        }).toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        '查询 exercise 历史反馈失败: $studentId, $exerciseTemplateId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Stream<List<TrainingFeedbackModel>> getDailyTrainingFeedbacks({
    required String dailyTrainingId,
    int? limit,
  }) {
    try {
      AppLogger.info('查询图文项反馈: $dailyTrainingId');

      // 构建查询条件：仅查询无 exerciseTemplateId 的反馈
      final where = <List<dynamic>>[
        ['dailyTrainingId', '==', dailyTrainingId],
        ['exerciseTemplateId', '==', null],
      ];

      return FirestoreService.watchCollection(
        'dailyTrainingFeedback',
        where: where,
        orderBy: 'createdAt',
        descending: true,
        limit: limit,
      ).map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return TrainingFeedbackModel.fromJson(data);
        }).toList();
      });
    } catch (e, stackTrace) {
      AppLogger.error('查询图文项反馈失败: $dailyTrainingId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadEditedImageBytes(
    Uint8List bytes,
    String dailyTrainingId,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'edited_image_$timestamp.jpg';
      final storagePath = 'feedback_images/$dailyTrainingId/$fileName';

      AppLogger.info('上传编辑后图片: $storagePath');

      final ref = FirebaseStorage.instance.ref(storagePath);

      // Use putData for Uint8List
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('编辑后图片上传成功: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传编辑后图片失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateFeedbackImage(
    String feedbackId,
    String newImageUrl,
  ) async {
    try {
      await FirestoreService.updateDocument(
        'dailyTrainingFeedback',
        feedbackId,
        {'imageUrl': newImageUrl},
      );
      AppLogger.info('更新反馈图片成功: $feedbackId');
    } catch (e, stackTrace) {
      AppLogger.error('更新反馈图片失败: $feedbackId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> uploadKeyframeImage(
    Uint8List bytes,
    String dailyTrainingId,
    int exerciseIndex,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'ex${exerciseIndex}_edited_$timestamp.jpg';
      final storagePath = 'training_keyframes/$dailyTrainingId/$fileName';

      AppLogger.info('上传关键帧图片: $storagePath');

      final ref = FirebaseStorage.instance.ref(storagePath);

      // Use putData for Uint8List
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      final downloadUrl = await ref.getDownloadURL();

      AppLogger.info('关键帧图片上传成功: $downloadUrl');
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.error('上传关键帧图片失败', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteStorageFile(String storageUrl) async {
    try {
      AppLogger.info('删除 Storage 文件: $storageUrl');

      final ref = FirebaseStorage.instance.refFromURL(storageUrl);
      await ref.delete();

      AppLogger.info('Storage 文件删除成功: $storageUrl');
    } catch (e) {
      // Ignore error if file doesn't exist
      if (e.toString().contains('object-not-found')) {
        AppLogger.info('Storage 文件不存在（已被删除）: $storageUrl');
      } else {
        AppLogger.error('删除 Storage 文件失败: $storageUrl', e, null);
        rethrow;
      }
    }
  }
}
