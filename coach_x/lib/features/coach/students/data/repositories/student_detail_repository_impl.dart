import 'package:coach_x/core/services/cloud_functions_service.dart';
import 'package:coach_x/core/utils/json_utils.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../models/student_detail_model.dart';
import 'student_detail_repository.dart';

/// 学生详情Repository实现
class StudentDetailRepositoryImpl implements StudentDetailRepository {
  StudentDetailRepositoryImpl();

  @override
  Future<StudentDetailModel> fetchStudentDetail({
    required String studentId,
    String timeRange = '3M',
  }) async {
    try {
      AppLogger.info(
        'Fetching student detail: studentId=$studentId, timeRange=$timeRange',
      );

      final response = await CloudFunctionsService.call(
        'fetch_student_detail',
        {'student_id': studentId, 'time_range': timeRange},
      );

      if (response['status'] != 'success') {
        throw Exception(
          'Failed to fetch student detail: ${response['status']}',
        );
      }

      final data = safeMapCast(response['data'], 'data');
      if (data == null) {
        throw Exception('Invalid response data: data is null');
      }

      final studentDetail = StudentDetailModel.fromJson(data);
      AppLogger.info(
        'Student detail fetched successfully: ${studentDetail.basicInfo.name}',
      );

      return studentDetail;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch student detail', e, stackTrace);
      rethrow;
    }
  }
}
