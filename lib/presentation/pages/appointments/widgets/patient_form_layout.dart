import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';
class FieldPlaceholder extends StatelessWidget {
  final String label;
  final bool isError;

  const FieldPlaceholder({super.key, required this.label, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: isError ? AppColors.error : AppColors.border),
      ),
      child: Row(
        children: [
          if (isError)
            const Icon(Icons.error_outline, size: AppDimensions.iconSizeSmall, color: AppColors.error)
          else
            const SizedBox(
              width: AppDimensions.iconSizeSmall,
              height: AppDimensions.iconSizeSmall,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: AppDimensions.paddingSmall),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isError ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderNote extends StatelessWidget {
  final IconData icon;
  final String label;

  const HeaderNote({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.iconSizeSmall, color: AppColors.textOnDarkMuted),
        const SizedBox(width: AppDimensions.paddingXS),
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textOnDarkMuted)),
      ],
    );
  }
}

class FormSection extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle),
                child: Text('$step', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark)),
              ),
              const SizedBox(width: AppDimensions.paddingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.labelMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          const Divider(),
          const SizedBox(height: AppDimensions.paddingMedium),
          ...children,
        ],
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? helperText;
  final Widget child;

  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.labelLarge),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text('*', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w800)),
              ],
            ],
          ),
          if (helperText != null) ...[
            const SizedBox(height: 2),
            Text(helperText!, style: AppTextStyles.labelSmall),
          ],
          const SizedBox(height: AppDimensions.paddingXS),
          child,
        ],
      ),
    );
  }
}

class ResponsiveFieldRow extends StatelessWidget {
  final bool isCompact;
  final List<Widget> children;

  const ResponsiveFieldRow({super.key, required this.isCompact, required this.children});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: AppDimensions.paddingMedium),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}