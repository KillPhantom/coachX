import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/models/training_feed_item.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../coach/plans/data/models/macros.dart';
import '../../../student/home/presentation/widgets/diet_plan_card_components/total_nutrition_card.dart';
import 'package:photo_view/photo_view.dart';

class TextFeedItem extends StatelessWidget {
  final TrainingFeedItem feedItem;
  final VoidCallback onCommentTap;
  final VoidCallback onDetailTap;

  const TextFeedItem({
    super.key,
    required this.feedItem,
    required this.onCommentTap,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = feedItem.metadata!;
    final isAggregated = metadata['isAggregated'] == true;

    if (isAggregated) {
      return _buildAggregatedView(context, metadata);
    } else {
      return _buildSingleView(context, metadata);
    }
  }

  Widget _buildAggregatedView(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
    final exercises = metadata['exercises'] as List? ?? [];
    final meals = metadata['meals'] as List? ?? [];
    final hasDiet =
        meals.isNotEmpty ||
        metadata['actualMacros'] != null ||
        metadata['targetMacros'] != null;
    final hasExercises = exercises.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          color: CupertinoColors.black,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                feedItem.exerciseName ?? 'Daily Summary',
                style: AppTextStyles.largeTitle.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 8),

              // 副标题
              Text(
                '训练与饮食 · 每日汇总',
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 32),

              // 饮食记录 Section
              if (hasDiet) ...[
                _buildDietSection(context, metadata),
                const SizedBox(height: 24),
              ],

              // 分隔线（如果同时有饮食和动作）
              if (hasDiet && hasExercises) ...[
                Container(
                  height: 1,
                  color: CupertinoColors.systemGrey5.darkColor,
                ),
                const SizedBox(height: 24),
              ],

              // 非视频动作 Section
              if (hasExercises) ...[
                _buildExercisesSection(exercises),
                const SizedBox(height: 24),
              ],

              // 操作按钮
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleView(BuildContext context, Map<String, dynamic> metadata) {
    final totalSets = metadata['totalSets'] as int? ?? 0;
    final completedSets = metadata['completedSets'] as int? ?? 0;
    final avgWeight = metadata['avgWeight'] as double? ?? 0.0;
    final totalReps = metadata['totalReps'] as int? ?? 0;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          color: CupertinoColors.black,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 动作名称
              Text(
                feedItem.exerciseName ?? '',
                style: AppTextStyles.largeTitle.copyWith(
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 8),

              // 副标题
              Text(
                '无视频记录 · 数据汇总',
                style: AppTextStyles.callout.copyWith(
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 32),

              // 数据卡片
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.darkColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _DataRow(
                      label: '完成组数',
                      value: '$completedSets / $totalSets 组',
                    ),
                    const SizedBox(height: 16),
                    _DataRow(
                      label: '平均重量',
                      value: '${avgWeight.toStringAsFixed(1)} kg',
                    ),
                    const SizedBox(height: 16),
                    _DataRow(label: '总次数', value: '$totalReps 次'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 操作按钮
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            onPressed: onCommentTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (feedItem.isReviewed) ...[
                  const Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  feedItem.isReviewed ? '已批阅' : '批阅',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: CupertinoColors.systemGrey5.darkColor,
            borderRadius: BorderRadius.circular(12),
            onPressed: onDetailTap,
            child: Text(
              '详情',
              style: AppTextStyles.buttonLarge.copyWith(
                color: CupertinoColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;

  const _DataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: CupertinoColors.systemGrey),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: CupertinoColors.white,
          ),
        ),
      ],
    );
  }
}

// Extension for aggregated view helper methods
extension _AggregatedViewHelpers on TextFeedItem {
  /// 计算营养进度
  Map<String, double> _calculateProgress(Macros? actual, Macros target) {
    if (actual == null) {
      return {'calories': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0};
    }
    return {
      'calories': target.calories > 0 ? actual.calories / target.calories : 0.0,
      'protein': target.protein > 0 ? actual.protein / target.protein : 0.0,
      'carbs': target.carbs > 0 ? actual.carbs / target.carbs : 0.0,
      'fat': target.fat > 0 ? actual.fat / target.fat : 0.0,
    };
  }

  /// 构建饮食记录 Section
  Widget _buildDietSection(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
    final actualMacrosData = metadata['actualMacros'] as Map<String, dynamic>?;
    final targetMacrosData = metadata['targetMacros'] as Map<String, dynamic>?;
    final meals = metadata['meals'] as List? ?? [];

    // 提取餐食图片
    final mealImages = <String>[];
    for (final meal in meals) {
      final mealMap = meal as Map<String, dynamic>;
      final images = mealMap['images'] as List?;
      if (images != null) {
        mealImages.addAll(images.map((img) => img.toString()));
      }
    }

    // 解析 Macros
    final actualMacros = actualMacrosData != null
        ? Macros.fromJson(actualMacrosData)
        : null;
    final targetMacros = targetMacrosData != null
        ? Macros.fromJson(targetMacrosData)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 标题
        Text(
          '饮食记录',
          style: AppTextStyles.title3.copyWith(color: CupertinoColors.white),
        ),
        const SizedBox(height: 16),

        // TotalNutritionCard
        if (targetMacros != null)
          TotalNutritionCard(
            macros: targetMacros,
            actualMacros: actualMacros,
            progress: _calculateProgress(actualMacros, targetMacros),
          ),

        // 餐食图片横滚
        if (mealImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mealImages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildMealImage(context, mealImages[index]);
              },
            ),
          ),
        ],
      ],
    );
  }

  /// 构建餐食图片
  Widget _buildMealImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.darkColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.systemGrey5.darkColor),
          image: DecorationImage(
            image: imageUrl.startsWith('http')
                ? NetworkImage(imageUrl)
                : AssetImage(imageUrl) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// 显示图片全屏预览
  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: PhotoView(
              imageProvider: imageUrl.startsWith('http')
                  ? NetworkImage(imageUrl)
                  : AssetImage(imageUrl) as ImageProvider,
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建非视频动作 Section
  Widget _buildExercisesSection(List exercises) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 标题
        Text(
          '非视频动作',
          style: AppTextStyles.title3.copyWith(color: CupertinoColors.white),
        ),
        const SizedBox(height: 16),

        // 动作列表
        ...exercises.map((e) {
          final exercise = e as Map<String, dynamic>;
          return _buildExerciseCard(exercise);
        }),
      ],
    );
  }

  /// 构建单个动作卡片
  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String? ?? '';
    final sets = exercise['sets'] as List? ?? [];
    final completedSets = sets.where((s) {
      final setMap = s as Map<String, dynamic>;
      return setMap['completed'] as bool? ?? false;
    }).length;
    final totalSets = sets.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.darkColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                color: CupertinoColors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$completedSets/$totalSets 组',
            style: AppTextStyles.body.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
          if (completedSets == totalSets && totalSets > 0) ...[
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}
