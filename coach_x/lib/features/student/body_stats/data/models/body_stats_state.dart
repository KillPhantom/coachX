/// 身体数据记录页面状态
///
/// 用于管理记录页面的状态
class BodyStatsState {
  /// 已选择的照片（本地文件路径）
  final List<String> photos;

  /// 体重值
  final double? weight;

  /// 体重单位 ('kg' 或 'lbs')
  final String weightUnit;

  /// 体脂率
  final double? bodyFat;

  /// 是否正在加载
  final bool isLoading;

  /// 错误消息
  final String? errorMessage;

  const BodyStatsState({
    this.photos = const [],
    this.weight,
    this.weightUnit = 'kg',
    this.bodyFat,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 复制并修改部分字段
  BodyStatsState copyWith({
    List<String>? photos,
    double? weight,
    String? weightUnit,
    double? bodyFat,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BodyStatsState(
      photos: photos ?? this.photos,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      bodyFat: bodyFat ?? this.bodyFat,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// 创建空状态（默认单位从用户偏好读取）
  factory BodyStatsState.initial({String weightUnit = 'kg'}) {
    return BodyStatsState(
      photos: const [],
      weight: null,
      weightUnit: weightUnit,
      bodyFat: null,
      isLoading: false,
      errorMessage: null,
    );
  }

  /// 验证数据
  bool get isValid {
    // 体重必须大于0
    if (weight == null || weight! <= 0) {
      return false;
    }

    // 如果提供了体脂率，必须在0-100范围内
    if (bodyFat != null && (bodyFat! < 0 || bodyFat! > 100)) {
      return false;
    }

    // 照片数量不能超过3
    if (photos.length > 3) {
      return false;
    }

    return true;
  }

  /// 是否达到照片上限
  bool get isPhotosLimitReached => photos.length >= 3;

  @override
  String toString() {
    return 'BodyStatsState(photos: ${photos.length}, weight: $weight$weightUnit, bodyFat: $bodyFat%, isLoading: $isLoading, error: $errorMessage)';
  }
}
