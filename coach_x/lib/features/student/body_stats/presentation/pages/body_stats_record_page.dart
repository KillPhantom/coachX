import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/routes/route_names.dart';
import 'package:coach_x/features/student/body_stats/presentation/widgets/body_stats_input_sheet.dart';
import 'package:coach_x/features/student/body_stats/presentation/providers/body_stats_providers.dart';

/// 身体数据记录页面
///
/// 相机页面，用于拍照或从相册选择照片
class BodyStatsRecordPage extends ConsumerStatefulWidget {
  const BodyStatsRecordPage({super.key});

  @override
  ConsumerState<BodyStatsRecordPage> createState() =>
      _BodyStatsRecordPageState();
}

class _BodyStatsRecordPageState extends ConsumerState<BodyStatsRecordPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  final ImagePicker _imagePicker = ImagePicker();

  // 相机相关状态
  CameraDescription? _currentCamera;
  List<CameraDescription> _availableCameras = [];
  bool _isFrontCamera = false;

  // 预览模式状态
  String? _capturedImagePath;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  /// 初始化相机
  Future<void> _initializeCamera() async {
    try {
      // 请求相机权限
      final status = await Permission.camera.request();

      if (status.isDenied || status.isPermanentlyDenied) {
        setState(() {
          _isPermissionDenied = true;
        });
        AppLogger.warning('⚠️ 相机权限被拒绝');
        return;
      }

      // 获取可用相机列表
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        AppLogger.error('❌ 没有可用的相机');
        return;
      }

      // 保存相机列表
      _availableCameras = cameras;

      // 根据状态选择相机
      CameraDescription? selectedCamera;
      if (_isFrontCamera) {
        // 查找前置相机
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      } else {
        // 查找后置相机
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
      }

      _currentCamera = selectedCamera;

      // 初始化相机控制器
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        AppLogger.info('✅ 相机初始化成功: ${_isFrontCamera ? "前置" : "后置"}');
      }
    } catch (e) {
      AppLogger.error('❌ 相机初始化失败', e);
      if (mounted) {
        _showError(context, '相机初始化失败: $e');
      }
    }
  }

  /// 拍照
  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      AppLogger.info('📸 拍照成功: ${image.path}');

      // 进入预览模式
      _showPreview(image.path);
    } catch (e) {
      AppLogger.error('❌ 拍照失败', e);
      _showError(context, '拍照失败: $e');
    }
  }

  /// 从相册选择图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        AppLogger.info('🖼️ 选择图片成功: ${image.path}');

        // 进入预览模式
        _showPreview(image.path);
      }
    } catch (e) {
      AppLogger.error('❌ 选择图片失败', e);
      _showError(context, '选择图片失败: $e');
    }
  }

  /// 跳过拍照
  void _skipPhoto() {
    AppLogger.info('⏭️ 跳过拍照');
    _showInputSheet();
  }

  /// 显示预览
  void _showPreview(String imagePath) {
    setState(() {
      _capturedImagePath = imagePath;
      _isPreviewMode = true;
    });
    AppLogger.info('📸 进入预览模式: $imagePath');
  }

  /// 关闭预览
  void _closePreview() {
    setState(() {
      _capturedImagePath = null;
      _isPreviewMode = false;
    });
    AppLogger.info('🔙 退出预览模式，返回实时相机');
  }

  /// 切换相机（前置/后置）
  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2) {
      AppLogger.warning('⚠️ 只有一个相机，无法切换');
      return;
    }

    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCameraInitialized = false;
    });

    // 释放当前相机控制器
    await _cameraController?.dispose();
    _cameraController = null;

    // 重新初始化相机
    await _initializeCamera();

    AppLogger.info('🔄 切换到${_isFrontCamera ? "前置" : "后置"}相机');
  }

  /// 使用照片
  void _usePhoto() {
    if (_capturedImagePath == null) return;

    AppLogger.info('✅ 使用照片: $_capturedImagePath');

    // 添加照片到状态
    ref.read(bodyStatsRecordProvider.notifier).addPhoto(_capturedImagePath!);

    // 显示输入表单
    _showInputSheet();
  }

  /// 显示输入表单
  void _showInputSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => BodyStatsInputSheet(
        onComplete: () {
          // 保存成功后，导航到历史页面
          if (mounted) {
            context.push(RouteNames.studentBodyStatsHistory);
          }
        },
      ),
    );
  }

  /// 显示错误对话框
  void _showError(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 打开设置页面
  void _openSettings() async {
    await openAppSettings();
  }

  /// 构建相机预览 - 全屏填充（类似iOS原生相机）
  Widget _buildCameraPreview(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // 获取屏幕尺寸（确保竖屏方向）
    var tmp = MediaQuery.of(context).size;
    final screenH = math.max(tmp.height, tmp.width);
    final screenW = math.min(tmp.height, tmp.width);

    // 获取相机预览尺寸
    tmp = _cameraController!.value.previewSize!;
    final previewH = math.max(tmp.height, tmp.width);
    final previewW = math.min(tmp.height, tmp.width);

    // 计算宽高比
    final screenRatio = screenH / screenW;
    final previewRatio = previewH / previewW;

    return Container(
      color: CupertinoColors.black,
      child: ClipRRect(
        child: OverflowBox(
          maxHeight: screenRatio > previewRatio
              ? screenH
              : screenW / previewW * previewH,
          maxWidth: screenRatio > previewRatio
              ? screenH / previewH * previewW
              : screenW,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          // 相机预览 - 全屏填充（类似iOS原生相机）
          if (_isCameraInitialized &&
              _cameraController != null &&
              !_isPreviewMode)
            Positioned.fill(child: _buildCameraPreview(context)),

          // 预览模式 - 显示拍摄的照片
          if (_isPreviewMode && _capturedImagePath != null)
            Positioned.fill(
              child: Container(
                color: CupertinoColors.black,
                child: Center(
                  child: Image.file(
                    File(_capturedImagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

          // 权限被拒绝提示
          if (_isPermissionDenied)
            Positioned.fill(
              child: Container(
                color: CupertinoColors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.camera,
                        size: 80,
                        color: CupertinoColors.systemGrey,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      Text(
                        l10n.cameraPermissionDenied,
                        style: AppTextStyles.body.copyWith(
                          color: CupertinoColors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDimensions.spacingL),
                      CupertinoButton(
                        color: AppColors.primaryColor,
                        onPressed: _openSettings,
                        child: Text(
                          '打开设置',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 加载中
          if (!_isCameraInitialized && !_isPermissionDenied)
            const Positioned.fill(
              child: Center(
                child: CupertinoActivityIndicator(
                  color: CupertinoColors.white,
                  radius: 20,
                ),
              ),
            ),

          // 顶部导航栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                  vertical: AppDimensions.spacingS,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 返回按钮
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.spacingS),
                        decoration: BoxDecoration(
                          color: CupertinoColors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.back,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // 标题
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacingL,
                        vertical: AppDimensions.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                      child: Text(
                        l10n.recordBodyStats,
                        style: AppTextStyles.navTitle.copyWith(
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),

                    // 相机切换按钮（仅在实时相机模式显示）
                    if (_isCameraInitialized && !_isPreviewMode)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _switchCamera,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.spacingS),
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.camera_rotate,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // 预览模式 - 顶部右上角关闭按钮
          if (_isPreviewMode)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _closePreview,
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingS),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 预览模式 - 底部"Use Photo"按钮
          if (_isPreviewMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingXL,
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: _usePhoto,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacingXXL,
                          vertical: AppDimensions.spacingM,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXL,
                          ),
                        ),
                        child: Text(
                          l10n.usePhoto,
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 底部按钮区域
          if (_isCameraInitialized && !_isPreviewMode)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingXL,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Skip Photo 按钮（左侧）
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _skipPhoto,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingL,
                            vertical: AppDimensions.spacingM,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusL,
                            ),
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            l10n.skipPhoto,
                            style: AppTextStyles.callout.copyWith(
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),

                      // 拍照按钮（中心）
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: CupertinoColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 上传图片按钮（右侧）
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _pickImage,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.photo,
                            color: CupertinoColors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
