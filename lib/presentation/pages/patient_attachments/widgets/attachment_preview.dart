import 'package:flutter/material.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '../utils/attachment_helpers.dart';
import 'attachment_generic_preview.dart';
import 'attachment_image_preview.dart';
import 'attachment_pdf_preview.dart';

class AttachmentPreview extends StatelessWidget {
  final PatientAttachment attachment;
  final double height;

  const AttachmentPreview({
    super.key,
    required this.attachment,
    this.height = 400,
  });

  @override
  Widget build(BuildContext context) {
    if (AttachmentHelpers.isImage(attachment.fileType)) {
      return AttachmentImagePreview(attachment: attachment, height: height);
    } else if (AttachmentHelpers.isPdf(attachment.fileType)) {
      return AttachmentPdfPreview(attachment: attachment);
    } else {
      return AttachmentGenericPreview(attachment: attachment);
    }
  }
}