import 'recognized_food.dart';
import 'food_record_mode.dart';

/// AI食物分析状态
class AIFoodAnalysisState {
  /// 是否正在分析
  final bool isAnalyzing;

  /// 是否正在上传图片
  final bool isUploading;

  /// 分析进度 (0.0 - 1.0)
  final double progress;

  /// 上传进度 (0.0 - 1.0)
  final double uploadProgress;

  /// 识别的食物列表
  final List<RecognizedFood> foods;

  /// 错误信息
  final String? errorMessage;

  /// 选中的meal名称（用于保存）
  final String? selectedMealName;

  /// 上传后的图片URL
  final String? imageUrl;

  /// 本餐进度 - 热量
  final double? currentCalories;

  /// 本餐进度 - 蛋白质
  final double? currentProtein;

  /// 本餐进度 - 碳水
  final double? currentCarbs;

  /// 本餐进度 - 脂肪
  final double? currentFat;

  /// AI识别的食物备注
  final String? aiDetectedFoods;

  /// 记录模式
  final FoodRecordMode recordMode;

  const AIFoodAnalysisState({
    this.isAnalyzing = false,
    this.isUploading = false,
    this.progress = 0.0,
    this.uploadProgress = 0.0,
    this.foods = const [],
    this.errorMessage,
    this.selectedMealName,
    this.imageUrl,
    this.currentCalories,
    this.currentProtein,
    this.currentCarbs,
    this.currentFat,
    this.aiDetectedFoods,
    this.recordMode = FoodRecordMode.aiScanner,
  });

  /// 创建初始状态
  factory AIFoodAnalysisState.initial() {
    return const AIFoodAnalysisState();
  }

  /// 分析中状态
  factory AIFoodAnalysisState.analyzing({double progress = 0.0}) {
    return AIFoodAnalysisState(
      isAnalyzing: true,
      progress: progress,
      foods: const [],
      errorMessage: null,
      selectedMealName: null,
    );
  }

  /// 分析完成状态
  factory AIFoodAnalysisState.completed({required List<RecognizedFood> foods}) {
    return AIFoodAnalysisState(
      isAnalyzing: false,
      progress: 1.0,
      foods: foods,
      errorMessage: null,
      selectedMealName: null,
    );
  }

  /// 错误状态
  factory AIFoodAnalysisState.error({required String error}) {
    return AIFoodAnalysisState(
      isAnalyzing: false,
      progress: 0.0,
      foods: const [],
      errorMessage: error,
      selectedMealName: null,
    );
  }

  /// 复制并修改部分字段
  AIFoodAnalysisState copyWith({
    bool? isAnalyzing,
    bool? isUploading,
    double? progress,
    double? uploadProgress,
    List<RecognizedFood>? foods,
    String? errorMessage,
    String? selectedMealName,
    String? imageUrl,
    double? currentCalories,
    double? currentProtein,
    double? currentCarbs,
    double? currentFat,
    String? aiDetectedFoods,
    FoodRecordMode? recordMode,
  }) {
    return AIFoodAnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      foods: foods ?? this.foods,
      errorMessage: errorMessage,
      selectedMealName: selectedMealName ?? this.selectedMealName,
      imageUrl: imageUrl ?? this.imageUrl,
      currentCalories: currentCalories ?? this.currentCalories,
      currentProtein: currentProtein ?? this.currentProtein,
      currentCarbs: currentCarbs ?? this.currentCarbs,
      currentFat: currentFat ?? this.currentFat,
      aiDetectedFoods: aiDetectedFoods ?? this.aiDetectedFoods,
      recordMode: recordMode ?? this.recordMode,
    );
  }

  /// 是否有错误
  bool get hasError => errorMessage != null;

  /// 是否有结果
  bool get hasResults => foods.isNotEmpty;

  @override
  String toString() {
    return 'AIFoodAnalysisState(analyzing: $isAnalyzing, uploading: $isUploading, progress: $progress, '
        'foods: ${foods.length}, error: $errorMessage, meal: $selectedMealName, '
        'imageUrl: $imageUrl, currentMacros: [$currentCalories, $currentProtein, $currentCarbs, $currentFat], '
        'recordMode: $recordMode)';
  }
}
