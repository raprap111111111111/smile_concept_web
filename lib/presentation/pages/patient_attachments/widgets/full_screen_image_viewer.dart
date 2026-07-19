import 'package:flutter/material.dart';
import '/core/widgets/authenticated_image.dart';
import '../utils/file_launcher.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String fileName;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(fileName,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in browser',
            onPressed: () => FileLauncher.openUrl(context, imageUrl),
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: AuthenticatedImage(url: imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}