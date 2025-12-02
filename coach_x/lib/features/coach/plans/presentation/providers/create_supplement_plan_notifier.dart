import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/coach/plans/data/models/create_supplement_plan_state.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_day.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_timing.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_plan_model.dart';
import 'package:coach_x/features/coach/plans/data/models/supplement_import_result.dart';
import 'package:coach_x/features/coach/plans/data/repositories/supplement_plan_repository.dart';

/// 创建补剂计划状态管理
class CreateSupplementPlanNotifier
    extends StateNotifier<CreateSupplementPlanState> {
  final SupplementPlanRepository _supplementPlanRepository;

  CreateSupplementPlanNotifier(this._supplementPlanRepository)
    : super(const CreateSupplementPlanState());

  // ==================== 基础字段更新 ====================

  /// 更新计划名称
  void updatePlanName(String name) {
    state = state.copyWith(planName: name);
  }

  /// 更新描述
  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  // ==================== 补剂日管理 ====================

  /// 添加补剂日
  void addDay({String? name}) {
    final dayNumber = state.days.length + 1;
    final newDay = SupplementDay(
      day: dayNumber,
      name: name ?? 'Day $dayNumber',
      timings: const [],
      completed: false,
    );

    final updatedDays = [...state.days, newDay];
    state = state.copyWith(days: updatedDays);

    AppLogger.debug('➕ 添加补剂日 - Day $dayNumber');
  }

  /// 删除补剂日
  void removeDay(int index) {
    if (index < 0 || index >= state.days.length) return;

    final updatedDays = List<SupplementDay>.from(state.days);
    updatedDays.removeAt(index);

    // 重新编号
    for (int i = 0; i < updatedDays.length; i++) {
      updatedDays[i] = updatedDays[i].copyWith(day: i + 1);
    }

    state = state.copyWith(days: updatedDays);

    AppLogger.debug('🗑️ 删除补剂日 - Index $index');
  }

  /// 更新补剂日
  void updateDay(int index, SupplementDay day) {
    if (index < 0 || index >= state.days.length) return;

    final updatedDays = List<SupplementDay>.from(state.days);
    updatedDays[index] = day;

    state = state.copyWith(days: updatedDays);
  }

  /// 更新补剂日名称
  void updateDayName(int dayIndex, String name) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final updatedDay = day.copyWith(name: name);
    updateDay(dayIndex, updatedDay);
  }

  // ==================== 时间段管理 ====================

  /// 添加时间段
  void addTiming(int dayIndex, {String? name}) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    final newTiming = SupplementTiming.empty(name: name);
    final updatedTimings = [...day.timings, newTiming];
    final updatedDay = day.copyWith(timings: updatedTimings);

    updateDay(dayIndex, updatedDay);

    AppLogger.debug('➕ 添加时间段 - Day ${dayIndex + 1}');
  }

  /// 删除时间段
  void removeTiming(int dayIndex, int timingIndex) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final updatedTimings = List<SupplementTiming>.from(day.timings);
    updatedTimings.removeAt(timingIndex);
    final updatedDay = day.copyWith(timings: updatedTimings);

    updateDay(dayIndex, updatedDay);

    AppLogger.debug(
      '🗑️ 删除时间段 - Day ${dayIndex + 1}, Timing ${timingIndex + 1}',
    );
  }

  /// 更新时间段
  void updateTiming(int dayIndex, int timingIndex, SupplementTiming timing) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final updatedTimings = List<SupplementTiming>.from(day.timings);
    updatedTimings[timingIndex] = timing;
    final updatedDay = day.copyWith(timings: updatedTimings);

    updateDay(dayIndex, updatedDay);
  }

  /// 更新时间段名称
  void updateTimingName(int dayIndex, int timingIndex, String name) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final timing = day.timings[timingIndex];
    final updatedTiming = timing.copyWith(name: name);
    updateTiming(dayIndex, timingIndex, updatedTiming);
  }

  /// 更新时间段备注
  void updateTimingNote(int dayIndex, int timingIndex, String note) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final timing = day.timings[timingIndex];
    final updatedTiming = timing.copyWith(note: note);
    updateTiming(dayIndex, timingIndex, updatedTiming);
  }

  // ==================== 补剂管理 ====================

  /// 添加补剂
  void addSupplement(int dayIndex, int timingIndex, {Supplement? supplement}) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final timing = day.timings[timingIndex];
    final newSupplement = supplement ?? Supplement.empty();
    final updatedSupplements = [...timing.supplements, newSupplement];
    final updatedTiming = timing.copyWith(supplements: updatedSupplements);

    updateTiming(dayIndex, timingIndex, updatedTiming);

    AppLogger.debug('➕ 添加补剂 - Day ${dayIndex + 1}, Timing ${timingIndex + 1}');
  }

  /// 删除补剂
  void removeSupplement(int dayIndex, int timingIndex, int supplementIndex) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final timing = day.timings[timingIndex];
    if (supplementIndex < 0 || supplementIndex >= timing.supplements.length) {
      return;
    }

    final updatedSupplements = List<Supplement>.from(timing.supplements);
    updatedSupplements.removeAt(supplementIndex);
    final updatedTiming = timing.copyWith(supplements: updatedSupplements);

    updateTiming(dayIndex, timingIndex, updatedTiming);

    AppLogger.debug(
      '🗑️ 删除补剂 - Day ${dayIndex + 1}, Timing ${timingIndex + 1}, Supplement ${supplementIndex + 1}',
    );
  }

  /// 更新补剂
  void updateSupplement(
    int dayIndex,
    int timingIndex,
    int supplementIndex,
    Supplement supplement,
  ) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final timing = day.timings[timingIndex];
    if (supplementIndex < 0 || supplementIndex >= timing.supplements.length) {
      return;
    }

    final updatedSupplements = List<Supplement>.from(timing.supplements);
    updatedSupplements[supplementIndex] = supplement;
    final updatedTiming = timing.copyWith(supplements: updatedSupplements);

    updateTiming(dayIndex, timingIndex, updatedTiming);
  }

  /// 更新补剂的单个字段
  void updateSupplementField(
    int dayIndex,
    int timingIndex,
    int supplementIndex, {
    String? name,
    String? amount,
  }) {
    if (dayIndex < 0 || dayIndex >= state.days.length) return;

    final day = state.days[dayIndex];
    if (timingIndex < 0 || timingIndex >= day.timings.length) return;

    final timing = day.timings[timingIndex];
    if (supplementIndex < 0 || supplementIndex >= timing.supplements.length) {
      return;
    }

    final supplement = timing.supplements[supplementIndex];
    final updatedSupplement = supplement.copyWith(name: name, amount: amount);

    updateSupplement(dayIndex, timingIndex, supplementIndex, updatedSupplement);
  }

  // ==================== AI 生成应用 ====================

  /// 应用 AI 生成的补剂日到多天
  ///
  /// [day] AI 生成的单天补剂方案
  /// [dayCount] 要复制到多少天（默认7天）
  void applyAIGeneratedDay(SupplementDay day, {int dayCount = 7}) {
    AppLogger.info('✅ 应用AI生成的补剂方案到 $dayCount 天');

    // 创建 dayCount 个副本
    final List<SupplementDay> newDays = [];
    for (int i = 0; i < dayCount; i++) {
      final dayNumber = i + 1;
      final newDay = day.copyWith(day: dayNumber, name: 'Day $dayNumber');
      newDays.add(newDay);
    }

    // 更新状态
    state = state.copyWith(days: newDays);

    AppLogger.debug('📋 已创建 ${newDays.length} 个补剂日');
  }

  // ==================== 验证 ====================

  /// 验证当前计划
  void validate() {
    final errors = <String>[];

    // 验证计划名称
    if (state.planName.trim().isEmpty) {
      errors.add('计划名称不能为空');
    }

    // 验证至少有一个补剂日
    if (state.days.isEmpty) {
      errors.add('至少需要添加一个补剂日');
    }

    // 验证每个补剂日
    for (int i = 0; i < state.days.length; i++) {
      final day = state.days[i];

      // 验证至少有一个时间段
      if (day.timings.isEmpty) {
        errors.add('第 ${i + 1} 天至少需要添加一个时间段');
        continue;
      }

      // 验证每个时间段
      for (int j = 0; j < day.timings.length; j++) {
        final timing = day.timings[j];

        // 验证时间段名称
        if (timing.name.trim().isEmpty) {
          errors.add('第 ${i + 1} 天的第 ${j + 1} 个时间段需要名称');
        }

        // 验证至少有一个补剂
        if (timing.supplements.isEmpty) {
          errors.add('第 ${i + 1} 天的第 ${j + 1} 个时间段至少需要添加一个补剂');
          continue;
        }

        // 验证每个补剂
        for (int k = 0; k < timing.supplements.length; k++) {
          final supplement = timing.supplements[k];

          // 验证补剂名称
          if (supplement.name.trim().isEmpty) {
            errors.add('第 ${i + 1} 天第 ${j + 1} 个时间段的第 ${k + 1} 个补剂需要名称');
          }

          // 验证用量
          if (supplement.amount.trim().isEmpty) {
            errors.add('第 ${i + 1} 天第 ${j + 1} 个时间段的第 ${k + 1} 个补剂需要用量');
          }
        }
      }
    }

    state = state.copyWith(validationErrors: errors);

    if (errors.isNotEmpty) {
      AppLogger.warning('⚠️ 验证失败: ${errors.first}');
    }
  }

  // ==================== 保存与加载 ====================

  /// 加载现有计划
  Future<bool> loadPlan(String planId) async {
    try {
      state = state.copyWith(isLoading: true);

      AppLogger.info('📖 加载补剂计划 - ID: $planId');

      // 从Repository加载计划
      final plan = await _supplementPlanRepository.getPlan(planId);

      if (plan == null) {
        throw Exception('计划不存在');
      }

      // 生成初始快照 JSON
      final initialDaysJson = jsonEncode(plan.days.map((d) => d.toJson()).toList());

      // 更新状态（包含初始快照）
      state = state.copyWith(
        planId: plan.id,
        planName: plan.name,
        description: plan.description,
        days: plan.days,
        isLoading: false,
        isEditMode: true,
        initialPlanName: plan.name,
        initialDescription: plan.description,
        initialDaysJson: initialDaysJson,
      );

      AppLogger.info('✅ 补剂计划加载成功: ${plan.name}');

      return true;
    } catch (e) {
      AppLogger.error('❌ 加载补剂计划失败', e);

      state = state.copyWith(isLoading: false, errorMessage: '加载失败: $e');

      return false;
    }
  }

  /// 从导入结果加载计划
  void loadFromImportResult(SupplementImportResult result) {
    if (!result.isSuccess || result.plan == null) {
      AppLogger.warning('⚠️ 导入结果无效');
      return;
    }

    final plan = result.plan!;

    AppLogger.info('📥 从导入结果加载补剂计划: ${plan.name}');

    // 更新状态
    state = state.copyWith(
      planName: plan.name,
      description: plan.description,
      days: plan.days,
    );

    AppLogger.info('✅ 导入成功 - 置信度: ${(result.confidence * 100).toInt()}%');

    if (result.hasWarnings) {
      AppLogger.warning('⚠️ 导入警告: ${result.warnings.join(", ")}');
    }
  }

  /// 保存计划
  Future<bool> savePlan() async {
    try {
      // 验证
      validate();
      if (state.validationErrors.isNotEmpty) {
        state = state.copyWith(errorMessage: state.validationErrors.first);
        return false;
      }

      state = state.copyWith(isLoading: true);

      AppLogger.info('💾 保存补剂计划: ${state.planName}');

      // 创建计划对象
      final plan = SupplementPlanModel(
        id: state.planId ?? '', // 编辑模式使用现有ID
        name: state.planName,
        description: state.description,
        ownerId: '', // 服务端填充
        studentIds: const [],
        createdAt: 0, // 服务端填充
        updatedAt: 0, // 服务端填充
        cyclePattern: '', // 可选，暂时为空
        days: state.days,
      );

      // 根据是否有planId判断是创建还是更新
      String planId;
      if (state.isEditMode &&
          state.planId != null &&
          state.planId!.isNotEmpty) {
        // 更新现有计划
        await _supplementPlanRepository.updatePlan(plan);
        planId = state.planId!;
        AppLogger.info('✅ 补剂计划更新成功 - ID: $planId');
      } else {
        // 创建新计划
        planId = await _supplementPlanRepository.createPlan(plan);
        AppLogger.info('✅ 补剂计划创建成功 - ID: $planId');
      }

      state = state.copyWith(isLoading: false, planId: planId);

      return true;
    } catch (e) {
      AppLogger.error('❌ 保存补剂计划失败', e);

      state = state.copyWith(isLoading: false, errorMessage: '保存失败: $e');

      return false;
    }
  }

  // ==================== 重置 ====================

  /// 重置状态
  void reset() {
    state = const CreateSupplementPlanState();
    AppLogger.debug('🔄 重置创建补剂计划状态');
  }

  /// 保存当前状态为初始快照（用于判断是否有修改）
  void saveInitialSnapshot() {
    final initialDaysJson = jsonEncode(state.days.map((d) => d.toJson()).toList());
    state = state.copyWith(
      initialPlanName: state.planName,
      initialDescription: state.description,
      initialDaysJson: initialDaysJson,
    );
    AppLogger.debug('📸 保存初始快照 - days: ${state.days.length}');
  }

  /// 清空错误
  void clearError() {
    state = state.clearError();
  }
}
