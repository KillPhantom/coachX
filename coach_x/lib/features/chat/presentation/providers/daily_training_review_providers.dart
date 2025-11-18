import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/app/providers.dart';
import 'package:coach_x/core/enums/feedback_input_type.dart';
import 'package:coach_x/core/models/voice_record_state.dart';
import 'package:coach_x/features/chat/data/models/training_feedback_model.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';

// ==================== State Providers ====================

/// 选中的运动索引
final selectedExerciseIndexProvider = StateProvider<int>((ref) => 0);

/// 选中的视频索引
final selectedVideoIndexProvider = StateProvider<int>((ref) => 0);

/// 选中的 Set 索引
final selectedSetIndexProvider = StateProvider<int>((ref) => 0);

/// 反馈文本内容
final feedbackTextProvider = StateProvider<String>((ref) => '');

/// 是否正在保存
final isSavingProvider = StateProvider<bool>((ref) => false);

/// 关键帧提取加载状态（key: exercise_index, value: is_loading）
final keyframeExtractionLoadingProvider = StateProvider<Map<int, bool>>(
  (ref) => {},
);

/// 关键帧提取错误状态（key: exercise_index, value: error_message）
final keyframeExtractionErrorProvider = StateProvider<Map<int, String?>>(
  (ref) => {},
);

/// 关键帧提取进度状态（key: exercise_index, value: progress_data）
final keyframeExtractionProgressProvider =
    StateProvider<Map<int, KeyframeExtractionProgress>>((ref) => {});

/// 图片编辑加载状态
final isEditingImageProvider = StateProvider<bool>((ref) => false);

/// 图片上传进度（可选，未来扩展）
final imageUploadProgressProvider = StateProvider<double?>((ref) => null);

// ==================== Data Providers ====================

/// 获取学生信息
final studentInfoProvider = FutureProvider.family<UserModel?, String>((
  ref,
  studentId,
) async {
  final repository = ref.read(userRepositoryProvider);
  return await repository.getUser(studentId);
});

/// 获取 TrainingFeedbackModel
final feedbackDetailProvider =
    FutureProvider.family<TrainingFeedbackModel?, String>((
      ref,
      feedbackId,
    ) async {
      final repository = ref.read(feedbackRepositoryProvider);
      return await repository.getFeedback(feedbackId);
    });

/// 获取 DailyTrainingModel (实时监听)
final dailyTrainingProvider =
    StreamProvider.family<DailyTrainingModel?, String>((ref, dailyTrainingId) {
      final repository = ref.watch(dailyTrainingRepositoryProvider);
      return repository.watchDailyTraining(dailyTrainingId);
    });

/// 组合数据Provider - 基于 dailyTrainingId 获取数据 (实时监听)
final reviewPageDataProvider = StreamProvider.family<ReviewPageData?, String>((
  ref,
  dailyTrainingId,
) {
  // 监听 dailyTraining 的实时更新
  return ref.watch(dailyTrainingProvider(dailyTrainingId).stream).asyncMap((
    dailyTraining,
  ) async {
    if (dailyTraining == null) {
      return null;
    }

    // 获取学生信息
    final studentInfo = await ref.read(
      studentInfoProvider(dailyTraining.studentId).future,
    );

    return ReviewPageData(
      feedback: null, // feedback 现在通过 feedbackHistoryStreamProvider 获取
      dailyTraining: dailyTraining,
      feedbackId: null,
      studentInfo: studentInfo,
    );
  });
});

// ==================== Data Models ====================

/// 页面数据模型
class ReviewPageData {
  final TrainingFeedbackModel? feedback; // 已废弃，改用 feedbackHistoryStreamProvider
  final DailyTrainingModel dailyTraining;
  final String? feedbackId; // 用于保存时判断是创建还是更新
  final UserModel? studentInfo; // 学生信息

  const ReviewPageData({
    this.feedback,
    required this.dailyTraining,
    this.feedbackId,
    this.studentInfo,
  });
}

// ==================== 新格式反馈相关 Providers ====================

/// 反馈历史流（新格式）
final feedbackHistoryStreamProvider =
    StreamProvider.family<List<TrainingFeedbackModel>, String>((
      ref,
      dailyTrainingId,
    ) {
      final repository = ref.watch(feedbackRepositoryProvider);
      return repository.getFeedbackHistory(dailyTrainingId);
    });

/// 当前输入类型
final feedbackInputTypeProvider = StateProvider<FeedbackInputType>(
  (ref) => FeedbackInputType.text,
);

/// 文字输入内容
final feedbackTextInputProvider = StateProvider<String>((ref) => '');

/// 语音录制状态
final feedbackVoiceStateProvider = StateProvider<VoiceRecordState>(
  (ref) => const VoiceRecordState(),
);

/// 图片选择状态（本地文件路径）
final feedbackImageStateProvider = StateProvider<String?>((ref) => null);

/// 提交状态
final isSubmittingFeedbackProvider = StateProvider<bool>((ref) => false);

// ==================== 关键帧提取进度数据模型 ====================

/// 关键帧提取进度数据
class KeyframeExtractionProgress {
  /// 进度值 (0.0 - 1.0)
  final double progress;

  /// 进度信息文本
  final String? infoText;

  const KeyframeExtractionProgress({required this.progress, this.infoText});

  KeyframeExtractionProgress copyWith({double? progress, String? infoText}) {
    return KeyframeExtractionProgress(
      progress: progress ?? this.progress,
      infoText: infoText ?? this.infoText,
    );
  }
}

// ==================== 动作反馈相关 Providers ====================

/// FeedbackInputBar 可见性状态
/// [已废弃] FeedbackInputBar 现在始终显示在固定底部区域
@Deprecated('FeedbackInputBar is now always visible in _FixedBottomSection')
final isFeedbackInputVisibleProvider = StateProvider<bool>((ref) => false);

/// 当前反馈页码（用于分页）
final exerciseFeedbackPageProvider = StateProvider<int>((ref) => 1);

/// 动作历史反馈 Provider (family: ExerciseFeedbackParams)
/// 监听当前选中动作的所有历史反馈（跨训练记录）
final exerciseFeedbackHistoryProvider =
    StreamProvider.family<List<TrainingFeedbackModel>, ExerciseFeedbackParams>((
      ref,
      params,
    ) {
      final repository = ref.watch(feedbackRepositoryProvider);
      final page = ref.watch(exerciseFeedbackPageProvider);

      return repository.getExerciseHistoryFeedbacks(
        studentId: params.studentId,
        exerciseTemplateId: params.exerciseTemplateId,
        limit: page * 10, // 每页10条，累加加载
      );
    });

/// 动作反馈参数模型
class ExerciseFeedbackParams {
  final String studentId;
  final String exerciseTemplateId;

  const ExerciseFeedbackParams({
    required this.studentId,
    required this.exerciseTemplateId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseFeedbackParams &&
          studentId == other.studentId &&
          exerciseTemplateId == other.exerciseTemplateId;

  @override
  int get hashCode => Object.hash(studentId, exerciseTemplateId);
}
