import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_dimensions.dart';
import '../../../../../core/exceptions/template_in_use_exception.dart';
import '../../data/models/exercise_library_state.dart';
import '../providers/exercise_library_providers.dart';
import '../widgets/exercise_template_card.dart';
import '../widgets/tag_filter_chips.dart';
import '../widgets/create_exercise_sheet.dart';
import '../widgets/delete_template_error_dialog.dart';

/// Exercise Library Page - 动作库主页面
class ExerciseLibraryPage extends ConsumerStatefulWidget {
  const ExerciseLibraryPage({super.key});

  @override
  ConsumerState<ExerciseLibraryPage> createState() =>
      _ExerciseLibraryPageState();
}

class _ExerciseLibraryPageState extends ConsumerState<ExerciseLibraryPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // 页面加载时初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseLibraryNotifierProvider.notifier).loadData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // 检测是否接近底部（距离底部200px时触发）
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 触发加载更多
      ref.read(exerciseLibraryNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(exerciseLibraryNotifierProvider);
    final templates = ref.watch(exerciseTemplatesProvider);
    final loadingStatus = state.loadingStatus;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(l10n.exerciseLibrary),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showCreateExerciseSheet,
          child: const Icon(CupertinoIcons.add, size: 28),
        ),
      ),
      child: SafeArea(
        child: _buildBody(context, loadingStatus, templates, state),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LoadingStatus status,
    List templates,
    ExerciseLibraryState state,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // 加载中
    if (status == LoadingStatus.loading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // 错误状态
    if (status == LoadingStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error ?? l10n.errorOccurred, style: AppTextStyles.body),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () {
                ref.read(exerciseLibraryNotifierProvider.notifier).loadData();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (templates.isEmpty && state.searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.square_list,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noExercisesYet,
              style: AppTextStyles.title3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createFirstExercise,
              style: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _showCreateExerciseSheet,
              child: Text(l10n.newExercise),
            ),
          ],
        ),
      );
    }

    // 列表视图
    return CustomScrollView(
      controller: _scrollController, // 绑定控制器
      slivers: [
        // 搜索栏占位
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CupertinoSearchTextField(
              placeholder: l10n.searchExercises,
              onChanged: (value) {
                ref
                    .read(exerciseLibraryNotifierProvider.notifier)
                    .searchTemplates(value);
              },
            ),
          ),
        ),

        // 标签筛选
        const SliverToBoxAdapter(child: TagFilterChips()),

        // 动作列表
        if (templates.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                l10n.noResults,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final template = templates[index];
              return ExerciseTemplateCard(
                template: template,
                onTap: () => _showEditExerciseSheet(template),
                onLongPress: () => _showDeleteDialog(template),
              );
            }, childCount: templates.length),
          ),

        // 加载更多指示器
        if (state.isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Center(
                child: Column(
                  children: [
                    const CupertinoActivityIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loadingMore,
                      style: AppTextStyles.caption1.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 到底提示（没有更多数据时）
        if (!state.hasMoreData && templates.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Center(
                child: Text(
                  l10n.noMoreData,
                  style: AppTextStyles.caption1.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCreateExerciseSheet() {
    CreateExerciseSheet.show(context);
  }

  void _showEditExerciseSheet(dynamic template) {
    CreateExerciseSheet.show(context, template: template);
  }

  void _showDeleteDialog(dynamic template) {
    final l10n = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteExercise),
        content: Text(l10n.confirmDeleteExercise),
        actions: [
          CupertinoDialogAction(
            child: Text(l10n.cancel),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(exerciseLibraryNotifierProvider.notifier)
                    .deleteTemplate(template.id);
              } on TemplateInUseException catch (e) {
                // 模板正在被使用，显示专用错误对话框
                if (mounted) {
                  DeleteTemplateErrorDialog.show(context, e.planCount);
                }
              } catch (e) {
                // 其他错误，显示通用错误对话框
                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text(l10n.errorOccurred),
                      content: Text(e.toString()),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(l10n.ok),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
