import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:coach_x/l10n/app_localizations.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../widgets/camera_focus_overlay.dart';
import '../widgets/food_analysis_bottom_sheet.dart';
import '../../data/models/food_record_mode.dart';
import '../providers/ai_food_scanner_providers.dart';

/// AI食物扫描相机页面
class AIFoodScannerPage extends ConsumerStatefulWidget {
  const AIFoodScannerPage({super.key});

  @override
  ConsumerState<AIFoodScannerPage> createState() => _AIFoodScannerPageState();
}

class _AIFoodScannerPageState extends ConsumerState<AIFoodScannerPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  final ImagePicker _imagePicker = ImagePicker();
  FoodRecordMode _currentMode = FoodRecordMode.aiScanner;

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

    // 当App不可见时暂停相机
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

      // 使用后置相机
      final camera = cameras.first;

      // 初始化相机控制器
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        AppLogger.info('✅ 相机初始化成功');
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

      // 立即显示Bottom Sheet（后台会自动上传）
      _showAnalysisSheet(image.path);
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

        // 显示分析Bottom Sheet并开始分析
        _showAnalysisSheet(image.path);
      }
    } catch (e) {
      AppLogger.error('❌ 选择图片失败', e);
      _showError(context, '选择图片失败: $e');
    }
  }

  /// 显示分析Bottom Sheet
  void _showAnalysisSheet(String imagePath) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => FoodAnalysisBottomSheet(
        imagePath: imagePath,
        recordMode: _currentMode,
        onComplete: () {
          // 分析完成并保存后，返回上一页
          Navigator.pop(context);
          if (mounted) {
            context.pop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Stack(
        children: [
          // 相机预览
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!)),

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
                        child: Text('打开设置', style: AppTextStyles.buttonMedium),
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

          // 取景框覆盖层
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraFocusOverlay(hintText: l10n.positionFoodInFrame),
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
                          color: CupertinoColors.black.withOpacity(0.5),
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
                        color: CupertinoColors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                      child: Text(
                        l10n.aiFoodScanner,
                        style: AppTextStyles.navTitle.copyWith(
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),

                    // 占位
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // 底部按钮区域
          if (_isCameraInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 拍照和上传按钮行
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.spacingM,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 占位
                          const SizedBox(width: 80),

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
                                color: CupertinoColors.black.withOpacity(0.5),
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

                    // 模式切换控件
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: AppDimensions.spacingL,
                      ),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                      ),
                      child: CupertinoSegmentedControl<FoodRecordMode>(
                        groupValue: _currentMode,
                        onValueChanged: (FoodRecordMode value) {
                          setState(() {
                            _currentMode = value;
                          });
                          ref
                              .read(aiFoodScannerProvider.notifier)
                              .setRecordMode(value);
                        },
                        children: {
                          FoodRecordMode.aiScanner: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingM,
                              vertical: AppDimensions.spacingS,
                            ),
                            child: Text(
                              l10n.aiScannerMode,
                              style: AppTextStyles.callout.copyWith(
                                color: _currentMode == FoodRecordMode.aiScanner
                                    ? AppColors.primaryText
                                    : CupertinoColors.white,
                              ),
                            ),
                          ),
                          FoodRecordMode.simpleRecord: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spacingM,
                              vertical: AppDimensions.spacingS,
                            ),
                            child: Text(
                              l10n.simpleRecordMode,
                              style: AppTextStyles.callout.copyWith(
                                color:
                                    _currentMode == FoodRecordMode.simpleRecord
                                        ? AppColors.primaryText
                                        : CupertinoColors.white,
                              ),
                            ),
                          ),
                        },
                        selectedColor: AppColors.primaryColor,
                        unselectedColor: CupertinoColors.black.withOpacity(0.0),
                        borderColor: CupertinoColors.black.withOpacity(0.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
