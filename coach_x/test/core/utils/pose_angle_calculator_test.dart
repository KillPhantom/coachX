import 'package:flutter_test/flutter_test.dart';
import 'package:coach_x/core/utils/pose_angle_calculator.dart';

void main() {
  group('PoseAngleCalculator', () {
    group('calculateAngle', () {
      test('should calculate 90 degree angle correctly', () {
        // 形成直角的三个点: (0,1) - (0,0) - (1,0)
        final pointA = const Offset(0, 1);
        final pointB = const Offset(0, 0);
        final pointC = const Offset(1, 0);

        final angle = PoseAngleCalculator.calculateAngle(
          pointA,
          pointB,
          pointC,
        );

        expect(angle, closeTo(90.0, 0.1));
      });

      test('should calculate 180 degree angle (straight line) correctly', () {
        // 形成直线的三个点: (0,0) - (1,0) - (2,0)
        final pointA = const Offset(0, 0);
        final pointB = const Offset(1, 0);
        final pointC = const Offset(2, 0);

        final angle = PoseAngleCalculator.calculateAngle(
          pointA,
          pointB,
          pointC,
        );

        expect(angle, closeTo(180.0, 0.1));
      });

      test('should calculate 45 degree angle correctly', () {
        // 形成45度角的三个点
        final pointA = const Offset(0, 1);
        final pointB = const Offset(0, 0);
        final pointC = const Offset(1, 1);

        final angle = PoseAngleCalculator.calculateAngle(
          pointA,
          pointB,
          pointC,
        );

        expect(angle, closeTo(45.0, 0.1));
      });

      test('should calculate 60 degree angle correctly', () {
        // 使用等边三角形的顶点
        final pointA = const Offset(0, 0);
        final pointB = const Offset(1, 0);
        final pointC = Offset(0.5, 0.866); // sqrt(3)/2 ≈ 0.866

        final angle = PoseAngleCalculator.calculateAngle(
          pointA,
          pointB,
          pointC,
        );

        expect(angle, closeTo(60.0, 1.0));
      });

      test('should return angle in 0-180 range', () {
        // 测试各种角度都在0-180范围内
        final pointA = const Offset(1, 1);
        final pointB = const Offset(0, 0);
        final pointC = const Offset(-1, 1);

        final angle = PoseAngleCalculator.calculateAngle(
          pointA,
          pointB,
          pointC,
        );

        expect(angle, greaterThanOrEqualTo(0.0));
        expect(angle, lessThanOrEqualTo(180.0));
      });
    });
  });
}
