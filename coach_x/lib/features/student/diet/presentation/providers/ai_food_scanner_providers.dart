import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../data/models/ai_food_analysis_state.dart';
import 'ai_food_scanner_notifier.dart';

/// AI食物扫描状态Provider
final aiFoodScannerProvider =
    StateNotifierProvider<AIFoodScannerNotifier, AIFoodAnalysisState>((ref) {
      return AIFoodScannerNotifier(ref);
    });

/// 可用相机列表Provider
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((
  ref,
) async {
  return await availableCameras();
});

/// 相机控制器Provider
final cameraControllerProvider = StateProvider<CameraController?>(
  (ref) => null,
);
