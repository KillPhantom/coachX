import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:coach_x/core/models/media_upload_state.dart';
import 'package:coach_x/core/widgets/media_upload_section.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Unified Media Upload Section (Wrapper around MediaUploadSection)
/// 
/// Adapts the new MediaUploadSection to the legacy separate URL list API.
class UnifiedMediaUploadSection extends StatefulWidget {
  final List<String> initialVideoUrls;
  final List<String> initialThumbnailUrls;
  final List<String> initialImageUrls;
  final ValueChanged<List<String>> onVideoUrlsChanged;
  final ValueChanged<List<String>> onThumbnailUrlsChanged;
  final ValueChanged<List<String>> onImageUrlsChanged;

  const UnifiedMediaUploadSection({
    super.key,
    required this.initialVideoUrls,
    required this.initialThumbnailUrls,
    required this.initialImageUrls,
    required this.onVideoUrlsChanged,
    required this.onThumbnailUrlsChanged,
    required this.onImageUrlsChanged,
  });

  @override
  State<UnifiedMediaUploadSection> createState() => _UnifiedMediaUploadSectionState();
}

class _UnifiedMediaUploadSectionState extends State<UnifiedMediaUploadSection> {
  final List<MediaUploadState> _initialMedia = [];

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  void _initializeMedia() {
    // Add existing videos
    for (int i = 0; i < widget.initialVideoUrls.length; i++) {
      _initialMedia.add(MediaUploadState.completed(
        downloadUrl: widget.initialVideoUrls[i],
        thumbnailUrl: i < widget.initialThumbnailUrls.length ? widget.initialThumbnailUrls[i] : null,
        type: MediaType.video,
      ));
    }

    // Add existing images
    for (int i = 0; i < widget.initialImageUrls.length; i++) {
      _initialMedia.add(MediaUploadState.completed(
        downloadUrl: widget.initialImageUrls[i],
        type: MediaType.image,
      ));
    }
  }

  void _updateParent(List<MediaUploadState> currentMedia) {
      final videoUrls = currentMedia
          .where((m) => m.type == MediaType.video && m.status == MediaUploadStatus.completed && m.downloadUrl != null)
          .map((m) => m.downloadUrl!)
          .toList();
      
      final thumbnailUrls = currentMedia
          .where((m) => m.type == MediaType.video && m.status == MediaUploadStatus.completed)
          .map((m) => m.thumbnailUrl ?? '')
          .toList();

      final imageUrls = currentMedia
          .where((m) => m.type == MediaType.image && m.status == MediaUploadStatus.completed && m.downloadUrl != null)
          .map((m) => m.downloadUrl!)
          .toList();

      widget.onVideoUrlsChanged(videoUrls);
      widget.onThumbnailUrlsChanged(thumbnailUrls);
      widget.onImageUrlsChanged(imageUrls);
  }
  
  // 由于 MediaUploadSection 内部管理状态，我们只需要监听变化并同步回父组件即可。
  // 但是 MediaUploadSection 目前设计为回调 index。
  // 我们需要维护一个本地的 _currentMedia 列表来对应 index 吗？
  // MediaUploadSection 自身维护 _mediaList。
  // 当发生添加/删除时，我们如何知道完整的列表？
  // MediaUploadSection 没有暴露完整的 list changed callback。
  // 但是 CreateExerciseSheet 需要完整的 list。
  // 我们可以通过 hack 的方式：
  // 在 MediaUploadSection 中添加一个 onMediaListChanged 回调?
  // 或者在回调中维护我们自己的 list。
  
  // 让我们维护一个本地的 _localMediaList 同步 MediaUploadSection 的状态。
  // 但是 MediaUploadSection 内部是 source of truth for loading/progress.
  // 我们的 _initialMedia 只是初始值。
  // 如果我们维护 _localMediaList，我们需要在每个 callback 中同步它。
  
  List<MediaUploadState> _localMediaList = [];

  @override
  Widget build(BuildContext context) {
    if (_localMediaList.isEmpty && _initialMedia.isNotEmpty) {
        _localMediaList = List.from(_initialMedia);
    }

    return MediaUploadSection(
      storagePathPrefix: 'exercise_library/${FirebaseAuth.instance.currentUser?.uid ?? "unknown"}/',
      maxCount: 10,
      maxVideoSeconds: 600, // Library allows longer videos? Assuming 10 mins.
      initialMedia: _initialMedia,
      onMediaSelected: (index, file, type) {
        // 添加到本地列表
        setState(() {
             // 确保 index 正确，如果是添加，index 应该是 length
             // 但是 MediaUploadSection 先 setState 然后 call callback.
             // 所以这里的 index 是 MediaUploadSection 中的 index。
             // 我们需要同步 _localMediaList。
             if (index >= _localMediaList.length) {
                 _localMediaList.add(MediaUploadState.pending(localPath: file.path, type: type));
             } else {
                 // Replace? usually select is add.
                 _localMediaList[index] = MediaUploadState.pending(localPath: file.path, type: type);
             }
        });
      },
      onUploadCompleted: (index, url, thumb, type) {
          setState(() {
              if (index < _localMediaList.length) {
                  _localMediaList[index] = _localMediaList[index].copyWith(
                      status: MediaUploadStatus.completed,
                      downloadUrl: url,
                      thumbnailUrl: thumb,
                      type: type,
                  );
              }
          });
          _updateParent(_localMediaList);
      },
      onMediaDeleted: (index) {
          setState(() {
              if (index < _localMediaList.length) {
                  _localMediaList.removeAt(index);
              }
          });
          _updateParent(_localMediaList);
      },
      // Retry etc don't affect URL lists until completed
    );
  }
}
