import 'package:coach_x/features/coach/plans/data/models/diet_day.dart';
import 'package:coach_x/features/coach/plans/data/models/meal.dart';

/// 饮食记录页面状态
class DietRecordState {
  final DietDay? dietDay;
  final List<String> uploadedImages;
  final String studentFeedback;
  final List<Meal> meals;
  final bool isLoading;
  final String? errorMessage;

  const DietRecordState({
    this.dietDay,
    this.uploadedImages = const [],
    this.studentFeedback = '',
    this.meals = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// 创建初始状态
  factory DietRecordState.initial() {
    return const DietRecordState();
  }

  /// 复制并修改部分字段
  DietRecordState copyWith({
    DietDay? dietDay,
    List<String>? uploadedImages,
    String? studentFeedback,
    List<Meal>? meals,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DietRecordState(
      dietDay: dietDay ?? this.dietDay,
      uploadedImages: uploadedImages ?? this.uploadedImages,
      studentFeedback: studentFeedback ?? this.studentFeedback,
      meals: meals ?? this.meals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'DietRecordState(meals: ${meals.length}, images: ${uploadedImages.length}, loading: $isLoading)';
  }
}
