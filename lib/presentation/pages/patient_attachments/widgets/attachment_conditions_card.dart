import 'package:flutter/material.dart';
import '/data/models/patient_attachment/patient_attachment_model.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import '/presentation/theme/app_text_styles.dart';
import '../utils/attachment_helpers.dart';

class AttachmentConditionsCard extends StatelessWidget {
  final PatientAttachment attachment;

  const AttachmentConditionsCard({super.key, required this.attachment});

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
          _Header(count: attachment.detectedConditions.length),
          const SizedBox(height: AppDimensions.paddingMedium),
          ...attachment.detectedConditions.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingSmall),
              child: _ConditionItem(condition: c),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSmall),
          const _Disclaimer(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
        ),
        const SizedBox(width: AppDimensions.paddingSmall),
        Text('Detected Conditions', style: AppTextStyles.titleMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          ),
          child: Text('$count found',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w800,
              )),
        ),
      ],
    );
  }
}

class _ConditionItem extends StatelessWidget {
  final DetectedCondition condition;
  const _ConditionItem({required this.condition});

  @override
  Widget build(BuildContext context) {
    final color = AttachmentHelpers.severityColor(condition.severity);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ToothBadge(number: condition.toothNumber, color: color),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AttachmentHelpers.formatConditionName(condition.condition),
                        style: AppTextStyles.labelLarge.copyWith(color: AppColors.ink)),
                    if (condition.location != null)
                      Text('Location: ${condition.location}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textMuted, fontSize: 12,
                          )),
                  ],
                ),
              ),
              _SeverityBadge(severity: condition.severity, confidence: condition.confidence, color: color),
            ],
          ),
          if (condition.description != null) ...[
            const SizedBox(height: AppDimensions.paddingXS),
            Text(condition.description!,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _ToothBadge extends StatelessWidget {
  final int? number;
  final Color color;
  const _ToothBadge({required this.number, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
      ),
      child: Center(
        child: Text(
          number != null ? '#$number' : '—',
          style: AppTextStyles.labelSmall.copyWith(
            color: color, fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final double confidence;
  final Color color;

  const _SeverityBadge({
    required this.severity,
    required this.confidence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSmall),
          ),
          child: Text(severity.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: color, fontWeight: FontWeight.w800, fontSize: 10,
              )),
        ),
        const SizedBox(height: 4),
        Text('${confidence.toStringAsFixed(0)}%',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AI results are for reference only. '
              'Final diagnosis should be made by a qualified dentist.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted, fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}