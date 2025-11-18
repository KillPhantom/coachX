import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/coach/exercise_library/data/models/exercise_template_model.dart';
import '../providers/exercise_template_search_providers.dart';

/// 动作搜索栏组件
///
/// 支持两种状态：
/// - 收起：显示标题 + 添加按钮
/// - 展开：显示搜索输入框 + 关闭按钮
class ExerciseSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<String>? onCreateNew; // 传递动作名称
  final ValueChanged<ExerciseTemplateModel>? onTemplateSelected;

  const ExerciseSearchBar({
    super.key,
    this.onCreateNew,
    this.onTemplateSelected,
  });

  @override
  ConsumerState<ExerciseSearchBar> createState() => _ExerciseSearchBarState();
}

class _ExerciseSearchBarState extends ConsumerState<ExerciseSearchBar>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _toggleSearchBar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        // 展开后自动聚焦
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      } else {
        // 收起时清空输入
        _searchController.clear();
        _focusNode.unfocus();
      }
    });
  }

  void _onTemplateSelected(ExerciseTemplateModel template) {
    widget.onTemplateSelected?.call(template);
    _toggleSearchBar(); // 选择后收起搜索栏
  }

  void _onCreateNew(String name) {
    widget.onCreateNew?.call(name); // 传递动作名称
    _toggleSearchBar(); // 创建后收起搜索栏
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = _searchController.text.isNotEmpty
        ? ref.watch(exerciseTemplateSearchProvider(_searchController.text))
        : <ExerciseTemplateModel>[];
    final showSuggestions = _focusNode.hasFocus && _searchController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部栏（固定高度，带动画切换）
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          height: 44,
          child: _isExpanded ? _buildSearchField(context, l10n) : _buildHeader(context, l10n),
        ),

        // 建议列表（浮动显示）
        if (_isExpanded && showSuggestions) ...[
          const SizedBox(height: 8),
          _buildSuggestionsList(context, l10n, suggestions),
        ],
      ],
    );
  }

  /// 收起状态：标题 + 添加按钮
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.exerciseList,
            style: AppTextStyles.callout,
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _toggleSearchBar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.addExercise,
                style: AppTextStyles.footnote.copyWith(
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 展开状态：搜索输入框 + 关闭按钮
  Widget _buildSearchField(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 搜索输入框
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              focusNode: _focusNode,
              placeholder: l10n.searchExercises,
              style: AppTextStyles.callout,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              onChanged: (_) => setState(() {}),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  CupertinoIcons.search,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 关闭按钮
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _toggleSearchBar,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建建议列表
  Widget _buildSuggestionsList(
    BuildContext context,
    AppLocalizations l10n,
    List<ExerciseTemplateModel> suggestions,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(
        maxHeight: 250, // 最大高度限制
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: suggestions.length + 1, // +1 for "Create New" option
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        itemBuilder: (context, index) {
          // "创建新动作" 选项（始终在最后）
          if (index == suggestions.length) {
            return _buildCreateNewOption(context, l10n);
          }

          // 已存在的模板
          final template = suggestions[index];
          return _buildTemplateOption(context, template);
        },
      ),
    );
  }

  /// 构建已存在模板选项
  Widget _buildTemplateOption(
    BuildContext context,
    ExerciseTemplateModel template,
  ) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onPressed: () => _onTemplateSelected(template),
      child: Row(
        children: [
          // 模板图标
          Icon(
            CupertinoIcons.square_stack_3d_up,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),

          // 名称和标签
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: AppTextStyles.callout.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (template.tags.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    template.tags.join(', '),
                    style: AppTextStyles.caption1.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建"创建新动作"选项
  Widget _buildCreateNewOption(BuildContext context, AppLocalizations l10n) {
    final query = _searchController.text.trim();

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onPressed: () => _onCreateNew(query),
      minSize: 0,
      child: Row(
        children: [
          // 创建图标
          Icon(
            CupertinoIcons.add_circled_solid,
            size: 18,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),

          // 提示文字
          Expanded(
            child: Text(
              l10n.createNewExercise(query),
              style: AppTextStyles.callout.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
