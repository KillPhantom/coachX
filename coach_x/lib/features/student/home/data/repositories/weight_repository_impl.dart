import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/features/student/body_stats/data/models/body_measurement_model.dart';
import 'package:coach_x/features/student/home/data/models/weight_comparison_model.dart';
import 'package:coach_x/features/student/home/data/repositories/weight_repository.dart';

/// 体重记录仓库实现
class WeightRepositoryImpl implements WeightRepository {
  final FirebaseFirestore _firestore;

  WeightRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<BodyMeasurementModel>> getRecentMeasurements({
    required String studentId,
    int limit = 10,
  }) async {
    try {
      AppLogger.info('📊 获取最近体重记录 - 学生ID: $studentId, 数量: $limit');

      final snapshot = await _firestore
          .collection('bodyMeasure')
          .where('studentID', isEqualTo: studentId)
          .orderBy('recordDate', descending: true)
          .limit(limit)
          .get();

      final measurements = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return BodyMeasurementModel.fromJson(data);
            } catch (e) {
              AppLogger.error('解析体重记录失败: ${doc.id}', e);
              return null;
            }
          })
          .whereType<BodyMeasurementModel>()
          .toList();

      AppLogger.info('✅ 获取到 ${measurements.length} 条体重记录');
      return measurements;
    } catch (e, stack) {
      AppLogger.error('获取体重记录失败', e, stack);
      return [];
    }
  }

  @override
  WeightComparisonResult calculateRelativeChange(
    List<BodyMeasurementModel> measurements,
  ) {
    if (measurements.isEmpty) {
      AppLogger.info('⚠️ 无体重记录，返回空结果');
      return WeightComparisonResult.empty();
    }

    if (measurements.length == 1) {
      AppLogger.info('⚠️ 只有一条体重记录，无法对比');
      final m = measurements[0];
      return WeightComparisonResult.single(
        weight: m.weight,
        date: DateTime.parse(m.recordDate),
      );
    }

    // 按日期排序（最新的在前）
    final sorted = [...measurements]
      ..sort((a, b) => b.recordDate.compareTo(a.recordDate));

    final current = sorted[0];
    final previous = sorted[sorted.length - 1];

    try {
      // 计算天数差
      final currentDate = DateTime.parse(current.recordDate);
      final previousDate = DateTime.parse(previous.recordDate);
      final daysDiff = currentDate.difference(previousDate).inDays;

      // 计算变化量
      final change = current.weight - previous.weight;

      AppLogger.info(
        '📊 体重对比 - 当前: ${current.weight}kg (${current.recordDate}), '
        '上次: ${previous.weight}kg (${previous.recordDate}), '
        '变化: ${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}kg, '
        '间隔: $daysDiff 天',
      );

      return WeightComparisonResult(
        currentWeight: current.weight,
        previousWeight: previous.weight,
        change: change,
        daysSince: daysDiff,
        currentDate: currentDate,
        previousDate: previousDate,
        hasData: true,
      );
    } catch (e, stack) {
      AppLogger.error('计算体重变化失败', e, stack);
      return WeightComparisonResult.empty();
    }
  }
}
