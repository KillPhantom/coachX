import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/student_detail_model.dart';
import '../../data/repositories/student_detail_repository.dart';
import '../../data/repositories/student_detail_repository_impl.dart';
import '../../data/repositories/ai_summary_repository.dart';
import '../../data/repositories/ai_summary_repository_impl.dart';

/// Repository Provider
final studentDetailRepositoryProvider = Provider<StudentDetailRepository>((
  ref,
) {
  return StudentDetailRepositoryImpl();
});

/// AI Summary Repository Provider
final aiSummaryRepositoryProvider = Provider<AISummaryRepository>((ref) {
  return AISummaryRepositoryImpl();
});

/// 时间范围选择Provider（用于Weight Chart）
final selectedTimeRangeProvider = StateProvider<String>((ref) => '3M');

/// 学生详情Provider（固定时间范围，不watch selectedTimeRangeProvider）
final studentDetailProvider = FutureProvider.family<StudentDetailModel, String>(
  (ref, studentId) async {
    final repository = ref.watch(studentDetailRepositoryProvider);

    // 使用固定的默认时间范围 '3M'，不watch selectedTimeRangeProvider
    // 这样时间范围改变时不会触发整个页面reload
    return repository.fetchStudentDetail(studentId: studentId, timeRange: '3M');
  },
);

/// 独立的体重趋势Provider（支持动态时间范围）
/// 使用 tuple (String, String) 作为参数: (studentId, timeRange)
final weightTrendProvider =
    FutureProvider.family<WeightTrend, (String, String)>((ref, params) async {
      final (studentId, timeRange) = params;
      final repository = ref.watch(studentDetailRepositoryProvider);

      // 获取完整的学生详情数据（包含weightTrend）
      final studentDetail = await repository.fetchStudentDetail(
        studentId: studentId,
        timeRange: timeRange,
      );

      // 仅返回weightTrend部分
      return studentDetail.weightTrend;
    });

// ==================== AI Summary Providers ====================

/// AI Summary 缓存Provider（按学生ID缓存）
final aiSummaryCacheProvider = StateProvider.family<AISummary?, String>(
  (ref, studentId) => null,
);

/// AI Summary 生成状态Provider（按学生ID跟踪loading状态）
final isGeneratingAISummaryProvider = StateProvider.family<bool, String>(
  (ref, studentId) => false,
);

/// AI Summary 生成Provider
/// 参数: Map<String, String> {'studentId': String, 'timeRange': String}
final generateAISummaryProvider =
    FutureProvider.family<AISummary, Map<String, String>>((ref, params) async {
      final studentId = params['studentId']!;
      final timeRange = params['timeRange'] ?? '3M';

      final repository = ref.watch(aiSummaryRepositoryProvider);
      return repository.generateAISummary(
        studentId: studentId,
        timeRange: timeRange,
      );
    });
