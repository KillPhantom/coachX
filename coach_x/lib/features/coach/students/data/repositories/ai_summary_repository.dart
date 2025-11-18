import '../models/student_detail_model.dart';

/// AI Summary Repository 接口
abstract class AISummaryRepository {
  /// 生成学生AI进度摘要
  ///
  /// [studentId] 学生ID
  /// [timeRange] 时间范围，默认 '3M'
  /// 返回生成的 AI Summary
  Future<AISummary> generateAISummary({
    required String studentId,
    String timeRange = '3M',
  });
}
