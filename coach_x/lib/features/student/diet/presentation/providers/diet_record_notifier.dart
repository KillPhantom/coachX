import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'package:coach_x/features/student/diet/data/models/diet_record_state.dart';
import 'package:coach_x/features/student/diet/data/repositories/diet_record_repository.dart';
import 'package:coach_x/features/student/diet/data/models/student_diet_record_model.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';

/// 饮食记录Notifier
class DietRecordNotifier extends StateNotifier<DietRecordState> {
  final DietRecordRepository _repository;
  final Ref _ref;

  DietRecordNotifier(this._repository, this._ref)
    : super(DietRecordState.initial());

  /// 初始化页面数据
  void initialize(DietDay dietDay) {
    AppLogger.info('初始化饮食记录页面: ${dietDay.name}');

    state = state.copyWith(
      dietDay: dietDay,
      meals: dietDay.meals,
      uploadedImages: [],
      studentFeedback: '',
      errorMessage: null,
    );
  }

  /// 切换餐次完成状态
  Future<void> toggleMealCompletion(int mealIndex) async {
    if (mealIndex < 0 || mealIndex >= state.meals.length) {
      AppLogger.error('无效的餐次索引: $mealIndex');
      return;
    }

    final currentMeal = state.meals[mealIndex];
    final updatedMeals = List.of(state.meals);
    updatedMeals[mealIndex] = currentMeal.copyWith(
      completed: !currentMeal.completed,
    );

    state = state.copyWith(meals: updatedMeals);
    AppLogger.info('餐次状态切换: ${currentMeal.name} -> ${!currentMeal.completed}');
  }

  /// 上传图片
  Future<void> uploadImage(ImageSource source) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        state = state.copyWith(isLoading: false);
        AppLogger.info('用户取消选择图片');
        return;
      }

      final file = File(pickedFile.path);
      final url = await _repository.uploadDietImage(file);

      final updatedImages = List<String>.from(state.uploadedImages)..add(url);
      state = state.copyWith(uploadedImages: updatedImages, isLoading: false);

      AppLogger.info('图片上传成功: $url');
    } catch (e, stackTrace) {
      AppLogger.error('上传图片失败', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: '上传图片失败: ${e.toString()}',
      );
    }
  }

  /// 更新学生反馈
  void updateFeedback(String feedback) {
    state = state.copyWith(studentFeedback: feedback);
  }

  /// 保存记录
  Future<void> saveRecord(String date) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      AppLogger.info('保存饮食记录: $date');

      final userId = AuthService.currentUserId;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // 构建 StudentDietRecordModel
      final dietRecord = StudentDietRecordModel(
        macros: state.dietDay?.macros,
        meals: state.meals,
        studentFeedback: state.studentFeedback,
      );

      // 构建 DailyTrainingModel
      // 注意：这里需要从现有记录获取或创建新记录
      final trainingModel = DailyTrainingModel(
        id: '', // 后端会生成ID
        studentId: userId,
        coachId: '', // 需要从用户信息获取
        date: date,
        planSelection: const TrainingDaySelection(), // TODO: 从当前计划获取
        diet: dietRecord,
      );

      await _repository.saveDietRecord(trainingModel);

      state = state.copyWith(isLoading: false);
      AppLogger.info('保存饮食记录成功');
    } catch (e, stackTrace) {
      AppLogger.error('保存饮食记录失败', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: '保存失败: ${e.toString()}',
      );
      rethrow;
    }
  }
}
