import 'package:coach_x/core/utils/json_utils.dart';

/// 每日训练摘要（用于圆点状态）
class DailyTrainingSummary {
  final String date;
  final bool hasRecord;

  const DailyTrainingSummary({required this.date, required this.hasRecord});

  factory DailyTrainingSummary.fromJson(Map<String, dynamic> json) {
    return DailyTrainingSummary(
      date: json['date'] as String? ?? '',
      hasRecord: json['hasRecord'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'hasRecord': hasRecord};
  }
}

/// 本周训练概览
class WeeklyTrainingsSummary {
  final String startDate;
  final String endDate;
  final List<DailyTrainingSummary> trainings;

  const WeeklyTrainingsSummary({
    required this.startDate,
    required this.endDate,
    required this.trainings,
  });

  factory WeeklyTrainingsSummary.fromJson(Map<String, dynamic> json) {
    final trainingsData = safeMapListCast(json['trainings'], 'trainings');

    return WeeklyTrainingsSummary(
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      trainings: trainingsData
          .map((t) => DailyTrainingSummary.fromJson(t))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
      'trainings': trainings.map((t) => t.toJson()).toList(),
    };
  }

  /// 获取已完成的天数
  int get completedCount => trainings.where((t) => t.hasRecord).length;

  /// 获取今天的索引（0-6，周一到周日）
  int get todayIndex {
    final today = DateTime.now();
    final weekday = today.weekday; // 1=Monday, 7=Sunday
    return weekday - 1; // 转换为 0-6
  }
}

/// 体重变化统计
class WeightChangeStats {
  final double? currentWeight;
  final double? previousWeight;
  final double? change;
  final int? daysSince;
  final String unit;
  final bool hasData;

  const WeightChangeStats({
    this.currentWeight,
    this.previousWeight,
    this.change,
    this.daysSince,
    required this.unit,
    required this.hasData,
  });

  factory WeightChangeStats.fromJson(Map<String, dynamic> json) {
    return WeightChangeStats(
      currentWeight: safeDoubleCast(
        json['currentWeight'],
        null,
        'currentWeight',
      ),
      previousWeight: safeDoubleCast(
        json['previousWeight'],
        null,
        'previousWeight',
      ),
      change: safeDoubleCast(json['change'], null, 'change'),
      daysSince: safeIntCast(json['daysSince'], null, 'daysSince'),
      unit: json['unit'] as String? ?? 'kg',
      hasData: json['hasData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWeight': currentWeight,
      'previousWeight': previousWeight,
      'change': change,
      'daysSince': daysSince,
      'unit': unit,
      'hasData': hasData,
    };
  }
}

/// 卡路里变化统计
class CaloriesChangeStats {
  final double? currentWeekTotal;
  final double? lastWeekTotal;
  final double? change;
  final bool hasData;

  const CaloriesChangeStats({
    this.currentWeekTotal,
    this.lastWeekTotal,
    this.change,
    required this.hasData,
  });

  factory CaloriesChangeStats.fromJson(Map<String, dynamic> json) {
    return CaloriesChangeStats(
      currentWeekTotal: safeDoubleCast(
        json['currentWeekTotal'],
        null,
        'currentWeekTotal',
      ),
      lastWeekTotal: safeDoubleCast(
        json['lastWeekTotal'],
        null,
        'lastWeekTotal',
      ),
      change: safeDoubleCast(json['change'], null, 'change'),
      hasData: json['hasData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWeekTotal': currentWeekTotal,
      'lastWeekTotal': lastWeekTotal,
      'change': change,
      'hasData': hasData,
    };
  }
}

/// Volume PR 统计
class VolumePRStats {
  final String? exerciseName;
  final double? currentWeekVolume;
  final double? lastWeekVolume;
  final double? improvement;
  final String unit;
  final bool hasData;

  const VolumePRStats({
    this.exerciseName,
    this.currentWeekVolume,
    this.lastWeekVolume,
    this.improvement,
    required this.unit,
    required this.hasData,
  });

  factory VolumePRStats.fromJson(Map<String, dynamic> json) {
    return VolumePRStats(
      exerciseName: json['exerciseName'] as String?,
      currentWeekVolume: safeDoubleCast(
        json['currentWeekVolume'],
        null,
        'currentWeekVolume',
      ),
      lastWeekVolume: safeDoubleCast(
        json['lastWeekVolume'],
        null,
        'lastWeekVolume',
      ),
      improvement: safeDoubleCast(json['improvement'], null, 'improvement'),
      unit: json['unit'] as String? ?? 'kg',
      hasData: json['hasData'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'currentWeekVolume': currentWeekVolume,
      'lastWeekVolume': lastWeekVolume,
      'improvement': improvement,
      'unit': unit,
      'hasData': hasData,
    };
  }
}

/// 本周统计数据模型（顶层）
class WeeklyStatsModel {
  final WeeklyTrainingsSummary currentWeek;
  final WeightChangeStats weightChange;
  final CaloriesChangeStats caloriesChange;
  final VolumePRStats volumePR;

  const WeeklyStatsModel({
    required this.currentWeek,
    required this.weightChange,
    required this.caloriesChange,
    required this.volumePR,
  });

  factory WeeklyStatsModel.fromJson(Map<String, dynamic> json) {
    final currentWeekData = safeMapCast(json['currentWeek'], 'currentWeek');
    final statsData = safeMapCast(json['stats'], 'stats');

    final weightChangeData = safeMapCast(
      statsData?['weightChange'],
      'weightChange',
    );
    final caloriesChangeData = safeMapCast(
      statsData?['caloriesChange'],
      'caloriesChange',
    );
    final volumePRData = safeMapCast(statsData?['volumePR'], 'volumePR');

    return WeeklyStatsModel(
      currentWeek: WeeklyTrainingsSummary.fromJson(currentWeekData ?? {}),
      weightChange: WeightChangeStats.fromJson(weightChangeData ?? {}),
      caloriesChange: CaloriesChangeStats.fromJson(caloriesChangeData ?? {}),
      volumePR: VolumePRStats.fromJson(volumePRData ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentWeek': currentWeek.toJson(),
      'stats': {
        'weightChange': weightChange.toJson(),
        'caloriesChange': caloriesChange.toJson(),
        'volumePR': volumePR.toJson(),
      },
    };
  }

  @override
  String toString() {
    return 'WeeklyStatsModel(week: ${currentWeek.startDate} ~ ${currentWeek.endDate}, '
        'completedDays: ${currentWeek.completedCount}/7)';
  }
}
