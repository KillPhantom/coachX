import '../models/student_detail_model.dart';

/// 学生详情Repository接口
abstract class StudentDetailRepository {
  /// 获取学生详情
  ///
  /// [studentId] 学生ID
  /// [timeRange] 时间范围 ('1M', '3M', '6M', '1Y')
  Future<StudentDetailModel> fetchStudentDetail({
    required String studentId,
    String timeRange = '3M',
  });
}
