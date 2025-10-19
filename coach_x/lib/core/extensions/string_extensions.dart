import '../utils/string_utils.dart';
import '../utils/date_utils.dart' as date_utils;

/// String 扩展方法
extension StringExtensions on String {
  /// 是否不为空（非null且不是空字符串）
  bool get isNotNullOrEmpty => StringUtils.isNotEmpty(this);

  /// 是否为空（空字符串）
  bool get isNullOrEmpty => StringUtils.isEmpty(this);

  /// 是否为空白（空字符串或只包含空白字符）
  bool get isBlank => StringUtils.isBlank(this);

  /// 是否不为空白
  bool get isNotBlank => StringUtils.isNotBlank(this);

  /// 首字母大写
  String get capitalize => StringUtils.capitalize(this);

  /// 首字母小写
  String get uncapitalize => StringUtils.uncapitalize(this);

  /// 转换为驼峰命名
  String get toCamelCase => StringUtils.toCamelCase(this);

  /// 转换为蛇形命名
  String get toSnakeCase => StringUtils.toSnakeCase(this);

  /// 移除所有空白字符
  String get removeWhitespace => StringUtils.removeWhitespace(this);

  /// 移除HTML标签
  String get removeHtmlTags => StringUtils.removeHtmlTags(this);

  /// 反转字符串
  String get reversed => StringUtils.reverse(this);

  /// 是否包含中文字符
  bool get containsChinese => StringUtils.containsChinese(this);

  /// 是否为纯中文
  bool get isAllChinese => StringUtils.isAllChinese(this);

  /// 获取字节长度（中文算2个字节）
  int get byteLength => StringUtils.getByteLength(this);

  /// 是否为邮箱格式
  bool get isEmail => StringUtils.isEmail(this);

  /// 是否为手机号格式
  bool get isPhoneNumber => StringUtils.isPhoneNumber(this);

  /// 是否为数字
  bool get isNumeric => StringUtils.isNumeric(this);

  /// 是否为整数
  bool get isInteger => StringUtils.isInteger(this);

  /// 是否为URL
  bool get isUrl => StringUtils.isUrl(this);

  /// 截断字符串
  String truncate(int maxLength, {String suffix = '...'}) {
    return StringUtils.truncate(this, maxLength, suffix: suffix);
  }

  /// 脱敏手机号
  String get maskedPhone => StringUtils.maskPhoneNumber(this);

  /// 脱敏邮箱
  String get maskedEmail => StringUtils.maskEmail(this);

  /// 转换为日期（使用 yyyy-MM-dd 格式）
  DateTime? toDate() {
    return date_utils.DateUtils.parseDate(this);
  }

  /// 转换为日期时间（使用 yyyy-MM-dd HH:mm 格式）
  DateTime? toDateTime() {
    return date_utils.DateUtils.parseDateTime(this);
  }

  /// 转换为整数
  int? toInt() {
    return int.tryParse(this);
  }

  /// 转换为浮点数
  double? toDouble() {
    return double.tryParse(this);
  }

  /// 如果为空则返回默认值
  String orDefault(String defaultValue) {
    return StringUtils.defaultIfEmpty(this, defaultValue);
  }

  /// 重复字符串
  String repeat(int times) {
    return List.filled(times, this).join();
  }

  /// 是否以指定字符串开头（忽略大小写）
  bool startsWithIgnoreCase(String prefix) {
    return toLowerCase().startsWith(prefix.toLowerCase());
  }

  /// 是否以指定字符串结尾（忽略大小写）
  bool endsWithIgnoreCase(String suffix) {
    return toLowerCase().endsWith(suffix.toLowerCase());
  }

  /// 是否包含指定字符串（忽略大小写）
  bool containsIgnoreCase(String other) {
    return toLowerCase().contains(other.toLowerCase());
  }

  /// 安全的子字符串（不会抛出异常）
  String safeSubstring(int start, [int? end]) {
    if (start < 0 || start >= length) return this;
    if (end != null && end > length) {
      return substring(start);
    }
    return substring(start, end);
  }
}

/// 可空String扩展
extension NullableStringExtensions on String? {
  /// 是否为空
  bool get isNullOrEmpty => StringUtils.isEmpty(this);

  /// 是否不为空
  bool get isNotNullOrEmpty => StringUtils.isNotEmpty(this);

  /// 是否为空白
  bool get isNullOrBlank => StringUtils.isBlank(this);

  /// 是否不为空白
  bool get isNotNullOrBlank => StringUtils.isNotBlank(this);

  /// 如果为空则返回默认值
  String orDefault(String defaultValue) {
    return StringUtils.defaultIfEmpty(this, defaultValue);
  }

  /// 安全转换为整数
  int? toIntOrNull() {
    if (this == null) return null;
    return int.tryParse(this!);
  }

  /// 安全转换为浮点数
  double? toDoubleOrNull() {
    if (this == null) return null;
    return double.tryParse(this!);
  }
}
