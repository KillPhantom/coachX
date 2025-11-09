/// 时间范围枚举
///
/// 用于历史页面的时间范围筛选
enum TimeRange {
  /// 最近14天
  days14,

  /// 最近30天
  days30,

  /// 最近90天
  days90,
}

extension TimeRangeExtension on TimeRange {
  /// 获取对应的天数
  int get days {
    switch (this) {
      case TimeRange.days14:
        return 14;
      case TimeRange.days30:
        return 30;
      case TimeRange.days90:
        return 90;
    }
  }

  /// 获取显示文本键名（用于国际化）
  String get i18nKey {
    switch (this) {
      case TimeRange.days14:
        return 'last14Days';
      case TimeRange.days30:
        return 'last30Days';
      case TimeRange.days90:
        return 'last90Days';
    }
  }
}
