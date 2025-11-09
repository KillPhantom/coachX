import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../../data/models/students_page_state.dart';
import '../../data/models/student_list_item_model.dart';
import '../../data/repositories/student_repository.dart';

/// 学生列表状态管理
class StudentsNotifier extends StateNotifier<StudentsPageState> {
  final StudentRepository _repository;
  static const int _pageSize = 20;

  StudentsNotifier(this._repository) : super(StudentsPageState.initial());

  /// 初始加载
  Future<void> loadStudents() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.fetchStudents(
        pageSize: _pageSize,
        pageNumber: 1,
        searchName: state.searchQuery,
        filterPlanId: state.filterPlanId,
        includePlans: true, // ✅ 明确传入，确保返回计划信息
      );

      state = state.copyWith(
        students: result.students,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoading: false,
      );

      AppLogger.info('学生列表加载成功: ${result.students.length}个学生');
    } catch (e, stackTrace) {
      AppLogger.error('加载学生列表失败', e, stackTrace);
      state = state.copyWith(isLoading: false, error: '加载失败: ${e.toString()}');
    }
  }

  /// 加载更多（分页）
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.fetchStudents(
        pageSize: _pageSize,
        pageNumber: nextPage,
        searchName: state.searchQuery,
        filterPlanId: state.filterPlanId,
        includePlans: true, // ✅ 明确传入，确保返回计划信息
      );

      // 追加到现有列表
      final updatedStudents = [...state.students, ...result.students];

      state = state.copyWith(
        students: updatedStudents,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );

      AppLogger.info('加载更多成功: 新增${result.students.length}个学生');
    } catch (e, stackTrace) {
      AppLogger.error('加载更多失败', e, stackTrace);
      state = state.copyWith(
        isLoadingMore: false,
        error: '加载更多失败: ${e.toString()}',
      );
    }
  }

  /// 搜索
  Future<void> search(String query) async {
    AppLogger.info('搜索学生: $query');

    state = state.copyWith(
      searchQuery: query.trim(),
      students: [], // 清空现有列表
      currentPage: 1,
    );

    await loadStudents();
  }

  /// 筛选
  Future<void> filter(String? planId) async {
    AppLogger.info('筛选学生: $planId');

    state = state.copyWith(
      filterPlanId: planId,
      students: [], // 清空现有列表
      currentPage: 1,
    );

    await loadStudents();
  }

  /// 清除筛选条件
  Future<void> clearFilter() async {
    AppLogger.info('清除筛选');

    state = state.copyWith(
      clearSearch: true,
      clearFilter: true,
      students: [],
      currentPage: 1,
    );

    await loadStudents();
  }

  /// 刷新
  Future<void> refresh() async {
    AppLogger.info('刷新学生列表');

    // 重置状态并重新加载
    state = state.copyWith(
      students: [],
      currentPage: 1,
      isLoading: false, // 确保isLoading为false，否则loadStudents会直接return
      clearError: true,
    );

    await loadStudents();
  }

  /// 删除学生
  Future<void> deleteStudent(String studentId) async {
    try {
      AppLogger.info('删除学生: $studentId');

      await _repository.deleteStudent(studentId);

      // 从列表中移除
      final updatedStudents = state.students
          .where((student) => student.id != studentId)
          .toList();

      state = state.copyWith(
        students: updatedStudents,
        totalCount: state.totalCount - 1,
      );

      AppLogger.info('删除学生成功');
    } catch (e, stackTrace) {
      AppLogger.error('删除学生失败', e, stackTrace);
      rethrow; // 让UI层处理错误提示
    }
  }

  /// 从列表中移除学生（本地更新，不调用API）
  void removeStudentLocally(String studentId) {
    final updatedStudents = state.students
        .where((student) => student.id != studentId)
        .toList();

    state = state.copyWith(
      students: updatedStudents,
      totalCount: state.totalCount - 1,
    );
  }
}
