// lib/presentation/layouts/widgets/sidebar/sidebar_header.dart
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_dimensions.dart';
import '../../../theme/app_text_styles.dart';

class SidebarHeader extends StatelessWidget {
  /// Icon-rail mode: the wordmark is dropped, only the logo tile stays.
  final bool collapsed;

  const SidebarHeader({super.key, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            collapsed ? 16 : 22,
            24,
            collapsed ? 16 : 22,
            20,
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accentWithOpacity(0.22),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadius),
                  border: Border.all(
                    color: AppColors.accentWithOpacity(0.5),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/smile.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SmileConcept',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 12 : 16),
          child: const Divider(
            color: AppColors.line,
            height: 1,
          ),
        ),
      ],
    );
  }
}
