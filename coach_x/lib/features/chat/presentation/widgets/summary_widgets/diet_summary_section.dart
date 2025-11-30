import 'package:flutter/material.dart';
import 'package:coach_x/core/theme/app_colors.dart';
import 'package:coach_x/core/theme/app_text_styles.dart';
import 'package:coach_x/features/chat/data/models/daily_summary_data.dart';
import 'package:coach_x/features/student/home/presentation/widgets/diet_plan_card_components/total_nutrition_card.dart';
import 'package:coach_x/features/coach/plans/data/models/macros.dart';
import 'package:photo_view/photo_view.dart';

class DietSummarySection extends StatelessWidget {
  final DailySummaryData data;

  const DietSummarySection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Data Preparation
    final dietRecord = data.dailyTraining.diet;
    final actualMacros = dietRecord?.macros;
    final targetMacros = data.targetMacros ?? Macros.zero();
    final progress = _calculateProgress(actualMacros, targetMacros);
    
    final mealImages = _extractMealImages(dietRecord);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diet summary',
            style: AppTextStyles.title3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Nutrition Card
          TotalNutritionCard(
            macros: targetMacros,
            actualMacros: actualMacros,
            progress: progress,
          ),
          
          const SizedBox(height: 16),
          
          // Meal Images
          if (mealImages.isNotEmpty)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mealImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildMealImage(context, mealImages[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  List<String> _extractMealImages(dynamic dietRecord) {
    if (dietRecord == null) return [];
    // dietRecord is StudentDietRecordModel
    final meals = dietRecord.meals ?? [];
    final images = <String>[];
    for (final meal in meals) {
      if (meal.images != null) {
        images.addAll(meal.images);
      }
    }
    return images;
  }

  Widget _buildMealImage(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerMedium),
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
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

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
}
