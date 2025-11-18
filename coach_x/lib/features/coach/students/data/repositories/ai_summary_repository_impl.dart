import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/student_detail_model.dart';
import 'ai_summary_repository.dart';

/// AI Summary Repository 实现
class AISummaryRepositoryImpl implements AISummaryRepository {
  @override
  Future<AISummary> generateAISummary({
    required String studentId,
    String timeRange = '3M',
  }) async {
    try {
      AppLogger.info(
        'Generating AI summary: studentId=$studentId, timeRange=$timeRange',
      );

      final response = await CloudFunctionsService.call(
        'generateStudentAISummary',
        {'student_id': studentId, 'time_range': timeRange},
      );

      if (response['status'] == 'success') {
        final data = safeMapCast(response['data'], 'data');
        if (data == null) {
          throw Exception('AI summary data is null');
        }

        final aiSummary = AISummary.fromJson(data);
        AppLogger.info('✅ AI summary generated successfully');
        return aiSummary;
      } else {
        throw Exception('Failed to generate AI summary: ${response['status']}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate AI summary', e, stackTrace);
      rethrow;
    }
  }
}
