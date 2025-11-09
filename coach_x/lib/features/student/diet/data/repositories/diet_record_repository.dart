import 'dart:io';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';

/// 饮食记录Repository接口
abstract class DietRecordRepository {
  /// 获取今日训练记录
  ///
  /// [date] 日期 (格式: "yyyy-MM-dd")
  Future<DailyTrainingModel?> getTodayTraining(String date);

  /// 保存饮食记录
  ///
  /// [training] 训练记录数据
  Future<void> saveDietRecord(DailyTrainingModel training);

  /// 上传饮食图片
  ///
  /// [image] 图片文件
  /// 返回图片URL
  Future<String> uploadDietImage(File image);
}
