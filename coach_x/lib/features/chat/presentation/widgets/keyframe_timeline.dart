import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KeyframeTimeline extends StatelessWidget {
  final List<KeyframeModel> keyframes;
  final Duration videoDuration;
  final ValueChanged<double> onKeyframeTap;

  const KeyframeTimeline({
    super.key,
    required this.keyframes,
    required this.videoDuration,
    required this.onKeyframeTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 40;

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          // 进度条背景
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              color: CupertinoColors.white.withOpacity(0.3),
            ),
          ),

          // 关键帧标记
          ...keyframes.map((keyframe) {
            final position = _calculatePosition(
              keyframe.timestamp,
              videoDuration.inSeconds.toDouble(),
              screenWidth,
            );

            return Positioned(
              left: position,
              child: GestureDetector(
                onTap: () => onKeyframeTap(keyframe.timestamp),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 缩略图
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.black.withOpacity(0.5),
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

                    // 时间刻度线
                    Container(
                      width: 2,
                      height: 10,
                      color: CupertinoColors.white,
                    ),

                    const SizedBox(height: 2),

                    // 时间文本
                    Text(
                      _formatTime(keyframe.timestamp),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  double _calculatePosition(
    double timestamp,
    double duration,
    double screenWidth,
  ) {
    return (timestamp / duration) * screenWidth - 30; // 减去缩略图宽度的一半
  }

  String _formatTime(double timestamp) {
    final minutes = (timestamp ~/ 60).toString();
    final seconds = (timestamp % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class KeyframeModel {
  final String? url;
  final double timestamp;

  const KeyframeModel({required this.url, required this.timestamp});

  factory KeyframeModel.fromJson(Map<String, dynamic> json) {
    return KeyframeModel(
      url: json['url'] as String?,
      timestamp: (json['timestamp'] as num).toDouble(),
    );
  }
}
