import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 全局计时器显示组件
///
/// 左边: 当前Exercise耗时 (MM:SS:MS)
/// 右边: 全局计时器 (HH:MM:SS)
class TimerHeader extends StatefulWidget {
  final DateTime? startTime; // 全局计时器开始时间
  final DateTime? currentExerciseStartTime; // 当前Exercise开始时间

  const TimerHeader({
    super.key,
    required this.startTime,
    this.currentExerciseStartTime,
  });

  @override
  State<TimerHeader> createState() => _TimerHeaderState();
}

class _TimerHeaderState extends State<TimerHeader> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // 每100毫秒刷新一次（为了显示毫秒）
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// 全局计时器经过时间
  Duration get _globalElapsedTime {
    if (widget.startTime == null) return Duration.zero;
    return DateTime.now().difference(widget.startTime!);
  }

  /// 当前Exercise经过时间
  Duration? get _exerciseElapsedTime {
    if (widget.currentExerciseStartTime == null) return null;
    return DateTime.now().difference(widget.currentExerciseStartTime!);
  }

  /// 格式化全局时间为 HH:MM:SS
  String _formatGlobalTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化Exercise时间为 MM:SS:MS (2位毫秒)
  String _formatExerciseTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = (duration.inMilliseconds.remainder(1000) ~/ 10); // 取2位

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}:'
        '${milliseconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final globalTimeString = _formatGlobalTime(_globalElapsedTime);
    final exerciseTimeString = _exerciseElapsedTime != null
        ? _formatExerciseTime(_exerciseElapsedTime!)
        : '--:--:--';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      color: AppColors.primaryLight,
      child: Row(
        children: [
          // 左边: 当前Exercise耗时
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentExercise,
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exerciseTimeString,
                  style: AppTextStyles.title3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 右边: 全局计时器
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.totalDuration,
                style: AppTextStyles.caption2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                globalTimeString,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
