import 'package:coach_x/core/services/firestore_service.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';
import 'package:coach_x/features/auth/data/models/user_model.dart';
import '../models/training_review_list_item_model.dart';
import 'training_review_repository.dart';

/// 训练审核Repository实现
class TrainingReviewRepositoryImpl implements TrainingReviewRepository {
  // 计划名称缓存
  final Map<String, String> _planNameCache = {};

  /// 获取计划名称（带缓存）
  /// [collection] - 'exercisePlans' 或 'dietPlans'
  Future<String?> _getPlanName(String planId, String collection) async {
    final cacheKey = '$collection:$planId';

    // 检查缓存
    if (_planNameCache.containsKey(cacheKey)) {
      return _planNameCache[cacheKey];
    }

    // 查询 Firestore
    try {
      final planDoc = await FirestoreService.getDocument(collection, planId);

      if (planDoc.exists) {
        final planData = planDoc.data() as Map<String, dynamic>;
        final planName = planData['name'] as String?;

        if (planName != null) {
          _planNameCache[cacheKey] = planName;
          return planName;
        }
      }
    } catch (e) {
      AppLogger.error('查询计划名称失败: $collection/$planId', e);
    }

    return null;
  }

  @override
  Stream<List<TrainingReviewListItemModel>> watchTrainingReviews(
    String coachId,
  ) {
    try {
      AppLogger.info(
        '🔍 [TrainingReviewRepo] Starting watchCollection for coachId: $coachId',
      );

      // 监听 dailyTrainings collection，按 coachId 筛选
      return FirestoreService.watchCollection(
        'dailyTrainings',
        where: [
          ['coachID', '==', coachId],
        ],
        orderBy: 'date',
        descending: true,
      ).asyncMap((snapshot) async {
        AppLogger.info(
          '🔍 [TrainingReviewRepo] Received snapshot with ${snapshot.docs.length} documents',
        );

        final List<TrainingReviewListItemModel> items = [];

        // 遍历每个 DailyTraining 记录
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;

            // 解析 DailyTrainingModel
            final dailyTraining = DailyTrainingModel.fromJson(data);

            // 通过 studentId 查询学生信息
            final studentDoc = await FirestoreService.getDocument(
              'users',
              dailyTraining.studentId,
            );

            if (!studentDoc.exists) {
              AppLogger.warning('学生不存在: ${dailyTraining.studentId}');
              continue;
            }

            final student = UserModel.fromFirestore(studentDoc);

            // 获取训练计划名称
            String? planName;
            if (dailyTraining.planSelection.exercisePlanId != null) {
              planName = await _getPlanName(
                dailyTraining.planSelection.exercisePlanId!,
                'exercisePlans',
              );
            }

            // 获取饮食计划名称
            String? dietPlanName;
            if (dailyTraining.planSelection.dietPlanId != null) {
              dietPlanName = await _getPlanName(
                dailyTraining.planSelection.dietPlanId!,
                'dietPlans',
              );
            }

            // 计算餐食数量
            final mealCount = dailyTraining.diet?.meals.length ?? 0;

            // 组合为 TrainingReviewListItemModel
            final item = TrainingReviewListItemModel(
              dailyTrainingId: dailyTraining.id,
              studentId: dailyTraining.studentId,
              studentName: student.name,
              studentAvatarUrl: student.avatarUrl,
              date: dailyTraining.date,
              isReviewed: dailyTraining.isReviewed,
              createdAt: DateTime.parse(dailyTraining.date),
              planName: planName,
              dietPlanName: dietPlanName,
              exercises: dailyTraining.exercises ?? [],
              mealCount: mealCount,
            );

            items.add(item);
            AppLogger.info(
              '🔍 [TrainingReviewRepo] Successfully added item for student: ${student.name}, date: ${dailyTraining.date}, reviewed: ${dailyTraining.isReviewed}',
            );
          } catch (e, stackTrace) {
            AppLogger.error('解析训练记录失败: ${doc.id}', e, stackTrace);
            // 继续处理其他记录
            continue;
          }
        }

        AppLogger.info(
          '🔍 [TrainingReviewRepo] Returning ${items.length} training review items',
        );
        return items;
      });
    } catch (e, stackTrace) {
      AppLogger.error('监听训练审核列表失败', e, stackTrace);
      rethrow;
    }
  }
}
