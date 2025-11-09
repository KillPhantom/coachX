import 'dart:io';
import 'package:coach_x/features/student/home/data/models/daily_training_model.dart';

/// 训练记录仓库接口
///
/// 定义训练记录相关的数据操作
abstract class TrainingRecordRepository {
  /// 获取指定日期的训练记录
  ///
  /// [date] - 日期，格式: "yyyy-MM-dd"
  /// 返回: DailyTrainingModel 或 null（如果没有记录）
  Future<DailyTrainingModel?> fetchTodayTraining(String date);

  /// 创建或更新训练记录
  ///
  /// [training] - 完整的 DailyTrainingModel
  /// 返回: 文档 ID
  Future<String> upsertTodayTraining(DailyTrainingModel training);

  /// 上传视频到 Firebase Storage
  ///
  /// [videoFile] - 视频文件
  /// [path] - 存储路径
  /// 返回: 下载 URL
  Future<String> uploadVideo(File videoFile, String path);

  /// 上传语音反馈到 Firebase Storage
  ///
  /// [audioFile] - 音频文件
  /// [path] - 存储路径
  /// 返回: 下载 URL
  Future<String> uploadAudio(File audioFile, String path);
}
