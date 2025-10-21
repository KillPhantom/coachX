import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

// 导出所有主题相关的类，方便统一导入
export 'app_colors.dart';
export 'app_text_styles.dart';
export 'app_dimensions.dart';

/// CoachX 应用主题配置
/// 提供统一的主题配置入口
class AppTheme {
  AppTheme._(); // 私有构造函数，防止实例化

  /// 浅色主题（当前唯一支持的主题）
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      // 主色调配置
      primaryColor: AppColors.primaryColor,
      primaryContrastingColor: AppColors.primaryText,

      // 背景色配置
      scaffoldBackgroundColor: AppColors.backgroundLight,
      barBackgroundColor: AppColors.backgroundWhite,

      // 文字主题
      textTheme: CupertinoTextThemeData(
        textStyle: AppTextStyles.body,
        actionTextStyle: AppTextStyles.buttonMedium,
        navTitleTextStyle: AppTextStyles.navTitle,
        navLargeTitleTextStyle: AppTextStyles.navLargeTitle,
        tabLabelTextStyle: AppTextStyles.tabLabel,
      ),

      // iOS风格亮度
      brightness: Brightness.light,
    );
  }

  /// 获取带毛玻璃效果的导航栏背景色
  static Color get navBarBackgroundBlur {
    return AppColors.backgroundWhite.withValues(alpha: 0.9);
  }

  /// 获取带毛玻璃效果的Tab栏背景色
  static Color get tabBarBackgroundBlur {
    return AppColors.backgroundWhite.withValues(alpha: 0.9);
  }

  /// 导航栏边框
  static Border get navBarBorder {
    return const Border(
      bottom: BorderSide(color: AppColors.dividerLight, width: 0.5),
    );
  }

  /// Tab栏边框
  static Border get tabBarBorder {
    return const Border(
      top: BorderSide(color: AppColors.dividerLight, width: 0.5),
    );
  }
}
