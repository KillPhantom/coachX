import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/enums/training_goal.dart';
import 'package:coach_x/core/enums/training_level.dart';
import 'package:coach_x/core/enums/muscle_group.dart';
import 'package:coach_x/core/enums/workload_level.dart';
import 'package:coach_x/core/enums/training_style.dart';
import 'package:coach_x/core/enums/equipment.dart';
import 'package:coach_x/features/coach/plans/data/models/plan_generation_params.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_training_plan_providers.dart';

/// AI 引导创建页面（单页表单）
///
/// 重新设计为单页滚动表单，包含3个区域
class GuidedCreationSheet extends ConsumerStatefulWidget {
  const GuidedCreationSheet({super.key});

  @override
  ConsumerState<GuidedCreationSheet> createState() =>
      _GuidedCreationSheetState();
}

class _GuidedCreationSheetState extends ConsumerState<GuidedCreationSheet> {
  // 基本设置
  TrainingGoal? _goal;
  TrainingLevel? _level;
  int _daysPerWeek = 3;
  int _durationMinutes = 60;

  // 训练目标与强度
  final Set<MuscleGroup> _targetGroups = {};
  WorkloadLevel? _workload;
  int _exercisesPerDayMin = 4;
  int _exercisesPerDayMax = 6;
  int _setsPerExerciseMin = 3;
  int _setsPerExerciseMax = 5;

  // 高级选项
  final Set<TrainingStyle> _trainingStyles = {};
  final Set<Equipment> _equipment = {};
  final TextEditingController _notesController = TextEditingController();

  // 折叠状态
  bool _showAdvancedOptions = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// 验证是否可以生成
  bool get _canGenerate {
    return _goal != null &&
        _level != null &&
        _targetGroups.isNotEmpty &&
        _workload != null &&
        _equipment.isNotEmpty;
  }

  /// 获取验证错误信息
  String? get _validationError {
    if (_goal == null) return '请选择训练目标';
    if (_level == null) return '请选择训练水平';
    if (_targetGroups.isEmpty) return '请至少选择一个目标肌群';
    if (_workload == null) return '请选择训练量级别';
    if (_equipment.isEmpty) return '请在高级选项中至少选择一种可用设备';
    return null;
  }

  /// 生成计划（流式）
  Future<void> _generatePlanStreaming() async {
    if (!_canGenerate) {
      // 如果设备未选择，自动展开高级选项
      if (_equipment.isEmpty && !_showAdvancedOptions) {
        setState(() {
          _showAdvancedOptions = true;
        });
      }
      return;
    }

    try {
      final params = PlanGenerationParams(
        goal: _goal!,
        level: _level!,
        muscleGroups: _targetGroups.toList(),
        daysPerWeek: _daysPerWeek,
        durationMinutes: _durationMinutes,
        workload: _workload!,
        exercisesPerDayMin: _exercisesPerDayMin,
        exercisesPerDayMax: _exercisesPerDayMax,
        setsPerExerciseMin: _setsPerExerciseMin,
        setsPerExerciseMax: _setsPerExerciseMax,
        trainingStyles: _trainingStyles.toList(),
        equipment: _equipment.toList(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      final notifier = ref.read(createTrainingPlanNotifierProvider.notifier);

      // 立即关闭弹窗
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 调用 notifier（不传递回调）
      await notifier.generateFromParamsStreaming(params);

      // 主页面的思考面板会自动响应状态变化
    } catch (e) {
      AppLogger.error('❌ 生成计划异常', e);
      // 错误会在 notifier 中处理，主页面会显示
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('AI 引导创建'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 滚动内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 基本设置
                    _buildSectionTitle('基本设置'),
                    const SizedBox(height: 12),
                    _buildBasicSettings(),
                    const SizedBox(height: 24),

                    // 训练目标与强度
                    _buildSectionTitle('训练目标与强度'),
                    const SizedBox(height: 12),
                    _buildTargetsAndIntensity(),
                    const SizedBox(height: 24),

                    // 高级选项（可折叠）
                    _buildAdvancedOptionsToggle(),
                    if (_showAdvancedOptions) ...[
                      const SizedBox(height: 12),
                      _buildAdvancedOptions(),
                    ],
                  ],
                ),
              ),
            ),

            // 错误提示
            if (_validationError != null) _buildErrorBanner(_validationError!),

            // 生成按钮
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  /// 分区标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 基本设置
  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 训练目标
        Text(
          '训练目标',
          style: AppTextStyles.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TrainingGoal.values.map((goal) {
            final isSelected = _goal == goal;
            return GestureDetector(
              onTap: () => setState(() => _goal = goal),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  goal.displayName,
                  style: AppTextStyles.subhead.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 训练水平
        Text(
          '训练水平',
          style: AppTextStyles.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TrainingLevel.values.map((level) {
            final isSelected = _level == level;
            return GestureDetector(
              onTap: () => setState(() => _level = level),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  level.displayName,
                  style: AppTextStyles.subhead.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 每周天数 + 每次时长（并排）
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '每周训练: $_daysPerWeek 天',
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CupertinoSlider(
                    value: _daysPerWeek.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    onChanged: (value) {
                      setState(() => _daysPerWeek = value.toInt());
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '每次时长: $_durationMinutes 分钟',
                    style: AppTextStyles.callout.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  CupertinoSlider(
                    value: _durationMinutes.toDouble(),
                    min: 30,
                    max: 120,
                    divisions: 9,
                    onChanged: (value) {
                      setState(() => _durationMinutes = value.toInt());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 训练目标与强度
  Widget _buildTargetsAndIntensity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 目标肌群
        Text(
          '目标肌群（可多选）',
          style: AppTextStyles.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  group.displayName,
                  style: AppTextStyles.subhead.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 训练量级别
        Text(
          '训练量级别',
          style: AppTextStyles.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WorkloadLevel.values.map((level) {
            final isSelected = _workload == level;
            return GestureDetector(
              onTap: () => setState(() => _workload = level),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  level.displayName,
                  style: AppTextStyles.subhead.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 每天动作数范围
        Text(
          '每天动作数: $_exercisesPerDayMin - $_exercisesPerDayMax 个',
          style: AppTextStyles.callout.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '最少',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: CupertinoSlider(
                value: _exercisesPerDayMin.toDouble(),
                min: 2,
                max: 8,
                divisions: 6,
                onChanged: (value) {
                  setState(() {
                    _exercisesPerDayMin = value.toInt();
                    if (_exercisesPerDayMin > _exercisesPerDayMax) {
                      _exercisesPerDayMax = _exercisesPerDayMin;
                    }
                  });
                },
              ),
            ),
            Text(
              '最多',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: CupertinoSlider(
                value: _exercisesPerDayMax.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                onChanged: (value) {
                  setState(() {
                    _exercisesPerDayMax = value.toInt();
                    if (_exercisesPerDayMax < _exercisesPerDayMin) {
                      _exercisesPerDayMin = _exercisesPerDayMax;
                    }
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 每个动作组数范围
        Text(
          '每个动作组数: $_setsPerExerciseMin - $_setsPerExerciseMax 组',
          style: AppTextStyles.callout.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '最少',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: CupertinoSlider(
                value: _setsPerExerciseMin.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (value) {
                  setState(() {
                    _setsPerExerciseMin = value.toInt();
                    if (_setsPerExerciseMin > _setsPerExerciseMax) {
                      _setsPerExerciseMax = _setsPerExerciseMin;
                    }
                  });
                },
              ),
            ),
            Text(
              '最多',
              style: AppTextStyles.footnote.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: CupertinoSlider(
                value: _setsPerExerciseMax.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                onChanged: (value) {
                  setState(() {
                    _setsPerExerciseMax = value.toInt();
                    if (_setsPerExerciseMax < _setsPerExerciseMin) {
                      _setsPerExerciseMin = _setsPerExerciseMax;
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 高级选项折叠控制
  Widget _buildAdvancedOptionsToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              _showAdvancedOptions
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.black,
            ),
            const SizedBox(width: 8),
            Text(
              '高级选项（设备为必填）',
              style: AppTextStyles.subhead.copyWith(
                color: CupertinoColors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 高级选项
  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 训练风格
        Text(
          '训练风格（可多选，可不选）',
          style: AppTextStyles.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TrainingStyle.values.map((style) {
            final isSelected = _trainingStyles.contains(style);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _trainingStyles.remove(style);
                  } else {
                    _trainingStyles.add(style);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  style.displayName,
                  style: AppTextStyles.subhead.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 可用设备
        Text(
          '可用设备（可多选）',
          style: AppTextStyles.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Equipment.values.map((eq) {
            final isSelected = _equipment.contains(eq);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _equipment.remove(eq);
                  } else {
                    _equipment.add(eq);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  eq.displayName,
                  style: AppTextStyles.subhead.copyWith(
                    color: isSelected
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 补充说明
        Text(
          '补充说明（可选）',
          style: AppTextStyles.footnote.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: _notesController,
          placeholder: '例如：某个部位需要避免或加强、特殊训练偏好、身体限制等',
          maxLines: 5,
          minLines: 3,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
        ),
      ],
    );
  }

  /// 错误横幅
  Widget _buildErrorBanner(String errorMessage) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.systemRed.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: AppTextStyles.footnote.copyWith(
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 生成按钮
  Widget _buildGenerateButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _canGenerate ? _generatePlanStreaming : null,
        child: Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: _canGenerate
                ? AppColors.primary
                : CupertinoColors.quaternarySystemFill,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            '生成训练计划',
            style: AppTextStyles.buttonLarge.copyWith(
              color: _canGenerate
                  ? CupertinoColors.black
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
