import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_dimensions.dart';
import '../../route/route_names.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildNavigationBar(context),
            _buildHeroSection(context),
            _buildServicesBanner(context),
            _buildFeaturesSection(context),
            _buildCTASection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal * 2,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        border: Border(
          bottom: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _buildNavButton(context, 'Home'),
                _buildNavButton(context, 'Services'),
                _buildNavButton(context, 'About'),
              ],
            ),
          ),

          // SmileConcept Logo
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: AppDimensions.paddingXLarge),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/smile.jpg',
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Text(
                  'SmileConcept',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildNavButton(context, 'Login', isPrimary: true),
                SizedBox(width: AppDimensions.paddingMedium),
                _buildNavButton(context, 'Register', isPrimary: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String text,
      {bool isPrimary = false}) {
    return TextButton(
      onPressed: () {
        if (text == 'Login') context.pushNamed(RouteNames.login);
        if (text == 'Register') context.pushNamed(RouteNames.register);
      },
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingSmall,
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: isPrimary ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 650,
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: NetworkImage(
              'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=2000'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.secondaryDark.withValues(alpha: 0.95),
              AppColors.secondaryDark.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Row(
          children: [
            const Expanded(flex: 1, child: SizedBox()),
            Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.paddingXLarge * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ELEVATE Your Life',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'With A Signature Smile!',
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'An artistry of care. Experience the SmileConcept difference.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () => context.pushNamed(RouteNames.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.secondaryDark,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('DISCOVER THE EXPERIENCE'),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppDimensions.paddingXLarge,
        horizontal: AppDimensions.screenPaddingHorizontal,
      ),
      decoration: BoxDecoration(gradient: AppColors.goldGradient),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: [
          _buildServiceRibbon('GENERAL WELLNESS', Icons.medical_services, true),
          _buildServiceRibbon('ARTISTRY VENEERS', Icons.auto_awesome, false),
          _buildServiceRibbon('PERFECTED ALIGNMENT', Icons.straighten, true),
          _buildServiceRibbon('GUM HEALTH ART', Icons.water_drop, false),
          _buildServiceRibbon('RESTORATIVE CROWNS', Icons.shield, true),
        ],
      ),
    );
  }

  Widget _buildServiceRibbon(String title, IconData icon, bool isLight) {
    return Container(
      width: 180,
      height: 140,
      decoration: BoxDecoration(
        color: isLight ? AppColors.primary : AppColors.secondaryDark,
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5), width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isLight ? AppColors.secondaryDark : AppColors.primary,
              size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: isLight ? AppColors.secondaryDark : AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal * 2,
        vertical: AppDimensions.paddingXLarge * 2,
      ),
      color: AppColors.secondaryDark,
      child: Column(
        children: [
          Text(
            'THE SMILECONCEPT DISTINCTION',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 100, height: 2, color: AppColors.primary),
          const SizedBox(height: AppDimensions.paddingXLarge * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeatureItem(Icons.schedule, 'SEAMLESS BOOKING',
                  'Schedule appointments online 24/7'),
              _buildFeatureItem(Icons.lock, 'SECURE RECORDS',
                  'Your medical data is protected'),
              _buildFeatureItem(Icons.notifications_active, 'SMART REMINDERS',
                  'Never miss an appointment'),
              _buildFeatureItem(Icons.account_balance_wallet,
                  'TRANSPARENT BILLING', 'Clear & easy payments'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingLarge),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: AppDimensions.paddingLarge),
        Text(
          title,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppDimensions.paddingSmall),
        SizedBox(
          width: 200,
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal * 2,
        vertical: AppDimensions.paddingXLarge * 2,
      ),
      decoration: BoxDecoration(gradient: AppColors.goldGradient),
      child: Column(
        children: [
          Text(
            'READY TO TRANSFORM YOUR SMILE?',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.secondaryDark,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            'Book your appointment today and experience the SmileConcept difference',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.secondaryDark,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXLarge),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.secondaryDark, width: 2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: ElevatedButton(
              onPressed: () => context.pushNamed(RouteNames.register),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryDark,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXLarge * 2,
                  vertical: AppDimensions.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: Text(
                'GET STARTED NOW',
                style: AppTextStyles.labelLarge
                    .copyWith(fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
        vertical: AppDimensions.paddingLarge,
      ),
      color: AppColors.secondaryDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/smile.jpg',
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Text(
                'SmileConcept',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingMedium),
          Text(
            '© 2024 SmileConcept Dental. All rights reserved.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
