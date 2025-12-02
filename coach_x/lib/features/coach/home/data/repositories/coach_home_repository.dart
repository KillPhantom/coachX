import '../models/coach_summary_model.dart';

/// Coach Home Repository接口
///
/// 定义教练首页数据获取的抽象方法
abstract class CoachHomeRepository {
  /// 获取教练首页统计数据
  ///
  /// 包括：
  /// - 本周学生打卡次数（最近7天）
  /// - 待审核训练记录数
  /// - 未读消息数
  Future<CoachSummaryModel> fetchCoachSummary(String coachId);
}
