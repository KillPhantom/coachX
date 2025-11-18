import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:coach_x/core/services/video_downloader.dart';
import 'package:coach_x/core/services/video_frame_extractor.dart';
import 'package:coach_x/core/services/keyframe_selector.dart';
import 'package:coach_x/core/services/storage_service.dart';
import 'package:coach_x/core/utils/pose_angle_calculator.dart';
import 'package:coach_x/core/utils/logger.dart';
import 'package:coach_x/core/utils/json_utils.dart';

/// 本地关键帧提取服务
/// 在教练端本地处理训练视频，提取关键帧
class LocalKeyframeExtractor {
  final VideoDownloader _videoDownloader;
  final VideoFrameExtractor _frameExtractor;
  final PoseDetector _poseDetector;

  LocalKeyframeExtractor({
    VideoDownloader? videoDownloader,
    VideoFrameExtractor? frameExtractor,
  }) : _videoDownloader = videoDownloader ?? VideoDownloader(),
       _frameExtractor = frameExtractor ?? VideoFrameExtractor(),
       _poseDetector = PoseDetector(
         options: PoseDetectorOptions(mode: PoseDetectionMode.single),
       );

  /// 提取关键帧
  ///
  /// [videoUrl] - Firebase Storage视频URL
  /// [trainingId] - 训练记录ID
  /// [exerciseIndex] - 练习索引
  /// [maxKeyframes] - 最大关键帧数量 (默认5)
  /// [onProgress] - 进度回调 (progress: 0.0-1.0, infoText: 进度信息)
  Future<void> extractKeyframes(
    String videoUrl,
    String trainingId,
    int exerciseIndex, {
    int maxKeyframes = 5,
    Function(double progress, String? infoText)? onProgress,
  }) async {
    String? videoPath;
    String? framesDir;
    List<String> selectedKeyframePaths = [];

    try {
      AppLogger.info(
        'Starting local keyframe extraction for training: $trainingId, exercise: $exerciseIndex',
      );

      // Step 1: 下载视频到本地
      AppLogger.info('Step 1: Downloading video...');
      onProgress?.call(0.0, 'Downloading video...');
      videoPath = await _videoDownloader.downloadVideo(videoUrl, trainingId);
      onProgress?.call(0.2, 'Video downloaded');

      // Step 2: 提取视频帧
      AppLogger.info('Step 2: Extracting frames...');
      onProgress?.call(0.2, 'Extracting frames...');
      final framePaths = await _frameExtractor.extractFrames(
        videoPath,
        trainingId,
        fps: 1, // 每秒10帧，避免过多帧
      );

      AppLogger.info('Extracted ${framePaths.length} frames');
      onProgress?.call(0.4, 'Frames extracted');

      if (framePaths.isEmpty) {
        throw Exception('No frames extracted from video');
      }

      // Step 3: 逐帧姿态检测和角度计算
      AppLogger.info('Step 3: Detecting poses and calculating angles...');
      onProgress?.call(0.4, 'Detecting poses...');
      final framesData = await _processPoseDetection(framePaths);

      AppLogger.info('Processed ${framesData.length} frames with pose data');
      onProgress?.call(0.6, 'Poses detected');

      // Step 4: 选择关键帧
      AppLogger.info('Step 4: Selecting keyframes...');
      onProgress?.call(0.6, 'Selecting keyframes...');
      final selectedIndices = framesData.isEmpty
          ? KeyframeSelector.selectKeyframesFallback(
              _createFallbackFramesData(framePaths),
              maxKeyframes,
            )
          : KeyframeSelector.selectKeyframesByAngleChange(
              framesData,
              maxFrames: maxKeyframes,
            );

      AppLogger.info('Selected ${selectedIndices.length} keyframes');
      onProgress?.call(0.8, 'Keyframes selected');

      // 准备关键帧数据（包含本地路径）
      final keyframesData = selectedIndices.map((index) {
        String framePath;
        double timestamp;

        if (framesData.isNotEmpty && index < framesData.length) {
          final frameData = framesData[index];
          framePath = frameData.framePath;
          timestamp = frameData.timestamp;
        } else {
          // 降级方案：直接使用索引
          framePath = framePaths[index];
          timestamp = index / 10.0;
        }

        selectedKeyframePaths.add(framePath); // 记录需要保留的路径
        return {'localPath': framePath, 'timestamp': timestamp};
      }).toList();

      // Step 5: 立即更新Firestore（本地路径）
      AppLogger.info('Step 5: Updating Firestore with local paths...');
      onProgress?.call(0.8, 'Saving keyframes...');
      await _updateFirestoreWithLocalPaths(
        trainingId,
        exerciseIndex,
        keyframesData,
      );

      AppLogger.info('Keyframes available locally, starting background upload');
      onProgress?.call(1.0, 'Completed');

      // Step 6: 后台上传（不等待）
      _uploadKeyframesInBackground(trainingId, exerciseIndex, keyframesData);

      AppLogger.info('Local keyframe extraction completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to extract keyframes', e, stackTrace);
      rethrow;
    } finally {
      // Step 7: 清理临时文件（保留关键帧）
      AppLogger.info('Step 7: Cleaning up temporary files...');
      await _cleanup(videoPath, framesDir, selectedKeyframePaths);
      _poseDetector.close();
    }
  }

  /// 逐帧姿态检测和角度计算
  Future<List<FrameData>> _processPoseDetection(List<String> framePaths) async {
    final framesData = <FrameData>[];
    int processedCount = 0;

    for (int i = 0; i < framePaths.length; i++) {
      try {
        // 每处理10帧清理一次图像缓存
        if (i % 10 == 0) {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          AppLogger.debug('Cleared image cache at frame $i');
        }

        final framePath = framePaths[i];
        final timestamp = i / 10.0; // fps=10

        // 创建输入图像
        final inputImage = InputImage.fromFilePath(framePath);

        // 姿态检测
        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isEmpty) {
          AppLogger.debug('No pose detected in frame $i');
          continue;
        }

        // 取第一个检测到的姿态
        final pose = poses.first;

        // 计算关节角度
        final angles = PoseAngleCalculator.getJointAngles(pose);

        if (angles.isEmpty) {
          AppLogger.debug('No angles calculated for frame $i');
          continue;
        }

        // 创建帧数据
        framesData.add(
          FrameData(
            frameNumber: i,
            timestamp: timestamp,
            angles: angles,
            framePath: framePath,
          ),
        );

        processedCount++;

        // 每20帧输出一次进度
        if (processedCount % 20 == 0) {
          AppLogger.info(
            'Pose detection progress: $processedCount/${framePaths.length}',
          );
        }
      } catch (e) {
        AppLogger.warning('Failed to process frame $i: $e');
        continue;
      }
    }

    return framesData;
  }

  /// 使用本地路径立即更新Firestore
  Future<void> _updateFirestoreWithLocalPaths(
    String trainingId,
    int exerciseIndex,
    List<Map<String, dynamic>> keyframesData, // 包含本地路径
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('dailyTrainings')
          .doc(trainingId);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) {
        throw Exception('Training document not found: $trainingId');
      }

      final data = docSnapshot.data()!;
      final extractedKeyFrames = Map<String, dynamic>.from(
        data['extractedKeyFrames'] ?? {},
      );

      // 获取练习名称
      final exercises = safeMapCast(data['exercises'], 'exercises');
      String exerciseName = 'Unknown Exercise';
      if (exercises != null) {
        final exercise = safeMapCast(
          exercises[exerciseIndex.toString()],
          'exercise',
        );
        if (exercise != null && exercise['name'] != null) {
          exerciseName = exercise['name'];
        }
      }

      // 存储本地路径和上传状态
      extractedKeyFrames[exerciseIndex.toString()] = {
        'exerciseName': exerciseName,
        'keyframes': keyframesData
            .map(
              (kf) => {
                'localPath': kf['localPath'], // 本地文件路径
                'url': null, // 远程URL（待上传）
                'timestamp': kf['timestamp'],
                'uploadStatus': 'pending', // pending/uploading/uploaded/failed
              },
            )
            .toList(),
        'method': 'mlkit_pose',
      };

      await docRef.update({'extractedKeyFrames': extractedKeyFrames});

      AppLogger.info(
        'Updated Firestore with local paths for exercise $exerciseIndex',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to update Firestore with local paths',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 在后台异步上传关键帧
  void _uploadKeyframesInBackground(
    String trainingId,
    int exerciseIndex,
    List<Map<String, dynamic>> keyframesData,
  ) {
    // 使用unawaited确保不阻塞主流程
    unawaited(
      _performBackgroundUpload(trainingId, exerciseIndex, keyframesData),
    );
  }

  Future<void> _performBackgroundUpload(
    String trainingId,
    int exerciseIndex,
    List<Map<String, dynamic>> keyframesData,
  ) async {
    try {
      AppLogger.info('Starting background upload for $exerciseIndex keyframes');

      final uploadedKeyframes = <Map<String, dynamic>>[];

      for (int i = 0; i < keyframesData.length; i++) {
        final kf = keyframesData[i];
        final localPath = kf['localPath'] as String;

        try {
          // 更新上传状态为uploading
          await _updateKeyframeUploadStatus(
            trainingId,
            exerciseIndex,
            i,
            'uploading',
          );

          // 上传到Storage
          final storagePath =
              'training_keyframes/$trainingId/ex${exerciseIndex}_frame$i.jpg';
          final file = File(localPath);
          final url = await StorageService.uploadFile(file, storagePath);

          uploadedKeyframes.add({
            'url': url,
            'timestamp': kf['timestamp'],
            'uploadStatus': 'uploaded',
          });

          // 更新单个关键帧的URL
          await _updateKeyframeUrl(
            trainingId,
            exerciseIndex,
            i,
            url,
            'uploaded',
          );

          AppLogger.info('Uploaded keyframe $i: $url');
        } catch (e) {
          AppLogger.error('Failed to upload keyframe $i: $e');

          // 标记为失败，但继续上传其他帧
          await _updateKeyframeUploadStatus(
            trainingId,
            exerciseIndex,
            i,
            'failed',
          );
        }
      }

      AppLogger.info('Background upload completed for exercise $exerciseIndex');
    } catch (e, stackTrace) {
      AppLogger.error('Background upload failed', e, stackTrace);
      // 不rethrow，避免影响主流程
    }
  }

  /// 更新单个关键帧的上传状态
  Future<void> _updateKeyframeUploadStatus(
    String trainingId,
    int exerciseIndex,
    int frameIndex,
    String status,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('dailyTrainings')
          .doc(trainingId);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data()!;
      final extractedKeyFrames = Map<String, dynamic>.from(
        data['extractedKeyFrames'] ?? {},
      );

      final exerciseKey = exerciseIndex.toString();
      if (extractedKeyFrames.containsKey(exerciseKey)) {
        final exerciseData = safeMapCast(
          extractedKeyFrames[exerciseKey],
          'exerciseData',
        );
        if (exerciseData == null) return;

        final keyframes = safeMapListCast(
          exerciseData['keyframes'],
          'keyframes',
        );

        if (frameIndex < keyframes.length) {
          keyframes[frameIndex]['uploadStatus'] = status;
          exerciseData['keyframes'] = keyframes;
          extractedKeyFrames[exerciseKey] = exerciseData;

          await docRef.update({'extractedKeyFrames': extractedKeyFrames});
        }
      }
    } catch (e) {
      AppLogger.error('Failed to update upload status', e);
    }
  }

  /// 更新单个关键帧的远程URL
  Future<void> _updateKeyframeUrl(
    String trainingId,
    int exerciseIndex,
    int frameIndex,
    String url,
    String status,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('dailyTrainings')
          .doc(trainingId);

      final docSnapshot = await docRef.get();
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data()!;
      final extractedKeyFrames = Map<String, dynamic>.from(
        data['extractedKeyFrames'] ?? {},
      );

      final exerciseKey = exerciseIndex.toString();
      if (extractedKeyFrames.containsKey(exerciseKey)) {
        final exerciseData = safeMapCast(
          extractedKeyFrames[exerciseKey],
          'exerciseData',
        );
        if (exerciseData == null) return;

        final keyframes = safeMapListCast(
          exerciseData['keyframes'],
          'keyframes',
        );

        if (frameIndex < keyframes.length) {
          keyframes[frameIndex]['url'] = url;
          keyframes[frameIndex]['uploadStatus'] = status;
          exerciseData['keyframes'] = keyframes;
          extractedKeyFrames[exerciseKey] = exerciseData;

          await docRef.update({'extractedKeyFrames': extractedKeyFrames});
        }
      }
    } catch (e) {
      AppLogger.error('Failed to update keyframe URL', e);
    }
  }

  /// 清理临时文件
  Future<void> _cleanup(
    String? videoPath,
    String? framesDir,
    List<String> selectedKeyframePaths, // 需要保留的关键帧
  ) async {
    try {
      // 删除视频文件
      if (videoPath != null) {
        final videoFile = File(videoPath);
        if (await videoFile.exists()) {
          await videoFile.delete();
          AppLogger.debug('Deleted video file');
        }
      }

      // 删除帧目录中的非关键帧
      if (framesDir != null) {
        final dir = Directory(framesDir);
        if (await dir.exists()) {
          final files = await dir.list().toList();
          for (final file in files) {
            if (file is File && !selectedKeyframePaths.contains(file.path)) {
              await file.delete();
            }
          }
          AppLogger.debug('Cleaned up non-keyframe files');
        }
      }

      // 清理图像缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      AppLogger.info('Cleanup completed');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to cleanup', e, stackTrace);
      // 不重新抛出异常，清理失败不应该影响主流程
    }
  }

  /// 创建降级方案的FrameData列表
  List<FrameData> _createFallbackFramesData(List<String> framePaths) {
    return framePaths
        .asMap()
        .entries
        .map(
          (entry) => FrameData(
            frameNumber: entry.key,
            timestamp: entry.key / 10.0,
            angles: {},
            framePath: entry.value,
          ),
        )
        .toList();
  }

  /// 释放资源
  void dispose() {
    _poseDetector.close();
    AppLogger.debug('LocalKeyframeExtractor disposed');
  }
}
