import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/features/coach/students/data/models/student_list_item_model.dart';
import '../../data/models/plan_base_model.dart';
import '../providers/plans_providers.dart';
import 'student_selection_list.dart';

/// 分配计划对话框
class AssignPlanDialog extends ConsumerStatefulWidget {
  final PlanBaseModel plan;

  const AssignPlanDialog({
    super.key,
    required this.plan,
  });

  @override
  ConsumerState<AssignPlanDialog> createState() => _AssignPlanDialogState();
}

class _AssignPlanDialogState extends ConsumerState<AssignPlanDialog> {
  List<StudentSelectionItem> _students = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  /// 加载学生列表
  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(planRepositoryProvider);
      final students = await repository.fetchStudentsForAssignment(
        widget.plan.id,
        widget.plan.planType,
      );

      // 构建选择项列表
      final items = students.map((student) {
        final hasCurrentPlan =
            widget.plan.studentIds.contains(student.id);
        final hasConflictPlan = _checkConflictPlan(student);

        return StudentSelectionItem(
          student: student,
          isSelected: hasCurrentPlan, // 已分配的默认选中
          hasCurrentPlan: hasCurrentPlan,
          hasConflictPlan: hasConflictPlan,
        );
      }).toList();

      setState(() {
        _students = items;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('加载学生列表失败: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 检查学生是否有同类计划冲突
  bool _checkConflictPlan(StudentListItemModel student) {
      switch (widget.plan.planType) {
      case 'exercise':
        return student.exercisePlan != null &&
            student.exercisePlan!.id != widget.plan.id;
      case 'diet':
        return student.dietPlan != null &&
            student.dietPlan!.id != widget.plan.id;
      case 'supplement':
        return student.supplementPlan != null &&
            student.supplementPlan!.id != widget.plan.id;
      default:
        return false;
    }
  }

  /// 切换学生选择状态
  void _toggleStudent(String studentId) {
    setState(() {
      final index = _students.indexWhere((item) => item.student.id == studentId);
      if (index != -1) {
        _students[index] = _students[index].copyWith(
          isSelected: !_students[index].isSelected,
        );
      }
    });
  }

  /// 获取已选中的学生
  List<StudentSelectionItem> get _selectedStudents {
    return _students.where((item) => item.isSelected).toList();
  }

  /// 获取有冲突的已选中学生
  List<StudentSelectionItem> get _conflictStudents {
    return _selectedStudents
        .where((item) => item.hasConflictPlan && !item.hasCurrentPlan)
        .toList();
  }

  /// 保存分配
  Future<void> _handleSave() async {
    final selectedStudents = _selectedStudents;
    final conflictStudents = _conflictStudents;

    // 检查是否有冲突
    if (conflictStudents.isNotEmpty && mounted) {
      final confirmed = await _showConflictWarning(conflictStudents);
      if (!confirmed) return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 计算需要分配和取消分配的学生
      final originalAssignedIds = widget.plan.studentIds.toSet();
      final newAssignedIds = selectedStudents.map((item) => item.student.id).toSet();

      final toAssign = newAssignedIds.difference(originalAssignedIds).toList();
      final toUnassign = originalAssignedIds.difference(newAssignedIds).toList();

      // 执行分配
      if (toAssign.isNotEmpty) {
        await ref.read(plansNotifierProvider.notifier).assignPlan(
              planId: widget.plan.id,
              planType: widget.plan.planType,
              studentIds: toAssign,
              unassign: false,
            );
      }

      // 执行取消分配
      if (toUnassign.isNotEmpty) {
        await ref.read(plansNotifierProvider.notifier).assignPlan(
              planId: widget.plan.id,
              planType: widget.plan.planType,
              studentIds: toUnassign,
              unassign: true,
            );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        _showSuccessMessage();
      }
    } catch (e) {
      AppLogger.error('分配计划失败: $e');
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 显示冲突警告
  Future<bool> _showConflictWarning(List<StudentSelectionItem> conflicts) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('覆盖现有计划'),
        content: Text(
          '${conflicts.length}位学生已有同类计划，是否覆盖？\n\n'
          '${conflicts.map((item) => item.student.name).join(', ')}',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('覆盖'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// 显示成功提示
  void _showSuccessMessage() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('成功'),
        content: const Text('计划分配成功'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示错误提示
  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        middle: Text('分配 ${widget.plan.name}'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : const Text('完成'),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 搜索栏
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                placeholder: 'Search students',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.textPrimary,
                ),
                placeholderStyle: AppTextStyles.callout.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            // 学生列表
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _loadStudents,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Text(
          'No students available',
          style: AppTextStyles.callout.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return StudentSelectionList(
      students: _students,
      onToggleStudent: _toggleStudent,
      searchQuery: _searchQuery,
    );
  }
}

