import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For LinearProgressIndicator
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/enums/training_goal.dart';
import 'package:coach_x/core/enums/training_level.dart';
import 'package:coach_x/core/enums/muscle_group.dart';
import 'package:coach_x/core/enums/workload_level.dart';
import 'package:coach_x/core/enums/equipment.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_generation_params.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';

/// AI 引导创建视图（分步卡片流）
///
/// 设计理念: Progressive Card Flow
/// 将复杂的配置拆分为 3 个核心步骤，降低认知负荷。
/// Step 1: 目标与水平 (The Goal)
/// Step 2: 时间与重点 (The Focus)
/// Step 3: 场景与微调 (The Context)
class TrainingAIGuidedView extends ConsumerStatefulWidget {
  final VoidCallback onGenerationStart;

  const TrainingAIGuidedView({super.key, required this.onGenerationStart});

  @override
  ConsumerState<TrainingAIGuidedView> createState() => _TrainingAIGuidedViewState();
}

class _TrainingAIGuidedViewState extends ConsumerState<TrainingAIGuidedView> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Goal & Level
  TrainingGoal? _goal;
  TrainingLevel? _level;

  // Step 2: Time & Focus
  int _daysPerWeek = 3;
  int _durationMinutes = 60;
  final Set<MuscleGroup> _targetGroups = {};

  // Step 3: Context & Details
  final Set<Equipment> _equipment = {};
  final TextEditingController _notesController = TextEditingController();
  WorkloadLevel _workload = WorkloadLevel.medium; // 默认中等，可微调

  // 场景预设
  String? _selectedScenario; // 'gym', 'home', 'bodyweight'

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- 逻辑处理 ---

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _generatePlanStreaming();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _goal != null && _level != null;
      case 1:
        return _targetGroups.isNotEmpty;
      case 2:
        return _equipment.isNotEmpty;
      default:
        return false;
    }
  }

  void _applyScenario(String scenario) {
    setState(() {
      _selectedScenario = scenario;
      _equipment.clear();
      switch (scenario) {
        case 'gym':
          // 健身房：全选常用器械
          _equipment.addAll([
            Equipment.barbell,
            Equipment.dumbbell,
            Equipment.machine,
            Equipment.cable,
            Equipment.bodyweight,
          ]);
          break;
        case 'home':
          // 居家：哑铃 + 自重
          _equipment.addAll([
            Equipment.dumbbell,
            Equipment.bodyweight,
            Equipment.resistanceBand,
          ]);
          break;
        case 'bodyweight':
          // 自重
          _equipment.add(Equipment.bodyweight);
          break;
      }
    });
  }

  /// 智能推导微观参数
  void _generatePlanStreaming() async {
    if (!_canProceed) return;

    // 1. 根据 Level 推导动作数和组数
    int exercisesMin = 4;
    int exercisesMax = 6;
    int setsMin = 3;
    int setsMax = 4;

    if (_level == TrainingLevel.beginner) {
      exercisesMin = 3;
      exercisesMax = 5;
      setsMin = 2;
      setsMax = 3;
    } else if (_level == TrainingLevel.advanced) {
      exercisesMin = 5;
      exercisesMax = 7;
      setsMin = 3;
      setsMax = 5;
    }

    // 2. 根据时长微调动作数
    if (_durationMinutes <= 45) {
      exercisesMax = exercisesMax > 4 ? 4 : exercisesMax;
    } else if (_durationMinutes >= 90) {
      exercisesMin = exercisesMin < 5 ? 5 : exercisesMin;
    }

    try {
      final params = PlanGenerationParams(
        goal: _goal!,
        level: _level!,
        muscleGroups: _targetGroups.toList(),
        daysPerWeek: _daysPerWeek,
        durationMinutes: _durationMinutes,
        workload: _workload,
        exercisesPerDayMin: exercisesMin,
        exercisesPerDayMax: exercisesMax,
        setsPerExerciseMin: setsMin,
        setsPerExerciseMax: setsMax,
        equipment: _equipment.toList(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);
      widget.onGenerationStart();
      await notifier.generateFromParamsStreaming(params);
    } catch (e) {
      AppLogger.error('❌ 生成计划异常', e);
    }
  }

  // --- UI 构建 ---

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Progress Indicator
        _buildProgressIndicator(),

        // 2. Page Content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // 禁止滑动
            children: [_buildStep1(), _buildStep2(), _buildStep3()],
          ),
        ),

        // 3. Bottom Navigation
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1}/$_totalSteps',
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getStepTitle(_currentStep),
                style: AppTextStyles.footnote.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return '目标与水平';
      case 1:
        return '时间与重点';
      case 2:
        return '场景与微调';
      default:
        return '';
    }
  }

  // --- Step 1: Goal & Level ---
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('您的学员处于什么阶段？', 'AI 将根据水平调整训练强度'),
          const SizedBox(height: 24),

          // Training Goal
          Text('训练目标', style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: TrainingGoal.values.map((goal) {
                  final isSelected = _goal == goal;
                  return GestureDetector(
                    onTap: () => setState(() => _goal = goal),
                    child: Container(
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        goal.displayName,
                        style: AppTextStyles.body.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 32),

          // Training Level
          Text('训练水平', style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: TrainingLevel.values.map((level) {
                final isSelected = _level == level;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _level = level),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.cardBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        level.displayName,
                        style: AppTextStyles.callout.copyWith(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Time & Focus ---
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('训练安排是怎样的？', '合理分配时间与重点'),
          const SizedBox(height: 24),

          // Days Per Week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('每周训练天数', style: AppTextStyles.subhead),
              Text(
                '$_daysPerWeek 天',
                style: AppTextStyles.subhead.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: _daysPerWeek.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() => _daysPerWeek = value.toInt());
              },
            ),
          ),

          const SizedBox(height: 24),

          // Duration
          Text('单次时长', style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [30, 45, 60, 90, 120].map((min) {
                final isSelected = _durationMinutes == min;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _durationMinutes = min),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        '$min 分钟',
                        style: AppTextStyles.callout.copyWith(
                          color: isSelected
                              ? CupertinoColors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Muscle Groups
          Text('重点肌群 (多选)', style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: MuscleGroup.values.map((group) {
              final isSelected = _targetGroups.contains(group);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _targetGroups.remove(group);
                    } else {
                      _targetGroups.add(group);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    group.displayName,
                    style: AppTextStyles.callout.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Context & Details ---
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('在哪里训练？', 'AI 将根据场景选择合适的动作'),
          const SizedBox(height: 24),

          // Scenario Presets
          Text('场景预设', style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildScenarioCard('gym', '🏢 健身房', '全套器械'),
              const SizedBox(width: 12),
              _buildScenarioCard('home', '🏠 居家', '哑铃/弹力带'),
              const SizedBox(width: 12),
              _buildScenarioCard('bodyweight', '🧘 自重', '无器械'),
            ],
          ),

          const SizedBox(height: 24),

          // Equipment (Auto-filled but editable)
          if (_equipment.isNotEmpty) ...[
            Text('已选设备', style: AppTextStyles.subhead),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipment.map((eq) {
                return Material(
                  type: MaterialType.transparency,
                  child: Chip(
                    label: Text(eq.displayName, style: AppTextStyles.caption1),
                    backgroundColor: AppColors.backgroundSecondary,
                    deleteIcon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 16,
                    ),
                    onDeleted: () {
                      setState(() {
                        _equipment.remove(eq);
                        _selectedScenario = null; // Clear preset if modified
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Notes
          Text('额外备注 (可选)', style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _notesController,
            placeholder: '例如：膝盖有伤避免深蹲，或者偏好高强度间歇...',
            maxLines: 4,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(String id, String title, String subtitle) {
    final isSelected = _selectedScenario == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => _applyScenario(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: AppTextStyles.callout.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption1.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.title2.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // --- Bottom Bar ---
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _prevStep,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_left,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _canProceed ? _nextStep : null,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _canProceed
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentStep == _totalSteps - 1 ? '✨ 生成计划' : '下一步',
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
