import '../utils/date_utils.dart' as date_utils;

/// DateTime 扩展方法
extension DateExtensions on DateTime {
  /// 格式化为日期字符串 - yyyy-MM-dd
  String formatDate() {
    return date_utils.DateUtils.formatDate(this);
  }

  /// 格式化为时间字符串 - HH:mm
  String formatTime() {
    return date_utils.DateUtils.formatTime(this);
  }

  /// 格式化为日期时间字符串 - yyyy-MM-dd HH:mm
  String formatDateTime() {
    return date_utils.DateUtils.formatDateTime(this);
  }

  /// 格式化为日期时间字符串（带秒） - yyyy-MM-dd HH:mm:ss
  String formatDateTimeWithSecond() {
    return date_utils.DateUtils.formatDateTimeWithSecond(this);
  }

  /// 自定义格式化
  String format(String pattern) {
    return date_utils.DateUtils.format(this, pattern);
  }

  /// 是否为今天
  bool get isToday => date_utils.DateUtils.isToday(this);

  /// 是否为昨天
  bool get isYesterday => date_utils.DateUtils.isYesterday(this);

  /// 是否为明天
  bool get isTomorrow => date_utils.DateUtils.isTomorrow(this);

  /// 获取星期几（中文）
  String get weekday => date_utils.DateUtils.getWeekday(this);

  /// 获取星期几（英文缩写）
  String get weekdayShort => date_utils.DateUtils.getWeekdayShort(this);

  /// 是否为同一天
  bool isSameDay(DateTime other) {
    return date_utils.DateUtils.isSameDay(this, other);
  }

  /// 计算与另一个日期的天数差
  int daysDifference(DateTime other) {
    return date_utils.DateUtils.getDaysDifference(this, other);
  }

  /// 计算与另一个日期的小时差
  int hoursDifference(DateTime other) {
    return date_utils.DateUtils.getHoursDifference(this, other);
  }

  /// 计算与另一个日期的分钟差
  int minutesDifference(DateTime other) {
    return date_utils.DateUtils.getMinutesDifference(this, other);
  }

  /// 获取相对时间描述（刚刚、几分钟前等）
  String get relativeTime => date_utils.DateUtils.getRelativeTime(this);

  /// 获取月份的第一天
  DateTime get firstDayOfMonth => date_utils.DateUtils.getFirstDayOfMonth(this);

  /// 获取月份的最后一天
  DateTime get lastDayOfMonth => date_utils.DateUtils.getLastDayOfMonth(this);

  /// 获取周的第一天（周一）
  DateTime get firstDayOfWeek => date_utils.DateUtils.getFirstDayOfWeek(this);

  /// 获取周的最后一天（周日）
  DateTime get lastDayOfWeek => date_utils.DateUtils.getLastDayOfWeek(this);

  /// 是否在指定日期之前
  bool isBefore(DateTime other) {
    return compareTo(other) < 0;
  }

  /// 是否在指定日期之后
  bool isAfter(DateTime other) {
    return compareTo(other) > 0;
  }

  /// 是否在指定日期范围内
  bool isBetween(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }

  /// 添加天数
  DateTime addDays(int days) {
    return add(Duration(days: days));
  }

  /// 添加小时
  DateTime addHours(int hours) {
    return add(Duration(hours: hours));
  }

  /// 添加分钟
  DateTime addMinutes(int minutes) {
    return add(Duration(minutes: minutes));
  }

  /// 减去天数
  DateTime subtractDays(int days) {
    return subtract(Duration(days: days));
  }

  /// 减去小时
  DateTime subtractHours(int hours) {
    return subtract(Duration(hours: hours));
  }

  /// 减去分钟
  DateTime subtractMinutes(int minutes) {
    return subtract(Duration(minutes: minutes));
  }

  /// 复制并修改日期
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }

  /// 设置时间为一天的开始（00:00:00）
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// 设置时间为一天的结束（23:59:59）
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// 是否为周末
  bool get isWeekend {
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// 是否为工作日
  bool get isWeekday {
    return !isWeekend;
  }

  /// 获取当月的天数
  int get daysInMonth {
    return DateTime(year, month + 1, 0).day;
  }

  /// 是否为闰年
  bool get isLeapYear {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// 获取年龄（从出生日期计算）
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }
}
