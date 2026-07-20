import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import '../../../../theme/app_text_styles.dart';

class PrescriptionFormSection extends StatelessWidget {
  final String number;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final bool isOptional;
  final List<Widget> children;

  const PrescriptionFormSection({
    super.key,
    required this.number,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.trailing,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(color: AppColors.line, height: 1),
          _buildBody(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        children: [
          _buildNumberBadge(),
          const SizedBox(width: 12),
          Expanded(child: _buildTitleColumn()),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildNumberBadge() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accentWithOpacity(0.15),
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Center(
        child: Text(
          number,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }

  Widget _buildTitleColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTextStyles.titleMedium),
            if (isOptional) ...[
              const SizedBox(width: 8),
              _buildOptionalBadge(),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTextStyles.bodySmall),
        ],
      ],
    );
  }

  Widget _buildOptionalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'Optional',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}