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
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.line),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            PageTitleResolver.resolve(context),
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Row(
            children: [
              NotificationBell(),
              SizedBox(width: 12),
              TopbarUserInfo(),
            ],
          ),
        ],
      ),
    );
  }
}