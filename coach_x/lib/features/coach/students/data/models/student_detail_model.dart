import 'package:coach_x/core/utils/json_utils.dart';

/// 学生详情模型
class StudentDetailModel {
  final BasicInfo basicInfo;
  final StudentPlans plans;
  final StudentStats stats;
  final AISummary aiSummary;
  final WeightTrend weightTrend;
  final List<RecentTraining> recentTrainings;

  const StudentDetailModel({
    required this.basicInfo,
    required this.plans,
    required this.stats,
    required this.aiSummary,
    required this.weightTrend,
    required this.recentTrainings,
  });

  factory StudentDetailModel.fromJson(Map<String, dynamic> json) {
    final basicInfoData = safeMapCast(json['basicInfo'], 'basicInfo');
    final plansData = safeMapCast(json['plans'], 'plans');
    final statsData = safeMapCast(json['stats'], 'stats');
    final aiSummaryData = safeMapCast(json['aiSummary'], 'aiSummary');
    final weightTrendData = safeMapCast(json['weightTrend'], 'weightTrend');
    final recentTrainingsData = safeMapListCast(
      json['recentTrainings'],
      'recentTrainings',
    );

    return StudentDetailModel(
      basicInfo: BasicInfo.fromJson(basicInfoData ?? {}),
      plans: StudentPlans.fromJson(plansData ?? {}),
      stats: StudentStats.fromJson(statsData ?? {}),
      aiSummary: AISummary.fromJson(aiSummaryData ?? {}),
      weightTrend: WeightTrend.fromJson(weightTrendData ?? {}),
      recentTrainings: recentTrainingsData
          .map((data) => RecentTraining.fromJson(data))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basicInfo': basicInfo.toJson(),
      'plans': plans.toJson(),
      'stats': stats.toJson(),
      'aiSummary': aiSummary.toJson(),
      'weightTrend': weightTrend.toJson(),
      'recentTrainings': recentTrainings.map((t) => t.toJson()).toList(),
    };
  }
}

/// 基本信息
class BasicInfo {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? gender;
  final int? age;
  final double? height;
  final double? currentWeight;
  final String weightUnit;
  final String coachId;

  const BasicInfo({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.gender,
    this.age,
    this.height,
    this.currentWeight,
    this.weightUnit = 'kg',
    required this.coachId,
  });

  factory BasicInfo.fromJson(Map<String, dynamic> json) {
    return BasicInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      height: (json['height'] as num?)?.toDouble(),
      currentWeight: (json['currentWeight'] as num?)?.toDouble(),
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      coachId: json['coachId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (gender != null) 'gender': gender,
      if (age != null) 'age': age,
      if (height != null) 'height': height,
      if (currentWeight != null) 'currentWeight': currentWeight,
      'weightUnit': weightUnit,
      'coachId': coachId,
    };
  }

  /// 获取姓名首字母
  String get nameInitial {
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

/// 学生计划
class StudentPlans {
  final PlanInfo? exercisePlan;
  final PlanInfo? dietPlan;
  final PlanInfo? supplementPlan;

  const StudentPlans({this.exercisePlan, this.dietPlan, this.supplementPlan});

  factory StudentPlans.fromJson(Map<String, dynamic> json) {
    final exerciseData = safeMapCast(json['exercisePlan'], 'exercisePlan');
    final dietData = safeMapCast(json['dietPlan'], 'dietPlan');
    final supplementData = safeMapCast(
      json['supplementPlan'],
      'supplementPlan',
    );

    return StudentPlans(
      exercisePlan: exerciseData != null
          ? PlanInfo.fromJson(exerciseData)
          : null,
      dietPlan: dietData != null ? PlanInfo.fromJson(dietData) : null,
      supplementPlan: supplementData != null
          ? PlanInfo.fromJson(supplementData)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (exercisePlan != null) 'exercisePlan': exercisePlan!.toJson(),
      if (dietPlan != null) 'dietPlan': dietPlan!.toJson(),
      if (supplementPlan != null) 'supplementPlan': supplementPlan!.toJson(),
    };
  }

  bool get hasAnyPlan =>
      exercisePlan != null || dietPlan != null || supplementPlan != null;
}

/// 计划信息
class PlanInfo {
  final String id;
  final String name;
  final String description;

  const PlanInfo({
    required this.id,
    required this.name,
    required this.description,
  });

  factory PlanInfo.fromJson(Map<String, dynamic> json) {
    return PlanInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}

/// 训练统计
class StudentStats {
  final int totalSessions;
  final double weightChange;
  final double adherenceRate;
  final double totalVolume;

  const StudentStats({
    required this.totalSessions,
    required this.weightChange,
    required this.adherenceRate,
    required this.totalVolume,
  });

  factory StudentStats.fromJson(Map<String, dynamic> json) {
    return StudentStats(
      totalSessions: json['totalSessions'] as int? ?? 0,
      weightChange: (json['weightChange'] as num?)?.toDouble() ?? 0.0,
      adherenceRate: (json['adherenceRate'] as num?)?.toDouble() ?? 0.0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'weightChange': weightChange,
      'adherenceRate': adherenceRate,
      'totalVolume': totalVolume,
    };
  }
}

/// AI摘要
class AISummary {
  final String content;
  final AIHighlights highlights;

  const AISummary({required this.content, required this.highlights});

  factory AISummary.fromJson(Map<String, dynamic> json) {
    final highlightsData = safeMapCast(json['highlights'], 'highlights');

    return AISummary(
      content: json['content'] as String? ?? '',
      highlights: AIHighlights.fromJson(highlightsData ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content, 'highlights': highlights.toJson()};
  }
}

/// AI高亮数据
class AIHighlights {
  final String trainingVolumeChange;
  final String weightLoss;
  final String avgStrength;
  final String adherence;

  const AIHighlights({
    required this.trainingVolumeChange,
    required this.weightLoss,
    required this.avgStrength,
    required this.adherence,
  });

  factory AIHighlights.fromJson(Map<String, dynamic> json) {
    return AIHighlights(
      trainingVolumeChange: json['trainingVolumeChange'] as String? ?? '0%',
      weightLoss: json['weightLoss'] as String? ?? '0 kg',
      avgStrength: json['avgStrength'] as String? ?? '0 kg',
      adherence: json['adherence'] as String? ?? '0%',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trainingVolumeChange': trainingVolumeChange,
      'weightLoss': weightLoss,
      'avgStrength': avgStrength,
      'adherence': adherence,
    };
  }
}

/// 体重趋势
class WeightTrend {
  final List<WeightDataPoint> dataPoints;
  final double starting;
  final double current;
  final double change;
  final double target;

  const WeightTrend({
    required this.dataPoints,
    required this.starting,
    required this.current,
    required this.change,
    required this.target,
  });

  factory WeightTrend.fromJson(Map<String, dynamic> json) {
    final dataPointsData = safeMapListCast(json['dataPoints'], 'dataPoints');

    return WeightTrend(
      dataPoints: dataPointsData
          .map((data) => WeightDataPoint.fromJson(data))
          .toList(),
      starting: (json['starting'] as num?)?.toDouble() ?? 0.0,
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      target: (json['target'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataPoints': dataPoints.map((p) => p.toJson()).toList(),
      'starting': starting,
      'current': current,
      'change': change,
      'target': target,
    };
  }

  bool get hasData => dataPoints.isNotEmpty;
}

/// 体重数据点
class WeightDataPoint {
  final String date;
  final double weight;
  final int timestamp;

  const WeightDataPoint({
    required this.date,
    required this.weight,
    required this.timestamp,
  });

  factory WeightDataPoint.fromJson(Map<String, dynamic> json) {
    return WeightDataPoint(
      date: json['date'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'weight': weight, 'timestamp': timestamp};
  }
}

/// 最近训练记录
class RecentTraining {
  final String id;
  final String date;
  final String title;
  final int exerciseCount;
  final int videoCount;
  final int duration;
  final bool isReviewed;

  const RecentTraining({
    required this.id,
    required this.date,
    required this.title,
    required this.exerciseCount,
    required this.videoCount,
    required this.duration,
    required this.isReviewed,
  });

  factory RecentTraining.fromJson(Map<String, dynamic> json) {
    return RecentTraining(
      id: json['id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? 'Training Session',
      exerciseCount: json['exerciseCount'] as int? ?? 0,
      videoCount: json['videoCount'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      isReviewed: json['isReviewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'title': title,
      'exerciseCount': exerciseCount,
      'videoCount': videoCount,
      'duration': duration,
      'isReviewed': isReviewed,
    };
  }

  /// 格式化时长（秒 -> 时分）
  String get formattedDuration {
    if (duration == 0) return '0m';

    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
