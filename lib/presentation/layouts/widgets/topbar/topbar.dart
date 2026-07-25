// lib/presentation/layouts/widgets/topbar/topbar.dart

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/common/notification_bell.dart';
import 'page_title.dart';
import 'topbar_user_info.dart';

class Topbar extends StatelessWidget {
  const Topbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(
          bottom: BorderSide(color: AppColors.line),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Page Title (flexible, ellipsis if too long) ───
          Expanded(
            child: Text(
              PageTitleResolver.resolve(context),
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          const SizedBox(width: 12),

          // ── Right Actions (fixed width, doesn't shrink) ───
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NotificationBell(),
              const SizedBox(width: 12),

              // Vertical divider
              Container(
                width: 1,
                height: 28,
                color: AppColors.line,
              ),
              const SizedBox(width: 12),

              const Flexible(
                child: TopbarUserInfo(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}