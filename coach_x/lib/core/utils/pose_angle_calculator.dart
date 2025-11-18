import 'dart:math';
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// 姿态角度计算工具
/// 用于计算MLKit Pose检测结果中的关节角度
class PoseAngleCalculator {
  /// 计算三点之间的角度 (0-180度)
  ///
  /// [pointA] - 第一个点
  /// [pointB] - 顶点 (角度的中心点)
  /// [pointC] - 第三个点
  ///
  /// 返回角度值 (0-180度)
  static double calculateAngle(Offset pointA, Offset pointB, Offset pointC) {
    // 向量 BA 和 BC
    final ba = Offset(pointA.dx - pointB.dx, pointA.dy - pointB.dy);
    final bc = Offset(pointC.dx - pointB.dx, pointC.dy - pointB.dy);

    // 计算夹角
    final radians = atan2(bc.dy, bc.dx) - atan2(ba.dy, ba.dx);

    // 转换为度数，确保0-180范围
    var angle = radians.abs() * 180.0 / pi;
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }

    return angle;
  }

  /// 从MLKit Pose对象提取8个关节角度
  ///
  /// [pose] - MLKit检测到的姿态对象
  ///
  /// 返回关节名称到角度的映射
  /// 如果某个关节的关键点检测不到，该关节将被省略
  static Map<String, double> getJointAngles(Pose pose) {
    final Map<String, double> angles = {};

    // 获取所有关键点
    final landmarks = pose.landmarks;

    // 定义关节计算规则 (关节名称 -> [点A索引, 顶点B索引, 点C索引])
    final jointDefinitions = {
      'left_elbow': [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
      ],
      'right_elbow': [
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
      ],
      'left_knee': [
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
      ],
      'right_knee': [
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
      ],
      'left_hip': [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
      ],
      'right_hip': [
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
      ],
      'left_shoulder': [
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
      ],
      'right_shoulder': [
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
      ],
    };

    // 计算每个关节的角度
    for (final entry in jointDefinitions.entries) {
      final jointName = entry.key;
      final types = entry.value;

      // 获取三个关键点
      final pointA = landmarks[types[0]];
      final pointB = landmarks[types[1]];
      final pointC = landmarks[types[2]];

      // 检查所有点是否存在
      if (pointA != null && pointB != null && pointC != null) {
        final angle = calculateAngle(
          Offset(pointA.x.toDouble(), pointA.y.toDouble()),
          Offset(pointB.x.toDouble(), pointB.y.toDouble()),
          Offset(pointC.x.toDouble(), pointC.y.toDouble()),
        );
        angles[jointName] = angle;
      }
    }

    return angles;
  }
}
