/// 计划分配状态模型
///
/// 用于AssignPlansToStudentDialog中管理用户的选择状态
/// 包含当前选择和原始值，用于计算变更
class PlanAssignmentState {
  /// 当前选择的训练计划ID (null表示无计划)
  final String? selectedExercisePlanId;

  /// 当前选择的饮食计划ID (null表示无计划)
  final String? selectedDietPlanId;

  /// 当前选择的补剂计划ID (null表示无计划)
  final String? selectedSupplementPlanId;

  /// 原始的训练计划ID (学生当前已分配的)
  final String? originalExercisePlanId;

  /// 原始的饮食计划ID (学生当前已分配的)
  final String? originalDietPlanId;

  /// 原始的补剂计划ID (学生当前已分配的)
  final String? originalSupplementPlanId;

  const PlanAssignmentState({
    this.selectedExercisePlanId,
    this.selectedDietPlanId,
    this.selectedSupplementPlanId,
    this.originalExercisePlanId,
    this.originalDietPlanId,
    this.originalSupplementPlanId,
  });

  /// 从学生当前计划初始化状态
  factory PlanAssignmentState.fromStudentPlans({
    String? exercisePlanId,
    String? dietPlanId,
    String? supplementPlanId,
  }) {
    return PlanAssignmentState(
      selectedExercisePlanId: exercisePlanId,
      selectedDietPlanId: dietPlanId,
      selectedSupplementPlanId: supplementPlanId,
      originalExercisePlanId: exercisePlanId,
      originalDietPlanId: dietPlanId,
      originalSupplementPlanId: supplementPlanId,
    );
  }

  /// 判断是否有任何变更
  bool hasChanges() {
    return selectedExercisePlanId != originalExercisePlanId ||
        selectedDietPlanId != originalDietPlanId ||
        selectedSupplementPlanId != originalSupplementPlanId;
  }

  /// 获取变更详情
  ///
  /// 返回格式：
  /// {
  ///   'exercise': {'from': 'planA_id', 'to': 'planB_id'},
  ///   'diet': {'from': null, 'to': 'planC_id'},
  ///   'supplement': {'from': 'planD_id', 'to': null},
  /// }
  ///
  /// 如果某个类型没有变更，则不会出现在返回的Map中
  Map<String, Map<String, String?>> getChanges() {
    final changes = <String, Map<String, String?>>{};

    // 检查训练计划变更
    if (selectedExercisePlanId != originalExercisePlanId) {
      changes['exercise'] = {
        'from': originalExercisePlanId,
        'to': selectedExercisePlanId,
      };
    }

    // 检查饮食计划变更
    if (selectedDietPlanId != originalDietPlanId) {
      changes['diet'] = {'from': originalDietPlanId, 'to': selectedDietPlanId};
    }

    // 检查补剂计划变更
    if (selectedSupplementPlanId != originalSupplementPlanId) {
      changes['supplement'] = {
        'from': originalSupplementPlanId,
        'to': selectedSupplementPlanId,
      };
    }

    return changes;
  }

  /// 获取变更摘要（用于确认对话框）
  ///
  /// 返回人类可读的变更描述列表
  /// 例如: ['训练计划: 增肌计划A → 减脂计划B', '饮食计划: 无 → 高蛋白饮食']
  List<String> getChangeSummary({required Map<String, String> planNames}) {
    final summary = <String>[];
    final changes = getChanges();

    for (final entry in changes.entries) {
      final planType = entry.key;
      final fromId = entry.value['from'];
      final toId = entry.value['to'];

      final fromName = fromId != null ? planNames[fromId] ?? '未知计划' : '无';
      final toName = toId != null ? planNames[toId] ?? '未知计划' : '无';

      final typeDisplayName = _getPlanTypeDisplayName(planType);
      summary.add('$typeDisplayName: $fromName → $toName');
    }

    return summary;
  }

  /// 获取计划类型的显示名称
  String _getPlanTypeDisplayName(String planType) {
    switch (planType) {
      case 'exercise':
        return '训练计划';
      case 'diet':
        return '饮食计划';
      case 'supplement':
        return '补剂计划';
      default:
        return '未知计划';
    }
  }

  /// 复制并修改状态
  PlanAssignmentState copyWith({
    String? selectedExercisePlanId,
    String? selectedDietPlanId,
    String? selectedSupplementPlanId,
    String? originalExercisePlanId,
    String? originalDietPlanId,
    String? originalSupplementPlanId,
    bool clearExercisePlan = false,
    bool clearDietPlan = false,
    bool clearSupplementPlan = false,
  }) {
    return PlanAssignmentState(
      selectedExercisePlanId: clearExercisePlan
          ? null
          : (selectedExercisePlanId ?? this.selectedExercisePlanId),
      selectedDietPlanId: clearDietPlan
          ? null
          : (selectedDietPlanId ?? this.selectedDietPlanId),
      selectedSupplementPlanId: clearSupplementPlan
          ? null
          : (selectedSupplementPlanId ?? this.selectedSupplementPlanId),
      originalExercisePlanId:
          originalExercisePlanId ?? this.originalExercisePlanId,
      originalDietPlanId: originalDietPlanId ?? this.originalDietPlanId,
      originalSupplementPlanId:
          originalSupplementPlanId ?? this.originalSupplementPlanId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanAssignmentState &&
          runtimeType == other.runtimeType &&
          selectedExercisePlanId == other.selectedExercisePlanId &&
          selectedDietPlanId == other.selectedDietPlanId &&
          selectedSupplementPlanId == other.selectedSupplementPlanId &&
          originalExercisePlanId == other.originalExercisePlanId &&
          originalDietPlanId == other.originalDietPlanId &&
          originalSupplementPlanId == other.originalSupplementPlanId;

  @override
  int get hashCode =>
      selectedExercisePlanId.hashCode ^
      selectedDietPlanId.hashCode ^
      selectedSupplementPlanId.hashCode ^
      originalExercisePlanId.hashCode ^
      originalDietPlanId.hashCode ^
      originalSupplementPlanId.hashCode;

  @override
  String toString() {
    return 'PlanAssignmentState{'
        'exercise: $originalExercisePlanId → $selectedExercisePlanId, '
        'diet: $originalDietPlanId → $selectedDietPlanId, '
        'supplement: $originalSupplementPlanId → $selectedSupplementPlanId'
        '}';
  }
}
