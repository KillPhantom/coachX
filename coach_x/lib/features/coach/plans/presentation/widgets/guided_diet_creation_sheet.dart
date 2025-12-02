import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/enums/activity_level.dart';
import 'package:coach_x/core/enums/diet_goal.dart';
import 'package:coach_x/core/enums/dietary_preference.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_generation_params.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_providers.dart';

/// AI 引导创建饮食计划 Sheet（1步骤表单）
class GuidedDietCreationSheet extends ConsumerStatefulWidget {
  const GuidedDietCreationSheet({super.key});

  @override
  ConsumerState<GuidedDietCreationSheet> createState() =>
      _GuidedDietCreationSheetState();
}

class _GuidedDietCreationSheetState
    extends ConsumerState<GuidedDietCreationSheet> {
  // 基本信息
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = 'male';

  // 目标设置
  DietGoal _goal = DietGoal.maintenance;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;

  // 可选设置
  final TextEditingController _bodyFatController = TextEditingController();
  String? _selectedTrainingPlanId;
  final Set<DietaryPreference> _dietaryPreferences = {};
  final TextEditingController _dietaryRestrictionsController = TextEditingController();
  int _mealCount = 4;
  int _planDurationDays = 1;

  // "其他"选项
  bool _hasOtherDietaryPreference = false;
  final TextEditingController _otherDietaryPreferenceController =
      TextEditingController();

  // 展开状态
  bool _showAdvancedOptions = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _bodyFatController.dispose();
    _otherDietaryPreferenceController.dispose();
    _dietaryRestrictionsController.dispose();
    super.dispose();
  }

  bool get _canGenerate {
    return _weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _ageController.text.isNotEmpty;
  }

  Future<void> _generatePlan() async {
    if (!_canGenerate) return;

    try {
      final params = DietPlanGenerationParams(
        weightKg: double.parse(_weightController.text),
        heightCm: double.parse(_heightController.text),
        age: int.parse(_ageController.text),
        gender: _gender,
        activityLevel: _activityLevel,
        goal: _goal,
        bodyFatPercentage: _bodyFatController.text.isNotEmpty
            ? double.tryParse(_bodyFatController.text)
            : null,
        trainingPlanId: _selectedTrainingPlanId,
        dietaryPreferences: _dietaryPreferences.isNotEmpty
            ? _dietaryPreferences.toList()
            : null,
        mealCount: _mealCount,
        dietaryRestrictions: _dietaryRestrictionsController.text.trim().isNotEmpty
            ? _dietaryRestrictionsController.text.trim()
            : null,
        planDurationDays: _planDurationDays,
      );

      // 调用生成
      await ref
          .read(createDietPlanNotifierProvider.notifier)
          .generateFromSkill(params);

      // 检查状态，仅在成功时关闭 Sheet
      if (mounted) {
        final state = ref.read(createDietPlanNotifierProvider);
        if (state.errorMessage == null) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // 错误会在notifier中处理
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createDietPlanNotifierProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('AI 引导创建饮食计划'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消', style: AppTextStyles.body),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 基本信息
                    _buildSectionTitle('基本信息'),
                    _buildBasicInfoForm(),
                    const SizedBox(height: 16),

                    // 目标设置
                    _buildSectionTitle('目标设置'),
                    _buildGoalSelection(),
                    const SizedBox(height: 16),

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
            if (state.errorMessage != null)
              _buildErrorBanner(state.errorMessage!),

            // 生成按钮
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBasicInfoForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // 第1行：性别选择器
        _buildEnumSelector<String>(
          label: '性别',
          value: _gender,
          values: const ['male', 'female'],
          getDisplayName: (g) => g == 'male' ? '男性' : '女性',
          getDescription: (g) => '',
          onChanged: (value) => setState(() => _gender = value),
          showDescription: false,
        ),
        const SizedBox(height: 8),
        // 第2行：体重 | 身高 | 年龄 | 体脂率
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: '体重(kg)',
                controller: _weightController,
                placeholder: '70',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: '身高(cm)',
                controller: _heightController,
                placeholder: '175',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: '年龄',
                controller: _ageController,
                placeholder: '30',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: '体脂率(%)',
                controller: _bodyFatController,
                placeholder: '14',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // 目标
        _buildEnumSelector<DietGoal>(
          label: '饮食目标',
          value: _goal,
          values: DietGoal.values,
          getDisplayName: (g) => g.displayName,
          getDescription: (g) => g.description,
          onChanged: (value) => setState(() => _goal = value),
          showDescription: false,
        ),
        const SizedBox(height: 12),
        // 活动水平
        _buildEnumSelector<ActivityLevel>(
          label: '活动水平',
          value: _activityLevel,
          values: ActivityLevel.values,
          getDisplayName: (a) => a.displayName,
          getDescription: (a) => a.description,
          onChanged: (value) => setState(() => _activityLevel = value),
        ),
        const SizedBox(height: 12),
        // 每日餐数 | 生成天数（同一行）
        Row(
          children: [
            Expanded(child: _buildMealCountSelector()),
            const SizedBox(width: 16),
            Expanded(child: _buildPlanDurationSelector()),
          ],
        ),
      ],
    );
  }

  Widget _buildEnumSelector<T>({
    required String label,
    required T value,
    required List<T> values,
    required String Function(T) getDisplayName,
    required String Function(T) getDescription,
    required Function(T) onChanged,
    bool showDescription = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.footnote.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            final isSelected = v == value;
            return GestureDetector(
              onTap: () => onChanged(v),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
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
                child: showDescription
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getDisplayName(v),
                            style: AppTextStyles.subhead.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            getDescription(v),
                            style: AppTextStyles.caption2.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        getDisplayName(v),
                        style: AppTextStyles.subhead.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

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
              '高级选项（可选）',
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

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 饮食偏好
        _buildMultiSelectorWithOther<DietaryPreference>(
          label: '饮食偏好（可多选）',
          values: DietaryPreference.values,
          selectedValues: _dietaryPreferences,
          getDisplayName: (p) => p.displayName,
          onToggle: (p) {
            setState(() {
              if (_dietaryPreferences.contains(p)) {
                _dietaryPreferences.remove(p);
              } else {
                _dietaryPreferences.add(p);
              }
            });
          },
          hasOther: _hasOtherDietaryPreference,
          onOtherToggle: () {
            setState(() {
              _hasOtherDietaryPreference = !_hasOtherDietaryPreference;
              if (!_hasOtherDietaryPreference) {
                _otherDietaryPreferenceController.clear();
              }
            });
          },
          otherController: _otherDietaryPreferenceController,
        ),
        const SizedBox(height: 12),

        // 其他要求
        Text(
          '其他要求',
          style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _dietaryRestrictionsController,
          placeholder: '填写过敏信息和不喜欢的食物（选填）',
          maxLines: 3,
          minLines: 3,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Widget _buildMealCountSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '每日餐数：$_mealCount 餐',
          style: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: _mealCount.toDouble(),
          min: 3,
          max: 6,
          divisions: 3,
          onChanged: (value) => setState(() => _mealCount = value.toInt()),
        ),
      ],
    );
  }

  Widget _buildPlanDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '生成天数：$_planDurationDays 天',
          style: AppTextStyles.callout.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        CupertinoSlider(
          value: _planDurationDays.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: (value) =>
              setState(() => _planDurationDays = value.toInt()),
        ),
      ],
    );
  }

  Widget _buildMultiSelectorWithOther<T>({
    required String label,
    required List<T> values,
    required Set<T> selectedValues,
    required String Function(T) getDisplayName,
    required Function(T) onToggle,
    required bool hasOther,
    required VoidCallback onOtherToggle,
    required TextEditingController otherController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.subhead.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            ...values.map((v) {
              final isSelected = selectedValues.contains(v);
              return GestureDetector(
                onTap: () => onToggle(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
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
                    getDisplayName(v),
                    style: AppTextStyles.caption1.copyWith(
                      color: isSelected
                          ? CupertinoColors.white
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
            // "其他"选项
            GestureDetector(
              onTap: onOtherToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hasOther
                      ? AppColors.primary
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasOther ? AppColors.primary : AppColors.divider,
                  ),
                ),
                child: Text(
                  '其他',
                  style: AppTextStyles.caption1.copyWith(
                    color: hasOther
                        ? CupertinoColors.white
                        : AppColors.textPrimary,
                    fontWeight: hasOther ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
        // "其他"选项的文本输入框
        if (hasOther) ...[
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: otherController,
            placeholder: '请输入其他选项',
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGenerateButton() {
    final state = ref.watch(createDietPlanNotifierProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _canGenerate && !state.isLoading ? _generatePlan : null,
        child: Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            color: _canGenerate && !state.isLoading
                ? AppColors.primary
                : CupertinoColors.quaternarySystemFill,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: state.isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(
                      color: CupertinoColors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '正在生成...',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: CupertinoColors.black,
                      ),
                    ),
                  ],
                )
              : Text(
                  '生成饮食计划',
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
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              ref.read(createDietPlanNotifierProvider.notifier).clearError();
            },
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: CupertinoColors.systemRed,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
