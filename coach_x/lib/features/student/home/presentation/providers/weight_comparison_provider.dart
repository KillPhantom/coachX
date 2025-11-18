import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/services/auth_service.dart';
import 'package:coach_x/features/student/home/data/models/weight_comparison_model.dart';
import 'package:coach_x/features/student/home/data/repositories/weight_repository.dart';
import 'package:coach_x/features/student/home/data/repositories/weight_repository_impl.dart';

/// 体重仓库 Provider
final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepositoryImpl();
});

/// 体重对比 Provider
///
/// 获取最近两条体重记录的对比信息
final weightComparisonProvider = FutureProvider<WeightComparisonResult>((
  ref,
) async {
  final repository = ref.watch(weightRepositoryProvider);
  final userId = AuthService.currentUserId;

  if (userId == null) {
    return WeightComparisonResult.empty();
  }

  // 获取最近 10 条记录
  final measurements = await repository.getRecentMeasurements(
    studentId: userId,
    limit: 10,
  );

  // 计算相对变化
  return repository.calculateRelativeChange(measurements);
});
