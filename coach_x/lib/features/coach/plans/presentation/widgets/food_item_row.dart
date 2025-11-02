import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/features/coach/plans/data/models/food_item.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/core/services/ai_service.dart';
import 'package:coach_x/core/utils/logger.dart';

/// 食物条目行组件
class FoodItemRow extends StatefulWidget {
  final FoodItem item;
  final int index;
  final ValueChanged<String>? onFoodChanged;
  final ValueChanged<String>? onAmountChanged;
  final ValueChanged<double>? onProteinChanged;
  final ValueChanged<double>? onCarbsChanged;
  final ValueChanged<double>? onFatChanged;
  final ValueChanged<double>? onCaloriesChanged;
  final VoidCallback? onDelete;

  // Review Mode 相关
  final bool isHighlighted;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;

  const FoodItemRow({
    super.key,
    required this.item,
    required this.index,
    this.onFoodChanged,
    this.onAmountChanged,
    this.onProteinChanged,
    this.onCarbsChanged,
    this.onFatChanged,
    this.onCaloriesChanged,
    this.onDelete,
    this.isHighlighted = false,
    this.beforeData,
    this.afterData,
  });

  @override
  State<FoodItemRow> createState() => _FoodItemRowState();
}

class _FoodItemRowState extends State<FoodItemRow>
    with SingleTickerProviderStateMixin {
  late TextEditingController _foodController;
  late TextEditingController _amountController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _caloriesController;

  // AI 获取状态
  bool _isLoadingMacros = false;
  String? _aiErrorMessage;
  Timer? _errorTimer;
  bool _showValidationError = false;

  // 脉冲动画
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _foodController = TextEditingController(text: widget.item.food);
    _amountController = TextEditingController(text: widget.item.amount);
    _proteinController = TextEditingController(
      text: widget.item.protein == 0.0 ? '' : widget.item.protein.toString(),
    );
    _carbsController = TextEditingController(
      text: widget.item.carbs == 0.0 ? '' : widget.item.carbs.toString(),
    );
    _fatController = TextEditingController(
      text: widget.item.fat == 0.0 ? '' : widget.item.fat.toString(),
    );
    _caloriesController = TextEditingController(
      text: widget.item.calories == 0.0 ? '' : widget.item.calories.toString(),
    );

    // 脉冲动画控制器
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseController = controller;

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

    // 如果高亮，启动脉冲动画
    if (widget.isHighlighted) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FoodItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.food != widget.item.food &&
        _foodController.text != widget.item.food) {
      _foodController.text = widget.item.food;
    }
    if (oldWidget.item.amount != widget.item.amount &&
        _amountController.text != widget.item.amount) {
      _amountController.text = widget.item.amount;
    }

    // 控制脉冲动画的启动和停止
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _pulseController?.repeat(reverse: true);
    } else if (!widget.isHighlighted && oldWidget.isHighlighted) {
      _pulseController?.stop();
      _pulseController?.reset();
    }
  }

  @override
  void dispose() {
    _foodController.dispose();
    _amountController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _caloriesController.dispose();
    _errorTimer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  /// 解析份量，返回克数
  double _parseAmount(String amountText) {
    if (amountText.isEmpty) return 100.0; // 默认100g

    // 提取数字
    final numRegex = RegExp(r'(\d+\.?\d*)');
    final match = numRegex.firstMatch(amountText);

    if (match == null) return 100.0;

    final number = double.tryParse(match.group(1)!) ?? 100.0;

    // 处理单位转换
    final lowerText = amountText.toLowerCase();
    if (lowerText.contains('kg') || lowerText.contains('千克')) {
      return number * 1000;
    }

    // 默认为克
    return number;
  }

  /// 填充营养数据到输入框
  void _fillMacrosToInputs(Macros macros, double grams) {
    final multiplier = grams / 100.0;

    final actualProtein = macros.protein * multiplier;
    final actualCarbs = macros.carbs * multiplier;
    final actualFat = macros.fat * multiplier;
    final actualCalories = macros.calories * multiplier;

    // 更新 controllers
    _proteinController.text = actualProtein.toStringAsFixed(1);
    _carbsController.text = actualCarbs.toStringAsFixed(1);
    _fatController.text = actualFat.toStringAsFixed(1);
    _caloriesController.text = actualCalories.toStringAsFixed(0);

    // 触发 onChanged 回调
    if (widget.onProteinChanged != null) {
      widget.onProteinChanged!(actualProtein);
    }
    if (widget.onCarbsChanged != null) {
      widget.onCarbsChanged!(actualCarbs);
    }
    if (widget.onFatChanged != null) {
      widget.onFatChanged!(actualFat);
    }
    if (widget.onCaloriesChanged != null) {
      widget.onCaloriesChanged!(actualCalories);
    }

    AppLogger.info(
      '✅ 营养数据已填充 - 蛋白质:${actualProtein.toStringAsFixed(1)}g, 碳水:${actualCarbs.toStringAsFixed(1)}g, 脂肪:${actualFat.toStringAsFixed(1)}g, 卡路里:${actualCalories.toStringAsFixed(0)}',
    );
  }

  /// 显示错误提示
  void _showError(String message) {
    setState(() {
      _aiErrorMessage = message;
    });

    // 3秒后自动清除
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _aiErrorMessage = null;
        });
      }
    });
  }

  /// 获取输入框边框颜色
  Color _getBorderColor(BuildContext context, bool hasValue) {
    if (_showValidationError && !hasValue) {
      return CupertinoColors.systemRed;
    }
    return CupertinoColors.separator.resolveFrom(context);
  }

  /// Sparkle 按钮点击处理
  void _onSparklePressed() {
    final hasFood = _foodController.text.trim().isNotEmpty;
    final hasAmount = _amountController.text.trim().isNotEmpty;

    // 验证必填项
    if (!hasFood || !hasAmount) {
      setState(() {
        _showValidationError = true;
      });
      _showError('请先填写食物名称和分量');
      return;
    }

    // 清除验证错误状态
    setState(() {
      _showValidationError = false;
    });

    _fetchMacrosFromAI();
  }

  /// AI 获取营养数据
  Future<void> _fetchMacrosFromAI() async {
    final foodName = _foodController.text.trim();

    setState(() {
      _isLoadingMacros = true;
      _aiErrorMessage = null;
    });

    try {
      AppLogger.info('🤖 开始获取食物营养信息 - 食物: $foodName');

      // 调用 AI 服务
      final macros = await AIService.getFoodMacros(foodName);

      // 检查是否返回空数据
      if (macros.protein == 0 &&
          macros.carbs == 0 &&
          macros.fat == 0 &&
          macros.calories == 0) {
        _showError('AI 无法识别该食物，请手动输入');
        AppLogger.warning('⚠️ AI 返回空营养数据');
        return;
      }

      // 解析份量
      final grams = _parseAmount(_amountController.text);
      AppLogger.debug('📏 解析份量: ${_amountController.text} → ${grams}g');

      // 填充营养数据
      _fillMacrosToInputs(macros, grams);
    } catch (e, stackTrace) {
      AppLogger.error('❌ AI 获取营养信息失败', e, stackTrace);
      _showError('获取失败，请手动输入');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMacros = false;
        });
      }
    }
  }

  /// 构建 before/after 对比视图
  Widget _buildComparisonView(BuildContext context) {
    if (widget.beforeData == null || widget.afterData == null) {
      return const SizedBox.shrink();
    }

    final beforeFood = widget.beforeData!['food'] as String? ?? '';
    final beforeAmount = widget.beforeData!['amount'] as String? ?? '';
    final beforeProtein =
        (widget.beforeData!['protein'] as num?)?.toDouble() ?? 0.0;
    final beforeCarbs =
        (widget.beforeData!['carbs'] as num?)?.toDouble() ?? 0.0;
    final beforeFat = (widget.beforeData!['fat'] as num?)?.toDouble() ?? 0.0;
    final beforeCalories =
        (widget.beforeData!['calories'] as num?)?.toDouble() ?? 0.0;

    final afterFood = widget.afterData!['food'] as String? ?? '';
    final afterAmount = widget.afterData!['amount'] as String? ?? '';
    final afterProtein =
        (widget.afterData!['protein'] as num?)?.toDouble() ?? 0.0;
    final afterCarbs = (widget.afterData!['carbs'] as num?)?.toDouble() ?? 0.0;
    final afterFat = (widget.afterData!['fat'] as num?)?.toDouble() ?? 0.0;
    final afterCalories =
        (widget.afterData!['calories'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 序号 + 食物名称和分量对比
          Row(
            children: [
              // 序号徽章
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index + 1}',
                  style: AppTextStyles.tabLabel.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 食物名称和分量对比
              Expanded(
                child: Row(
                  children: [
                    // Before
                    Text(
                      '$beforeFood $beforeAmount',
                      style: AppTextStyles.footnote.copyWith(
                        color: CupertinoColors.systemRed.resolveFrom(context),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      ' → ',
                      style: AppTextStyles.footnote.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                    // After
                    Text(
                      '$afterFood $afterAmount',
                      style: AppTextStyles.footnote.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 营养数据对比
          Row(
            children: [
              Expanded(
                child: _buildNutrientComparisonChip(
                  context,
                  '蛋白',
                  beforeProtein,
                  afterProtein,
                  'g',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildNutrientComparisonChip(
                  context,
                  '碳水',
                  beforeCarbs,
                  afterCarbs,
                  'g',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildNutrientComparisonChip(
                  context,
                  '脂肪',
                  beforeFat,
                  afterFat,
                  'g',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildNutrientComparisonChip(
                  context,
                  '热量',
                  beforeCalories,
                  afterCalories,
                  '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建营养对比 chip
  Widget _buildNutrientComparisonChip(
    BuildContext context,
    String label,
    double before,
    double after,
    String unit,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.tabLabel.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                before.toStringAsFixed(unit.isEmpty ? 0 : 1),
                style: AppTextStyles.tabLabel.copyWith(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                '→',
                style: AppTextStyles.tabLabel.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              Text(
                after.toStringAsFixed(unit.isEmpty ? 0 : 1),
                style: AppTextStyles.tabLabel.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果是 Review Mode 高亮状态，显示对比视图
    if (widget.isHighlighted &&
        widget.beforeData != null &&
        widget.afterData != null) {
      Widget comparisonWidget = _buildComparisonView(context);

      // 应用脉冲动画
      if (_pulseAnimation != null) {
        comparisonWidget = AnimatedBuilder(
          animation: _pulseAnimation!,
          builder: (context, child) {
            return Transform.scale(scale: _pulseAnimation!.value, child: child);
          },
          child: comparisonWidget,
        );
      }

      return comparisonWidget;
    }

    // 正常编辑模式
    final hasFood = _foodController.text.trim().isNotEmpty;
    final hasAmount = _amountController.text.trim().isNotEmpty;
    final canFetch = hasFood && hasAmount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 主容器
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：序号 + 食物名称 + 分量 + Sparkle
              Row(
                children: [
                  // 序号徽章
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index + 1}',
                      style: AppTextStyles.tabLabel.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 食物名称输入框
                  Flexible(
                    flex: 3,
                    child: CupertinoTextField(
                      controller: _foodController,
                      placeholder: '食物名称',
                      onChanged: (value) {
                        setState(() {
                          if (_showValidationError && value.trim().isNotEmpty) {
                            _showValidationError = false;
                          }
                        });
                        if (widget.onFoodChanged != null) {
                          widget.onFoodChanged!(value);
                        }
                      },
                      style: AppTextStyles.caption1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getBorderColor(context, hasFood),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // 分量输入框
                  Flexible(
                    flex: 2,
                    child: CupertinoTextField(
                      controller: _amountController,
                      placeholder: '分量',
                      onChanged: (value) {
                        setState(() {
                          if (_showValidationError && value.trim().isNotEmpty) {
                            _showValidationError = false;
                          }
                        });
                        if (widget.onAmountChanged != null) {
                          widget.onAmountChanged!(value);
                        }
                      },
                      style: AppTextStyles.caption1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6.resolveFrom(context),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getBorderColor(context, hasAmount),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Sparkle 图标按钮
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 0,
                      onPressed: _isLoadingMacros ? null : _onSparklePressed,
                      child: _isLoadingMacros
                          ? const CupertinoActivityIndicator(radius: 8)
                          : Icon(
                              CupertinoIcons.sparkles,
                              color: canFetch
                                  ? AppColors.primary
                                  : CupertinoColors.quaternaryLabel.resolveFrom(
                                      context,
                                    ),
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),

              // 错误提示（可选）
              if (_aiErrorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _aiErrorMessage!,
                  style: AppTextStyles.tabLabel.copyWith(
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],

              const SizedBox(height: 6),

              // 第二行：营养数据输入框
              Row(
                children: [
                  // 蛋白质
                  Expanded(
                    child: _buildNutritionField(
                      context: context,
                      controller: _proteinController,
                      label: '蛋白质(g)',
                      onChanged: (value) {
                        final num = double.tryParse(value);
                        if (num != null && widget.onProteinChanged != null) {
                          widget.onProteinChanged!(num);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 碳水
                  Expanded(
                    child: _buildNutritionField(
                      context: context,
                      controller: _carbsController,
                      label: '碳水(g)',
                      onChanged: (value) {
                        final num = double.tryParse(value);
                        if (num != null && widget.onCarbsChanged != null) {
                          widget.onCarbsChanged!(num);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 脂肪
                  Expanded(
                    child: _buildNutritionField(
                      context: context,
                      controller: _fatController,
                      label: '脂肪(g)',
                      onChanged: (value) {
                        final num = double.tryParse(value);
                        if (num != null && widget.onFatChanged != null) {
                          widget.onFatChanged!(num);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),

                  // 卡路里
                  Expanded(
                    child: _buildNutritionField(
                      context: context,
                      controller: _caloriesController,
                      label: '卡路里',
                      onChanged: (value) {
                        final num = double.tryParse(value);
                        if (num != null && widget.onCaloriesChanged != null) {
                          widget.onCaloriesChanged!(num);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 右上角删除按钮
        if (widget.onDelete != null)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemBackground.resolveFrom(context),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 24,
                onPressed: widget.onDelete,
                child: Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNutritionField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.tabLabel.copyWith(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 2),
        CupertinoTextField(
          controller: controller,
          placeholder: '0',
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTextStyles.caption1,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
