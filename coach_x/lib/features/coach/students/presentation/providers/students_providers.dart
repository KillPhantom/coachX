import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/students_page_state.dart';
import '../../data/models/invitation_code_model.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/student_repository_impl.dart';
import '../../data/repositories/invitation_code_repository.dart';
import '../../data/repositories/invitation_code_repository_impl.dart';
import 'students_notifier.dart';

// ==================== Repository Providers ====================

/// 学生Repository Provider
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepositoryImpl();
});

/// 邀请码Repository Provider
final invitationCodeRepositoryProvider = Provider<InvitationCodeRepository>((
  ref,
) {
  return InvitationCodeRepositoryImpl();
});

// ==================== State Providers ====================

/// 学生列表状态Provider
final studentsStateProvider =
    StateNotifierProvider<StudentsNotifier, StudentsPageState>((ref) {
      final repository = ref.watch(studentRepositoryProvider);
      return StudentsNotifier(repository);
    });

/// 邀请码列表Provider
final invitationCodesProvider =
    FutureProvider.autoDispose<List<InvitationCodeModel>>((ref) async {
      final repository = ref.watch(invitationCodeRepositoryProvider);
      return repository.fetchInvitationCodes();
    });

/// 可用计划列表Provider
final availablePlansProvider =
    FutureProvider.autoDispose<Map<String, List<Map<String, String>>>>((
      ref,
    ) async {
      final repository = ref.watch(studentRepositoryProvider);
      return repository.fetchAvailablePlans();
    });
