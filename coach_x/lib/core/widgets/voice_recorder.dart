import 'dart:async';
import 'dart:io';

import 'package:coach_x/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// 语音录制工具类
///
/// 负责录音权限管理、音频录制、文件保存
class VoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _durationTimer;
  Duration _recordingDuration = Duration.zero;

  final _durationController = StreamController<Duration>.broadcast();

  /// 录制时长流
  Stream<Duration> get recordingDuration => _durationController.stream;

  /// 当前录制时长
  Duration get currentDuration => _recordingDuration;

  /// 检查麦克风权限
  ///
  /// 返回 true 表示已授权，false 表示被拒绝
  Future<bool> checkPermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        AppLogger.info('麦克风权限已授予');
        return true;
      }

      if (status.isDenied) {
        AppLogger.info('请求麦克风权限');
        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        AppLogger.warning('麦克风权限被永久拒绝，需要在设置中开启');
        return false;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error('检查麦克风权限失败', e, stackTrace);
      return false;
    }
  }

  /// 开始录制
  ///
  /// 录制为 AAC 格式（iOS/Android 通用，文件最小）
  Future<void> startRecording() async {
    try {
      // 检查权限
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        throw Exception('麦克风权限未授予');
      }

      // 检查是否支持录音
      final canRecord = await _recorder.hasPermission();
      if (!canRecord) {
        throw Exception('设备不支持录音');
      }

      // 生成临时文件路径
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/voice_$timestamp.aac';

      // 开始录制（AAC格式）
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // AAC-LC 编码器，兼容性好
          bitRate: 64000, // 64kbps，语音质量足够
          sampleRate: 44100, // 标准采样率
        ),
        path: filePath,
      );

      // 重置时长
      _recordingDuration = Duration.zero;
      _durationController.add(_recordingDuration);

      // 启动计时器
      _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        _recordingDuration += const Duration(milliseconds: 100);
        _durationController.add(_recordingDuration);
      });

      AppLogger.info('开始录音: $filePath');
    } catch (e, stackTrace) {
      AppLogger.error('开始录音失败', e, stackTrace);
      rethrow;
    }
  }

  /// 停止录制
  ///
  /// 返回录制文件的本地路径
  Future<String> stopRecording() async {
    try {
      // 停止计时器
      _durationTimer?.cancel();
      _durationTimer = null;

      // 停止录制
      final path = await _recorder.stop();

      if (path == null || path.isEmpty) {
        throw Exception('录音文件路径为空');
      }

      // 检查文件是否存在
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('录音文件不存在: $path');
      }

      final fileSize = await file.length();
      AppLogger.info(
        '停止录音: $path, 时长: ${_recordingDuration.inSeconds}s, 大小: ${fileSize}B',
      );

      return path;
    } catch (e, stackTrace) {
      AppLogger.error('停止录音失败', e, stackTrace);
      rethrow;
    }
  }

  /// 取消录制
  ///
  /// 删除临时文件
  Future<void> cancelRecording() async {
    try {
      // 停止计时器
      _durationTimer?.cancel();
      _durationTimer = null;

      // 停止录制并获取路径
      final path = await _recorder.stop();

      if (path != null && path.isNotEmpty) {
        // 删除临时文件
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info('已删除取消的录音文件: $path');
        }
      }

      // 重置时长
      _recordingDuration = Duration.zero;
      _durationController.add(_recordingDuration);

      AppLogger.info('取消录音');
    } catch (e, stackTrace) {
      AppLogger.error('取消录音失败', e, stackTrace);
      rethrow;
    }
  }

  /// 检查是否正在录制
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (e) {
      return false;
    }
  }

  /// 释放资源
  void dispose() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _durationController.close();
    _recorder.dispose();
    AppLogger.info('VoiceRecorder 已释放');
  }
}
