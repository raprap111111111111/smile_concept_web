import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../route/route_names.dart';
import '/presentation/theme/app_colors.dart';
import '/presentation/theme/app_dimensions.dart';
import 'landing_shared_widgets.dart';

class LandingNavigation extends StatelessWidget {
  const LandingNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AppDimensions.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLarge,
              vertical: AppDimensions.navVerticalPadding,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact =
                    constraints.maxWidth < AppDimensions.compactBreakpoint;

                if (isCompact) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _Logo(),
                      const _Actions(),
                    ],
                  );
                }

                // Desktop: force full width row with 3 zones
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LEFT
                    const _Logo(),
                    // CENTER
                    const _NavLinks(),
                    // RIGHT
                    const _Actions(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          child: Image.asset(
            'assets/images/smile.jpg',
            height: AppDimensions.navLogoSize,
            width: AppDimensions.navLogoSize,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'SmileConcept',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NavLinks extends StatelessWidget {
  const _NavLinks();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        LandingNavLink(label: 'Services'),
        LandingNavLink(label: 'Doctors'),
        LandingNavLink(label: 'Care'),
        LandingNavLink(label: 'Contact'),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LoginButton(onTap: () => context.goNamed(RouteNames.login)),
        const SizedBox(width: 12),
        LandingPrimaryButton(
          label: 'Register',
          onTap: () => context.goNamed(RouteNames.register),
        ),
      ],
    );
  }
}

/// Custom login button that bypasses theme defaults completely
class _LoginButton extends StatefulWidget {
  const _LoginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accentWithOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(
              color: _hovered ? AppColors.primary : AppColors.line,
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 8),
              Text(
                'Login',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}