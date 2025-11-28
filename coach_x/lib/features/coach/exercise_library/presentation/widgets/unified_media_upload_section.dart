import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, CircularProgressIndicator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:coach_x/core/theme/app_theme.dart';
import 'package:coach_x/core/services/video_service.dart';
import 'package:coach_x/core/providers/video_upload_providers.dart';
import 'package:coach_x/core/utils/video_utils.dart';
import 'package:coach_x/core/utils/logger.dart';
import '../providers/exercise_library_providers.dart';

/// Media Type Enum
enum MediaType { image, video }

/// Media Item State
class MediaItemState {
  final String id;
  final MediaType type;
  final String? url; // Remote URL
  final String? localPath;
  final String? thumbnailUrl; // Remote thumbnail URL
  final String? localThumbnailPath;
  final double progress;
  final bool isUploading;
  final String? error;

  const MediaItemState({
    required this.id,
    required this.type,
    this.url,
    this.localPath,
    this.thumbnailUrl,
    this.localThumbnailPath,
    this.progress = 0.0,
    this.isUploading = false,
    this.error,
  });

  bool get isCompleted => url != null && !isUploading && error == null;

  MediaItemState copyWith({
    String? url,
    String? thumbnailUrl,
    double? progress,
    bool? isUploading,
    String? error,
  }) {
    return MediaItemState(
      id: id,
      type: type,
      url: url ?? this.url,
      localPath: localPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localThumbnailPath: localThumbnailPath,
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
  
  // Custom copyWith to allow clearing error
  MediaItemState update({
    String? url,
    String? thumbnailUrl,
    double? progress,
    bool? isUploading,
    String? error,
    bool clearError = false,
  }) {
    return MediaItemState(
      id: id,
      type: type,
      localPath: localPath,
      localThumbnailPath: localThumbnailPath,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Unified Media Upload Section
/// 
/// Handles both images and videos in a single list.
/// Only supports Gallery selection.
class UnifiedMediaUploadSection extends ConsumerStatefulWidget {
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
  ConsumerState<UnifiedMediaUploadSection> createState() => _UnifiedMediaUploadSectionState();
}

class _UnifiedMediaUploadSectionState extends ConsumerState<UnifiedMediaUploadSection> {
  final List<MediaItemState> _mediaItems = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  void _initializeMedia() {
    // Add existing videos
    for (int i = 0; i < widget.initialVideoUrls.length; i++) {
      _mediaItems.add(MediaItemState(
        id: '${DateTime.now().microsecondsSinceEpoch}_v_$i',
        type: MediaType.video,
        url: widget.initialVideoUrls[i],
        thumbnailUrl: i < widget.initialThumbnailUrls.length ? widget.initialThumbnailUrls[i] : null,
      ));
    }

    // Add existing images
    for (int i = 0; i < widget.initialImageUrls.length; i++) {
      _mediaItems.add(MediaItemState(
        id: '${DateTime.now().microsecondsSinceEpoch}_i_$i',
        type: MediaType.image,
        url: widget.initialImageUrls[i],
      ));
    }
  }

  void _notifyChanges() {
    final videoUrls = _mediaItems
        .where((m) => m.type == MediaType.video && m.isCompleted)
        .map((m) => m.url!)
        .toList();
    
    final thumbnailUrls = _mediaItems
        .where((m) => m.type == MediaType.video && m.isCompleted)
        .map((m) => m.thumbnailUrl ?? '')
        .toList();

    final imageUrls = _mediaItems
        .where((m) => m.type == MediaType.image && m.isCompleted)
        .map((m) => m.url!)
        .toList();

    widget.onVideoUrlsChanged(videoUrls);
    widget.onThumbnailUrlsChanged(thumbnailUrls);
    widget.onImageUrlsChanged(imageUrls);
  }

  Future<void> _pickMedia() async {
    try {
      final List<XFile> medias = await _picker.pickMultipleMedia();
      
      if (medias.isNotEmpty) {
        for (final media in medias) {
          await _processAndUploadMedia(File(media.path));
        }
      }
    } catch (e) {
      AppLogger.error('Failed to pick media', e);
    }
  }

  Future<void> _processAndUploadMedia(File file) async {
    // Determine type by extension or try to decode
    final String path = file.path.toLowerCase();
    final bool isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
    
    final String id = DateTime.now().microsecondsSinceEpoch.toString();
    
    if (isVideo) {
      await _processVideo(id, file);
    } else {
      await _processImage(id, file);
    }
  }

  Future<void> _processImage(String id, File file) async {
    // Add to list
    setState(() {
      _mediaItems.add(MediaItemState(
        id: id,
        type: MediaType.image,
        localPath: file.path,
        isUploading: true,
      ));
    });

    try {
      final notifier = ref.read(exerciseLibraryNotifierProvider.notifier);
      final imageUrl = await notifier.uploadImage(file);

      setState(() {
        final index = _mediaItems.indexWhere((m) => m.id == id);
        if (index != -1) {
          _mediaItems[index] = _mediaItems[index].update(
            url: imageUrl,
            isUploading: false,
            progress: 1.0,
          );
        }
      });
      _notifyChanges();
    } catch (e) {
      setState(() {
        final index = _mediaItems.indexWhere((m) => m.id == id);
        if (index != -1) {
          _mediaItems[index] = _mediaItems[index].update(
            isUploading: false,
            error: e.toString(),
          );
        }
      });
    }
  }

  Future<void> _processVideo(String id, File file) async {
    // 1. Generate thumbnail
    final thumbnail = await VideoUtils.generateThumbnail(file.path);
    
    setState(() {
      _mediaItems.add(MediaItemState(
        id: id,
        type: MediaType.video,
        localPath: file.path,
        localThumbnailPath: thumbnail?.path,
        isUploading: true,
      ));
    });

    try {
      // 2. Compress if needed
      File finalFile = file;
      final shouldCompress = await VideoService.shouldCompress(file);
      if (shouldCompress) {
        finalFile = await VideoService.compressVideo(file);
      }

      // 3. Upload Video
      final uploadService = ref.read(videoUploadServiceProvider);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'exercise_videos/unified/$timestamp.mp4';

      uploadService.uploadVideoWithProgress(finalFile, path).listen(
        (progress) {
          if (mounted) {
            setState(() {
              final index = _mediaItems.indexWhere((m) => m.id == id);
              if (index != -1) {
                _mediaItems[index] = _mediaItems[index].update(progress: progress);
              }
            });
          }
        },
        onDone: () async {
          try {
            final downloadUrl = await uploadService.getDownloadUrl(path);
            
            // 4. Upload Thumbnail
            String? thumbUrl;
            if (thumbnail != null) {
               final thumbPath = path.replaceAll('.mp4', '_thumb.jpg');
               thumbUrl = await uploadService.uploadThumbnail(File(thumbnail.path), thumbPath);
            }

            if (mounted) {
              setState(() {
                final index = _mediaItems.indexWhere((m) => m.id == id);
                if (index != -1) {
                  _mediaItems[index] = _mediaItems[index].update(
                    url: downloadUrl,
                    thumbnailUrl: thumbUrl,
                    isUploading: false,
                    progress: 1.0,
                  );
                }
              });
              _notifyChanges();
            }
          } catch (e) {
            _handleVideoError(id, e.toString());
          }
        },
        onError: (e) => _handleVideoError(id, e.toString()),
      );

    } catch (e) {
      _handleVideoError(id, e.toString());
    }
  }

  void _handleVideoError(String id, String error) {
    if (mounted) {
      setState(() {
        final index = _mediaItems.indexWhere((m) => m.id == id);
        if (index != -1) {
          _mediaItems[index] = _mediaItems[index].update(
            isUploading: false,
            error: error,
          );
        }
      });
    }
  }

  void _deleteMedia(int index) {
    setState(() {
      _mediaItems.removeAt(index);
    });
    _notifyChanges();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaItems.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddButton();
          }
          return _buildMediaItem(_mediaItems[index - 1], index - 1);
        },
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _pickMedia,
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: AppDimensions.spacingS),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.photo_on_rectangle, color: AppColors.primaryColor, size: 32),
            const SizedBox(height: 4),
            Text(
              'Add Media',
              style: AppTextStyles.caption1.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(MediaItemState item, int index) {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: AppDimensions.spacingS),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        image: item.type == MediaType.image && (item.localPath != null || item.url != null)
            ? DecorationImage(
                image: item.localPath != null 
                    ? FileImage(File(item.localPath!)) as ImageProvider
                    : NetworkImage(item.url!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Video Thumbnail
          if (item.type == MediaType.video)
             Positioned.fill(
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(12),
                 child: item.localThumbnailPath != null
                     ? Image.file(File(item.localThumbnailPath!), fit: BoxFit.cover)
                     : (item.thumbnailUrl != null
                         ? Image.network(item.thumbnailUrl!, fit: BoxFit.cover)
                         : Container(color: Colors.black)),
               ),
             ),

          // Video Icon
          if (item.type == MediaType.video)
            const Center(
              child: Icon(CupertinoIcons.play_circle_fill, color: Colors.white, size: 32),
            ),

          // Loading
          if (item.isUploading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: item.progress > 0 ? item.progress : null,
                  color: Colors.white,
                ),
              ),
            ),

          // Error
          if (item.error != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.white),
              ),
            ),

          // Delete Button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteMedia(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
