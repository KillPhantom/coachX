import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

/// CoachX 应用文字样式定义
/// 定义了应用中使用的所有文字样式
/// 当前使用iOS系统默认字体（SF Pro）
/// TODO: 下载Lexend字体文件后，取消注释下方的_fontFamily配置
class AppTextStyles {
  AppTextStyles._(); // 私有构造函数，防止实例化

  // 字体家族名称
  // static const String _fontFamily = 'Lexend'; // 未下载字体时注释掉
  static const String? _fontFamily =
      null; // 使用系统默认字体（iOS: SF Pro, Android: Roboto）

  // ==================== 标题样式 ====================

  /// 超大标题 - 34px, Bold
  static const TextStyle largeTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// 标题1 - 28px, Bold
  static const TextStyle title1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 标题2 - 22px, Bold
  static const TextStyle title2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// 标题3 - 20px, SemiBold
  static const TextStyle title3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ==================== 正文样式 ====================

  /// 正文 - 17px, Regular
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 正文中等 - 17px, Medium
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 正文加粗 - 17px, SemiBold
  static const TextStyle bodySemiBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// 突出显示 - 16px, Regular
  static const TextStyle callout = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ==================== 辅助样式 ====================

  /// 副标题 - 15px, Regular
  static const TextStyle subhead = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  /// 脚注 - 13px, Regular
  static const TextStyle footnote = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// 说明文字1 - 12px, Regular
  static const TextStyle caption1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.4,
  );

  /// 说明文字2 - 11px, Regular
  static const TextStyle caption2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.3,
  );

  // ==================== 按钮样式 ====================

  /// 大按钮文字 - 17px, SemiBold
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 中按钮文字 - 15px, SemiBold
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// 小按钮文字 - 13px, Medium
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // ==================== 导航栏样式 ====================

  /// 导航栏标题 - 17px, SemiBold
  static const TextStyle navTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// 导航栏大标题 - 34px, Bold
  static const TextStyle navLargeTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // ==================== Tab栏样式 ====================

  /// Tab标签 - 10px, Medium
  static const TextStyle tabLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
