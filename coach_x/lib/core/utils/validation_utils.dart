import '../constants/app_constants.dart';
import 'string_utils.dart';

/// 验证工具类
/// 提供各种表单验证方法，返回错误信息或null
class ValidationUtils {
  ValidationUtils._(); // 私有构造函数，防止实例化

  /// 验证必填项
  static String? validateRequired(String? value, {String fieldName = '此项'}) {
    if (StringUtils.isBlank(value)) {
      return '$fieldName不能为空';
    }
    return null;
  }

  /// 验证邮箱
  static String? validateEmail(String? value, {bool required = true}) {
    if (!required && StringUtils.isEmpty(value)) {
      return null;
    }

    if (StringUtils.isEmpty(value)) {
      return '邮箱不能为空';
    }

    if (!StringUtils.isEmail(value!)) {
      return '请输入有效的邮箱地址';
    }

    return null;
  }

  /// 验证手机号
  static String? validatePhone(String? value, {bool required = true}) {
    if (!required && StringUtils.isEmpty(value)) {
      return null;
    }

    if (StringUtils.isEmpty(value)) {
      return '手机号不能为空';
    }

    if (!StringUtils.isPhoneNumber(value!)) {
      return '请输入有效的手机号';
    }

    return null;
  }

  /// 验证密码
  /// 要求：长度在6-20之间
  static String? validatePassword(String? value) {
    if (StringUtils.isEmpty(value)) {
      return '密码不能为空';
    }

    if (value!.length < AppConstants.minPasswordLength) {
      return '密码长度不能少于${AppConstants.minPasswordLength}位';
    }

    if (value.length > AppConstants.maxPasswordLength) {
      return '密码长度不能超过${AppConstants.maxPasswordLength}位';
    }

    return null;
  }

  /// 验证密码强度
  /// 要求：至少包含字母和数字
  static String? validatePasswordStrength(String? value) {
    final basicValidation = validatePassword(value);
    if (basicValidation != null) {
      return basicValidation;
    }

    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value!);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);

    if (!hasLetter || !hasNumber) {
      return '密码必须包含字母和数字';
    }

    return null;
  }

  /// 验证确认密码
  static String? validateConfirmPassword(String? value, String? password) {
    if (StringUtils.isEmpty(value)) {
      return '确认密码不能为空';
    }

    if (value != password) {
      return '两次输入的密码不一致';
    }

    return null;
  }

  /// 验证用户名
  /// 要求：长度在2-20之间
  static String? validateUsername(String? value) {
    if (StringUtils.isEmpty(value)) {
      return '用户名不能为空';
    }

    if (value!.length < AppConstants.minUsernameLength) {
      return '用户名长度不能少于${AppConstants.minUsernameLength}位';
    }

    if (value.length > AppConstants.maxUsernameLength) {
      return '用户名长度不能超过${AppConstants.maxUsernameLength}位';
    }

    return null;
  }

  /// 验证长度
  static String? validateLength(
    String? value, {
    required int min,
    required int max,
    String fieldName = '内容',
  }) {
    if (StringUtils.isEmpty(value)) {
      return '$fieldName不能为空';
    }

    if (value!.length < min) {
      return '$fieldName长度不能少于$min位';
    }

    if (value.length > max) {
      return '$fieldName长度不能超过$max位';
    }

    return null;
  }

  /// 验证数字范围
  static String? validateNumberRange(
    String? value, {
    required num min,
    required num max,
    String fieldName = '数值',
  }) {
    if (StringUtils.isEmpty(value)) {
      return '$fieldName不能为空';
    }

    final number = num.tryParse(value!);
    if (number == null) {
      return '请输入有效的数字';
    }

    if (number < min || number > max) {
      return '$fieldName必须在$min-$max之间';
    }

    return null;
  }

  /// 验证整数
  static String? validateInteger(String? value, {String fieldName = '数值'}) {
    if (StringUtils.isEmpty(value)) {
      return '$fieldName不能为空';
    }

    if (!StringUtils.isInteger(value!)) {
      return '请输入有效的整数';
    }

    return null;
  }

  /// 验证正整数
  static String? validatePositiveInteger(String? value, {String fieldName = '数值'}) {
    final intValidation = validateInteger(value, fieldName: fieldName);
    if (intValidation != null) {
      return intValidation;
    }

    if (int.parse(value!) <= 0) {
      return '$fieldName必须大于0';
    }

    return null;
  }

  /// 验证小数
  static String? validateDecimal(String? value, {String fieldName = '数值'}) {
    if (StringUtils.isEmpty(value)) {
      return '$fieldName不能为空';
    }

    if (!StringUtils.isNumeric(value!)) {
      return '请输入有效的数字';
    }

    return null;
  }

  /// 验证邀请码
  static String? validateInvitationCode(String? value) {
    if (StringUtils.isEmpty(value)) {
      return '邀请码不能为空';
    }

    if (value!.length != AppConstants.invitationCodeLength) {
      return '邀请码长度必须为${AppConstants.invitationCodeLength}位';
    }

    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return '邀请码只能包含大写字母和数字';
    }

    return null;
  }

  /// 验证URL
  static String? validateUrl(String? value, {bool required = true}) {
    if (!required && StringUtils.isEmpty(value)) {
      return null;
    }

    if (StringUtils.isEmpty(value)) {
      return 'URL不能为空';
    }

    if (!StringUtils.isUrl(value!)) {
      return '请输入有效的URL';
    }

    return null;
  }

  /// 验证身高（单位：cm）
  static String? validateHeight(String? value) {
    return validateNumberRange(value, min: 50, max: 250, fieldName: '身高');
  }

  /// 验证体重（单位：kg）
  static String? validateWeight(String? value) {
    return validateNumberRange(value, min: 20, max: 300, fieldName: '体重');
  }

  /// 验证年龄
  static String? validateAge(String? value) {
    return validateNumberRange(value, min: 1, max: 150, fieldName: '年龄');
  }

  /// 通用验证组合器
  /// 可以组合多个验证器
  static String? compose(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
