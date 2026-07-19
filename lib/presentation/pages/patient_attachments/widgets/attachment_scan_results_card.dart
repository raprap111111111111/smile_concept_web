import 'package:flutter/material.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '../utils/attachment_helpers.dart';

class AttachmentScanResultsCard extends StatelessWidget {
  final PatientAttachment attachment;

  const AttachmentScanResultsCard({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
                child: const Icon(Icons.smart_toy, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Text('AI Scan Analysis', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          _buildStateWidget(),
        ],
      ),
    );
  }

  Widget _buildStateWidget() {
    if (attachment.isScanProcessing) return const _ProcessingState();
    if (attachment.isScanPending)    return const _PendingState();
    if (attachment.isScanFailed)     return const _FailedState();
    if (attachment.isScanCompleted)  return _CompletedState(attachment: attachment);
    return const SizedBox.shrink();
  }
}

// ─── SUB-WIDGETS ───

class _ProcessingState extends StatelessWidget {
  const _ProcessingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(color: AppColors.info, strokeWidth: 3),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text('Analyzing X-Ray...', style: AppTextStyles.titleSmall),
          const SizedBox(height: 4),
          Text('AI is scanning for dental conditions', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _PendingState extends StatelessWidget {
  const _PendingState();

  @override
  Widget build(BuildContext context) {
    return _StatusBox(
      color: AppColors.statusPending,
      icon: Icons.schedule,
      title: 'Scan Queued',
      subtitle: 'Your X-ray is waiting to be analyzed by AI.',
    );
  }
}

class _FailedState extends StatelessWidget {
  const _FailedState();

  @override
  Widget build(BuildContext context) {
    return _StatusBox(
      color: AppColors.error,
      icon: Icons.error_outline,
      title: 'Analysis Failed',
      subtitle: 'Unable to analyze this X-ray. Please retry.',
    );
  }
}

class _CompletedState extends StatelessWidget {
  final PatientAttachment attachment;
  const _CompletedState({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analysis Complete',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.success)),
                if (attachment.scannedAt != null) ...[
                  const SizedBox(height: 2),
                  Text('Scanned: ${AttachmentHelpers.formatDateTime(attachment.scannedAt!)}',
                      style: AppTextStyles.bodySmall),
                ],
                if (attachment.scanProvider != null) ...[
                  const SizedBox(height: 1),
                  Text('Provider: ${attachment.scanProvider}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
          if (attachment.scanConfidence != null)
            _ConfidenceBadge(confidence: attachment.scanConfidence!),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatusBox({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Column(
        children: [
          Text('${confidence.toStringAsFixed(0)}%',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.success)),
          Text('confidence',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.success, fontSize: 9,
              )),
        ],
      ),
    );
  }
}