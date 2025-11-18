import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:audioplayers/audioplayers.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 音频播放器组件
class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int duration; // 时长（秒）
  final bool isMine;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMine,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // 监听播放状态
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // 监听播放进度
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // 监听总时长
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // 播放完成后重置
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = _totalDuration.inSeconds > 0
        ? _totalDuration
        : Duration(seconds: widget.duration);

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isMine
            ? AppColors.primary.withValues(alpha: 0.2)
            : CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 播放/暂停按钮
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.isMine
                    ? AppColors.primary
                    : CupertinoColors.systemGrey.resolveFrom(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_arrow_solid,
                color: CupertinoColors.white,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 波形图（简化版 - 使用进度条代替）
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 进度条
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: _totalDuration.inSeconds > 0
                          ? _currentPosition.inSeconds /
                                _totalDuration.inSeconds
                          : 0,
                      backgroundColor: CupertinoColors.systemGrey4.resolveFrom(
                        context,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isMine
                            ? AppColors.primary
                            : CupertinoColors.systemGrey.resolveFrom(context),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // 时长显示
                Text(
                  _isPlaying
                      ? '${_formatDuration(_currentPosition)} / ${_formatDuration(displayDuration)}'
                      : _formatDuration(displayDuration),
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
