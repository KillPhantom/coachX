import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;

  const FullScreenImageViewer({
    super.key, 
    required this.imageUrl,
    this.isLocal = false,
  });

  static void show(BuildContext context, String imageUrl, {bool isLocal = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(imageUrl: imageUrl, isLocal: isLocal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: isLocal
              ? Image.file(File(imageUrl))
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

