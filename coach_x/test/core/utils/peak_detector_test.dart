import 'package:flutter_test/flutter_test.dart';
import 'package:coach_x/core/utils/peak_detector.dart';

void main() {
  group('PeakDetector', () {
    group('detectPeaks', () {
      test('should detect single peak in simple wave', () {
        // 简单波形: [0, 1, 2, 3, 2, 1, 0]
        final series = [0.0, 1.0, 2.0, 3.0, 2.0, 1.0, 0.0];

        final peaks = PeakDetector.detectPeaks(
          series,
          minDistance: 1,
          prominence: 0.5,
        );

        expect(peaks, contains(3)); // 索引3是峰值
      });

      test('should detect multiple peaks', () {
        // 多峰波形: [0, 1, 0, 1, 0, 1, 0]
        final series = [0.0, 10.0, 0.0, 10.0, 0.0, 10.0, 0.0];

        final peaks = PeakDetector.detectPeaks(
          series,
          minDistance: 1,
          prominence: 5.0,
        );

        expect(peaks.length, equals(3));
        expect(peaks, containsAll([1, 3, 5]));
      });

      test('should respect minDistance constraint', () {
        // 密集峰值，但minDistance限制
        final series = [0.0, 10.0, 5.0, 10.0, 0.0];

        final peaks = PeakDetector.detectPeaks(
          series,
          minDistance: 3,
          prominence: 1.0,
        );

        // 由于minDistance=3，只能检测到第一个峰值
        expect(peaks.length, lessThanOrEqualTo(1));
      });

      test('should return empty list for flat series', () {
        // 平坦数据
        final series = [5.0, 5.0, 5.0, 5.0, 5.0];

        final peaks = PeakDetector.detectPeaks(series);

        expect(peaks, isEmpty);
      });

      test('should return empty list for monotonic increasing series', () {
        // 单调递增
        final series = [1.0, 2.0, 3.0, 4.0, 5.0];

        final peaks = PeakDetector.detectPeaks(series);

        expect(peaks, isEmpty);
      });

      test('should return empty list for series with less than 3 points', () {
        final series = [1.0, 2.0];

        final peaks = PeakDetector.detectPeaks(series);

        expect(peaks, isEmpty);
      });
    });

    group('detectValleys', () {
      test('should detect single valley in simple wave', () {
        // 简单波形: [3, 2, 1, 0, 1, 2, 3]
        final series = [3.0, 2.0, 1.0, 0.0, 1.0, 2.0, 3.0];

        final valleys = PeakDetector.detectValleys(
          series,
          minDistance: 1,
          prominence: 0.5,
        );

        expect(valleys, contains(3)); // 索引3是谷值
      });

      test('should detect multiple valleys', () {
        // 多谷波形: [10, 0, 10, 0, 10, 0, 10]
        final series = [10.0, 0.0, 10.0, 0.0, 10.0, 0.0, 10.0];

        final valleys = PeakDetector.detectValleys(
          series,
          minDistance: 1,
          prominence: 5.0,
        );

        expect(valleys.length, equals(3));
        expect(valleys, containsAll([1, 3, 5]));
      });

      test('should return empty list for flat series', () {
        final series = [5.0, 5.0, 5.0, 5.0, 5.0];

        final valleys = PeakDetector.detectValleys(series);

        expect(valleys, isEmpty);
      });
    });

    group('calculateAngleChangeScore', () {
      test('should calculate high score for significant change', () {
        // 显著变化: [10, 10, 10, 50, 10, 10, 10]
        final series = [10.0, 10.0, 10.0, 50.0, 10.0, 10.0, 10.0];

        final score = PeakDetector.calculateAngleChangeScore(
          series,
          3,
          windowSize: 2,
        );

        expect(score, greaterThan(20.0)); // 应该有高分
      });

      test('should calculate low score for gradual change', () {
        // 平缓变化: [10, 11, 12, 13, 14, 15, 16]
        final series = [10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0];

        final score = PeakDetector.calculateAngleChangeScore(
          series,
          3,
          windowSize: 2,
        );

        expect(score, lessThan(5.0)); // 应该有低分
      });

      test('should return 0 for edge frames', () {
        final series = [1.0, 2.0, 3.0, 4.0, 5.0];

        // 边缘帧应该返回0
        final scoreStart = PeakDetector.calculateAngleChangeScore(
          series,
          0,
          windowSize: 2,
        );
        final scoreEnd = PeakDetector.calculateAngleChangeScore(
          series,
          4,
          windowSize: 2,
        );

        expect(scoreStart, equals(0.0));
        expect(scoreEnd, equals(0.0));
      });

      test('should cap score at 100', () {
        // 极端变化
        final series = [0.0, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.0];

        final score = PeakDetector.calculateAngleChangeScore(
          series,
          3,
          windowSize: 2,
        );

        expect(score, lessThanOrEqualTo(100.0));
      });
    });
  });
}
