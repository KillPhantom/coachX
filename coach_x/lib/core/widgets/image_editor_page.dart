import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Universal Image Editor Page
///
/// Supports editing images from:
/// - Network URL (networkUrl parameter)
/// - Local file path (localPath parameter)
///
/// Returns edited image as Uint8List when user completes editing
class ImageEditorPage extends StatefulWidget {
  /// Network image URL (mutually exclusive with localPath)
  final String? networkUrl;

  /// Local file path (mutually exclusive with networkUrl)
  final String? localPath;

  /// Optional feedback ID for updating existing feedback
  final String? feedbackId;

  const ImageEditorPage({
    super.key,
    this.networkUrl,
    this.localPath,
    this.feedbackId,
  }) : assert(
         networkUrl != null || localPath != null,
         'Either networkUrl or localPath must be provided',
       );

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  @override
  Widget build(BuildContext context) {
    return _buildEditor();
  }

  /// Build the ProImageEditor widget
  Widget _buildEditor() {
    if (widget.networkUrl != null) {
      return ProImageEditor.network(
        widget.networkUrl!,
        callbacks: _buildCallbacks(),
      );
    } else if (widget.localPath != null) {
      return ProImageEditor.file(
        File(widget.localPath!),
        callbacks: _buildCallbacks(),
      );
    } else {
      // Should never happen due to constructor assertion
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
  }

  /// Build editor callbacks
  ProImageEditorCallbacks _buildCallbacks() {
    return ProImageEditorCallbacks(onImageEditingComplete: _handleEditComplete);
  }

  /// Handle editing completion
  Future<void> _handleEditComplete(Uint8List bytes) async {
    // Return the edited image bytes to the calling page
    if (mounted) {
      Navigator.of(context).pop(bytes);
    }
  }
}
