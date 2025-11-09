import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';

/// 视频播放模态框
///
/// 支持单个或多个视频播放，多个视频时支持横向滚动切换
class VideoPlayerModal extends StatefulWidget {
  final List<String> videoUrls;

  const VideoPlayerModal({super.key, required this.videoUrls});

  /// 显示视频播放模态框
  static Future<void> show(
    BuildContext context, {
    required List<String> videoUrls,
  }) {
    return showCupertinoModalPopup(
      context: context,
      builder: (context) => VideoPlayerModal(videoUrls: videoUrls),
    );
  }

  @override
  State<VideoPlayerModal> createState() => _VideoPlayerModalState();
}

class _VideoPlayerModalState extends State<VideoPlayerModal> {
  late PageController _pageController;
  int _currentPage = 0;
  List<VideoPlayerController> _controllers = [];
  List<bool> _initialized = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeControllers();
  }

  void _initializeControllers() {
    _controllers = widget.videoUrls.map((url) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      return controller;
    }).toList();

    _initialized = List.filled(widget.videoUrls.length, false);

    // 只初始化第一个视频
    if (_controllers.isNotEmpty) {
      _initializeVideo(0);
    }
  }

  Future<void> _initializeVideo(int index) async {
    if (index < 0 || index >= _controllers.length) return;
    if (_initialized[index]) return;

    try {
      await _controllers[index].initialize();
      if (mounted) {
        setState(() {
          _initialized[index] = true;
        });
        _controllers[index].play();
      }
    } catch (e) {
      // 处理初始化错误
      if (mounted) {
        setState(() {
          _initialized[index] = false;
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      // 暂停当前视频
      if (_currentPage >= 0 && _currentPage < _controllers.length) {
        _controllers[_currentPage].pause();
      }
      _currentPage = page;
    });

    // 初始化并播放新视频
    _initializeVideo(page);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPopupSurface(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 头部：标题和关闭按钮
              Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.video, style: AppTextStyles.title3),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppColors.textSecondary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // 视频播放区域
              Expanded(
                child: widget.videoUrls.length == 1
                    ? _buildSingleVideo()
                    : _buildMultipleVideos(),
              ),

              // 页面指示器（多视频时显示）
              if (widget.videoUrls.length > 1) ...[
                const SizedBox(height: AppDimensions.spacingM),
                _buildPageIndicator(),
                const SizedBox(height: AppDimensions.spacingM),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleVideo() {
    if (_controllers.isEmpty) {
      return const Center(child: Text('No video available'));
    }

    return _buildVideoPlayer(0);
  }

  Widget _buildMultipleVideos() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.videoUrls.length,
      itemBuilder: (context, index) {
        return _buildVideoPlayer(index);
      },
    );
  }

  Widget _buildVideoPlayer(int index) {
    if (!_initialized[index]) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final controller = _controllers[index];

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            // 播放/暂停按钮
            GestureDetector(
              onTap: () {
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
              child: Container(
                color: CupertinoColors.black.withOpacity(0.3),
                child: Center(
                  child: Icon(
                    controller.value.isPlaying
                        ? CupertinoIcons.pause_circle_fill
                        : CupertinoIcons.play_circle_fill,
                    size: 64,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.videoUrls.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? AppColors.primaryColor
                : AppColors.dividerLight,
          ),
        ),
      ),
    );
  }
}
