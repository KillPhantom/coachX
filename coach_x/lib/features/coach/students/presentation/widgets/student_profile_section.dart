import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:coach_x/features/chat/presentation/providers/chat_providers.dart';
import '../../data/models/student_detail_model.dart';
import '../providers/student_detail_providers.dart';
import 'ai_summary_dialog.dart';

/// 学生资料区块（重构版：头像+姓名+AI按钮同行）
class StudentProfileSection extends ConsumerWidget {
  final BasicInfo basicInfo;
  final StudentPlans plans;
  final StudentStats stats;

  const StudentProfileSection({
    super.key,
    required this.basicInfo,
    required this.plans,
    required this.stats,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 姓名 + AI按钮行
          _buildProfileHeader(context, ref, l10n),

          const SizedBox(height: 16),

          // 快捷操作按钮
          _buildQuickActions(context, ref, l10n),

          const SizedBox(height: 16),

          // 统计网格（3列：Sessions, Weight, Adherence）
          _buildStatsGrid(l10n),

          // 计划表格
          if (plans.hasAnyPlan) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.dividerLight),
            const SizedBox(height: 16),
            _buildPlansTable(context, l10n),
          ],
        ],
      ),
    );
  }

  /// 构建头像+姓名+AI按钮行（水平布局）
  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final isGenerating = ref.watch(isGeneratingAISummaryProvider(basicInfo.id));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 头像（60px，左侧）
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.backgroundWhite, width: 3),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: basicInfo.avatarUrl != null && basicInfo.avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    basicInfo.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildInitialAvatar(),
                  ),
                )
              : _buildInitialAvatar(),
        ),

        const SizedBox(width: 12),

        // 姓名 + Meta信息（中间，自动扩展）
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 姓名
              Text(
                basicInfo.name,
                style: AppTextStyles.title2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Meta信息（年龄、身高、体重）
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (basicInfo.age != null)
                    _buildMetaItem('👤 ${basicInfo.age} ${l10n.years}'),
                  if (basicInfo.height != null)
                    _buildMetaItem(
                      '📏 ${basicInfo.height!.toStringAsFixed(0)} cm',
                    ),
                  if (basicInfo.currentWeight != null)
                    _buildMetaItem(
                      '⚖️ ${basicInfo.currentWeight!.toStringAsFixed(1)} ${basicInfo.weightUnit}',
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // AI 按钮（最右侧）
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: isGenerating
              ? null
              : () => _handleAISummaryTap(context, ref), minimumSize: Size(0, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primaryAction, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isGenerating)
                  const CupertinoActivityIndicator(
                    radius: 8,
                    color: AppColors.primaryAction,
                  )
                else ...[
                  Text(
                    'AI',
                    style: AppTextStyles.caption1.copyWith(
                      color: AppColors.primaryAction,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.sparkles,
                    size: 16,
                    color: AppColors.primaryAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 处理AI总结按钮点击
  Future<void> _handleAISummaryTap(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    // 1. 检查缓存
    final cachedSummary = ref.read(aiSummaryCacheProvider(basicInfo.id));

    if (cachedSummary != null) {
      // 直接显示缓存的结果
      if (context.mounted) {
        AISummaryDialog.show(context, cachedSummary, basicInfo.name);
      }
      return;
    }

    // 2. 生成新的AI Summary
    // 设置loading状态
    ref.read(isGeneratingAISummaryProvider(basicInfo.id).notifier).state = true;

    try {
      // 调用生成
      final summary = await ref.read(
        generateAISummaryProvider({
          'studentId': basicInfo.id,
          'timeRange': ref.read(selectedTimeRangeProvider),
        }).future,
      );

      // 缓存结果
      ref.read(aiSummaryCacheProvider(basicInfo.id).notifier).state = summary;

      // 显示dialog
      if (context.mounted) {
        AISummaryDialog.show(context, summary, basicInfo.name);
      }
    } catch (e) {
      // 显示错误
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l10n.aiSummaryFailed),
            content: Text(l10n.aiSummaryFailedMessage),
            actions: [
              CupertinoDialogAction(
                child: Text(l10n.ok),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } finally {
      // 清除loading状态
      if (ref.context.mounted) {
        ref.read(isGeneratingAISummaryProvider(basicInfo.id).notifier).state =
            false;
      }
    }
  }

  /// 构建默认头像（首字母）
  Widget _buildInitialAvatar() {
    return Center(
      child: Text(
        basicInfo.nameInitial,
        style: AppTextStyles.title3.copyWith(
          color: CupertinoColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// 构建元信息项
  Widget _buildMetaItem(String text) {
    return Text(
      text,
      style: AppTextStyles.caption1.copyWith(color: AppColors.textSecondary),
    );
  }

  /// 构建快捷操作按钮
  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.successGreen,
      borderRadius: BorderRadius.circular(8),
      onPressed: () async {
        // 获取或创建对话，然后跳转
        try {
          final conversation = await ref.read(
            conversationProvider(basicInfo.id).future,
          );
          if (conversation != null && context.mounted) {
            context.push(RouteNames.getChatDetailRoute(conversation.id));
          }
        } catch (e) {
          // 显示错误提示
          if (context.mounted) {
            showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: Text(l10n.error),
                content: Text('Failed to create conversation: $e'),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.chat_bubble_fill,
            color: CupertinoColors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.message,
            style: AppTextStyles.footnote.copyWith(
              color: CupertinoColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计网格（3列：Sessions, Weight, Adherence）
  Widget _buildStatsGrid(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.dividerLight, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: stats.totalSessions.toString(),
            label: l10n.sessions,
          ),
          _buildStatItem(
            value:
                '${stats.weightChange >= 0 ? '+' : ''}${stats.weightChange.toStringAsFixed(1)}',
            label: l10n.weight,
          ),
          _buildStatItem(
            value: '${stats.adherenceRate.toStringAsFixed(0)}%',
            label: l10n.adherence,
          ),
        ],
      ),
    );
  }

  /// 构建单个统计项
  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.title3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 构建计划表格（单行三列，纵向分隔线）
  Widget _buildPlansTable(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        // 运动计划
        Expanded(
          child: _buildPlanCell(
            context: context,
            label: l10n.currentExercisePlan,
            planName: plans.exercisePlan?.name,
            onTap: plans.exercisePlan != null
                ? () => context.push('/training-plan/${plans.exercisePlan!.id}')
                : null,
          ),
        ),

        // 纵向分隔线
        Container(width: 1, height: 40, color: AppColors.dividerLight),

        // 饮食计划
        Expanded(
          child: _buildPlanCell(
            context: context,
            label: l10n.currentDietPlan,
            planName: plans.dietPlan?.name,
            onTap: plans.dietPlan != null
                ? () => context.push('/diet-plan/${plans.dietPlan!.id}')
                : null,
          ),
        ),

        // 纵向分隔线
        Container(width: 1, height: 40, color: AppColors.dividerLight),

        // 补剂计划
        Expanded(
          child: _buildPlanCell(
            context: context,
            label: l10n.currentSupplementPlan,
            planName: plans.supplementPlan?.name,
            onTap: plans.supplementPlan != null
                ? () => context.push(
                    '/supplement-plan/${plans.supplementPlan!.id}',
                  )
                : null,
          ),
        ),
      ],
    );
  }

  /// 构建单个计划单元格
  Widget _buildPlanCell({
    required BuildContext context,
    required String label,
    required String? planName,
    required VoidCallback? onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final hasPlan = planName != null;

    return GestureDetector(
      onTap: hasPlan ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 标签
            Text(
              label,
              style: AppTextStyles.caption2.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // 计划名称或"无计划"
            Text(
              planName ?? l10n.noPlan,
              style: AppTextStyles.caption1.copyWith(
                color: hasPlan ? AppColors.textPrimary : AppColors.textTertiary,
                fontWeight: hasPlan ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
