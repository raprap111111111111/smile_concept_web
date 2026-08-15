import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ConsentStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const ConsentStepIndicator({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;

          return Expanded(
            child: Row(
              children: [
                _StepDot(index: i, isActive: isActive, isDone: isDone),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isDone ? AppColors.success : AppColors.border,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.index,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success
            : isActive
                ? AppColors.primary
                : AppColors.border,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color:
                      isActive ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}