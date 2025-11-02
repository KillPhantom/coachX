/// 加载状态枚举
enum LoadingStatus {
  /// 初始状态
  initial,

  /// 加载中
  loading,

  /// 成功
  success,

  /// 错误
  error,
}

/// LoadingStatus 扩展方法
extension LoadingStatusExtension on LoadingStatus {
  /// 是否为初始状态
  bool get isInitial => this == LoadingStatus.initial;

  /// 是否为加载中
  bool get isLoading => this == LoadingStatus.loading;

  /// 是否为成功
  bool get isSuccess => this == LoadingStatus.success;

  /// 是否为错误
  bool get isError => this == LoadingStatus.error;
}

/// 网络状态枚举
enum NetworkStatus {
  /// 在线
  online,

  /// 离线
  offline,
}

/// NetworkStatus 扩展方法
extension NetworkStatusExtension on NetworkStatus {
  /// 是否在线
  bool get isOnline => this == NetworkStatus.online;

  /// 是否离线
  bool get isOffline => this == NetworkStatus.offline;

  /// 获取显示文本
  String get displayText {
    switch (this) {
      case NetworkStatus.online:
        return '在线';
      case NetworkStatus.offline:
        return '离线';
    }
  }
}

/// 按钮类型枚举
enum ButtonType {
  /// 主要按钮
  primary,

  /// 次要按钮
  secondary,

  /// 文字按钮
  text,
}

/// 按钮大小枚举
enum ButtonSize {
  /// 小按钮
  small,

  /// 中按钮
  medium,

  /// 大按钮
  large,
}
