import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository.dart';
import 'package:coach_x/features/auth/data/repositories/user_repository_impl.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import 'package:coach_x/features/chat/data/repositories/feedback_repository.dart';
import 'package:coach_x/features/chat/data/repositories/feedback_repository_impl.dart';
import 'package:coach_x/features/chat/data/repositories/daily_training_repository.dart';
import 'package:coach_x/features/chat/data/repositories/daily_training_repository_impl.dart';

/// 全局Providers配置
/// 用于管理应用级的状态和依赖

/// 用户仓库Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

/// 训练反馈仓库Provider
final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl();
});

/// 每日训练记录仓库Provider
final dailyTrainingRepositoryProvider = Provider<DailyTrainingRepository>((
  ref,
) {
  return DailyTrainingRepositoryImpl();
});

/// 当前用户Provider (监听Firestore)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userId = AuthService.currentUserId;
  if (userId == null) {
    return Stream.value(null);
  }

  final repo = ref.read(userRepositoryProvider);
  return repo.watchUser(userId);
});

/// 日志Provider（预留）
/// TODO: 实现日志Provider

/// 主题Provider（预留）
/// TODO: 实现主题切换Provider
