import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // For LinearProgressIndicator
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/enums/activity_level.dart';
import 'package:coach_x/core/enums/diet_goal.dart';
import 'package:coach_x/core/enums/dietary_preference.dart';
import 'package:coach_x/features/coach/students/data/repositories/student_repository_impl.dart';
import 'package:coach_x/features/coach/students/data/models/plan_summary.dart';
import 'package:coach_x/features/coach/plans/data/models/diet_plan_generation_params.dart';
import 'package:coach_x/features/coach/plans/presentation/providers/create_diet_plan_providers.dart';

/// 饮食计划 AI 引导创建视图（3步骤表单）
///
/// 设计理念: Progressive Card Flow
/// 将饮食计划配置拆分为 3 个核心步骤，降低认知负荷。
/// Step 1: Personal Profile (个人资料)
/// Step 2: Goals & Activity (目标与活动)
/// Step 3: Preferences & Restrictions (偏好与限制)
class DietAIGuidedView extends ConsumerStatefulWidget {
  final VoidCallback onGenerationStart;

  const DietAIGuidedView({super.key, required this.onGenerationStart});

  @override
  ConsumerState<DietAIGuidedView> createState() => _DietAIGuidedViewState();
}

class _DietAIGuidedViewState extends ConsumerState<DietAIGuidedView> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Step 1: Personal Profile
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  String? _gender; // 'male' or 'female'

  // Step 2: Goals & Activity
  String? _dietGoal; // 'muscleGain', 'fatLoss', 'maintenance'
  String? _activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'veryActive'
  String? _referenceTrainingPlan;
  String? _referenceTrainingPlanId; // 训练计划 ID

  // 训练计划选择器状态
  bool _isTrainingPlanExpanded = false;
  List<PlanSummary> _exercisePlans = [];
  bool _isLoadingPlans = false;

  // Step 3: Preferences
  int _mealCount = 4; // 默认 4 餐
  final Set<String> _dietaryPreferences = {}; // 饮食偏好
  final TextEditingController _dietaryRestrictionsController = TextEditingController(); // 饮食限制和其他要求

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _bodyFatController.dispose();
    _dietaryRestrictionsController.dispose();
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
      _generateDietPlan();
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
        // Step 1: 必填 - 体重、身高、年龄、性别
        return _weightController.text.isNotEmpty &&
            _heightController.text.isNotEmpty &&
            _ageController.text.isNotEmpty &&
            _gender != null;
      case 1:
        // Step 2: 必填 - 饮食目标、活动水平
        return _dietGoal != null && _activityLevel != null;
      case 2:
        // Step 3: 所有字段可选
        return true;
      default:
        return false;
    }
  }

  void _generateDietPlan() async {
    if (!_canProceed) return;

    AppLogger.info('🥗 开始生成饮食计划');
    AppLogger.info('体重: ${_weightController.text} kg');
    AppLogger.info('身高: ${_heightController.text} cm');
    AppLogger.info('年龄: ${_ageController.text}');
    AppLogger.info('性别: $_gender');
    AppLogger.info('饮食目标: $_dietGoal');
    AppLogger.info('活动水平: $_activityLevel');
    AppLogger.info('每日餐数: $_mealCount');
    AppLogger.info('饮食偏好: $_dietaryPreferences');
    AppLogger.info('饮食限制: ${_dietaryRestrictionsController.text}');

    widget.onGenerationStart();

    // 构建参数
    final params = DietPlanGenerationParams(
      weightKg: double.parse(_weightController.text),
      heightCm: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      gender: _gender!,
      activityLevel: _parseActivityLevel(_activityLevel!),
      goal: _parseDietGoal(_dietGoal!),
      bodyFatPercentage: _bodyFatController.text.isNotEmpty
          ? double.tryParse(_bodyFatController.text)
          : null,
      trainingPlanId: _referenceTrainingPlanId,
      dietaryPreferences: _dietaryPreferences.isNotEmpty
          ? _dietaryPreferences
              .map((p) => _parseDietaryPreference(p))
              .whereType<DietaryPreference>()
              .toList()
          : null,
      mealCount: _mealCount,
      dietaryRestrictions: _dietaryRestrictionsController.text.trim().isNotEmpty
          ? _dietaryRestrictionsController.text.trim()
          : null,
    );

    // 调用生成
    await ref
        .read(createDietPlanNotifierProvider.notifier)
        .generateFromParamsStreaming(params);
  }

  // 辅助方法：将字符串转换为 DietGoal 枚举
  DietGoal _parseDietGoal(String value) {
    switch (value) {
      case 'muscleGain':
        return DietGoal.muscleGain;
      case 'fatLoss':
        return DietGoal.fatLoss;
      case 'maintenance':
        return DietGoal.maintenance;
      default:
        return DietGoal.maintenance;
    }
  }

  // 辅助方法：将字符串转换为 ActivityLevel 枚举
  ActivityLevel _parseActivityLevel(String value) {
    switch (value) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'light':
        return ActivityLevel.lightlyActive;
      case 'moderate':
        return ActivityLevel.moderatelyActive;
      case 'active':
        return ActivityLevel.veryActive;
      case 'veryActive':
        return ActivityLevel.extremelyActive;
      default:
        return ActivityLevel.moderatelyActive;
    }
  }

  // 辅助方法：将字符串转换为 DietaryPreference 枚举
  DietaryPreference? _parseDietaryPreference(String value) {
    switch (value) {
      case 'vegetarian':
        return DietaryPreference.vegetarian;
      case 'vegan':
        return DietaryPreference.vegan;
      case 'lowCarb':
        return DietaryPreference.carbCycling;
      case 'highProtein':
        return DietaryPreference.highCarb;
      case 'keto':
        return DietaryPreference.keto;
      default:
        return null;
    }
  }

  /// 切换训练计划选择器展开/收起
  Future<void> _toggleTrainingPlanPicker() async {
    if (_isTrainingPlanExpanded) {
      // 收起
      setState(() {
        _isTrainingPlanExpanded = false;
      });
      return;
    }

    // 展开前先加载训练计划列表
    if (_exercisePlans.isEmpty) {
      await _loadTrainingPlans();
    }

    setState(() {
      _isTrainingPlanExpanded = true;
    });
  }

  /// 加载训练计划列表
  Future<void> _loadTrainingPlans() async {
    setState(() {
      _isLoadingPlans = true;
    });

    try {
      final repository = StudentRepositoryImpl();
      final plansMap = await repository.fetchAvailablePlansSummary(maxPerType: 100);
      final exercisePlans = plansMap['exercise'] ?? [];

      if (!mounted) return;

      setState(() {
        _exercisePlans = exercisePlans;
        _isLoadingPlans = false;
      });

      AppLogger.info('加载训练计划列表成功: ${_exercisePlans.length} 个');
    } catch (e, stackTrace) {
      AppLogger.error('加载训练计划列表失败', e, stackTrace);
      if (!mounted) return;

      setState(() {
        _isLoadingPlans = false;
      });

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('错误'),
          content: Text('加载训练计划失败: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('确定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  /// 选择训练计划
  void _selectTrainingPlan(PlanSummary? plan) {
    setState(() {
      if (plan == null) {
        // 清除选择
        _referenceTrainingPlan = null;
        _referenceTrainingPlanId = null;
      } else {
        // 选中计划
        _referenceTrainingPlan = plan.name;
        _referenceTrainingPlanId = plan.id;
      }
      _isTrainingPlanExpanded = false; // 选择后收起
    });
    AppLogger.info('选中训练计划: ${plan?.name ?? "无"}');
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
    final l10n = AppLocalizations.of(context)!;
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
                _getStepTitle(_currentStep, l10n),
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

  String _getStepTitle(int step, AppLocalizations l10n) {
    switch (step) {
      case 0:
        return l10n.dietStep1ProfileTitle;
      case 1:
        return l10n.dietStep2GoalTitle;
      case 2:
        return l10n.dietStep3PreferencesTitle;
      default:
        return '';
    }
  }

  // --- Step 1: Personal Profile ---
  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            l10n.dietStep1ProfileTitle,
            l10n.dietStep1ProfileSubtitle,
          ),
          const SizedBox(height: 24),

          // 体重
          Text(l10n.weightKg, style: AppTextStyles.subhead),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _weightController,
            placeholder: '70',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            style: AppTextStyles.body,
            suffix: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('kg', style: AppTextStyles.body),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          // 身高
          Text(l10n.heightCm, style: AppTextStyles.subhead),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _heightController,
            placeholder: '175',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            style: AppTextStyles.body,
            suffix: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('cm', style: AppTextStyles.body),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          // 年龄
          Text(l10n.age, style: AppTextStyles.subhead),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _ageController,
            placeholder: '25',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            style: AppTextStyles.body,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          // 性别
          Text(l10n.gender, style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = 'male'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _gender == 'male'
                            ? AppColors.cardBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _gender == 'male'
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
                        l10n.male,
                        style: AppTextStyles.callout.copyWith(
                          color: _gender == 'male'
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = 'female'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _gender == 'female'
                            ? AppColors.cardBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _gender == 'female'
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
                        l10n.female,
                        style: AppTextStyles.callout.copyWith(
                          color: _gender == 'female'
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 体脂率（可选）
          Text(l10n.bodyFatPercentage, style: AppTextStyles.subhead),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _bodyFatController,
            placeholder: '15',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            style: AppTextStyles.body,
            suffix: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('%', style: AppTextStyles.body),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Goals & Activity ---
  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            l10n.dietStep2GoalTitle,
            l10n.dietStep2GoalSubtitle,
          ),
          const SizedBox(height: 24),

          // 饮食目标
          Text(l10n.dietGoal, style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildOptionChip('muscleGain', '增肌', _dietGoal == 'muscleGain',
                  () => setState(() => _dietGoal = 'muscleGain')),
              _buildOptionChip('fatLoss', '减脂', _dietGoal == 'fatLoss',
                  () => setState(() => _dietGoal = 'fatLoss')),
              _buildOptionChip('maintenance', '维持', _dietGoal == 'maintenance',
                  () => setState(() => _dietGoal = 'maintenance')),
            ],
          ),

          const SizedBox(height: 24),

          // 活动水平
          Text(l10n.activityLevel, style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildOptionChip(
                  'sedentary',
                  '久坐',
                  _activityLevel == 'sedentary',
                  () => setState(() => _activityLevel = 'sedentary')),
              _buildOptionChip(
                  'light',
                  '轻度活动',
                  _activityLevel == 'light',
                  () => setState(() => _activityLevel = 'light')),
              _buildOptionChip(
                  'moderate',
                  '中度活动',
                  _activityLevel == 'moderate',
                  () => setState(() => _activityLevel = 'moderate')),
              _buildOptionChip(
                  'active',
                  '高度活动',
                  _activityLevel == 'active',
                  () => setState(() => _activityLevel = 'active')),
              _buildOptionChip(
                  'veryActive',
                  '非常活跃',
                  _activityLevel == 'veryActive',
                  () => setState(() => _activityLevel = 'veryActive')),
            ],
          ),

          const SizedBox(height: 24),

          // 引用训练计划（可选）- 展开式下拉菜单
          _buildTrainingPlanPicker(l10n),
        ],
      ),
    );
  }

  // --- Step 3: Preferences & Restrictions ---
  Widget _buildStep3() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            l10n.dietStep3PreferencesTitle,
            l10n.dietStep3PreferencesSubtitle,
          ),
          const SizedBox(height: 24),

          // 每日餐数
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.mealCount, style: AppTextStyles.subhead),
              Text(
                '$_mealCount 餐',
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
              value: _mealCount.toDouble(),
              min: 2,
              max: 6,
              divisions: 4,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() => _mealCount = value.toInt());
              },
            ),
          ),

          const SizedBox(height: 24),

          // 饮食偏好
          Text(l10n.dietaryPreferences, style: AppTextStyles.subhead),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMultiSelectChip('vegetarian', '素食'),
              _buildMultiSelectChip('vegan', '纯素'),
              _buildMultiSelectChip('lowCarb', '低碳水'),
              _buildMultiSelectChip('highProtein', '高蛋白'),
              _buildMultiSelectChip('keto', '生酮'),
            ],
          ),

          const SizedBox(height: 24),

          // 其他要求
          Text(l10n.dietaryRestrictions, style: AppTextStyles.subhead),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _dietaryRestrictionsController,
            placeholder: l10n.dietaryRestrictionsPlaceholder,
            maxLines: 4,
            minLines: 4,
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

  Widget _buildOptionChip(
      String id, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          label,
          style: AppTextStyles.callout.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChip(String id, String label) {
    final isSelected = _dietaryPreferences.contains(id);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _dietaryPreferences.remove(id);
          } else {
            _dietaryPreferences.add(id);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          label,
          style: AppTextStyles.callout.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建训练计划选择器（展开式下拉菜单）
  Widget _buildTrainingPlanPicker(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(l10n.referenceTrainingPlan, style: AppTextStyles.subhead),
        const SizedBox(height: 8),

        // 选择器容器
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              // 收起/展开的头部按钮
              GestureDetector(
                onTap: _toggleTrainingPlanPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _referenceTrainingPlan ?? '无',
                          style: AppTextStyles.body.copyWith(
                            color: _referenceTrainingPlan != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        _isTrainingPlanExpanded
                            ? CupertinoIcons.chevron_up
                            : CupertinoIcons.chevron_down,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),

              // 展开的列表
              if (_isTrainingPlanExpanded) ...[
                Container(
                  height: 1,
                  color: AppColors.divider,
                ),
                _buildTrainingPlanList(l10n),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 构建训练计划列表
  Widget _buildTrainingPlanList(AppLocalizations l10n) {
    if (_isLoadingPlans) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const CupertinoActivityIndicator(),
      );
    }

    if (_exercisePlans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          '暂无可引用的训练计划',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 250, // 最大高度限制
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _exercisePlans.length + 1, // +1 for "清除" option
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          // "清除" 选项（在第一个位置）
          if (index == 0) {
            return GestureDetector(
              onTap: () => _selectTrainingPlan(null),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.xmark_circle,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '清除选择',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 训练计划选项
          final plan = _exercisePlans[index - 1];
          final isSelected = _referenceTrainingPlanId == plan.id;

          return GestureDetector(
            onTap: () => _selectTrainingPlan(plan),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardBackground,
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    size: 18,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (plan.description != null && plan.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            plan.description!,
                            style: AppTextStyles.footnote.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
    final l10n = AppLocalizations.of(context)!;
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
