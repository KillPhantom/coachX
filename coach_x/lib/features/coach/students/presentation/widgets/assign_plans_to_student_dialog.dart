import 'package:flutter/cupertino.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/widgets/loading_indicator.dart';
import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import '../../data/models/student_list_item_model.dart';
import '../../data/models/plan_summary.dart';
import '../../data/models/plan_assignment_state.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/repositories/student_repository_impl.dart';
import 'plan_type_section.dart';

/// 分配计划给学生对话框
///
/// 用于从学生列表为单个学生分配三类计划（训练+饮食+补剂）
class AssignPlansToStudentDialog extends StatefulWidget {
  final StudentListItemModel student;

  const AssignPlansToStudentDialog({super.key, required this.student});

  @override
  State<AssignPlansToStudentDialog> createState() =>
      _AssignPlansToStudentDialogState();
}

class _AssignPlansToStudentDialogState
    extends State<AssignPlansToStudentDialog> {
  final StudentRepository _repository = StudentRepositoryImpl();

  // 计划列表
  List<PlanSummary> _exercisePlans = [];
  List<PlanSummary> _dietPlans = [];
  List<PlanSummary> _supplementPlans = [];

  // UI状态
  bool _isLoadingPlans = true;
  bool _isSaving = false;
  String? _errorMessage;

  // section展开状态
  final Set<String> _expandedSections = {};

  // 计划分配状态
  late PlanAssignmentState _assignmentState;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _loadPlans();
  }

  /// 初始化状态
  void _initializeState() {
    _assignmentState = PlanAssignmentState.fromStudentPlans(
      exercisePlanId: widget.student.exercisePlan?.id,
      dietPlanId: widget.student.dietPlan?.id,
      supplementPlanId: widget.student.supplementPlan?.id,
    );
  }

  /// 加载计划列表
  Future<void> _loadPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _errorMessage = null;
    });

    try {
      final plansMap = await _repository.fetchAvailablePlansSummary(
        maxPerType: 100,
      );

      setState(() {
        _exercisePlans = plansMap['exercise'] ?? [];
        _dietPlans = plansMap['diet'] ?? [];
        _supplementPlans = plansMap['supplement'] ?? [];
        _isLoadingPlans = false;
      });

      AppLogger.info(
        '加载计划列表成功: '
        '训练${_exercisePlans.length}, '
        '饮食${_dietPlans.length}, '
        '补剂${_supplementPlans.length}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('加载计划列表失败', e, stackTrace);
      setState(() {
        _errorMessage = e.toString();
        _isLoadingPlans = false;
      });
    }
  }

  /// 切换section展开状态
  void _toggleSection(String planType) {
    setState(() {
      if (_expandedSections.contains(planType)) {
        _expandedSections.remove(planType);
      } else {
        _expandedSections.add(planType);
      }
    });
  }

  /// 选择计划
  void _selectPlan(String planType, String? planId) {
    setState(() {
      switch (planType) {
        case 'exercise':
          _assignmentState = _assignmentState.copyWith(
            selectedExercisePlanId: planId,
            clearExercisePlan: planId == null,
          );
          break;
        case 'diet':
          _assignmentState = _assignmentState.copyWith(
            selectedDietPlanId: planId,
            clearDietPlan: planId == null,
          );
          break;
        case 'supplement':
          _assignmentState = _assignmentState.copyWith(
            selectedSupplementPlanId: planId,
            clearSupplementPlan: planId == null,
          );
          break;
      }
    });

    AppLogger.debug('选择计划: $planType -> $planId');
  }

  /// 保存分配
  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context)!;

    // 检查是否有变更
    if (!_assignmentState.hasChanges()) {
      AppLogger.info('没有变更,直接返回');
      if (mounted) {
        Navigator.of(context).pop(false);
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final changes = _assignmentState.getChanges();
      AppLogger.info('准备保存变更: ${changes.keys.join(', ')}');

      // 依次处理每个类型的变更
      for (final entry in changes.entries) {
        final planType = entry.key;
        final fromPlanId = entry.value['from'];
        final toPlanId = entry.value['to'];

        // 如果有旧计划,先取消分配
        if (fromPlanId != null) {
          await _assignPlan(
            planType: planType,
            planId: fromPlanId,
            unassign: true,
          );
        }

        // 如果有新计划,分配
        if (toPlanId != null) {
          await _assignPlan(
            planType: planType,
            planId: toPlanId,
            unassign: false,
          );
        }
      }

      AppLogger.info('所有变更保存成功');

      if (mounted) {
        Navigator.of(context).pop(true);
        _showSuccessDialog(l10n);
      }
    } catch (e, stackTrace) {
      AppLogger.error('保存失败', e, stackTrace);
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showErrorDialog(e.toString());
      }
    }
  }

  /// 调用assign_plan API
  Future<void> _assignPlan({
    required String planType,
    required String planId,
    required bool unassign,
  }) async {
    try {
      final result = await CloudFunctionsService.call('assign_plan', {
        'action': unassign ? 'unassign' : 'assign',
        'planType': planType,
        'planId': planId,
        'studentIds': [widget.student.id],
      });

      if (result['status'] != 'success') {
        throw Exception(result['message'] ?? '分配失败');
      }

      AppLogger.debug('${unassign ? '取消' : ''}分配计划成功: $planType/$planId');
    } catch (e) {
      AppLogger.error('分配计划失败: $planType/$planId', e);
      rethrow;
    }
  }

  /// 显示成功对话框
  void _showSuccessDialog(AppLocalizations l10n) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.success),
        content: Text(l10n.assignmentSaved),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.error),
        content: Text('${l10n.assignmentFailed}\n\n$message'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        middle: Text('${l10n.assignPlansToStudent} ${widget.student.name}'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(l10n.done),
        ),
      ),
      child: SafeArea(child: _buildContent(l10n)),
    );
  }

  /// 构建内容区域
  Widget _buildContent(AppLocalizations l10n) {
    // 加载中
    if (_isLoadingPlans) {
      return const Center(child: LoadingIndicator());
    }

    // 加载错误
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 48,
                color: AppColors.errorRed,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              Text(l10n.loadingPlans, style: AppTextStyles.title3),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                _errorMessage!,
                style: AppTextStyles.callout.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacingXL),
              CupertinoButton.filled(
                onPressed: _loadPlans,
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    // 正常显示三个section
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      children: [
        // 训练计划section
        PlanTypeSection(
          planType: 'exercise',
          isExpanded: _expandedSections.contains('exercise'),
          currentPlanId: _assignmentState.originalExercisePlanId,
          selectedPlanId: _assignmentState.selectedExercisePlanId,
          plans: _exercisePlans,
          isLoading: false,
          onToggle: () => _toggleSection('exercise'),
          onSelectPlan: (planId) => _selectPlan('exercise', planId),
        ),

        // 饮食计划section
        PlanTypeSection(
          planType: 'diet',
          isExpanded: _expandedSections.contains('diet'),
          currentPlanId: _assignmentState.originalDietPlanId,
          selectedPlanId: _assignmentState.selectedDietPlanId,
          plans: _dietPlans,
          isLoading: false,
          onToggle: () => _toggleSection('diet'),
          onSelectPlan: (planId) => _selectPlan('diet', planId),
        ),

        // 补剂计划section
        PlanTypeSection(
          planType: 'supplement',
          isExpanded: _expandedSections.contains('supplement'),
          currentPlanId: _assignmentState.originalSupplementPlanId,
          selectedPlanId: _assignmentState.selectedSupplementPlanId,
          plans: _supplementPlans,
          isLoading: false,
          onToggle: () => _toggleSection('supplement'),
          onSelectPlan: (planId) => _selectPlan('supplement', planId),
        ),
      ],
    );
  }
}
