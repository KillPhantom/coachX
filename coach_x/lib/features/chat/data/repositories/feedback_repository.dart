import 'dart:typed_data';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';

/// Feedback Repository 抽象接口
abstract class FeedbackRepository {
  /// 监听学生的训练反馈列表
  ///
  /// [studentId] 学生ID
  /// [coachId] 教练ID
  /// [startDate] 开始日期（可选） "yyyy-MM-dd"
  /// [endDate] 结束日期（可选） "yyyy-MM-dd"
  /// 返回实时更新的反馈列表流
  Stream<List<TrainingFeedbackModel>> watchFeedbacks({
    required String studentId,
    required String coachId,
    String? startDate,
    String? endDate,
  });

  /// 获取单个反馈详情
  ///
  /// [feedbackId] 反馈ID
  /// 返回反馈模型，不存在返回null
  Future<TrainingFeedbackModel?> getFeedback(String feedbackId);

  /// 通过 dailyTrainingId 获取反馈
  ///
  /// [dailyTrainingId] 训练记录ID
  /// 返回反馈模型，不存在返回null
  Future<TrainingFeedbackModel?> getFeedbackByDailyTrainingId(
    String dailyTrainingId,
  );

  /// 标记反馈为已读
  ///
  /// [feedbackId] 反馈ID
  /// 返回操作是否成功
  Future<void> markFeedbackAsRead(String feedbackId);

  /// 获取反馈历史
  ///
  /// [dailyTrainingId] 训练记录ID
  /// 返回实时更新的反馈列表流（按创建时间降序）
  Stream<List<TrainingFeedbackModel>> getFeedbackHistory(
    String dailyTrainingId,
  );

  /// 添加反馈
  ///
  /// [dailyTrainingId] 训练记录ID
  /// [studentId] 学生ID
  /// [coachId] 教练ID
  /// [trainingDate] 训练日期 "yyyy-MM-dd"
  /// [exerciseTemplateId] 教练动作库 Exercise ID（可选）视频项填写，图文项不填
  /// [exerciseName] exercise名称（可选）用于历史查询
  /// [feedbackType] 反馈类型："text"/"voice"/"image"/"video"
  /// [textContent] 文字内容（feedbackType为text时使用）
  /// [voiceUrl] 语音文件URL（feedbackType为voice时使用）
  /// [voiceDuration] 语音时长，单位：秒（feedbackType为voice时使用）
  /// [imageUrl] 图片URL（feedbackType为image时使用）
  /// [videoUrl] 视频URL（feedbackType为video时使用）
  /// [videoThumbnailUrl] 视频缩略图URL（feedbackType为video时使用）
  /// [videoDuration] 视频时长，单位：秒（feedbackType为video时使用）
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
    String? videoUrl,
    String? videoThumbnailUrl,
    int? videoDuration,
  });

  /// 查询某个动作的历史反馈（跨多个 dailyTraining）
  ///
  /// [studentId] 学生ID
  /// [exerciseTemplateId] 教练动作库 Exercise ID
  /// [limit] 限制数量（可选）
  /// 返回实时更新的反馈列表流（按训练日期降序）
  Stream<List<TrainingFeedbackModel>> getExerciseHistoryFeedbacks({
    required String studentId,
    required String exerciseTemplateId,
    int? limit,
  });

  /// 查询图文项反馈（exerciseTemplateId == null）
  ///
  /// [dailyTrainingId] 训练记录ID
  /// [limit] 限制数量（可选）
  /// 返回实时更新的反馈列表流（按创建时间降序）
  Stream<List<TrainingFeedbackModel>> getDailyTrainingFeedbacks({
    required String dailyTrainingId,
    int? limit,
  });

  /// 上传语音文件到 Firebase Storage
  ///
  /// [filePath] 本地文件路径
  /// [dailyTrainingId] 训练记录ID（用于构建存储路径）
  /// 返回上传后的下载URL
  Future<String> uploadVoiceFile(String filePath, String dailyTrainingId);

  /// 上传图片文件到 Firebase Storage
  ///
  /// [filePath] 本地文件路径
  /// [dailyTrainingId] 训练记录ID（用于构建存储路径）
  /// 返回上传后的下载URL
  Future<String> uploadImageFile(String filePath, String dailyTrainingId);

  /// 上传视频文件到 Firebase Storage
  ///
  /// [filePath] 本地文件路径
  /// [dailyTrainingId] 训练记录ID（用于构建存储路径）
  /// 返回上传后的下载URL
  Future<String> uploadVideoFile(String filePath, String dailyTrainingId);

  /// 上传视频缩略图文件到 Firebase Storage
  ///
  /// [filePath] 本地文件路径
  /// [dailyTrainingId] 训练记录ID（用于构建存储路径）
  /// 返回上传后的下载URL
  Future<String> uploadVideoThumbnail(String filePath, String dailyTrainingId);

  /// 上传编辑后的图片字节数据到 Firebase Storage
  ///
  /// [bytes] 编辑后的图片字节数据（JPG格式）
  /// [dailyTrainingId] 关联的训练记录ID（用于构建存储路径）
  /// 返回上传后的下载URL
  Future<String> uploadEditedImageBytes(
    Uint8List bytes,
    String dailyTrainingId,
  );

  /// 更新已有反馈的图片URL
  ///
  /// [feedbackId] 反馈记录ID
  /// [newImageUrl] 新的图片URL
  Future<void> updateFeedbackImage(String feedbackId, String newImageUrl);

  /// 上传关键帧图片到 Firebase Storage（用于替换现有关键帧）
  ///
  /// [bytes] 编辑后的图片字节数据（JPG格式）
  /// [dailyTrainingId] 关联的训练记录ID
  /// [exerciseIndex] 动作索引
  /// 返回上传后的下载URL
  Future<String> uploadKeyframeImage(
    Uint8List bytes,
    String dailyTrainingId,
    int exerciseIndex,
  );

  /// 删除 Firebase Storage 中的文件
  ///
  /// [storageUrl] Storage 文件的完整 URL
  /// 如果文件不存在，忽略错误
  Future<void> deleteStorageFile(String storageUrl);

  /// 删除反馈
  ///
  /// [feedbackId] 反馈ID
  /// [feedback] 反馈对象 (用于删除关联文件)
  Future<void> deleteFeedback(String feedbackId, TrainingFeedbackModel feedback);
}
