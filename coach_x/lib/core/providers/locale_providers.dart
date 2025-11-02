import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/features/auth/data/providers/user_providers.dart';

/// 语言代码 Provider
///
/// 从当前用户的 languageCode 字段获取语言偏好
/// 如果用户未设置，返回 null（将使用系统默认语言）
final languageCodeProvider = Provider<String?>((ref) {
  final userData = ref.watch(currentUserDataProvider);
  return userData.when(
    data: (user) => user?.languageCode,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// 当前 Locale Provider
///
/// 将 languageCode 转换为 Locale 对象
/// 支持的语言：
/// - 'en' or 'en_US' → Locale('en', 'US')
/// - 'zh' or 'zh_CN' → Locale('zh', 'CN')
/// - null → 使用系统默认语言
final currentLocaleProvider = Provider<Locale?>((ref) {
  final languageCode = ref.watch(languageCodeProvider);

  if (languageCode == null || languageCode.isEmpty) {
    // 返回 null，app.dart 会使用系统默认语言
    return null;
  }

  // 支持 'zh' 或 'zh_CN' 格式
  if (languageCode.startsWith('zh')) {
    return const Locale('zh', 'CN');
  }

  // 支持 'en' 或 'en_US' 格式
  if (languageCode.startsWith('en')) {
    return const Locale('en', 'US');
  }

  // 默认返回英文
  return const Locale('en', 'US');
});

/// 语言显示名称 Provider
///
/// 返回当前语言的显示名称（用于UI展示）
final languageDisplayNameProvider = Provider<String>((ref) {
  final languageCode = ref.watch(languageCodeProvider);

  // 如果用户已设置语言
  if (languageCode != null && languageCode.isNotEmpty) {
    if (languageCode.startsWith('zh')) {
      return '中文';
    }
    return 'English';
  }

  // 如果未设置，默认显示 English（因为我们无法在 Provider 中可靠访问系统语言）
  // 实际语言会由系统自动选择
  return 'English';
});
