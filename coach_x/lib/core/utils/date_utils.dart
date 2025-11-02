import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// 日期时间工具类
class DateUtils {
  DateUtils._(); // 私有构造函数，防止实例化

  /// 格式化日期 - yyyy-MM-dd
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  /// 格式化时间 - HH:mm
  static String formatTime(DateTime date) {
    return DateFormat(AppConstants.timeFormat).format(date);
  }

  /// 格式化日期时间 - yyyy-MM-dd HH:mm
  static String formatDateTime(DateTime date) {
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  /// 格式化日期时间（带秒） - yyyy-MM-dd HH:mm:ss
  static String formatDateTimeWithSecond(DateTime date) {
    return DateFormat(AppConstants.dateTimeSecondFormat).format(date);
  }

  /// 自定义格式化
  static String format(DateTime date, String pattern) {
    return DateFormat(pattern).format(date);
  }

  /// 判断是否为今天
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 判断是否为昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// 判断是否为明天
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// 获取星期几（中文）
  static String getWeekday(DateTime date) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${weekdays[date.weekday - 1]}';
  }

  /// 获取星期几（英文缩写）
  static String getWeekdayShort(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  /// 计算天数差
  static int getDaysDifference(DateTime date1, DateTime date2) {
    final diff = date1.difference(date2);
    return diff.inDays;
  }

  /// 计算小时差
  static int getHoursDifference(DateTime date1, DateTime date2) {
    final diff = date1.difference(date2);
    return diff.inHours;
  }

  /// 计算分钟差
  static int getMinutesDifference(DateTime date1, DateTime date2) {
    final diff = date1.difference(date2);
    return diff.inMinutes;
  }

  /// 获取相对时间描述（刚刚、几分钟前、几小时前等）
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return formatDate(date);
    }
  }

  /// 判断是否为同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 获取当前日期字符串
  static String getCurrentDate() {
    return formatDate(DateTime.now());
  }

  /// 获取当前时间字符串
  static String getCurrentTime() {
    return formatTime(DateTime.now());
  }

  /// 获取当前日期时间字符串
  static String getCurrentDateTime() {
    return formatDateTime(DateTime.now());
  }

  /// 从字符串解析日期
  static DateTime? parseDate(String dateStr) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  /// 从字符串解析日期时间
  static DateTime? parseDateTime(String dateTimeStr) {
    try {
      return DateFormat(AppConstants.dateTimeFormat).parse(dateTimeStr);
    } catch (e) {
      return null;
    }
  }

  /// 获取月份的第一天
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取月份的最后一天
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 获取周的第一天（周一）
  static DateTime getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// 获取周的最后一天（周日）
  static DateTime getLastDayOfWeek(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }
}
