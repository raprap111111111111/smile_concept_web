import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_dimensions.dart';
import 'role_badge.dart';

class PrescriptionFormHeader extends StatelessWidget {
  final String role;

  const PrescriptionFormHeader({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Row(
        children: [
          _buildIcon(),
          const SizedBox(width: 16),
          const Expanded(child: _HeaderText()),
          RoleBadge(role: role),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius:
            BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: const Icon(
        Icons.medication_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Prescription',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Fill in the details below to create a prescription',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}