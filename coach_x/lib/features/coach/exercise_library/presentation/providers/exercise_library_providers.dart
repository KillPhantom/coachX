import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise_library_state.dart';
import '../../data/models/exercise_template_model.dart';
import '../../data/models/exercise_tag_model.dart';
import '../../data/repositories/exercise_library_repository.dart';
import '../../data/repositories/exercise_library_repository_impl.dart';
import 'exercise_library_notifier.dart';
import '../../../../../core/services/auth_service.dart';

/// Repository Provider
final exerciseLibraryRepositoryProvider = Provider<ExerciseLibraryRepository>((
  ref,
) {
  return ExerciseLibraryRepositoryImpl();
});

/// State Notifier Provider
final exerciseLibraryNotifierProvider =
    StateNotifierProvider<ExerciseLibraryNotifier, ExerciseLibraryState>((ref) {
      final repository = ref.watch(exerciseLibraryRepositoryProvider);
      final coachId = AuthService.currentUserId ?? '';

      return ExerciseLibraryNotifier(repository, coachId);
    });

/// 派生 Provider: 获取所有动作模板
final exerciseTemplatesProvider = Provider<List<ExerciseTemplateModel>>((ref) {
  final state = ref.watch(exerciseLibraryNotifierProvider);
  return state.getFilteredTemplates();
});

/// 派生 Provider: 获取所有标签
final exerciseTagsProvider = Provider<List<ExerciseTagModel>>((ref) {
  final state = ref.watch(exerciseLibraryNotifierProvider);
  return state.tags;
});

/// 派生 Provider: 动作库数量（用于 Profile 页面显示）
final exerciseLibraryCountProvider = Provider<int>((ref) {
  final state = ref.watch(exerciseLibraryNotifierProvider);
  return state.templates.length;
});

/// 派生 Provider: 加载状态
final exerciseLibraryLoadingStatusProvider = Provider<LoadingStatus>((ref) {
  final state = ref.watch(exerciseLibraryNotifierProvider);
  return state.loadingStatus;
});
