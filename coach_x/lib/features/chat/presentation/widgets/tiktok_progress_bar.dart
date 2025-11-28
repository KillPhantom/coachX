import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../student/training/data/models/keyframe_model.dart';

class TikTokProgressBar extends StatefulWidget {
  final VideoPlayerController controller;
  final ValueChanged<bool>? onDragStart;
  final ValueChanged<bool>? onDragEnd;
  final List<KeyframeModel>? keyframes;
  final ValueChanged<double>? onKeyframeTap;

  const TikTokProgressBar({
    super.key,
    required this.controller,
    this.onDragStart,
    this.onDragEnd,
    this.keyframes,
    this.onKeyframeTap,
  });

  @override
  State<TikTokProgressBar> createState() => _TikTokProgressBarState();
}

class _TikTokProgressBarState extends State<TikTokProgressBar> {
  bool _isDragging = false;
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            setState(() {
              _isDragging = true;
              _dragValue = _getValueFromPosition(
                details.localPosition.dx,
                constraints.maxWidth,
              );
            });
            widget.onDragStart?.call(true);
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragValue = _getValueFromPosition(
                details.localPosition.dx,
                constraints.maxWidth,
              );
            });
          },
          onHorizontalDragEnd: (details) {
            if (_dragValue != null) {
              widget.controller.seekTo(
                Duration(milliseconds: _dragValue!.toInt()),
              );
            }
            setState(() {
              _isDragging = false;
              _dragValue = null;
            });
            widget.onDragEnd?.call(false);
          },
          onTapDown: (details) {
            setState(() {
              _isDragging = true;
              _dragValue = _getValueFromPosition(
                details.localPosition.dx,
                constraints.maxWidth,
              );
            });
            widget.onDragStart?.call(true);
          },
          onTapUp: (details) {
            if (_dragValue != null) {
              widget.controller.seekTo(
                Duration(milliseconds: _dragValue!.toInt()),
              );
            }
            setState(() {
              _isDragging = false;
              _dragValue = null;
            });
            widget.onDragEnd?.call(false);
          },
          child: SizedBox(
            height: widget.keyframes != null && widget.keyframes!.isNotEmpty
                ? 100 // Extended height for keyframes
                : 20, // Original height
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none, // Allow time display to overflow
              children: [
                // Background track
                Container(
                  height: _isDragging ? 4 : 2,
                  width: double.infinity,
                  color: CupertinoColors.white.withOpacity(0.2),
                ),
                // Progress track
                ValueListenableBuilder(
                  valueListenable: widget.controller,
                  builder: (context, VideoPlayerValue value, child) {
                    final duration = value.duration.inMilliseconds.toDouble();
                    final position =
                        _dragValue ?? value.position.inMilliseconds.toDouble();
                    final max = duration > 0 ? duration : 1.0;
                    final widthFactor = (position / max).clamp(0.0, 1.0);

                    return Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        height: _isDragging ? 4 : 2,
                        width: constraints.maxWidth * widthFactor,
                        color: CupertinoColors.white,
                      ),
                    );
                  },
                ),
                // Thumb (only visible when dragging)
                if (_isDragging)
                  ValueListenableBuilder(
                    valueListenable: widget.controller,
                    builder: (context, VideoPlayerValue value, child) {
                      final duration = value.duration.inMilliseconds.toDouble();
                      final position =
                          _dragValue ??
                          value.position.inMilliseconds.toDouble();
                      final max = duration > 0 ? duration : 1.0;
                      final widthFactor = (position / max).clamp(0.0, 1.0);

                      // Calculate left position for the thumb
                      // We need to center the thumb on the end of the progress bar
                      final left =
                          (constraints.maxWidth * widthFactor) -
                          6; // 6 is half of thumb width (12/2)

                      return Positioned(
                        left: left.clamp(0.0, constraints.maxWidth - 12),
                        bottom:
                            -4, // Adjust to center vertically on the track (track is at bottom)
                        // Actually track is at bottom of stack. Stack alignment is bottomCenter.
                        // Let's adjust alignment.
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: CupertinoColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),

                // Keyframes (positioned above progress bar)
                if (widget.keyframes != null && widget.keyframes!.isNotEmpty)
                  ...widget.keyframes!.map((keyframe) {
                    return ValueListenableBuilder(
                      valueListenable: widget.controller,
                      builder: (context, VideoPlayerValue value, child) {
                        final duration = value.duration.inSeconds.toDouble();
                        final position = _calculateKeyframePosition(
                          keyframe.timestamp,
                          duration,
                          constraints.maxWidth,
                        );

                        return Positioned(
                          left: position.clamp(0.0, constraints.maxWidth - 50),
                          bottom: 2, // Align with progress bar (2px is the progress bar height)
                          child: GestureDetector(
                            onTap: () =>
                                widget.onKeyframeTap?.call(keyframe.timestamp),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Thumbnail
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: CupertinoColors.white,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.black
                                            .withOpacity(0.5),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: CachedNetworkImage(
                                      imageUrl: keyframe.url ?? '',
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const CupertinoActivityIndicator(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Time mark line - connects to progress bar
                                Container(
                                  width: 2,
                                  height: 14, // Extended to reach progress bar
                                  color: CupertinoColors.white,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }),

                // Time display (centered, only when dragging)
                if (_isDragging)
                  Positioned(
                    bottom: 40, // Move it up a bit more
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ValueListenableBuilder(
                        valueListenable: widget.controller,
                        builder: (context, VideoPlayerValue value, child) {
                          final duration = value.duration;
                          final position = Duration(
                            milliseconds: (_dragValue ?? 0).toInt(),
                          );

                          return Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _formatDuration(position),
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' / ',
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                TextSpan(
                                  text: _formatDuration(duration),
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 20, // Smaller font size
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: CupertinoColors.black,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateKeyframePosition(
    double timestamp,
    double duration,
    double screenWidth,
  ) {
    return (timestamp / duration) * screenWidth - 25; // Center 50px thumbnail
  }

  String _formatTime(double timestamp) {
    final minutes = (timestamp ~/ 60).toString();
    final seconds = (timestamp % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double _getValueFromPosition(double dx, double maxWidth) {
    final duration = widget.controller.value.duration.inMilliseconds.toDouble();
    final relative = (dx / maxWidth).clamp(0.0, 1.0);
    return relative * duration;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
