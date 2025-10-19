/// 字符串工具类
class StringUtils {
  StringUtils._(); // 私有构造函数，防止实例化

  /// 判断字符串是否为空（null或空字符串）
  static bool isEmpty(String? str) {
    return str == null || str.isEmpty;
  }

  /// 判断字符串是否不为空
  static bool isNotEmpty(String? str) {
    return !isEmpty(str);
  }

  /// 判断字符串是否为空或只包含空白字符
  static bool isBlank(String? str) {
    return str == null || str.trim().isEmpty;
  }

  /// 判断字符串是否不为空且不只包含空白字符
  static bool isNotBlank(String? str) {
    return !isBlank(str);
  }

  /// 验证邮箱格式
  static bool isEmail(String str) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(str);
  }

  /// 验证手机号格式（中国大陆）
  static bool isPhoneNumber(String str) {
    final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
    return phoneRegex.hasMatch(str);
  }

  /// 验证是否为纯数字
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  /// 验证是否为整数
  static bool isInteger(String str) {
    return int.tryParse(str) != null;
  }

  /// 截断字符串
  /// @param str 原字符串
  /// @param maxLength 最大长度
  /// @param suffix 后缀（默认为'...'）
  static String truncate(String str, int maxLength, {String suffix = '...'}) {
    if (str.length <= maxLength) {
      return str;
    }
    return str.substring(0, maxLength) + suffix;
  }

  /// 首字母大写
  static String capitalize(String str) {
    if (isEmpty(str)) return '';
    return str[0].toUpperCase() + str.substring(1);
  }

  /// 首字母小写
  static String uncapitalize(String str) {
    if (isEmpty(str)) return '';
    return str[0].toLowerCase() + str.substring(1);
  }

  /// 转换为驼峰命名（camelCase）
  static String toCamelCase(String str) {
    if (isEmpty(str)) return '';
    final words = str.split(RegExp(r'[_\s-]+'));
    if (words.isEmpty) return '';

    final result = StringBuffer(words[0].toLowerCase());
    for (var i = 1; i < words.length; i++) {
      result.write(capitalize(words[i].toLowerCase()));
    }
    return result.toString();
  }

  /// 转换为蛇形命名（snake_case）
  static String toSnakeCase(String str) {
    if (isEmpty(str)) return '';
    return str
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'[_\s-]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// 移除所有空白字符
  static String removeWhitespace(String str) {
    return str.replaceAll(RegExp(r'\s+'), '');
  }

  /// 移除HTML标签
  static String removeHtmlTags(String str) {
    return str.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// 反转字符串
  static String reverse(String str) {
    return str.split('').reversed.join('');
  }

  /// 检查是否包含中文字符
  static bool containsChinese(String str) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(str);
  }

  /// 检查是否为纯中文
  static bool isAllChinese(String str) {
    return RegExp(r'^[\u4e00-\u9fa5]+$').hasMatch(str);
  }

  /// 获取字符串字节长度（中文算2个字节）
  static int getByteLength(String str) {
    int length = 0;
    for (int i = 0; i < str.length; i++) {
      final code = str.codeUnitAt(i);
      if (code > 0xFF) {
        length += 2; // 中文等双字节字符
      } else {
        length += 1; // 英文等单字节字符
      }
    }
    return length;
  }

  /// 脱敏手机号（保留前3位和后4位）
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 11) return phoneNumber;
    return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(7)}';
  }

  /// 脱敏邮箱（保留前2位和@后的内容）
  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    if (username.length <= 2) return email;
    return '${username.substring(0, 2)}***@${parts[1]}';
  }

  /// 生成随机字符串
  static String randomString(int length, {bool includeNumbers = true}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    final pool = includeNumbers ? chars + numbers : chars;

    return List.generate(
      length,
      (index) =>
          pool[(DateTime.now().microsecondsSinceEpoch + index) % pool.length],
    ).join();
  }

  /// 将数字转换为千分位格式
  static String formatNumberWithCommas(num number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  /// 判断是否为URL
  static bool isUrl(String str) {
    final urlRegex = RegExp(
      r'^(http|https):\/\/([\w.]+\/?)\S*$',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(str);
  }

  /// 默认值处理（如果为空则返回默认值）
  static String defaultIfEmpty(String? str, String defaultValue) {
    return isEmpty(str) ? defaultValue : str!;
  }
}
