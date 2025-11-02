import 'package:flutter/cupertino.dart';

/// CoachX 应用颜色定义
/// 定义了应用中使用的所有颜色常量
class AppColors {
  AppColors._(); // 私有构造函数，防止实例化

  // ==================== 主色系 ====================
  /// 主色调 - 温暖米黄色
  static const Color primaryColor = Color(0xFFF2E8CF);

  /// 主色文字
  static const Color primaryText = Color(0xFF6B5E3F);

  /// 主色浅色背景
  static const Color primaryLight = Color(0xFFFDFAF3);

  /// 主色交互色
  static const Color primaryAction = Color.fromRGBO(235, 206, 137, 0.5);

  // 别名（用于简化使用）
  static const Color primary = Color(0xFFf0e9d8);// 主要交互色
  static const Color primaryDark = Color(0xFF3D3424); // 主要交互色深色版

  // ==================== 辅助色系 ====================
  /// 辅助蓝色
  static const Color secondaryBlue = Color.fromRGBO(89, 165, 216, 1);

  static const Color secondaryOrange = Color.fromARGB(255, 178, 138, 83);

  static const Color secondaryRed = Color.fromARGB(255, 220, 108, 108);

  static const Color secondaryPurple = Color.fromARGB(255, 207, 134, 222);


  /// 辅助灰色
  static const Color secondaryGrey = Color(0xFFA0A0A0);

  /// 深灰蓝
  static const Color secondaryDarkGrey = Color(0xFF7F8C8D);

  /// 中灰色
  static const Color secondaryMediumGrey = Color(0xFF95A5A6);

  // ==================== 文字颜色 ====================
  /// 主要文字颜色
  static const Color textPrimary = Color(0xFF1F2937);

  /// 次要文字颜色
  static const Color textSecondary = Color(0xFF4B5563);

  /// 三级文字颜色
  static const Color textTertiary = Color(0xFF6B7280);

  /// 白色文字
  static const Color textWhite = Color(0xFFFFFFFF);

  // ==================== 背景颜色 ====================
  /// 浅色背景
  static const Color backgroundLight = Color(0xFFF7F7F7);

  /// 白色背景
  static const Color backgroundWhite = Color(0xFFFFFFFF);

  /// 卡片背景
  static const Color backgroundCard = Color(0xFFFFFFFF);

  /// 次级背景
  static const Color backgroundSecondary = Color(0xFFF3F4F6);

  // ==================== 边框颜色 ====================
  /// 边框颜色
  static const Color borderColor = Color(0xFFE5E7EB);

  // ==================== 功能色 ====================
  /// 成功/完成 - 绿色
  static const Color successGreen = Color(0xFF10B981);
  static const Color success = successGreen; // 别名

  /// 警告 - 黄色
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color warning = warningYellow; // 别名

  /// 错误 - 红色
  static const Color errorRed = Color(0xFFEF4444);
  static const Color error = errorRed; // 别名

  /// 信息 - 蓝色
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color info = infoBlue; // 别名

  // ==================== 分割线 ====================
  /// 浅色分割线
  static const Color dividerLight = Color(0xFFE5E7EB);

  /// 中度分割线
  static const Color dividerMedium = Color(0xFFD1D5DB);

  // ==================== 常用别名 ====================
  /// 分割线（默认浅色）
  static const Color divider = dividerLight;

  /// 卡片背景（默认白色）
  static const Color cardBackground = backgroundCard;

  /// 背景色（默认浅色）
  static const Color background = backgroundLight;

  /// 阴影颜色
  static const Color shadowColor = Color(0xFF000000);

  /// 成功颜色（别名）
  static const Color successColor = successGreen;
}
