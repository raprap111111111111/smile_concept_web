import 'package:flutter/material.dart';
import '/core/config/api_config.dart';
import '/core/widgets/authenticated_image.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import 'full_screen_image_viewer.dart';

class AttachmentImagePreview extends StatelessWidget {
  final PatientAttachment attachment;
  final double height;

  const AttachmentImagePreview({
    super.key,
    required this.attachment,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.attachmentFileUrl(attachment.id);

    return GestureDetector(
      onTap: () => _openFullScreen(context, url),
      child: Hero(
        tag: 'attachment-${attachment.id}',
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AuthenticatedImage(
                url: url,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
              ),
              const Positioned(
                top: 12,
                right: 12,
                child: _ZoomHint(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageUrl: url,
          heroTag: 'attachment-${attachment.id}',
          fileName: attachment.fileName,
        ),
      ),
    );
  }
}

class _ZoomHint extends StatelessWidget {
  const _ZoomHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.zoom_in, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text('Tap to zoom',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}